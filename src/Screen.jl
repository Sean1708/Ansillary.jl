"""
This module deals with controlling what is displayed on the screen.

The two major features of this module are switching to the alernative screen and clearing the what is currenlty on the screen.

The [alternative screen](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-The-Alternate-Screen-Buffer) is a feature of most terminals that allows an application to switch to a screen that has no scrollback, allowing it to draw whatever it wants to the terminal without interfering with the scrollback of the normal screen. This is most useful for full-screen applications, such as vim or emacs. Ansillary allows you to enter the alternative screen with the [`alternative`](@ref) function:

```julia-repl
julia> Screen.alternative() do
		   println("No scrollback!")
		   read(stdin, UInt8)
	   end
```

Ansillary will set raw mode (also known as [non-canonical mode](https://www.gnu.org/software/libc/manual/html_node/Canonical-or-Not.html)) when [`alternative`](@ref) is called as this is almost always what is wanted, to avoid this use the non-exported [`alternative!`](@ref) and [`standard!`](@ref) functions.

It also possible to only set raw mode using the [`raw`](@ref) function. The main benefits of raw mode are that the input stream is not line buffered allowing one byte to be read at a time (which in turn allows the application to respond to key presses), and that the input is not printed directly to the output allowing the application to handle printable input in it's own way (so that it can implement vim-style keybindings, for example).

To clear the screen Ansillary provides the [`clear!`](@ref) function, as well as the [`Area`](@ref) types for specifying which parts of the screen need clearing.

This short script

```julia
print("Some line...")
move!(Left(3))
clear!(FromCursorForward())
print("!")
```

will result in `Some line!` being printed to the terminal.

This module also provides the [`size`](@ref) as a slightly nicer wrapper around `displaysize`.
"""
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

This function **does not** set the terminal to raw mode, so that must be done manually where necessary.

!!! note

	You should prefer using [`alternative`](@ref) where possible as it's very easy to accidently leave the terminal on the alternative screen using this method.
"""
alternative!(terminal = TERMINAL[]) = print(terminal.out_stream, CSI, "?1049h")

"""
Permanently activate the standard screen.
"""
standard!(terminal = TERMINAL[]) = print(terminal.out_stream, CSI, "?1049l")

"""
Temporarily activate the alernative screen for the duration of the function.

This function also sets the terminal to raw mode as it is rare that you'll need the alternative screen but not raw mode. If the alternative screen is needed without setting raw mode, use [`alternative!`](@ref) and [`standard!`](@ref) directly.
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

"""
An area of the screen.

See the documentation on it's subtypes for more details:

* [`All`](@ref)
* [`CurrentLine`](@ref)
* [`FromCursorBack`](@ref)
* [`FromCursorForward`](@ref)
* [`FromCursorDown`](@ref)
* [`FromCursorUp`](@ref)
"""
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

If switching to raw mode permanently is required use `REPL.Terminals.raw!`.
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

See also: `displaysize`.
"""
function size(terminal = TERMINAL[])
	(rows, columns) = displaysize(terminal.out_stream)
	Size(rows, columns)
end

end # module
