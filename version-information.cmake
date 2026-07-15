set(EVEREST_VERSION_INFORMATION_HEADER_IN "${CMAKE_CURRENT_LIST_DIR}/assets/version_information.hpp.in")
set(EVEREST_VERSION_INFORMATION_TXT_IN "${CMAKE_CURRENT_LIST_DIR}/assets/version_information.txt.in")

function (evc_generate_version_information)
    find_package(Git QUIET)

    set(GIT_DESCRIBE_OUTPUT "")
    set(GIT_SYMBOLIC_REF_OUTPUT "")

    if(GIT_FOUND)
        execute_process(
            COMMAND
                "${GIT_EXECUTABLE}" describe --dirty --always --tags
            WORKING_DIRECTORY
                "${PROJECT_SOURCE_DIR}"
            RESULT_VARIABLE
                GIT_DESCRIBE_RESULT
            OUTPUT_VARIABLE
                GIT_DESCRIBE_OUTPUT
            ERROR_VARIABLE
                GIT_DESCRIBE_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
        if(NOT GIT_DESCRIBE_RESULT EQUAL 0)
            message(WARNING
                "git describe failed in '${PROJECT_SOURCE_DIR}' "
                "(exit code ${GIT_DESCRIBE_RESULT}): ${GIT_DESCRIBE_ERROR}"
            )
        endif()

        execute_process(
            COMMAND
                "${GIT_EXECUTABLE}" symbolic-ref --quiet --short HEAD
            WORKING_DIRECTORY
                "${PROJECT_SOURCE_DIR}"
            RESULT_VARIABLE
                GIT_SYMBOLIC_REF_RESULT
            OUTPUT_VARIABLE
                GIT_SYMBOLIC_REF_OUTPUT
            ERROR_VARIABLE
                GIT_SYMBOLIC_REF_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
        if(NOT GIT_SYMBOLIC_REF_RESULT EQUAL 0)
            message(WARNING
                "git symbolic-ref failed in '${PROJECT_SOURCE_DIR}' "
                "(exit code ${GIT_SYMBOLIC_REF_RESULT}): ${GIT_SYMBOLIC_REF_ERROR}"
            )
        endif()
    else()
        message(WARNING "Git executable not found, cannot determine EVEREST_GIT_VERSION")
    endif()

    if(GIT_DESCRIBE_RESULT EQUAL 0 AND NOT GIT_DESCRIBE_OUTPUT STREQUAL "")
        if(GIT_SYMBOLIC_REF_RESULT EQUAL 0 AND NOT GIT_SYMBOLIC_REF_OUTPUT STREQUAL "")
            set(EVEREST_GIT_VERSION "${GIT_SYMBOLIC_REF_OUTPUT}@${GIT_DESCRIBE_OUTPUT}")
        else()
            set(EVEREST_GIT_VERSION "${GIT_DESCRIBE_OUTPUT}")
        endif()
    else()
        set(EVEREST_GIT_VERSION "")
    endif()

    string(REGEX MATCH "^[^/]+" GIT_BRANCH_PREFIX_OUTPUT "${GIT_SYMBOLIC_REF_OUTPUT}")
    if(GIT_BRANCH_PREFIX_OUTPUT STREQUAL "release" OR GIT_BRANCH_PREFIX_OUTPUT STREQUAL "stable")
        set(EVEREST_PROJECT_VERSION "${PROJECT_VERSION}")
    else()
        set(EVEREST_PROJECT_VERSION "${PROJECT_VERSION}-dev")
    endif()

    message(STATUS "EVEREST_GIT_VERSION exported as ${EVEREST_GIT_VERSION}")
    message(STATUS "EVEREST_PROJECT_VERSION exported as ${EVEREST_PROJECT_VERSION}")
    configure_file("${EVEREST_VERSION_INFORMATION_HEADER_IN}" "${CMAKE_CURRENT_BINARY_DIR}/generated/include/generated/version_information.hpp" @ONLY)
    configure_file("${EVEREST_VERSION_INFORMATION_TXT_IN}" "${CMAKE_CURRENT_BINARY_DIR}/generated/version_information.txt" @ONLY)
endfunction()
