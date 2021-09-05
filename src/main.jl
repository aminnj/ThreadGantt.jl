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
    usems, multiplier = false, 1
    if gt1-gt0 < 2
        usems, multiplier = true, 1e3
    end
    for (color,g) in zip(colors,groups)
        xs = Vector{Union{Float64,Missing}}()
        ys = Vector{Union{Float64,Missing}}()
        for d in data
            d[:label] != g && continue
            x0 = multiplier*(d[:start]-gt0)
            x1 = multiplier*(d[:stop]-gt0)
            y0 = d[:thread]-0.3
            y1 = d[:thread]+0.3
            # https://github.com/plotly/plotly.py/blob/0a833291f2b01b77cecf2a168936aa90e17acaed/packages/python/plotly/plotly/figure_factory/_gantt.py#L172
            append!(xs, [x0,x1,x1,x0,missing])
            append!(ys, [y0,y0,y1,y1,missing])
        end
        push!(traces, scatter(x=xs, y=ys, fill="toself", hoverinfo="name", mode="none", fillcolor=color, name=g))
    end

    totalwalltime = gt1-gt0
    markedwalltime = sum(d[:duration] for d in data)
    eff = (markedwalltime/length(threads)) / totalwalltime

    xaxis_attr = attr(title="walltime", ticksuffix=(usems ? "ms" : "s"), zeroline=false)
    yaxis_attr = attr(range=[0.5, length(threads)+0.5], autorange=false, zeroline=false, tickvals=threads, tickprefix="thread ")
    legend_attr = attr(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1)
    title = "duration = $(round(totalwalltime; sigdigits=4))s, efficiency = $(round(100*eff; sigdigits=3))%"
    layout = Layout(;shapes=shapes,
                    yaxis=yaxis_attr,
                    xaxis=xaxis_attr,
                    legend=legend_attr,
                    title=title,
                    showlegend=true,
                   )
    p = plot(traces, layout)
    return p
end
