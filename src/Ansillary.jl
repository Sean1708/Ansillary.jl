module Ansillary

using REPL.Terminals: TTYTerminal


export Cursor, Inputs, Screen, Scroll, TTYTerminal


const TERMINAL = Ref{TTYTerminal}()

function __init__()
	TERMINAL[] = TTYTerminal(get(ENV, "TERM", Sys.iswindows() ? "" : "dumb"), stdin, stdout, stderr)
end


# Needs to be at top because `Cursor` needs it.
include("Inputs.jl")

include("Cursor.jl")
include("Screen.jl")
include("Scroll.jl")

end # module
