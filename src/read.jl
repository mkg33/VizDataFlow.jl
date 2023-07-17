
export adios2_init, write_mode

using ADIOS2

let
    global adios2_init, adios, engine

    function adios2_init(filename::AbstractString = "",
                         mpi = true, comm = nothing)
                         #engine = "SST", var_name = "temperature", var_type = "")

        if isempty(filename)
            if serial == true
                adios = adios_init_serial()
            elseif mpi == true
                filename = adios2_config(engine = engine)
                adios = ADIOS2.adios_init_mpi(joinpath(pwd(), filename), comm)
            else
                filename = adios2_config(engine = engine)
                adios = ADIOS2.adios_init_serial(joinpath(pwd(), filename))
            end
        else
            if mpi == true
                adios = ADIOS2.adios_init_mpi(joinpath(pwd(), filename), comm)
            else
                adios = ADIOS2.adios_init_serial(joinpath(pwd(), filename))
            end
        end

        """
        io = ADIOS2.declare_io(adios, "IO")

        T_id = define_variable(io, var_name, eltype(var_type))

        bp_path = joinpath(pwd(), "diffusion2D.bp")

        engine = ADIOS2.open(io, bp_path, mode_write)

        io = ADIOS2.declare_io(adios, "readerIO")
        """

    end

    function read_mode()

    end

    function write_mode(var_name = "", var_type = nothing)

        io = ADIOS2.declare_io(adios, "IO")

        T_id = define_variable(io, var_name, eltype(var_type))

        bp_path = joinpath(pwd(), "diffusion2D.bp")

        engine = ADIOS2.open(io, bp_path, mode_write)

    end

    function perform_update()
        begin_step(engine)                                       # Begin ADIOS2 write step
        put!(engine, T_id, T_nohalo)                             # Add T (without halo) to variables for writing
        end_step(engine)
    end



function adios2_config(; engine = "")

    template_path = joinpath(pwd(), "adios2_template.xml")
    xml_path = joinpath(pwd(), "adios2_config.xml")

    adios2_template = open(template_path, "r")

    adios2_xml = open(xml_path, "w")

    cp(template_path, xml_path, force = true)

    # temp file for replacing modified lines

    if cmp(engine, "SST") == 0
        for line in eachline(xml_path, keep = true)
            if occursin("ENGINE_TYPE", line)
                line = "<engine type=\"SST\">"
            end
            write(adios2_xml, line)
        end
    elseif cmp(engine, "BP4") == 0
        for line in eachline(xml_path, keep = true)
            if occursin("ENGINE_TYPE", line)
                line = "<engine type=\"BP4\">"
            end
            write(adios2_xml, line)
        end

    else
        println("Error")

    end

    close(adios2_template)
    close(adios2_xml)

    return xml_path

end

end

#adios2_init()

#adios2_config(engine="SST")
