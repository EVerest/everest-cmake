function (_evc_install_edm)
    include (FetchContent)

    FetchContent_Declare(
        everest-edm
        GIT_REPOSITORY https://github.com/EVerest/everest-dev-environment
        # NOTE: still using an older version here, because it is much faster
        GIT_TAG        deca310febcf1c2dad05f042d8a8ce0df2a312de
    )

    FetchContent_Populate(everest-edm)

    message(STATUS "Installing edm to python venv")
    execute_process(
        COMMAND ${PYTHON3_VENV_EXECUTABLE} -m pip install ${everest-edm_SOURCE_DIR}/dependency_manager
    )

    find_program(EVEREST_DEPENDENCY_MANAGER edm
        PATHS "${PYTHON3_VENV_DIR}/bin"
        NO_SYSTEM_ENVIRONMENT_PATH
    )

    if(NOT EVEREST_DEPENDENCY_MANAGER)
        message(FATAL_ERROR "Could not find EVerest dependency manager. Please make it available in your PATH.")
    endif()

endfunction ()

function (evc_setup_edm)
    # NOTE: by setting EVEREST_DEPENDENCY_MANAGER on the cmake configure line,
    #       a different binary can be used
    if (NOT EVEREST_DEPENDENCY_MANAGER)
        evc_assert_python_venv()

        _evc_install_edm()

    endif ()

    execute_process(
        COMMAND "${EVEREST_DEPENDENCY_MANAGER}"
            --cmake
            --working_dir "${PROJECT_SOURCE_DIR}"
            --out "${CMAKE_CURRENT_BINARY_DIR}/dependencies.cmake"
    RESULT_VARIABLE 
        EVEREST_DEPENDENCY_MANAGER_RETURN_CODE
    )

    if(EVEREST_DEPENDENCY_MANAGER_RETURN_CODE AND NOT EVEREST_DEPENDENCY_MANAGER_RETURN_CODE EQUAL 0)
        message(FATAL_ERROR "EVerest dependency manager did not run successfully.")
    endif()

    evc_include("CPM")

    include("${CMAKE_CURRENT_BINARY_DIR}/dependencies.cmake")
endfunction()




