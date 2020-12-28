module JuliaLambdaExample

using JSON

# Must export `handle_event` function
export handle_event

# Put any extra initialization code here
function __init__()
    @info "Initializing module"
end

# Calculate π using Monte Carlo simulation
function monte_carlo_pi(n)
    inside((x, y)) = x * x + y * y < 1.0
    points = rand(2, n)
    hits = count(inside(points[:, v]) for v in 1:n)
    return hits / n * 4
end

# Handle a lambda invocation event
function handle_event(event_data, headers = [])
    @info "Handling request" event_data headers

    parsed_data = JSON.parse(event_data)
    simulations = get(parsed_data, "simulations", 0)
    if simulations > 0
        my_pi = monte_carlo_pi(simulations)
        return JSON.json(Dict("pi" => my_pi))
    end

    # Raising an exception would cause the event to be logged and discarded
    error("Please specify the number of simulations")
end

end
