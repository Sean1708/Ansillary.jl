using Ansillary

println("Press Ctrl+c to exit.")

Screen.raw() do
    for event in Inputs.Events()
        if event == Inputs.CTRL_C
            break
        end
        println(event)
    end
end

println("Bye!")
