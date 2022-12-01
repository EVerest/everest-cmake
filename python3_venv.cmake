function (evc_assert_python_venv)
    if (PYTHON3_VENV_EXECUTABLE)
        return()
    endif ()

    find_package (Python3 COMPONENTS Interpreter)

    if (NOT IS_DIRECTORY ${PYTHON3_VENV_DIR})
        execute_process (
            COMMAND "${Python3_EXECUTABLE}" -m venv ${PYTHON3_VENV_DIR}
            RESULT_VARIABLE CREATE_VENV_RETURN_CODE
        )
    endif ()

    if (CREATE_VENV_RETURN_CODE)
        execute_process(
            COMMAND ${CMAKE_COMMAND} "-E" "remove_directory" "${PYTHON3_VENV_DIR}"
        )
        message(FATAL_ERROR "Failed to set up python virtual environment.  See above for diagnostics!")
    endif()

    set (PYTHON3_VENV_EXECUTABLE "${PYTHON3_VENV_DIR}/bin/python3" CACHE FILEPATH "Python3 venv interpreter")
    if (NOT EXISTS ${PYTHON3_VENV_EXECUTABLE})
        unset (PYTHON3_VENV_EXECUTABLE CACHE)
        message(FATAL_ERROR
"Could not find python3 interpreter in virtual environment at \
${PYTHON3_VENV_EXECUTABLE}.  Try to remove ${PYTHON3_VENV_DIR} and run \
cmake again"
        )
    endif ()
endfunction ()

set (PYTHON3_VENV_DIR "${CMAKE_BINARY_DIR}/.venv" CACHE FILEPATH "Python3 venv directory")

if (NOT TARGET whereis-venv)
    add_custom_target(whereis-venv
        COMMENT "Looking up python venv"
        COMMAND ${CMAKE_COMMAND} -E echo "The python venv should be located at: ${PYTHON3_VENV_DIR}"
    )
endif ()
