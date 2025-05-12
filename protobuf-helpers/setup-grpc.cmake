include_guard(GLOBAL)

option(GRPC_EDM "Enable EDM for gRPC" OFF)

# This macro sets up gRPC for the project. It will check
# if the GRPC_EDM installation is enabled and if so, it
# will check if the grpc++ target is available and if it
# is a STATIC_LIBRARY. If the GRPC_EDM installation is 
# not enabled, it will find the Protobuf and gRPC packages
# from the system.
macro(setup_grpc)
    if (DISABLE_EDM AND GRPC_EDM)
        message(FATAL_ERROR "EDM is disabled, but GRPC_EDM is set to true")
    elseif(DISABLE_EDM AND NOT GRPC_EDM)
        message(STATUS "EDM is disabled, GRPC_EDM is set to false, gRPC system installation will be used")
        set(_GRPC_EDM FALSE)
    elseif(NOT DISABLE_EDM AND GRPC_EDM)
        message(STATUS "EDM is enabled, GRPC_EDM is set to true, gRPC EDM installation will be used")
        set(_GRPC_EDM TRUE)
    elseif(NOT DISABLE_EDM AND NOT GRPC_EDM)
        message(STATUS "EDM is enabled, GRPC_EDM is set to false, gRPC system installation will be used")
        set(_GRPC_EDM FALSE)
    endif()

    if (_GRPC_EDM)
        if (NOT grpc_SOURCE_DIR)
            message(FATAL_ERROR "grpc_SOURCE_DIR not set, is the grpc repository added in the dependencies.yaml?")
        endif()
        if (NOT TARGET grpc++)
            message(FATAL_ERROR "grpc++ target not found")
        endif()
        get_target_property(_GRPC_TYPE grpc++ TYPE)
        if (NOT _GRPC_TYPE STREQUAL "STATIC_LIBRARY")
            message(FATAL_ERROR "grpc++ target is not a STATIC_LIBRARY")
        endif()
        add_library(gRPC::grpc++ ALIAS grpc++)
    else()
        find_package(Protobuf CONFIG)
        if (NOT Protobuf_FOUND)
            message(FATAL_ERROR "Protobuf not found, is it installed? If not, try using the EDM installation for gRPC by setting GRPC_EDM=ON")
        endif()
        find_package(gRPC CONFIG)
        if (NOT gRPC_FOUND)
            message(FATAL_ERROR "gRPC not found, is it installed? If not, try using the EDM installation by setting GRPC_EDM=ON")
        endif()
    endif()

    set(_GRPC_SETUP_DONE TRUE)
endmacro()
