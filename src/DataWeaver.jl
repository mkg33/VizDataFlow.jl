"""
Module DataWeaver
"""

module DataWeaver

export adios2_init, write_mode, read_mode, perform_update, finalize_adios,
       inspect_variables, perform_read

let
    global adios2_init, write_mode, read_mode, perform_update, finalize_adios,
    adios, engine, vars, init_state

    include("rw.jl")
    include("utils.jl")
    include("visualize.jl")

end

end
