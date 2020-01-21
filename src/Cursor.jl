module Cursor

import ..TERMINAL

using ..Inputs: Event, Location
using REPL.Terminals: CSI


export Column, Coordinate, Down, Left, Up, Right, Row, checkpoint, hide, location, move!, save


function checkpoint(f, terminal = TERMINAL[])
	old = location(terminal)
	try
		f()
	finally
		move!(terminal, Coordinate(old.row, old.column))
	end
end


function hide!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?25l")
end

function show!(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "?25h")
end

function hide(f, terminal = TERMINAL[])
	hide!(terminal)
	try
		f()
	finally
		show!(terminal)
	end
end


"""
!!! warning

    This function will only work properly in raw mode, e.g. `Screen.raw(Cursor.location)`.

!!! warning

    This function currently does not work correctly with `Inputs.EventLoop`.
"""
function location(terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "6n")

	event = read(terminal.in_stream, Event)

	@assert event isa Location

	event
end


struct Up
	count::UInt16
end
move!(terminal, direction::Up) = print(terminal.out_stream, CSI, direction.count, "A")
move!(direction::Up) = move!(TERMINAL[], direction)

struct Down
	count::UInt16
end
move!(terminal, direction::Down) = print(terminal.out_stream, CSI, direction.count, "B")
move!(direction::Down) = move!(TERMINAL[], direction)

struct Left
	count::UInt16
end
move!(terminal, direction::Left) = print(terminal.out_stream, CSI, direction.count, "D")
move!(direction::Left) = move!(TERMINAL[], direction)

struct Right
	count::UInt16
end
move!(terminal, direction::Right) = print(terminal.out_stream, CSI, direction.count, "C")
move!(direction::Right) = move!(TERMINAL[], direction)

struct Coordinate
	row::UInt16
	column::UInt16
end
move!(terminal, direction::Coordinate) = print(terminal.out_stream, CSI, direction.row, ";", direction.column, "H")
move!(direction::Coordinate) = move!(TERMINAL[], direction)

"""
!!! warning

    This movement currently does not work properly with `Inputs.EventLoop` due to it's use of `Cursor.location`.
"""
struct Row
	row::UInt16
end
function move!(terminal, direction::Row)
	column = location(terminal).column
	move!(terminal, Coordinate(direction.row, column))
end
move!(direction::Row) = move!(TERMINAL[], direction)

struct Column
	column::UInt16
end
move!(terminal, direction::Column) = print(terminal.out_stream, CSI, direction.column, "G")
move!(direction::Column) = move!(TERMINAL[], direction)


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

!!! note

    This uses the ANSI code for saving the cursor so it can't be nested, use
    `Cursor.checkpoint` if these calls need to be nested.
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
