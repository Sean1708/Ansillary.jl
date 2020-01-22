using Ansillary


struct State
	size
	issues
end

State() = State(Screen.raw(Screen.size), [])


abstract type Stage end

function draw(::Stage, _) end

handle(stage::Stage, _, _) = stage

tick(stage::Stage) = stage


struct Sleep <: Stage
	until
	next
end

tick(stage::Sleep) = if time() > stage.until
	stage.next
else
	stage
end


struct Introduction <: Stage end

function draw(::Introduction, _)
	Cursor.move!(Cursor.Coordinate(1, 1))

	println("Welcome to Ansillary's interactive test script!")
	println("At any point you can press Ctrl+c to exit the script.")
	println("Otherwise, please follow the instructions on screen.")
	println("Press any key to continue.")
end

function handle(stage::Introduction, _, _)
	Screen.clear!(Screen.All())
	Cursor.move!(Cursor.Coordinate(1, 1))

	SizeTest()
end


struct SizeTest <: Stage end

function draw(::SizeTest, state)
	rows = state.size.rows
	columns = state.size.columns
	println("We have calculated that your terminal is $rows rows by $columns columns.")
	println("Does this look correct? (y/n)")
end

function handle(stage::SizeTest, event, state)
	next = HideTestInitial()

	if event == Inputs.Character('y')
		Screen.clear!(Screen.All())
		Cursor.move!(Cursor.Coordinate(1, 1))

		next
	elseif event == Inputs.Character('n')
		Screen.clear!(Screen.All())
		Cursor.move!(Cursor.Coordinate(1, 1))

		push!(state.issues, "`Screen.size` did not correctly calculate the terminal size.")

		next
	else
		Cursor.move!(Cursor.Coordinate(3, 1))
		Screen.clear!(Screen.CurrentLine())
		println("You must press 'y' or 'n' not: $event")

		stage
	end
end


struct HideTestInitial <: Stage end

function draw(::HideTestInitial, _)
	println("This will test hiding the cursor (it should currently be visible).")
	println("Is the cursor currently visible on the screen? (y/n)")
end

handle(stage::HideTestInitial, event, state) = if event == Inputs.Character('y')
	Cursor.move!(Cursor.Coordinate(1, 1))
	Screen.clear!(Screen.CurrentLine())

	HideTestHidden()
elseif event == Inputs.Character('n')
	Cursor.move!(Cursor.Coordinate(1, 1))
	Screen.clear!(Screen.CurrentLine())

	push!(state.issues, "Cursor was not visible at the beginning of the script.")

	MoveTest()
else
	Cursor.move!(Cursor.Coordinate(3, 1))
	Screen.clear!(Screen.CurrentLine())
	println("You must press 'y' or 'n' not: $event")

	stage
end


struct HideTestHidden <: Stage end

function draw(::HideTestHidden, _)
	Cursor.hide!()

	println("The cursor should now have disappeared.")
end

handle(stage::HideTestHidden, event, state) = if event == Inputs.Character('y')
	push!(state.issues, "`Cursor.hide!` did not hide the cursor.")

	# In case this was an accident.
	Cursor.show!()

	Cursor.move!(Cursor.Coordinate(1, 1))
	Screen.clear!(Screen.CurrentLine())

	MoveTest()
elseif event == Inputs.Character('n')
	Cursor.move!(Cursor.Coordinate(1, 1))
	Screen.clear!(Screen.CurrentLine())

	HideTestFinal()
else
	Cursor.move!(Cursor.Coordinate(3, 1))
	Screen.clear!(Screen.CurrentLine())
	println("You must press 'y' or 'n' not: $event")

	stage
end


struct HideTestFinal <: Stage end

function draw(::HideTestFinal, _)
	Cursor.show!()

	println("The cursor should now have reappeared.")
end

