using Test
using ConstExpr

@testset "@constfunction" begin
    @constfunction nbits(x) = sizeof(x) * 8
    @test @inferred nbits(5) == 64
    Main.@code_typed nbits(5)

    # Test non-const case:
    @constfunction f(x) = x+1
    @test_throws AssertionError f(5) # ERROR: AssertionError: Main.ConstExpr.f failed to compile away to a Const!
end


@testset "@constexpr" begin
    function typestablefunc(x)
        nbits = @constexpr sizeof(x) * 8
        return Val(nbits)
    end

    @test @inferred typestablefunc(5) == Val{64}()
    @test @inferred typestablefunc(Int8(2)) == Val{8}()

    function typeUNstablefunc(x)
        return @constexpr Val(x)
    end
    @macroexpand @constexpr Val(x)

    # ERROR: AssertionError: Expr (Val(x)) failed to compile away to a Const!
    @test_throws AssertionError typeUNstablefunc(5)
end
