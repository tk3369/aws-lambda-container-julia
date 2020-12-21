const AWS_LAMBDA_RUNTIME_API = ENV["AWS_LAMBDA_RUNTIME_API"]
const LAMBDA_TASK_ROOT = ENV["LAMBDA_TASK_ROOT"]
const _HANDLER = ENV["_HANDLER"]
#@info "Settings" AWS_LAMBDA_RUNTIME_API LAMBDA_TASK_ROOT _HANDLER

using JuliaLambdaExample
using HTTP

# Easy way to find a header
get_header(headers, key) = [last(p) for p in headers if first(p) == key][1]

# Loop to process events
@info "Starting loop"
while true
    try 
        r = HTTP.get("http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/next")
        request_id = get_header(r.headers, "Lambda-Runtime-Aws-Request-Id")
        @info "Received event" request_id

        response = JuliaLambdaExample.handle_event(String(r.body), r.headers)
        @info "Got response from handler" response

        HTTP.post("http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/$request_id/response", [], response)
        @info "notified lambda runtime"
    catch ex
        @error "Error: $ex"
    end
end

@info "Shut down"

