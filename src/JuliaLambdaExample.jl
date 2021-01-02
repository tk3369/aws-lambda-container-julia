module JuliaLambdaExample

using JSON

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

# Parse event data
function get_simulations(event_data)
    try
        parsed_data = JSON.parse(event_data)
        return parsed_data["simulations"]
    catch ex
        throw(ArgumentError("Please specify the number of simulations"))
    end
end

# Construct return value
make_result(value) = JSON.json(Dict("pi" => value)) 

# Handle a lambda invocation event
function handle_event(event_data, headers)
    @info "Handling request" event_data headers
    simulations = get_simulations(event_data)
    my_pi = monte_carlo_pi(simulations)
    return make_result(my_pi)
end

end