function handle(stage::HideTestFinal, event, state)
	if event == Inputs.Character('y')
		Screen.clear!(Screen.All())
		Cursor.move!(Cursor.Coordinate(1, 1))

		MoveTest()
	elseif event == Inputs.Character('n')
		Screen.clear!(Screen.All())
		Cursor.move!(Cursor.Coordinate(1, 1))

		push!(state.issues, "`Cursor.show!` did not reveal the cursor.")

		MoveTest()
	else
		Cursor.move!(Cursor.Coordinate(3, 1))
		Screen.clear!(Screen.CurrentLine())
		println("You must press 'y' or 'n' not: $event")

		stage
	end
end


struct MoveTest <: Stage
	step
	tests
end

MoveTest() = MoveTest(1)

MoveTest(step) = MoveTest(step, [
	(Cursor.Coordinate(8, 4), 5),
	(Cursor.Up(2), 2),
	(Cursor.Left(2), 1),
	(Cursor.Right(4), 3),
	(Cursor.Down(4), 9),
	(Cursor.Column(2), 7),
])

function draw(stage::MoveTest, _)
	if stage.step == 1
		println("We will now test moving the cursor.")
		println("A grid of numbers will apear below.")
		println("When prompted you should press the number that the cursor is on.")
		println("If the cursor is not on a number then press any other key.")
		println()
		println(" 1 2 3")
		println()
		println(" 4 5 6")
		println()
		println(" 7 8 9")
		println()
		println("What number is the cursor on?")
		println("Step ")
	end

	Cursor.save() do
		Cursor.move!(Cursor.Coordinate(13, 6))
		print(stage.step)
	end

	movement, _ = stage.tests[stage.step]
	Cursor.move!(movement)
end

handle(stage::MoveTest, event, state) = if event in Inputs.Character.('0':'9')
	movement, expected = stage.tests[stage.step]

	if event != Inputs.Character('0' + expected)
		push!(state.issues, "`$movement` did not move the cursor onto the number $expected.")
	end

	if stage.step >= length(stage.tests)
		Screen.clear!(Screen.All())
		Cursor.move!(Cursor.Coordinate(1, 1))

		ClearTestIntroduction()
	else
		MoveTest(stage.step + 1)
	end
else
	Cursor.save() do
		Cursor.move!(Cursor.Coordinate(14, 1))
		Screen.clear!(Screen.CurrentLine())
		println("You must press a number key not: $event")
	end

	stage
end


struct ClearTestIntroduction <: Stage end

function draw(::ClearTestIntroduction, _)
	println("Next we will test clearing the screen.")
	println("Your screen will fill with 'x's and 'o's, then there will be a brief pause.")
	println("Occasionally there will be a '|' to make it more obvious where the 'x's end.")
	println("After the pause the 'x's should disappear, leaving all of the 'o's and the '|'.")
	println("There will be another pause and you will be asked whether the 'x's disappeared.")
	println("If only the 'x's disappeared, press 'y'.")
	println("If any of the 'o's or '|' disappeared or there are some 'x's left, press 'n'.")
	println("Press any key to continue.")
end

function handle(::ClearTestIntroduction, _, _)
	Screen.clear!(Screen.All())
	Cursor.move!(Cursor.Coordinate(1, 1))

	ClearTestAll()
end

abstract type ClearTest <: Stage end

struct ClearTestRun <: Stage
	stage::ClearTest
end

struct ClearTestFinish <: Stage
	stage::ClearTest
end

function draw(stage::ClearTest, state)
	setup(stage, state)
end

tick(stage::ClearTest) = Sleep(time() + 2, ClearTestRun(stage))

draw(stage::ClearTestRun, _) = Screen.clear!(area(stage.stage))

tick(stage::ClearTestRun) = Sleep(time() + 2, ClearTestFinish(stage.stage))

function draw(stage::ClearTestFinish, _)
	Screen.clear!(Screen.All())
	Cursor.move!(Cursor.Coordinate(1, 1))

	println("Did the 'x's (and only the 'x's) disappear? (y/n)")
