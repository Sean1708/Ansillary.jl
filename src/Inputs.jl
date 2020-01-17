"""
!!! warning

    The functionality of this module will only work properly if the terminal is
    in raw mode, e.g.

    ```julia
    Screen.raw() do
        for key in Inputs.Events(stdin)
            @show key
            if key == Inputs.CTRL_C
                break
            end
        end
    end
    ```
"""
module Inputs

import ..TERMINAL
import REPL.Terminals

using Dates: Millisecond, Period, Second, now


export
	Alt,
	Backspace,
	Character,
	Ctrl,
	CTRL_C,
	Delete,
	Down,
	End,
	Esc,
	Event,
	Events,
	EventLoop,
	F,
	Home,
	Insert,
	Left,
	Meta,
	Millisecond,
	Null,
	PageDown,
	PageUp,
	Right,
	Second,
	Shift,
	Tick,
	Up


abstract type Event end

struct Unknown <: Event
	data::Vector{UInt8}
end

# When trying to read an event, we want to soak up any extra bytes because it
# is better to miss an event that was sent quickly than it is to accidentally
# send an event that the user didn't wish to send.
Unknown(data, input) = Unknown([
	data;
	bytesavailable(input) > 0 ? readavailable(input) : [];
])

struct Tick <: Event end

abstract type Input <: Event end

abstract type Key <: Input end

Base.show(io::IO, key::Key) = print(io, nameof(typeof(key)))

struct Backspace <: Key end

struct Backtab <: Key end

struct Delete <: Key end

struct Up <: Key end

struct Down <: Key end

struct Left <: Key end

struct Right <: Key end

struct Home <: Key end

struct End <: Key end

struct PageUp <: Key end

struct PageDown <: Key end

struct Insert <: Key end

struct Esc <: Key end

struct Null <: Key end

struct F <: Key
	number::UInt8
end

Base.show(io::IO, f::F) = print(io, 'F', f.number)

struct Character <: Key
	value::Char
end

Base.show(io::IO, character::Character) = print(io, character.value)

abstract type Modifier end

Base.show(io::IO, modifier::Modifier) = print(io, nameof(typeof(modifier)))

struct Meta <: Modifier end

struct Ctrl <: Modifier end

struct Alt <: Modifier end

struct Shift <: Modifier end

struct Modified <: Key
	key::Key
	modifiers::Vector{Modifier}
end

Base.show(io::IO, modified::Modified) = print(
	io,
	join(modified.modifiers, '+'),
	'+',
	modified.key,
)

# We actually want the vector in `Modified` to be a set, but actually using
# `Set` is just annoying. This vector can only have at most 4 elements, so
# performance not a worry (and probably better than using a `Set` TBH).
function Base.:(==)(left::Modified, right::Modified)
	left.key == right.key && all(
		modifier in right.modifiers
		for modifier in left.modifiers
	)
end

const CTRL_C = Modified(Character('c'), [Ctrl()])


"""
Blocking.

# Examples

```
for key in Inputs.Events(stdin)
	@show key
	if key == Inputs.CTRL_C
		break
	end
end
```
"""
struct Events{I <: IO}
	input::I
end

Events(terminal::Terminals.TTYTerminal) = Events(terminal.in_stream)
Events() = Events(TERMINAL[].in_stream)

# TODO: Rewrite this based on: http://www.inwap.com/pdp10/ansicode.txt

const CTRL_LOWER_RANGE = 0x01:0x1a
const CTRL_LOWER_OFFSET = UInt8('a') - first(CTRL_LOWER_RANGE)
const CTRL_UPPER_RANGE = 0x1c:0x1f
const CTRL_UPPER_OFFSET = UInt8('4') - first(CTRL_UPPER_RANGE)

const DIGITS = UInt8.('0':'9')

const ESC = UInt8(Terminals.CSI[1])
const CSI = UInt8(Terminals.CSI[2])

const FN_INDICATOR_UNKNOWN = UInt8('[')
const FN_RANGE_UNKNOWN = UInt8.('A':'E')
const FN_OFFSET_UNKNOWN = UInt8('A')
const FN_INDICATOR_XTERM = UInt8('O')
const FN_RANGE_XTERM = UInt8.('P':'S')
const FN_OFFSET_XTERM = UInt8('P')

