module JuliaLambdaExample

using JSON

export handle_event

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
# Input: JSON string with
function handle_event(event_data, headers = [])
    @info "Handling request" event_data headers
    parsed_data = JSON.parse(event_data)
    simulations = get(parsed_data, "simulations", 0)
    if simulations > 0
        my_pi = monte_carlo_pi(simulations)
        return JSON.json(Dict("pi" => my_pi))
    end
    error("Please specify the number of simulations")
end

end
