module JuliaLambdaExample

function handle_event(event_data, headers)
    @info "Handling request" event_data
    return "hello world"
end

end
