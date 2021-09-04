module ThreadGantt

import IOCapture: capture
using PlotlyJS

export @workunit, plotgantt, capture

include("main.jl")

end
