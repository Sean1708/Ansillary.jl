using Documenter, Ansillary

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

makedocs(;
    modules=[
        Ansillary,
    ],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://gitlab.com/seamsay/Ansillary.jl/blob/{commit}{path}#L{line}",
    sitename="Ansillary.jl",
    authors="Sean Marshallsay",
)