end

handle(stage::ClearTestFinish, event, state) = if event == Inputs.Character('y')
	Screen.clear!(Screen.All())
	Cursor.move!(Cursor.Coordinate(1, 1))

	next(stage.stage)
elseif event == Inputs.Character('n')
	Screen.clear!(Screen.All())
	Cursor.move!(Cursor.Coordinate(1, 1))

	push!(state.issues, "`$(area(stage.stage))` did not clear the correct area of the screen.")

	next(stage.stage)
else
	Cursor.move!(Cursor.Coordinate(2, 1))
	Screen.clear!(Screen.CurrentLine())

	println("You must press 'y' or 'n' not: $event")

	stage
end

row(character, state) = character ^ state.size.columns
line(character, state) = row(character, state) * '\n'

struct ClearTestAll <: ClearTest end

function setup(::ClearTestAll, state)
	print(line('x', state) ^ (state.size.rows - 1))
	print(row('x', state))
end

area(::ClearTestAll) = Screen.All()

next(::ClearTestAll) = ClearTestCurrentLine()

struct ClearTestCurrentLine <: ClearTest end

function setup(::ClearTestCurrentLine, state)
	print(line('o', state) ^ 10)
	print(line('x', state))
	print(line('o', state) ^ (state.size.rows - 12))
	print(row('o', state))

	Cursor.move!(Cursor.Coordinate(11, 1))
end

area(::ClearTestCurrentLine) = Screen.CurrentLine()

next(::ClearTestCurrentLine) = ClearTestFromCursorBack()

struct ClearTestFromCursorBack <: ClearTest end

function setup(::ClearTestFromCursorBack, state)
	print(line('o', state) ^ 15)
	println('x' ^ 10, '|', 'o' ^ (state.size.columns - 11))
	print(line('o', state) ^ (state.size.rows - 17))
	print(row('o', state))

	Cursor.move!(Cursor.Coordinate(16, 10))
end

area(::ClearTestFromCursorBack) = Screen.FromCursorBack()

next(::ClearTestFromCursorBack) = ClearTestFromCursorForward()

struct ClearTestFromCursorForward <: ClearTest end

function setup(::ClearTestFromCursorForward, state)
	print(line('o', state) ^ 20)
	println('o' ^ 20, '|', 'x' ^ (state.size.columns - 21))
	print(line('o', state) ^ (state.size.rows - 22))
	print(row('o', state))

	Cursor.move!(Cursor.Coordinate(21, 22))
end

area(::ClearTestFromCursorForward) = Screen.FromCursorForward()

next(::ClearTestFromCursorForward) = ClearTestFromCursorUp()

struct ClearTestFromCursorUp <: ClearTest end

function setup(::ClearTestFromCursorUp, state)
	print(line('x', state) ^ 7)
	println('x' ^ 16, '|', 'o' ^ (state.size.columns - 17))
	print(line('o', state) ^ (state.size.rows - 9))
	print(row('o', state))

	Cursor.move!(Cursor.Coordinate(8, 16))
end

area(::ClearTestFromCursorUp) = Screen.FromCursorUp()

next(::ClearTestFromCursorUp) = ClearTestFromCursorDown()

struct ClearTestFromCursorDown <: ClearTest end

function setup(::ClearTestFromCursorDown, state)
	print(line('o', state) ^ 17)
	println('o' ^ 8, '|', 'x' ^ (state.size.columns - 9))
	print(line('x', state) ^ (state.size.rows - 19))
	print(row('x', state))

	Cursor.move!(Cursor.Coordinate(18, 10))
end

area(::ClearTestFromCursorDown) = Screen.FromCursorDown()

next(::ClearTestFromCursorDown) = PasteTest()


struct PasteTest <: Stage end

