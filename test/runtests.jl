using JuliaLambdaExample
using Test

@testset "JuliaLambdaExample.jl" begin
    result = JuliaLambdaExample.handle_event("1000000", String[])
    @test result isa String
    @test_nowarn parse(Float64, result)
    @test isapprox(parse(Float64, result), π, atol = 0.1)
end
