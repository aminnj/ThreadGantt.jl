macro workunit(label, ex)
    quote
        local start = time()
        local val = $(esc(ex))
        local stop = time()
        local label = $(esc(label))
        local tid = Threads.threadid()
        duration = stop-start
        lock(stdout)
        out = "[$label] thread = $tid, start = $start, stop = $stop, duration = $duration"
        println(stdout, out)
        unlock(stdout)
        val
    end
end

function plotgantt(out)
    lines = split(out, "\n")
    patt = r"\[(.*)\] thread = ([0-9]+), start = ([0-9\.e]+), stop = ([0-9\.e]+), duration = ([0-9\.e\-]+)"
    data::Vector{Dict{Symbol,Any}} = []
    for line in lines
        m = match(patt, line)
        isnothing(m) && continue
        label, thread, start, stop, duration = m.captures
        thread = parse(Int, thread)
        start, stop, duration = parse.(Float64, (start, stop, duration))
        push!(data, Dict(
                         :label => label,
                         :thread => thread,
                         :start => start,
                         :stop => stop,
                         :duration => duration,
                        ))
    end

    groups = sort(unique([d[:label] for d in data]))
    threads = sort(unique([d[:thread] for d in data]))
    gt0 = minimum([d[:start] for d in data])
    gt1 = maximum([d[:stop] for d in data])
    shapes::Vector{PlotlyJS.Shape} = []
    traces::Vector{GenericTrace} = []
    colors = PlotlyJS.colors.tab10
    for (color,g) in zip(colors,groups)
        for d in data
            d[:label] != g && continue
            r = rect(d[:start]-gt0, d[:stop]-gt0, d[:thread]-0.3, d[:thread]+0.3; fillcolor=color, line_width=0)
            push!(shapes, r)
        end
        push!(traces, bar(name=g, x=[0,0], y=[0,0], marker_color=color))
    end

    totalwalltime = gt1-gt0
    markedwalltime = sum(d[:duration] for d in data)
    eff = markedwalltime/length(threads) / totalwalltime

    p = plot(traces, Layout(;shapes=shapes,
                               yaxis=attr(range=(0.5,length(threads)+0.5), nticks=2*length(threads), title="thread"),
                               xaxis=attr(range=(0-0.05*(gt1-gt0),(gt1-gt0)*1.05), title="walltime (s)"),
                               legend=attr(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
                               title="duration = $(round(totalwalltime; sigdigits=4))s, efficiency = $(round(100*eff; sigdigits=3))%",
                              ))
    return p
end
