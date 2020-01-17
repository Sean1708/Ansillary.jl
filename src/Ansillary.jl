module Ansillary

using REPL.Terminals: TTYTerminal


export Cursor, Inputs, Screen, Scroll, TTYTerminal


const TERMINAL = Ref{TTYTerminal}()

function __init__()
	TERMINAL[] = TTYTerminal(get(ENV, "TERM", Sys.iswindows() ? "" : "dumb"), stdin, stdout, stderr)
end


include("Cursor.jl")
include("Inputs.jl")
include("Screen.jl")
include("Scroll.jl")

end # module
