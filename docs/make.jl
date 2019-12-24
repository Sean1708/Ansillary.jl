using Documenter, Ansillary

makedocs(;
    modules=[Ansillary],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://gitlab.com/seamsay/Ansillary.jl/blob/{commit}{path}#L{line}",
    sitename="Ansillary.jl",
    authors="Sean Marshallsay",
    assets=String[],
)
