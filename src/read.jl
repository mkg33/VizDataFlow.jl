#using ADIOS2

"""
Sample usage:

adios2_init(filename = "adios2.xml", comm) # initialization from XML file, with
MPI and an existing comm write_mode("temperature", eltype(T)) # define a new
variable 'temperature' and provide its type

"""
    # assign values

    """
    Intialize ADIOS2. Supports several configuration options: MPI, serial,
    existing XML config file or a new file with specified parameters.
    """
    function adios2_init(; filename::AbstractString = "", engine_type = "",
                         serial = false, comm = nothing)

        use_mpi = !isnothing(comm)

        if isempty(filename)
            if serial
                adios = adios_init_serial()
                # some function
            elseif use_mpi
                filename = adios2_config(engine = engine_type)
                adios = ADIOS2.adios_init_mpi(joinpath(pwd(), filename), comm)
                # add error
            else serial_file # third option
                filename = adios2_config(engine = engine_type)
                adios = ADIOS2.adios_init_serial(joinpath(pwd(), filename))
            end
        else
            if use_mpi
                adios = ADIOS2.adios_init_mpi(joinpath(pwd(), filename), comm)
            else
                adios = ADIOS2.adios_init_serial(joinpath(pwd(), filename))
            end
        end

        init_state = true # mark the initialization step

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
    function write_mode(variable_name = "", variable = nothing, bp_filename = "") # other options

        io = ADIOS2.declare_io(adios, "IO")
        var = define_variable(io, variable_name, eltype(variable))  # Define a new variable
        bp_path = joinpath(pwd(), bp_filename)
        engine = ADIOS2.open(io, bp_path, mode_write)   # Open the file/stream from the .bp file

    end

    """
    Perform the update using specified variables.
    """
    function perform_update(T_nohalo = nothing) # add options

        begin_step(engine)                                       # Begin ADIOS2 write step
        put!(engine, var, T_nohalo)                              # Add T (without halo) to variables for writing
        end_step(engine)                                         # End ADIOS2 write step (normally, also includes the actual writing of data)

    end

    function perform_read(a...; read_function = nothing, verbose = true) # add defaults (allocation etc.) + verbose flag

        nprocessed = 0

        while begin_step(engine, step_mode_read, 100.0) != step_status_end_of_stream

            read_function

            end_step(engine)

            if verbose
                print("Step: " * string(nprocessed))
            end

            nprocessed += 1
        end

    end

    """
    Close the ADIOS2 engine once all steps have been performed.
    """
    function finalize_adios()

        if init_state == true
            close(engine)
        else
            print("Error. ADIOS2 hasn't been initialized.")
        end

    end

    """
    If the ADIOS2 config file is not provided, this function uses the XML
    template to create the file automatically with parameters provided by the
    user. Returns the XML path to the new file.
    """
    function adios2_config(engine_type = "") # write whole as string

        template_path = joinpath(pwd(), "adios2_template.xml")
        xml_path = joinpath(pwd(), "adios2_config.xml") # save location

        adios2_template = open(template_path, "r")

        adios2_xml = open(xml_path, "w")

        cp(template_path, xml_path, force = true)

        # temp file for replacing modified lines

        if cmp(engine_type, "SST") == 0
            for line in eachline(xml_path, keep = true)
                if occursin("ENGINE_TYPE", line)
                    line = "<engine type=\"SST\">"
                end
                write(adios2_xml, line)
            end
        elseif cmp(engine_type, "BP4") == 0
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