const DIRECTIONS = Dict(
	UInt8('A') => Up,
	UInt8('B') => Down,
	UInt8('C') => Right,
	UInt8('D') => Left,
	UInt8('F') => End,
	UInt8('H') => Home,
)

function modifiers(parameter)
	modmap = parameter - 1
	modifiers = Modifier[]

	if modmap & 0b0001 != 0
		push!(modifiers, Shift())
	end

	if modmap & 0b0010 != 0
		push!(modifiers, Alt())
	end

	if modmap & 0b0100 != 0
		push!(modifiers, Ctrl())
	end

	if modmap & 0b1000 != 0
		push!(modifiers, Meta())
	end

	modifiers
end

function Base.read(input::IO, ::Type{Event})
	first = read(input, UInt8)

	# Escape, must check if it's the key or a sequence.
	if first == ESC
		read_esc(input, first)
	elseif first == 0x00
		Null()
	elseif first == 0x7f
		Backspace()
	# Line feeds and carriage returns are indistinguishable from Ctrl+j and
	# Ctrl+m so catch them before checking for Ctrl.
	elseif first == UInt8('\n') || first == UInt8('\r')
		# Enter key sends a carriage return not a line feed, which is surprising
		# to most people.
		Character('\n')
	# Tabs are indistinguishable from Ctrl+i so catch them before checking for
	# Ctrl.
	elseif first == UInt8('\t')
		Character('\t')
	elseif first in CTRL_LOWER_RANGE
		read_ctrl(input, first, CTRL_LOWER_OFFSET)
	elseif first in CTRL_UPPER_RANGE
		read_ctrl(input, first, CTRL_UPPER_OFFSET)
	else
		read_utf8(input, [], first)
	end
end

function read_alt(input, first, second)
	if second in CTRL_LOWER_RANGE
		ctrl = read_ctrl(input, second, CTRL_LOWER_OFFSET)
		Modified(ctrl.key, [ctrl.modifiers; Alt()])
	elseif second in CTRL_UPPER_RANGE
		ctrl = read_ctrl(input, second, CTRL_UPPER_OFFSET)
		Modified(ctrl.key, [ctrl.modifiers; Alt()])
	else
		char = read_utf8(input, [first], second)
		if char isa Character
			Modified(char, [Alt()])
		else
			char
		end
	end
end

function read_csi(input, first, second)
	third = read(input, UInt8)

	if third == FN_INDICATOR_UNKNOWN
		read_fn(input, [first, second, third], FN_RANGE_UNKNOWN, FN_OFFSET_UNKNOWN)
	elseif third in keys(DIRECTIONS)
		return DIRECTIONS[third]()
	elseif third == UInt8('Z')
		return Backtab()
	elseif third == UInt8('M')
		error("X10 mouse not implemented")
	elseif third == UInt8('<')
		error("XTerm mouse not implemented")
	elseif third in DIGITS
		read_numbered_escape(input, [first, second], third)
	else
		Unknown([first, second, third], input)
	end
end

read_ctrl(_, first, offset) = Modified(Character(Char(first + offset)), [Ctrl()])

function read_esc(input, first)
	if bytesavailable(input) == 0
		return Esc()
	end

	second = read(input, UInt8)

	if second == ESC
		# Double escape is equivalent to single.
		Esc()
	# XTerm-style function keys.
	elseif second == FN_INDICATOR_XTERM
		read_fn(input, [first, second], FN_RANGE_XTERM, FN_OFFSET_XTERM)
	elseif second == CSI
		read_csi(input, first, second)
	else
		read_alt(input, first, second)
	end
end

function read_fn(input, previous, range, offset)
	current = read(input, UInt8)

	if current in range
		F(1 + current - offset)
	else
		# TODO: This can have parameters.
		Unknown([previous; current], input)
	end
end

function read_modified_direction(input, previous, buffer, final)
	key = DIRECTIONS[final]()
	parameters = parse.(UInt16, split(String(copy(buffer)), ';'))
	Modified(key, modifiers(parameters[end]))
end

