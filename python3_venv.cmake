function (evc_assert_python_venv)
    if (PYTHON3_VENV_EXECUTABLE)
        return()
    endif ()

    find_package (Python3 COMPONENTS Interpreter)
    set (PYTHON3_VENV_DIR "${PROJECT_BINARY_DIR}/.venv" CACHE FILEPATH "Python3 venv directory")

    if (NOT IS_DIRECTORY ${PYTHON3_VENV_DIR})
        execute_process (
            COMMAND "${Python3_EXECUTABLE}" -m venv ${PYTHON3_VENV_DIR}
            RESULT_VARIABLE CREATE_VENV_RETURN_CODE
        )
    endif ()

    if (CREATE_VENV_RETURN_CODE)
        execute_process(
            COMMAND ${CMAKE_COMMAND} "-E" "remove_directory" "${PROJECT_BINARY_DIR}/.venv"
        )
        message(FATAL_ERROR "Failed to set up python virtual environment.  See above for diagnostics!")
    endif()

    set (PYTHON3_VENV_EXECUTABLE "${PYTHON3_VENV_DIR}/bin/python3")
    if (NOT EXISTS ${PYTHON3_VENV_EXECUTABLE})
        message(FATAL_ERROR
"Could not find python3 interpreter in virtual environment at \
${PYTHON3_VENV_EXECUTABLE}.  Try to remove ${PYTHON3_VENV_DIR} and run \
cmake again"
        )
    endif ()

    set (PYTHON3_VENV_EXECUTABLE "${PYTHON3_VENV_DIR}/bin/python3" CACHE FILEPATH "Python3 venv interpreter")
endfunction ()
