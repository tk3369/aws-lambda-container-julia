const mod = Ref{Symbol}()
const func = Ref{Symbol}()

const AWS_LAMBDA_RUNTIME_API = ENV["AWS_LAMBDA_RUNTIME_API"]
const LAMBDA_TASK_ROOT = ENV["LAMBDA_TASK_ROOT"]
const HANDLER = ENV["_HANDLER"]
const RUNTIME_URL = "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01"

# Using curl as HTTP client

function http_get(url)
    cmd = `curl --silent --show-error --location --include --request GET $url`
    response = read(cmd, String)
    headers_str, body = split(response, "\r\n\r\n")
    headers = [s[1] => s[2] for s in split.(split(headers_str, "\r\n"), r": *") if length(s) == 2]
    return headers, body
end

function http_post(url, headers, body)
    header_lines = ["$k: $v" for (k,v) in headers]
    header_options = collect(Iterators.flatten(("-H", v) for v in header_lines))
    cmd = `curl --silent --show-error $header_options --request POST $url --data $body`
    return read(cmd, String)
end

# Convenient functions

function post_error(path::AbstractString, ex::Exception)
    headers = [
        "Content-type" => "application/json",
        "Lambda-Runtime-Function-Error-Type" => "Unhandled",
    ]
    local url
    try
        url = "$RUNTIME_URL/$path"
        http_post(url, headers, """{"errorType": "$(typeof(ex))", "errorMessage": "$(ex)"}""")
        @info "Notified lambda runtime about the error" url ex
    catch failure
        @error "Unable to notify lambda runtime about the error" url ex failure
    end
end

# Init function to load user module and locate function
function init()
    try
        @info "Loading user module"
        mod[], func[] = Symbol.(split(HANDLER, "."))

        @eval using $(mod[])

        @info "Completed loading user module" mod[] func[]
    catch ex
        @error "Initializtion error" ex
        post_error("runtime/init/error", ex)
        @info "Shutting down container"
        exit(1)
    end
end

# An infinite loop to process events
function process_events()
    @info "Start processing requests"
    while true
        local state, request_id
        try
            state = :start
            request_headers, request_body = http_get("$RUNTIME_URL/runtime/invocation/next")
            request_id_idx = findfirst(x -> x[1] == "Lambda-Runtime-Aws-Request-Id", request_headers)
            request_id = request_headers[request_id_idx][2]
            @info "Received event" request_id
            state = :received

            response = @eval $(mod[]).$(func[])($request_body, $request_headers)
            @info "Got response from handler" response
            state = :handled

            http_post("$RUNTIME_URL/runtime/invocation/$request_id/response", [], response)
            @info "notified lambda runtime"
            state = :finished
        catch ex
            if state == :start
                @error "Unable to receive request" ex
            elseif state == :received
                @error "Unable to handle event" ex request_id
                post_error("runtime/invocation/$request_id/error", ex)
            elseif state == :handled
                @error "Unable to notify lambda runtime (invocation response)" ex request_id
            else
                @error "Unknown state" ex state
            end
        end
    end
end

function main()
    init()
    process_events()
    @info "Shutdown complete"
end

main()
