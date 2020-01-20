# An (incredibly simplistic) example of how you might wish to handle logging in a TUI environment.

using Ansillary
using Logging


# Warning! Not threadsafe!
struct TUILogger <: AbstractLogger
	queue::Vector
	displayed::Vector
end

TUILogger() = TUILogger([], [])

Logging.shouldlog(::TUILogger, _, _, _, _) = true

Logging.min_enabled_level(::TUILogger) = Logging.Info

Logging.handle_message(logger::TUILogger, level, message, module_, group, id, file, line; kwargs...) = push!(logger.queue, (level, (id, message, module_, group, file, line), kwargs))

function render_logs!(logger)
	MAX_DISPLAYED = 5
	TIMEOUT = 5

	filter!(l -> time() < l[1], logger.displayed)

	n = length(logger.displayed)

	for _ in 1:MAX_DISPLAYED-n
		if length(logger.queue) == 0
			break
		end
		push!(logger.displayed, (time() + TIMEOUT, popfirst!(logger.queue)))
	end

	(rows, _) = displaysize(stdout)
	Cursor.save() do
		Cursor.move!(Cursor.Coordinate(rows - MAX_DISPLAYED, 1))
		Screen.clear!(Screen.FromCursorDown())
		for (_, data) in logger.displayed
			println(data)
		end
	end
end


const LOGGER = TUILogger()
global_logger(LOGGER)

Screen.alternative() do
	for event in Inputs.EventLoop(Inputs.Second(1))
		render_logs!(LOGGER)

		if event == Inputs.CTRL_C
			break
		elseif event isa Inputs.Modified && Inputs.Ctrl() in event.modifiers
			@error "D:" event
		elseif event isa Inputs.Character
			@warn ":|" event
		elseif event isa Inputs.Key
			Cursor.move!(Cursor.Coordinate(1, 1))
			Screen.clear!(Screen.CurrentLine())
			println(event)
		end
	end
end
