module Screen

import ..Cursor
import ..TERMINAL

using REPL.Terminals: CSI, raw!


export
	All,
	CurrentLine,
	FromCursorBack,
	FromCursorDown,
	FromCursorForward,
	FromCursorUp,
	alternative,
	clear!,
	raw,
	size


function alternative!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?1049h")
end

function standard!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?1049l")
end

"""
!!! note

    This function sets the terminal to raw mode.
"""
function alternative(f, terminal = TERMINAL[])
	raw(terminal) do
		alternative!(terminal)
		try
			f()
		finally
			standard!(terminal)
		end
	end
end


_clear!(stream, code) = print(stream, CSI, code)

abstract type Area end

clear!(area::Area) = clear!(TERMINAL[], area)

struct All <: Area end
clear!(terminal, ::All) = _clear!(terminal.out_stream, "2J")

struct CurrentLine <: Area end
clear!(terminal, ::CurrentLine) = _clear!(terminal.out_stream, "2K")

struct FromCursorBack <: Area end
clear!(terminal, ::FromCursorBack) = _clear!(terminal.out_stream, "1K")

struct FromCursorForward <: Area end
clear!(terminal, ::FromCursorForward) = _clear!(terminal.out_stream, "K")

struct FromCursorDown <: Area end
clear!(terminal, ::FromCursorDown) = _clear!(terminal.out_stream, "J")

struct FromCursorUp <: Area end
clear!(terminal, ::FromCursorUp) = _clear!(terminal.out_stream, "1J")


function raw(f, terminal = TERMINAL[])
	raw!(terminal, true)
	try
		f()
	finally
		raw!(terminal, false)
	end
end


"""
!!! warning

    This function will only work properly in raw mode, e.g. `Screen.raw(Screen.size)`.
"""
function size(terminal = TERMINAL[])
	Cursor.checkpoint(terminal) do
		Cursor.move!(terminal, Cursor.Coordinate(typemax(UInt16), typemax(UInt16)))
		Cursor.location(terminal)
	end
end

end # module
