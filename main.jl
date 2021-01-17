const AWS_LAMBDA_RUNTIME_API = ENV["AWS_LAMBDA_RUNTIME_API"]
const LAMBDA_TASK_ROOT = ENV["LAMBDA_TASK_ROOT"]
const HANDLER = ENV["_HANDLER"]  # from Dockerfile's CMD command
const RUNTIME_URL = "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01"

# Using curl as HTTP client.
# (Don't want to introduce HTTP.jl dependency for faster initialization)

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

# Convenient function to post errors to the lamdba execution environment
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

# Initialize lambda function by loading user module
try
    @info "Loading user module"
    global mod, func = Symbol.(split(HANDLER, "."))

    @eval using $(mod)

    @info "Completed loading user module" mod func
catch ex
    @error "Initializtion error" ex
    post_error("runtime/init/error", ex)
    @info "Shutting down container"
    exit(1)
end

@info "Resolve handler function"
const my_module = Base.eval(Main, mod)
const my_handler = Base.eval(my_module, func)

# An infinite loop to process events
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

        response  = my_handler(request_body, request_headers)
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

@info "All done"
