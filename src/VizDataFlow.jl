"""
Module VizDataFlow
"""

module VizDataFlow

export adios2_init, write_mode, read_mode, perform_update, finalize_adios

let
    global adios2_init, write_mode, read_mode, perform_update, finalize_adios, adios, engine, vars, init_state

    include("read.jl")
    include("setup.jl")
    include("utils.jl")
    include("visualize.jl")
    include("write.jl")

end

end
