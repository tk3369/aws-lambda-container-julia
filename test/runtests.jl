using JuliaLambdaExample
using Test
using JSON

@testset "JuliaLambdaExample.jl" begin
    event_data = JSON.json(Dict("simulations" => 100_000))
    result = handle_event(event_data)
    @test_nowarn JSON.parse(result)
    @test haskey(JSON.parse(result), "pi")
end
