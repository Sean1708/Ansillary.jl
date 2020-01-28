using Ansillary
using Ansillary.Inputs
using Documenter
using JuliaFormatter
using Test

# Style Tests!

function isformatted(path)
    if isfile(path)
        if last(splitext(path)) != ".jl" || success(`git check-ignore $path`)
            return true
        end

        original = read(path, String)
        formatted = format_text(
            original,
            always_for_in = true,
            whitespace_typedefs = true,
            whitespace_ops_in_indices = true,
            remove_extra_newlines = true,
        )

        original == formatted
    else
        isformatted(joinpath.(path, readdir(path)))
    end
end

isformatted(paths::Vector) = all(isformatted.(paths))

@testset "Formatting" begin
    let tests = dirname(@__FILE__), project = dirname(tests)
        @test isformatted(project)
    end
end

# Doc Tests!

DocMeta.setdocmeta!(Ansillary, :DocTestSetup, :(using Ansillary))
DocMeta.setdocmeta!(
    Ansillary.Cursor,
    :DocTestSetup,
    :(using Ansillary; using Ansillary.Cursor),
)
DocMeta.setdocmeta!(
    Ansillary.Inputs,
    :DocTestSetup,
    :(using Ansillary; using Ansillary.Inputs),
)
DocMeta.setdocmeta!(
    Ansillary.Screen,
    :DocTestSetup,
    :(using Ansillary; using Ansillary.Screen),
)
doctest(Ansillary)

# Unit Tests!

# TODO: Use libvterm (http://www.leonerd.org.uk/code/libvterm/) to implement tests.

@testset "Modifiers" begin
    @test Alt() + Left() == Modified(Left(), [Alt()])
    @test Ctrl() + 'c' == CTRL_C == Modified(Character('c'), [Ctrl()])
    @test Ctrl() + Alt() + Delete() == Modified(Delete(), [Ctrl(), Alt()])
    @test Shift() + Super() + 'y' == Modified(Character('y'), [Shift(), Super()])
    @test Ctrl() + Alt() + Super() + F(1) == Modified(F(1), [Alt(), Super(), Ctrl()])
    @test Ctrl() + Alt() + Shift() + Super() + Character('q') ==
          Modified(Character('q'), [Shift(), Alt(), Super(), Ctrl()])
    @test Super() + Ctrl() + Alt() + Shift() + Super() + Character('q') ==
          Modified(Character('q'), [Shift(), Alt(), Super(), Ctrl()])
end
