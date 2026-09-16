option(EVC_FORCE_EDM_RUN "Run the EVerest dependency manager even when dependencies.yaml is unchanged" OFF)

function (evc_setup_edm)
    find_program(EVEREST_DEPENDENCY_MANAGER "edm")

    if(NOT EVEREST_DEPENDENCY_MANAGER)
        message(FATAL_ERROR "Could not find EVerest dependency manager. Please make it available in your PATH.")
    endif()

    set(EVC_EDM_DEPENDENCIES_YAML "${PROJECT_SOURCE_DIR}/dependencies.yaml")
    set(EVC_EDM_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/dependencies.cmake")

    # add the dependencies.yaml to the list of files which trigger
    # a cmake rerun, when changed
    set_property(
        DIRECTORY
        APPEND
        PROPERTY CMAKE_CONFIGURE_DEPENDS "${EVC_EDM_DEPENDENCIES_YAML}"
    )

    # only rerun EDM if it is necessary (environment vars set or dependencies.yaml changed)
    set(EVC_EDM_UP_TO_DATE FALSE)
    if(NOT EVC_FORCE_EDM_RUN
            AND NOT DEFINED ENV{EVEREST_MODIFY_DEPENDENCIES_URLS}
            AND NOT DEFINED ENV{EVEREST_MODIFY_DEPENDENCIES}
            AND EXISTS "${EVC_EDM_OUTPUT}"
            AND (NOT EXISTS "${EVC_EDM_DEPENDENCIES_YAML}"
                OR "${EVC_EDM_OUTPUT}" IS_NEWER_THAN "${EVC_EDM_DEPENDENCIES_YAML}"))
        set(EVC_EDM_UP_TO_DATE TRUE)
        message(DEBUG "Keeping ${EVC_EDM_OUTPUT}, ${EVC_EDM_DEPENDENCIES_YAML} did not change")
    endif()

    if(NOT EVC_EDM_UP_TO_DATE)
        execute_process(
            COMMAND "${EVEREST_DEPENDENCY_MANAGER}"
                --cmake
                --working_dir "${PROJECT_SOURCE_DIR}"
                --out "${EVC_EDM_OUTPUT}"
        RESULT_VARIABLE
            EVEREST_DEPENDENCY_MANAGER_RETURN_CODE
        )

        if(EVEREST_DEPENDENCY_MANAGER_RETURN_CODE AND NOT EVEREST_DEPENDENCY_MANAGER_RETURN_CODE EQUAL 0)
            message(FATAL_ERROR "EVerest dependency manager did not run successfully.")
        endif()
    endif()

    evc_include("CPM")

    include("${EVC_EDM_OUTPUT}")
endfunction()




