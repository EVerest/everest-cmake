include_guard(GLOBAL)

# This function generates C++ code from proto files.
#
# The function requires the setup_grpc_generator function to be called before.
# The function will generate the standard protobuf cpp files,
# the standard grpc cpp files and the extended grpc cpp files.
#
# PROTOBUF_DIR: The directory containing the proto files
# HDRS_VAR: The variable to store the generated header files as a list
# SRCS_VAR: The variable to store the generated source files as a list
# OUT_DIR: The directory to store the generated files
# TARGET_NAME: The name of the custom target to generate the files
# PROTO_FILES: The list of proto files to generate the files from
function(generate_cpp_from_proto)
    set(options)
    set(oneValueArgs
        PROTOBUF_DIR
        HDRS_VAR
        SRCS_VAR
        OUT_DIR
        TARGET_NAME
    )
    set(multiValueArgs
        PROTO_FILES
    )
    cmake_parse_arguments(arg
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    if (NOT arg_PROTOBUF_DIR)
        message(FATAL_ERROR "PROTOBUF_DIR not set")
    endif()
    if (NOT IS_ABSOLUTE ${arg_PROTOBUF_DIR})
        message(FATAL_ERROR "PROTOBUF_DIR ${arg_PROTOBUF_DIR} is not an absolute path")
    endif()
    if (NOT arg_PROTO_FILES)
        message(FATAL_ERROR "PROTO_FILES not set")
    endif()
    foreach(proto_file ${arg_PROTO_FILES})
        if (NOT IS_ABSOLUTE ${proto_file})
            message(FATAL_ERROR "PROTO file ${proto_file} is not an absolute path")
        endif()
        if (NOT ${proto_file} MATCHES "^${arg_PROTOBUF_DIR}/")
            message(FATAL_ERROR "PROTO file ${proto_file} is not located in PROTOBUF_DIR ${arg_PROTOBUF_DIR}")
        endif()
    endforeach()
    if (NOT arg_OUT_DIR)
        message(FATAL_ERROR "OUT_DIR not set")
    endif()
    if (NOT IS_ABSOLUTE ${arg_OUT_DIR})
        message(FATAL_ERROR "OUT_DIR ${arg_OUT_DIR} is not an absolute path")
    endif()
    if (NOT arg_TARGET_NAME)
        message(FATAL_ERROR "TARGET_NAME not set")
    endif()

    if (NOT _GRPC_GENERATOR_SETUP_DONE)
        message(FATAL_ERROR "setup_grpc_generator must be called before generate_cpp_from_proto")
    endif()

    set(OUT_HDRS)
    set(OUT_SRCS)
    foreach(proto_file ${arg_PROTO_FILES})
        file(RELATIVE_PATH proto_name ${arg_PROTOBUF_DIR} ${proto_file})
        string(REPLACE ".proto" "" proto_name ${proto_name})
        list(APPEND OUT_HDRS
            "${arg_OUT_DIR}/${proto_name}.pb.h"
            "${arg_OUT_DIR}/${proto_name}.grpc.pb.h"
            "${arg_OUT_DIR}/${proto_name}.grpc-ext.pb.h"
        )
        list(APPEND OUT_SRCS
            "${arg_OUT_DIR}/${proto_name}.pb.cc"
            "${arg_OUT_DIR}/${proto_name}.grpc.pb.cc"
            "${arg_OUT_DIR}/${proto_name}.grpc-ext.pb.cc"
        )
    endforeach()

    set(COMMAND_ARGS)
    list(APPEND COMMAND_ARGS
        -I "${arg_PROTOBUF_DIR}"
    )
    # standard protobuf cpp
    list(APPEND COMMAND_ARGS
        --cpp_out "${arg_OUT_DIR}"
    )
    # extended grpc cpp
    list(APPEND COMMAND_ARGS
        --ext_grpc_out "${arg_OUT_DIR}"
        --plugin=protoc-gen-ext_grpc="${GRPC_EXTENDED_CPP_PLUGIN_BINARY_PATH}"
    )
    # proto files
    list(APPEND COMMAND_ARGS
        ${arg_PROTO_FILES}
    )

    add_custom_command(
        OUTPUT
            ${OUT_HDRS}
            ${OUT_SRCS}
        COMMAND
            ${PROTOBUF_PROTOC_BINARY_PATH}
        ARGS
            ${COMMAND_ARGS}
        DEPENDS
            ${arg_PROTO_FILES}
            ${GRPC_GENERATOR_DEPS}
        COMMENT
            "Generating C++ code from proto files"
    )

    add_custom_target(${arg_TARGET_NAME}
        DEPENDS
            ${OUT_HDRS}
            ${OUT_SRCS}
    )

    if (arg_HDRS_VAR)
        set(${arg_HDRS_VAR} ${OUT_HDRS} PARENT_SCOPE)
    endif()
    if (arg_SRCS_VAR)
        set(${arg_SRCS_VAR} ${OUT_SRCS} PARENT_SCOPE)
    endif()
endfunction()
