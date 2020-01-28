"""
This module deals with controlling the cursor.

The two major pieces of functionality in this module are moving the cursor and hiding the cursor.

Move the cursor using the [`move!`](@ref) function:

```julia
move!(Up(3))
```

There are several different movements available, see documentation on the subtypes of [`Movement`](@ref) for more details.

It is possible to temporarily move the cursor to a different location using [`save`](@ref) or [`checkpoint`](@ref):

```julia
move!(Coordinate(1, 1))
println("First line!")

save() do
	move!(Down(4))
	println("Fifth line!")

	checkpoint() do
		move!(Down(4))
		println("Tenth line!")

		checkpoint() do
			move!(Down(4))
			println("Fifteenth line!")
		end
	end
end

println("Second line!")

checkpoint() do
	move!(Down(4))
	println("Sixth line!")

	checkpoint() do
		move!(Down(4))
		println("Eleventh line!")
	end
end
```

The location of the cursor can also be found using [`location`](@ref), though note that this only works in raw mode:

```julia-repl
julia> Screen.raw(Cursor.location)
Ansillary.Inputs.Location(0x003c, 0x0001)
```

Hiding the cursor is done using Julia's support for `do`-notation:

```julia-repl
julia> Cursor.hide() do
		   for c in "There is no cursor..."
			   print(c)
			   sleep(0.1)
		   end
	   end
There is no cursor...
```
"""
module Cursor

import ..TERMINAL

using ..Inputs: Event, Location
using REPL.Terminals: CSI


export
	Column,
	Coordinate,
	Down,
	Left,
	Movement,
	Up,
	Right,
	Row,
	checkpoint,
	hide,
	location,
	move!,
	save


"""
A nestable implementation of [`save`](@ref).

!!! warning

	This function will not work correctly with [`Inputs.EventLoop`](@ref).

!!! warning

	This function will only work correctly when using [`Screen.raw`](@ref).

This function will save the current location of the cursor, run the function, then move the cursor back to it's original location.
"""
function checkpoint(f, terminal = TERMINAL[])
	old = location(terminal)
	try
		f()
	finally
		move!(terminal, Coordinate(old.row, old.column))
	end
end


"""
Permanently hide the cursor.

Use [`show!`](@ref) to show the cursor again.

!!! note

	You should prefer using [`hide`](@ref) where possible as it's very easy to accidently leave the cursor hidden using this method.
"""
hide!(terminal = TERMINAL[]) = print(terminal.out_stream, CSI, "?25l")

"""
Show the cursor again after it has been hidden by [`hide!`](@ref).
"""
function show!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?25h")
end

"""
Temporarily hide the cursor for the duration of the provided function.
"""
function hide(f, terminal = TERMINAL[])
	hide!(terminal)
	try
		f()
	finally
		show!(terminal)
	end
end


"""
Get the current location of the cursor.

!!! warning

	This function will only work properly in raw mode, e.g. `Screen.raw(Cursor.location)`.
"""
function location(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "6n")

	event = read(terminal.in_stream, Event)

	@assert event isa Location

	event
end


_move!(terminal, codes...) = print(terminal.out_stream, CSI, codes...)

"""
A way that the cursor can be moved.

See the documentation of it's subtypes for more details:

* [`Up`](@ref)
* [`Down`](@ref)
* [`Left`](@ref)
* [`Right`](@ref)
* [`Coordinate`](@ref)
* [`Row`](@ref)
* [`Column`](@ref)
"""
abstract type Movement end

"""
Move the cursor.

See the documentation on subtypes of [`Movement`](@ref) for more details.
"""
move!(direction::Movement) = move!(TERMINAL[], direction)

"""
Move the cursor up the given number of rows.
"""
struct Up <: Movement
	count::UInt16
end
move!(terminal, direction::Up) = _move!(terminal, direction.count, "A")

"""
Move the cursor down the given number of rows.
"""
struct Down <: Movement
	count::UInt16
end
move!(terminal, direction::Down) = _move!(terminal, direction.count, "B")

"""
Move the cursor left the given number of columns.
"""
struct Left <: Movement
	count::UInt16
end
move!(terminal, direction::Left) = _move!(terminal, direction.count, "D")

"""
Move the cursor right the given number of columns.
"""
struct Right <: Movement
	count::UInt16
end
move!(terminal, direction::Right) = _move!(terminal, direction.count, "C")

"""
Move the cursor to the given coordinate.
"""
struct Coordinate <: Movement
	row::UInt16
	column::UInt16
end
move!(terminal, direction::Coordinate) = _move!(terminal, direction.row, ";", direction.column, "H")

"""
Move the cursor to a given row _without changing it's column_.

!!! warning

	This movement currently does not work properly with `Inputs.EventLoop` due to it's use of `Cursor.location`.
"""
struct Row <: Movement
	row::UInt16
end
function move!(terminal, direction::Row)
	column = location(terminal).column
	move!(terminal, Coordinate(direction.row, column))
end

"""
Move the cursor to a given column _without changing it's row_.
"""
struct Column <: Movement
	column::UInt16
end
move!(terminal, direction::Column) = _move!(terminal, direction.column, "G")


"""
Save the current location of the cursor.

You can then return to that location using [`restore!`](@ref).

!!! warning

	Calling this function twice will overwrite the old value.
"""
save!(terminal = TERMINAL[]) = print(terminal.out_stream, CSI, "s")

"""
Move the cursor back to it's saved location.

You can save a location using [`save!`](@ref).
"""
restore!(terminal = TERMINAL[]) = print(terminal.out_stream, CSI, "u")

"""
Return the cursor to it's current location after the function has finished.

!!! tip

	Use this function instead of [`checkpoint`](@ref) if you are not using raw mode or if you are using [`Inputs.EventLoop`](@ref).

!!! warning

	This uses the ANSI code for saving the cursor so it can't be nested, use [`checkpoint`](@ref) if these calls need to be nested.
"""
function save(f, terminal = TERMINAL[])
	save!(terminal)
	try
		f()
	finally
		restore!(terminal)
	end
end

end # module
