# ThreadGantt

The package is currently unregistered. Install it with
```julia
]add https://github.com/aminnj/ThreadGantt.jl
```

## Usage

Tag a section of code with a label (`"sum"` and `"mean"` below).
```julia
julia> using ThreadGantt

julia> function foo()
        a = randn(100)
        s = 0.0
        sleep(rand()*0.05)
        @workunit "sum" begin
            sleep(0.25 + rand()*0.2)
            s += sum(a)
        end
        @workunit "mean" begin
            sleep(0.5 + rand()*0.2)
            s += mean(a)
        end
        s
    end
```

Then do some work in parallel with threads. By default, information is printed to stdout
in case you want to pipe a script to a text file. 
```julia
julia> Threads.@threads for i in 1:8 ; foo(); end
[sum] thread = 2, start = 1.630745245690166e9, stop = 1.630745245965308e9, duration = 0.27514195442199707
[sum] thread = 1, start = 1.630745245681062e9, stop = 1.630745246068402e9, duration = 0.38734006881713867
...
[mean] thread = 3, start = 1.630745247075008e9, stop = 1.630745247668403e9, duration = 0.5933949947357178
[mean] thread = 4, start = 1.630745247183934e9, stop = 1.630745247803387e9, duration = 0.619452953338623
```

This package also exports `capture` from [IOCapture.jl](https://github.com/JuliaDocs/IOCapture.jl) to capture stdout.
```julia
julia> c = capture() do
           Threads.@threads for i in 1:8 ; foo(); end
       end;

julia> plotgantt(c.output)
```