function read_numbered_escape(input, previous, final)
	buffer = UInt8[]
	while !(0x40 <= final <= 0x7e)
		push!(buffer, final)
		final = read(input, UInt8)
	end

	if final == UInt8('~')
		read_special_keycode(input, previous, buffer, final)
	elseif final in keys(DIRECTIONS)
		read_modified_direction(input, previous, buffer, final)
	elseif final == UInt8('M')
		error("rxvt mouse not implemented")
	else
		Unknown([previous; buffer; final], input)
	end
end

function read_special_keycode(input, previous, buffer, final)
	parameters = parse.(UInt16, split(String(copy(buffer)), ';'))
	if length(parameters) < 1
		return Unknown([previous; buffer; final], input)
	end

	keycode = parameters[1]
	key = if keycode == 1 || keycode == 7
		Home()
	elseif keycode == 2
		Insert()
	elseif keycode == 3
		Delete()
	elseif keycode == 4 || keycode == 8
		End()
	elseif keycode == 5
		PageUp()
	elseif keycode == 6
		PageDown()
	elseif keycode in 11:15
		F(keycode - 10)
	elseif keycode in 17:21
		F(keycode - 11)
	elseif keycode in 23:24
		F(keycode - 12)
	else
		return Unknown([previous; buffer; final], input)
	end

	if length(parameters) == 1 || parameters[2] == 1
		key
	elseif length(parameters) == 2 && parameters[2] <= 15
		Modified(key, modifiers(parameters[2]))
	else
		Unknown([previous; buffer; final], input)
	end
end

function read_utf8(input, previous, first)
	# 0XXXXXXX is the only byte of a one-byte UTF-8 character.
	# 10XXXXXX is a continuation byte that can't occur as the first byte.
	# 110XXXXX is the first byte of a two-byte UTF-8 character.
	# 1110XXXX is the first byte of a three-byte UTF-8 character.
	# 11110XXX is the first byte of a four-byte UTF-8 character.
	# 11111XXX is an invalid byte that can't occur anywhere.

	ones = leading_ones(first)
	bytes = if ones == 0
		1
	elseif ones == 1 || ones > 4
		return Unknown([previous; first], input)
	else
		ones
	end

	buffer = [first; read(input, bytes - 1)]
	string = String(copy(buffer))

	if isvalid(string) && length(string) == 1
		Character(Base.first(string))
	else
		Unknown([previous; buffer], input)
	end
end


Base.iterate(e::Events, _ = nothing) = (read(e.input, Event), nothing)
Base.IteratorSize(::Type{Events}) = Base.IsInfinite()
Base.IteratorEltype(::Type{Events}) = Base.HasEltype()
Base.eltype(::Type{Events}) = Input


"""
Non-blocking (at least it doesn't block indefinitely).

!!! warning

    There is currently a bug in this iterator which makes it "eat" the next byte
    sent to the stream. This shouldn't be an issue in the common use-case of an
    event loop, where the process exits when the event loop does.

!!! warning

    The current implementation can't be used with `Cursor.location` (and therefore
    `Cursor.Row`), due to implementation limitations.

Usually ticks will always be `period` apart and key presses will come between
ticks however this is not guaranteed, especially if you're doing computationally
heavy work inside the loop.

# Examples

```
for key in Inputs.EventLoop(Inputs.Second(1))
	@show key
	if key == CTRL_C
		break
	end
end
```
"""
struct EventLoop
	channel::Channel{Event}
end

EventLoop(period::Period) = EventLoop(TERMINAL[].in_stream, period)

function EventLoop(input, period::Period)
	channel = Channel{Event}(0)

	reader = @async for event in Events(input)
		put!(channel, event)
	end
	bind(channel, reader)

	ticker = @async begin
		last = now()
		while true
			remaining = last + period - now()
			if remaining > Millisecond(0)
				sleep(remaining)
			end

			put!(channel, Tick())
			last = now()
		end
	end
	bind(channel, ticker)

	EventLoop(channel)
end

Base.iterate(e::EventLoop) =  Base.iterate(e, nothing)
Base.iterate(e::EventLoop, _) = (take!(e.channel), nothing)
Base.IteratorSize(::Type{EventLoop}) = Base.IsInfinite()
Base.IteratorEltype(::Type{EventLoop}) = Base.HasEltype()
Base.eltype(::Type{EventLoop}) = Event

end # module
