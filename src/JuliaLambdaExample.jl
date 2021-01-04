module JuliaLambdaExample

# Calculate π using Monte Carlo simulation
function monte_carlo_pi(n)
    inside((x, y)) = x * x + y * y < 1.0
    points = rand(2, n)
    hits = count(inside(points[:, v]) for v in 1:n)
    return hits / n * 4
end

# Parsing input
parse_simulations(event_data) = parse(Int, event_data)

# Formatting for output
json_result(value) = """{"pi":$value}"""

# Lambda invocation handler
function handle_event(event_data, headers)
    @info "Handling request" event_data headers
    simulations = parse_simulations(event_data)
    my_pi = monte_carlo_pi(simulations)
    return json_result(my_pi)
end

end