function draw(stage::PasteTest, _)
	println("Next we will test whether bracketed paste is working.")
	println("Please paste some (not too much) text into the terminal.")

	Inputs.paste!()
end

handle(::PasteTest, event, state) = if event == Inputs.PasteStart()
	PasteTestFindEnd()
else
	push!(state.issues, "Terminal did not send the `PasteStart` event.")

	Inputs.nopaste!()

	PasteTestEatInput()
end

struct PasteTestFindEnd <: Stage end

handle(stage::PasteTestFindEnd, event, _) = if event == Inputs.PasteEnd()
	Inputs.nopaste!()

	InputTest()
else
	stage
end

struct PasteTestEatInput <: Stage
	seen_tick
end

PasteTestEatInput() = PasteTestEatInput(false)

# Since pasted input gets sent all at once if we see two ticks then that's
# probably the end of input.
tick(stage::PasteTestEatInput) = if stage.seen_tick
	InputTest()
else
	PasteTestEatInput(true)
end


struct InputTest <: Stage
	step
	draw
	tests
end

InputTest(step, draw) = InputTest(
	step,
	draw,
	[
		Inputs.Character('g'),
		Inputs.Character('T'),
		Inputs.Character('5'),
		Inputs.Character('*'),
		Inputs.Insert(),
		Inputs.Delete(),
		Inputs.Home(),
		Inputs.End(),
		Inputs.PageUp(),
		Inputs.PageDown(),
		Inputs.Up(),
		Inputs.Down(),
		Inputs.Left(),
		Inputs.Right(),
		Inputs.Esc(),
		Inputs.Modified(Inputs.Character('d'), [Inputs.Ctrl()]),
		Inputs.Modified(Inputs.Character('a'), [Inputs.Ctrl(), Inputs.Alt()]),
		Inputs.Modified(Inputs.Insert(), [Inputs.Ctrl()]),
		Inputs.Modified(Inputs.PageUp(), [Inputs.Ctrl(), Inputs.Alt()]),
		Inputs.Modified(Inputs.Right(), [Inputs.Ctrl()]),
		Inputs.Modified(Inputs.Left(), [Inputs.Ctrl(), Inputs.Alt()]),
		Inputs.F(1),
		Inputs.Modified(Inputs.F(2), [Inputs.Ctrl()]),
	],
)

InputTest() = InputTest(1, true)

function draw(stage::InputTest, _)
	if stage.draw
		Cursor.hide!()

		Cursor.move!(Cursor.Coordinate(1, 1))
		Screen.clear!(Screen.All())

		println("The remainder of the test will check input events.")
		println("This will not be an exhaustive test, for that use `examples/keylogger.jl`.")
		println("Please follow the instructions on screen.")

		print("Please press: ")
	end

	Cursor.move!(Cursor.Coordinate(4, 15))
	Screen.clear!(Screen.FromCursorForward())

	print(stage.tests[stage.step])
end

function handle(stage::InputTest, event, state)
	expected = stage.tests[stage.step]
	if event != expected
		push!(state.issues, "$expected received as $event.")
	end

	if stage.step >= length(stage.tests)
		Cursor.show!()
		nothing
	else
		InputTest(stage.step + 1, false)
	end
end


state = State()
if state.size.rows < 24 || state.size.columns < 80
	error("this script assumes a terminal size of at least 24x80")
end

Screen.alternative() do
	previous = nothing
	stage = Introduction()

	for event in Inputs.EventLoop(Inputs.Millisecond(100))
		if event == Inputs.CTRL_C
			break
		end

		if previous != stage
			draw(stage, state)
			previous = stage
		end

		stage = if event == Inputs.Tick()
			tick(stage)
		else
			handle(stage, event, state)
		end

		if stage === nothing
			break
		end
	end
end


if !isempty(state.issues)
	println("Test script found the following issues:")
	for issue in state.issues
		println('\t', issue)
	end
else
	println("Ansillary seems to handle your terminal well!")
end
