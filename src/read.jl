export adios2_init, write_mode, read_mode, perform_update

using ADIOS2

"""
Sample usage:

adios2_init(joinpath(pwd(),"adios2.xml"), comm) # initialization from XML file, with MPI and an existing comm
write_mode("temperature", eltype(T)) # define a new variable 'temperature'

"""

let
    global adios2_init, write_mode, perform_update, adios, engine, T_id

    """
    Intialize ADIOS2. Supports several configuration options: MPI, serial,
    existing XML config file or a new file with specified parameters.
    """
    function adios2_init(filename::AbstractString = "", engine = "",
                         mpi = true, serial = false, comm = nothing)

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

    end

    """
    Initialize io in read mode and the corresponding engine for reading data.
    """
    function read_mode(bp_filename = "")

        io = ADIOS2.declare_io(adios, "readerIO")
        bp_path = joinpath(pwd(), bp_filename)
        engine = ADIOS2.open(io, bp_path, mode_read)    # Open the file/stream from the .bp file

    end

    """
    Initialize io in write mode and the corresponding engine for writing data.
    """
    function write_mode(var_name = "", var_type = nothing, bp_filename = "")

        io = ADIOS2.declare_io(adios, "IO")
        T_id = define_variable(io, var_name, eltype(var_type))  # Define a new variable
        bp_path = joinpath(pwd(), bp_filename)
        engine = ADIOS2.open(io, bp_path, mode_write)   # Open the file/stream from the .bp file

    end

    """
    Perform the update using specified variables.
    """
    function perform_update(T_nohalo = nothing)
        begin_step(engine)                                       # Begin ADIOS2 write step
        put!(engine, T_id, T_nohalo)                             # Add T (without halo) to variables for writing
        end_step(engine)                                         # End ADIOS2 write step (normally, also includes the actual writing of data)
    end

    """
    If the ADIOS2 config file is not provided, this function uses the XML
    template to create the file automatically with parameters provided by the
    user. Returns the XML path to the new file.
    """
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
