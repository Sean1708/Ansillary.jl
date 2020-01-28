using Ansillary

@enum Direction Up Down Left Right

mutable struct Game
    fruit::Cursor.Coordinate
    snake::Vector{Cursor.Coordinate}
    clear::Union{Nothing, Cursor.Coordinate}
    direction::Direction
    finished::Bool
end

function Game(rows, columns)
    crow = div(rows - 3, 2)
    ccol = div(columns - 2, 2)
    snake = [
        Cursor.Coordinate(crow, ccol - 2),
        Cursor.Coordinate(crow, ccol - 1),
        Cursor.Coordinate(crow, ccol),
        Cursor.Coordinate(crow, ccol + 1),
    ]

    fruit = new_fruit(snake, rows, columns)

    Game(fruit, snake, nothing, Right, false)
end

function draw(rows, columns)
    Cursor.move!(Cursor.Coordinate(1, 1))

    print("┏", "━"^(columns - 2), "┓")

    for row in 2:(rows - 2)
        Cursor.move!(Cursor.Coordinate(row, 1))
        print("┃")

        Cursor.move!(Cursor.Column(columns))
        print("┃")
    end

    Cursor.move!(Cursor.Coordinate(rows - 1, 1))
    print("┗", "━"^(columns - 2), "┛")

    Cursor.move!(Cursor.Coordinate(rows, 1))
    print("Arrow Keys: Change direction. - Esc: Quit.")
end

function draw(game::Game)
    if game.clear !== nothing
        Cursor.move!(game.clear)
        print(' ')
    end

    draw(game.snake)
    draw(game.fruit)
end

function draw(snake::Vector{Cursor.Coordinate})
    char = 'O'
    for coord in Iterators.reverse(snake)
        Cursor.move!(coord)
        print(char)
        char = '*'
    end
end

function draw(fruit::Cursor.Coordinate)
    Cursor.move!(fruit)
    print('$')
end

function update!(game, rows, columns)
    game.finished && return

    old = game.snake[end]

    new = if game.direction == Up
        Cursor.Coordinate(old.row - 1, old.column)
    elseif game.direction == Down
        Cursor.Coordinate(old.row + 1, old.column)
    elseif game.direction == Left
        Cursor.Coordinate(old.row, old.column - 1)
    elseif game.direction == Right
        Cursor.Coordinate(old.row, old.column + 1)
    end

    if new.row == 1
        new = Cursor.Coordinate(rows - 2, new.column)
    end

    if new.row == rows - 1
        new = Cursor.Coordinate(2, new.column)
    end

    if new.column == 1
        new = Cursor.Coordinate(new.row, columns - 1)
    end

    if new.column == columns
        new = Cursor.Coordinate(new.row, 2)
    end

    if new in game.snake
        game.finished = true
        return
    end

    push!(game.snake, new)

    if new == game.fruit
        game.fruit = new_fruit(game.snake, rows, columns)
        game.clear = nothing
    else
        game.clear = popfirst!(game.snake)
    end
end

function new_fruit(snake, rows, columns)
    while true
        fruit = Cursor.Coordinate(rand(2:(rows - 2)), rand(2:(columns - 1)))
        if !(fruit in snake)
            return fruit
        end
    end
end

function main()
    size = Screen.raw(Screen.size)
    main(size.row, size.column)
end

function main(rows, columns)
    Screen.alternative() do
        Cursor.hide() do
            game = Game(rows, columns)

            draw(rows, columns)
            draw(game)

            for event in Inputs.EventLoop(Inputs.Millisecond(200))
                if event == Inputs.Esc()
                    break
                elseif event == Inputs.Up()
                    game.direction = Up
                elseif event == Inputs.Down()
                    game.direction = Down
                elseif event == Inputs.Left()
                    game.direction = Left
                elseif event == Inputs.Right()
                    game.direction = Right
                elseif event == Inputs.Tick()
                    update!(game, rows, columns)
                    draw(game)
                end
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    function usage(code = 0)
        println(PROGRAM_FILE, " [-h|--help] [ROWS COLUMNS]")
        exit(code)
    end

    if "-h" in ARGS || "--help" in ARGS
        usage()
    elseif isempty(ARGS)
        main()
    elseif length(ARGS) == 2
        main(parse(UInt16, ARGS[1]), parse(UInt16, ARGS[2]))
    else
        usage(1)
    end
end
