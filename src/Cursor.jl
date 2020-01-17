module Cursor

import ..TERMINAL

using REPL.Terminals: CSI


export Column, Coordinate, Down, Left, Up, Right, Row, checkpoint, hide, location, move!, save


function checkpoint(f, terminal = TERMINAL[])
	old = location(terminal)
	try
		f()
	finally
		move!(terminal, old)
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

	@assert read(terminal.in_stream, UInt8) == UInt8(CSI[1])
	@assert read(terminal.in_stream, UInt8) == UInt8(CSI[2])

	row = parse(UInt16, readuntil(terminal.in_stream, ';'))
	col = parse(UInt16, readuntil(terminal.in_stream, 'R'))

	Coordinate(row, col)
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
!!! note

    This uses the ANSI code for saving the cursor so it can't be nested, use
    `Cursor.checkpoint` if you need to nest these calls.
"""
function save(f, terminal = TERMINAL[])
	print(terminal.out_stream, CSI, "s")
	try
		f()
	finally
		print(terminal.out_stream, CSI, "u")
	end
end

end # module
