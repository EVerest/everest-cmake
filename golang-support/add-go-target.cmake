include_guard(GLOBAL)

function(add_go_target)
    set(options)
    set(oneValueArgs
        COMMENT
        GO_PACKAGE_SOURCE_PATH
        NAME
        OUTPUT_DIRECTORY
        WORKING_DIRECTORY
    )
    set(multiValueArgs
        DEPENDS
        OUTPUT
    )
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unparsed arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()
    if (arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Keywords missing values: ${arg_KEYWORDS_MISSING_VALUES}")
    endif()

    if (NOT arg_OUTPUT_DIRECTORY)
        message(FATAL_ERROR "OUTPUT_DIRECTORY not set")
    endif()
    if (NOT IS_ABSOLUTE ${arg_OUTPUT_DIRECTORY})
        message(FATAL_ERROR "OUTPUT_DIRECTORY ${arg_OUTPUT_DIRECTORY} is not an absolute path")
    endif()
    if (NOT arg_OUTPUT)
        message(FATAL_ERROR "OUTPUT not set")
    endif()
    foreach(output_file ${arg_OUTPUT})
        if (NOT IS_ABSOLUTE ${output_file})
            message(FATAL_ERROR "OUTPUT file ${output_file} is not an absolute path")
        endif()
        if (NOT ${output_file} MATCHES "^${arg_OUTPUT_DIRECTORY}/")
            message(FATAL_ERROR "OUTPUT file ${output_file} is not located in OUTPUT_DIRECTORY ${arg_OUTPUT_DIRECTORY}")
        endif()
    endforeach()
    list(LENGTH arg_OUTPUT output_count)
    if (NOT output_count EQUAL 1)
        message(FATAL_ERROR "Only one output file supported at the moment")
    endif()

    if (NOT arg_WORKING_DIRECTORY)
        message(FATAL_ERROR "WORKING_DIRECTORY not set")
    endif()
    if (NOT IS_ABSOLUTE ${arg_WORKING_DIRECTORY})
        message(FATAL_ERROR "WORKING_DIRECTORY ${arg_WORKING_DIRECTORY} is not an absolute path")
    endif()
    if (NOT arg_GO_PACKAGE_SOURCE_PATH)
        message(FATAL_ERROR "GO_PACKAGE_SOURCE_PATH not set")
    endif()
    if (NOT IS_ABSOLUTE ${arg_GO_PACKAGE_SOURCE_PATH})
        message(FATAL_ERROR "GO_PACKAGE_SOURCE_PATH ${arg_GO_PACKAGE_SOURCE_PATH} is not an absolute path")
    endif()
    if (NOT ${arg_GO_PACKAGE_SOURCE_PATH} MATCHES "^${arg_WORKING_DIRECTORY}/")
        message(FATAL_ERROR "GO_PACKAGE_SOURCE_PATH ${arg_GO_PACKAGE_SOURCE_PATH} is not located in WORKING_DIRECTORY ${arg_WORKING_DIRECTORY}")
    endif()


    if(NOT arg_NAME)
        message(FATAL_ERROR "NAME not set")
    endif()

    if (NOT arg_COMMENT)
        set(arg_COMMENT "Building ${arg_GO_PACKAGE_SOURCE_PATH}")
    endif()

    add_custom_command(
        OUTPUT
            ${arg_OUTPUT}
        COMMAND
            GOBIN=${arg_OUTPUT_DIRECTORY} go install ${arg_GO_PACKAGE_SOURCE_PATH}
        COMMENT
            ${arg_COMMENT}
        WORKING_DIRECTORY
            ${arg_WORKING_DIRECTORY}
        DEPENDS
            ${arg_DEPENDS}

    )

    add_custom_target(
        ${arg_NAME}
        DEPENDS
            ${arg_OUTPUT}
    )

    set_target_properties(${arg_NAME}
        PROPERTIES
            TARGET_FILE ${arg_OUTPUT}
    )
endfunction()
