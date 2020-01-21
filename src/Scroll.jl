module Scroll

import ..TERMINAL

using REPL.Terminals: CSI


export down!, up!


"""
Scroll the terminal down the given number of lines.
"""
down!(terminal, n::UInt16) = print(terminal.out_stream, CSI, n, "T")
down!(terminal, n) = down!(terminal, UInt16(n))
down!(n::UInt16) = down!(TERMINAL[], n)
down!(n) = down!(UInt16(n))

"""
Scroll the terminal up the given number of lines.
"""
up!(terminal, n::UInt16) = print(terminal.out_stream, CSI, n, "S")
up!(terminal, n) = up!(terminal, UInt16(n))
up!(n::UInt16) = up!(TERMINAL[], n)
up!(n) = up!(UInt16(n))

end # module
