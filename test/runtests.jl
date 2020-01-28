using Ansillary
using Ansillary.Inputs
using Documenter
using Test

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

# TODO: Use libvterm (http://www.leonerd.org.uk/code/libvterm/) to implement tests.

@testset "Modifiers" begin
	@test Alt()+Left() == Modified(Left(), [Alt()])
	@test Ctrl()+'c' == CTRL_C == Modified(Character('c'), [Ctrl()])
	@test Ctrl()+Alt()+Delete() == Modified(Delete(), [Ctrl(), Alt()])
	@test Shift()+Super()+'y' == Modified(Character('y'), [Shift(), Super()])
	@test Ctrl()+Alt()+Super()+F(1) == Modified(F(1), [Alt(), Super(), Ctrl()])
	@test Ctrl()+Alt()+Shift()+Super()+Character('q') == Modified(Character('q'), [Shift(), Alt(), Super(), Ctrl()])
	@test Super()+Ctrl()+Alt()+Shift()+Super()+Character('q') == Modified(Character('q'), [Shift(), Alt(), Super(), Ctrl()])
end
