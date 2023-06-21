using Documenter, VizDataFlow

makedocs(;
     modules  = [VizDataFlow],
     authors  = "tba",
     sitename = "VizDataFlow.jl",
     format   = Documenter.HTML(;
        prettyurls       = true,
        canonical        = "https://mkg33.github.io/VizDataFlow.jl",
        collapselevel    = 1,
        sidebar_sitename = true,
        edit_link        = "main",
    ),
    pages = [
        "Home"             => "index.md",
        "Getting started"  => "getting_started.md",
        "Tutorials"        => [
            "Introduction" => "tutorials/index.md",
        ],
        "API"              => "API/index.md",
    ],
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(;
        repo         = "github.com/mkg33/VizDataFlow.jl",
        push_preview = true,
        devbranch    = "main",
    )
end
