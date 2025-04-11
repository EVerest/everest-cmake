include_guard(GLOBAL)

function(generate_py_from_proto)
    set(options)
    set(oneValueArgs
        PROTOBUF_DIR
        OUT_FILES_VAR
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

    set(OUT_FILES)
    foreach(proto_file ${arg_PROTO_FILES})
        file(RELATIVE_PATH proto_name ${arg_PROTOBUF_DIR} ${proto_file})
        string(REPLACE ".proto" "" proto_name ${proto_name})
        list(APPEND OUT_FILES
            "${arg_OUT_DIR}/${proto_name}_pb2.py"
            "${arg_OUT_DIR}/${proto_name}_pb2_grpc.py"
            "${arg_OUT_DIR}/${proto_name}_pb2.pyi"
        )
    endforeach()

    set(COMMAND_ARGS)
    list(APPEND COMMAND_ARGS
        -I "${arg_PROTOBUF_DIR}"
    )
    # standard protobuf cpp
    list(APPEND COMMAND_ARGS
        --python_out="${arg_OUT_DIR}"
    )
    list(APPEND COMMAND_ARGS
        --pyi_out="${arg_OUT_DIR}"
    )
    # grpc cpp
    list(APPEND COMMAND_ARGS
        --grpc_python_out="${arg_OUT_DIR}"
    )
    # proto files
    list(APPEND COMMAND_ARGS
        ${arg_PROTO_FILES}
    )

    add_custom_command(
        OUTPUT
            ${OUT_FILES}
        COMMAND
            ${PROTOBUF_PROTOC_PYTHON_COMMAND}
        ARGS
            ${COMMAND_ARGS}
        DEPENDS
            ${arg_PROTO_FILES}
        COMMENT
            "Generating Python files from proto files"
    )

    add_custom_target(${arg_TARGET_NAME}
        DEPENDS
            ${OUT_FILES}
    )

    if (arg_OUT_FILES_VAR)
        set(${arg_OUT_FILES_VAR} ${OUT_FILES} PARENT_SCOPE)
    endif()
endfunction()
