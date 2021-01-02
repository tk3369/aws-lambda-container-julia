using JuliaLambdaExample
using Test
using JSON

@testset "JuliaLambdaExample.jl" begin
    event_data = JSON.json(Dict("simulations" => 100_000))
    result = JuliaLambdaExample.handle_event(event_data, [])
    @test haskey(JSON.parse(result), "pi")
end
