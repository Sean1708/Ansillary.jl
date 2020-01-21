# Ansillary

A Julia package for interacting with ANSI terminals.

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://seamsay.gitlab.io/Ansillary.jl/dev)
[![Build Status](https://gitlab.com/seamsay/Ansillary.jl/badges/master/pipeline.svg)](https://gitlab.com/seamsay/Ansillary.jl/pipelines)
[![Coverage](https://gitlab.com/seamsay/Ansillary.jl/badges/master/coverage.svg)](https://gitlab.com/seamsay/Ansillary.jl/commits/master)

## Future Work

### REPLectomy

The standard library REPL package is pretty heavyweight, and Ansillary only uses like two things from it (`raw!` and `TTYTerminal`) so removing it seems more sensible. It would also be nice if Ansillary could theoretically be used as the base for REPL rather than the other way around.

### Mouse Support

Will eventually be done, but needs more research first.
