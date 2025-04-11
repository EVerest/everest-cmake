include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/setup-grpc.cmake)

option(GRPC_GENERATOR_EDM "Enable EDM installation for gRPC generator" ON)

# This function checks if the required pip PACKAGES are installed
# on the system. If not, it will fail.
function(_require_pip_packages)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs
        PACKAGES
    )
    cmake_parse_arguments(arg
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    if (NOT arg_PACKAGES)
        message(FATAL_ERROR "PACKAGES not set")
    endif()

    if (NOT Python3_EXECUTABLE)
        message(FATAL_ERROR "Python3_EXECUTABLE not set")
    endif()

    foreach(package ${arg_PACKAGES})
        execute_process(
            COMMAND ${Python3_EXECUTABLE} -m pip show ${package}
            RESULT_VARIABLE EXIT_CODE
            OUTPUT_QUIET
        )
        if (NOT EXIT_CODE EQUAL 0)
            message(FATAL_ERROR "pip package ${package} not found, try running 'pip install ${package}'")
        endif()
    endforeach()
endfunction()

# This macro sets up the Python generator for the project.
# It will check if the required pip packages grpcio and grpcio-tools are installed
# on the system and if not, it will fail.
# It will also set the PROTOBUF_PROTOC_PYTHON_COMMAND
# variable to the Python command to run the protoc compiler.
macro(_setup_python_generator)
    _require_pip_packages(
        PACKAGES
            grpcio
            grpcio-tools
    )
    set(PROTOBUF_PROTOC_PYTHON_COMMAND
        ${Python3_EXECUTABLE} -m grpc_tools.protoc
    )
endmacro()

# This macro sets up the gRPC generator for the project.
# It will check if the GRPC_EDM installation is enabled 
# and if so, it will setup PROTOBUF_PROTOC_BINARY_PATH,
# GRPC_EXTENDED_CPP_PLUGIN_BINARY_PATH and GRPC_GENERATOR_DEPS.
# If the GRPC_EDM installation is not enabled, it will
# fail as non-EDM installation of gRPC generator is not
# supported at the moment.
macro(setup_grpc_generator)
    if (GRPC_GENERATOR_EDM)
        if (DISABLE_EDM)
            message(FATAL_ERROR "EDM is disabled, but GRPC_GENERATOR_EDM is set to true")
        endif()
        if (NOT GRPC_EDM)
            message(FATAL_ERROR "GRPC_EDM is set to false, but GRPC_GENERATOR_EDM is set to true")
        endif()

        if (NOT _GRPC_SETUP_DONE)
            message(FATAL_ERROR "setup_grpc must be called before setup_grpc_generator")
        endif()

        if (NOT grpc-extended-cpp-plugin_SOURCE_DIR)
            message(FATAL_ERROR "grpc-extended-cpp-plugin_SOURCE_DIR not set, is the grpc-extended-cpp-plugin repository added in the dependencies.yaml?")
        endif()

        if (NOT TARGET grpc_extended_cpp_plugin)
            message(FATAL_ERROR "grpc_extended_cpp_plugin target not found")
        endif()
        set(GRPC_EXTENDED_CPP_PLUGIN_BINARY_PATH $<TARGET_FILE:grpc_extended_cpp_plugin>)

        if (NOT TARGET protobuf::protoc)
            message(FATAL_ERROR "protobuf::protoc target not found")
        endif()
        set(PROTOBUF_PROTOC_BINARY_PATH $<TARGET_FILE:protobuf::protoc>)

        set(GRPC_GENERATOR_DEPS
            grpc_extended_cpp_plugin
            protobuf::protoc
        )
    else()
        message(FATAL_ERROR "Non-EDM installation of gRPC generator is not supported at the moment")
    endif()

    _setup_python_generator()

    set(_GRPC_GENERATOR_SETUP_DONE TRUE)
endmacro()
