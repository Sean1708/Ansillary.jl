"""
Ansillary is a package for interacting with ANSI compatible terminals.

Ansillary aims to support only the commonly supported capabilities of ANSI terminals, i.e. completely replacing ncurses is not a goal of Ansillary. Explicitly, if a capability is not available in one of the following terminals then it will not be supported in Ansillary:

* LibVTE terminals.
* LibVTerm terminals.
* The Linux console.
* Konsole.
* XTerm.

The reason for this is simple, reliable capability detection is harder than writing a package that wraps ncurses (or similar libraries such as termbox). Do note, however, that if a terminal does not support a capability but the lack of that capability does not cause issues for the user then it will be supported. For example, bracketed paste mode is supported despite the Linux console not actually having a paste feature because the Linux console still parses and accepts the required escape sequences even though they have no effect. Whereas scrolling is _not_ supported because the Linux console does not support scrolling and not having something scroll is something that the user will definitely notice.

The package is currently split into three modules: [`Cursor`](@ref) for controlling the position and visibilty of the cursor, [`Inputs`](@ref) for reading input events from a terminal, and [`Screen`](@ref) for controlling what is displayed.
"""
module Ansillary

using REPL.Terminals: TTYTerminal


export Cursor, Inputs, Screen, TTYTerminal


const TERMINAL = Ref{TTYTerminal}()

function __init__()
	TERMINAL[] = TTYTerminal(get(ENV, "TERM", Sys.iswindows() ? "" : "dumb"), stdin, stdout, stderr)
end


# Needs to be at top because `Cursor` needs it.
include("Inputs.jl")

include("Cursor.jl")
include("Screen.jl")

end # module
