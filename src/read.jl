using ADIOS2

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
            elseif use_mpi
                filename = adios2_config(engine = engine_type)
                adios = ADIOS2.adios_init_mpi(joinpath(pwd(), filename), comm)
            else serial_file
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

        init_state = true   # mark the initialization step
        vars = []           # initialize the variable array (used later for reading and writing)

        print(@isdefined(adios))

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
    function write_mode(variables... ; bp_filename = "") # other options

        # variable input: "temp", T, "temp1", T1, "temp2", T2 etc.

        """
        check if even:

        if length(variables) % 2 != 0
            print(error)
        end
        """

        io = ADIOS2.declare_io(adios, "IO")

        for i in 1:length(variables)
            var_id = define_variable(io, variables(i), eltype(variables(i+1)))  # Define a new variable
            push!(vars, var_id)
        end

        bp_path = joinpath(pwd(), bp_filename)
        engine = ADIOS2.open(io, bp_path, mode_write)   # Open the file/stream from the .bp file

    end

    """
    Perform the update using specified variables.
    """
    function perform_update(update_var = nothing)

        for v in vars                                           # Locate the variable to be updated
            if v == update_var
                var = v
                break
            end
        end

        begin_step(engine)                                       # Begin ADIOS2 write step
        put!(engine, var, update_var)                            # Add update_var to variables for writing
        end_step(engine)                                         # End ADIOS2 write step (normally, also includes the actual writing of data)

    end

    function perform_read(vars...; read_function = nothing, timeout = 100.0, verbose = true)

        for var in vars

            nprocessed = 0

            while begin_step(engine, step_mode_read, timeout) != step_status_end_of_stream

                var_id = inquire_variable(io, var)

                if nprocessed == 0
                    nxy_global = shape(var_id)                                               # Extract meta data
                    nxy        = count(var_id)                                               # ...
                    var_type   = type(var_id)                                                # ...
                    global V   = zeros(var_type, nxy)                                        # Preallocate memory for the variable using the meta data
                end

                read_function

                get(engine, var_id, V)
                end_step(engine)

                if verbose
                    print("Variable: " * string(var))
                    print("Step: " * string(nprocessed))
                end

                nprocessed += 1
            end
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
