using Documenter, VizDataFlow

makedocs(;
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting_started.md",
        "Tutorials" => [
            "Introduction" => "tutorials/index.md",
        ],
        "API" => "API/index.md",
    ],
    sitename="VizDataFlow.jl",
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(;
        repo="github.com/mkg33/VizDataFlow.jl",
    )
end
