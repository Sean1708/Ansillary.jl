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


"""
Permanently activate the alternative screen.

Use [`standard!`](@ref) to switch back to the standard screen.

This function **does not** set the terminal to raw mode, so that must be done
manually where necessary.

!!! note

    You should prefer using [`alternative`](@ref) where possible as it's very
    easy to accidently leave the terminal on the alternative screen using this
    method.
"""
function alternative!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?1049h")
end

"""
Permanently activate the standard screen.
"""
function standard!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?1049l")
end

"""
Temporarily activate the alernative screen for the duration of the function.

This function also sets the terminal to raw mode as it is raw that you'll need
the alternative screen but not raw mode. If the alternative screen is needed
without setting raw mode, use [`alternative!`](@ref) and [`standard!`](@ref)
directly.
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


_clear!(terminal, code) = print(terminal.out_stream, CSI, code)

abstract type Area end

"""
Clear an area of the screen.

See subtypes of [`Area`](@ref) for more details.
"""
clear!(area::Area) = clear!(TERMINAL[], area)

"""
Clear the entire screen.
"""
struct All <: Area end
clear!(terminal, ::All) = _clear!(terminal, "2J")

"""
Clear the line that the cursor is currently on.
"""
struct CurrentLine <: Area end
clear!(terminal, ::CurrentLine) = _clear!(terminal, "2K")

"""
Clear from the start of the current line up to, and including, the cursor.
"""
struct FromCursorBack <: Area end
clear!(terminal, ::FromCursorBack) = _clear!(terminal, "1K")

"""
Clear from the cursor up to the end of the line.
"""
struct FromCursorForward <: Area end
clear!(terminal, ::FromCursorForward) = _clear!(terminal, "K")

"""
Clear from the cursor up to the end of the line and all lines below the cursor.
"""
struct FromCursorDown <: Area end
clear!(terminal, ::FromCursorDown) = _clear!(terminal, "J")

"""
Clear from the start of the current line up to the cursor and any lines above the cursor.
"""
struct FromCursorUp <: Area end
clear!(terminal, ::FromCursorUp) = _clear!(terminal, "1J")


"""
Temporarily set the terminal to raw mode for the duration of the function.

If switching to raw mode permanently is required use [`REPL.Terminals.raw!`](@ref).
"""
function raw(f, terminal = TERMINAL[])
	raw!(terminal, true)
	try
		f()
	finally
		raw!(terminal, false)
	end
end


struct Size
	rows::UInt32
	columns::UInt32
end

"""
Get the current size of the terminal.

See also: [`displaysize`](@ref).
"""
function size(terminal = TERMINAL[])
	(rows, columns) = displaysize(terminal.out_stream)
	Size(rows, columns)
end

end # module
