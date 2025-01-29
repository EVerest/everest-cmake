function(ev_remove_target_compile_option)
    set(one_value_args
        PREFIX # removes all compile options with this prefix
        EXACT # removes an option only if it matches exactly
    )

    set(multi_value_args
        TARGETS
    )

    cmake_parse_arguments(
        "args"
        ""
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    foreach(target ${args_TARGETS})
        set(COMPILE_OPTIONS_TO_REMOVE "")
        get_target_property(TARGET_COMPILE_OPTIONS "${target}" COMPILE_OPTIONS)
        # find applicable compile options for this target
        foreach(compile_option ${TARGET_COMPILE_OPTIONS})
            # collect compile options with a certain prefix
            if(NOT "${args_PREFIX}" STREQUAL "")
                string(FIND "${compile_option}" "${args_PREFIX}" POSITION)
                if("${POSITION}" EQUAL "0")
                    list(APPEND COMPILE_OPTIONS_TO_REMOVE "${compile_option}")
                endif()
            endif()
            # collect compile options with an exact match
            if(NOT "${args_EXACT}" STREQUAL "")
                if("${args_EXACT}" STREQUAL "${compile_option}")
                    message(STATUS "FOUND IT! ${compile_option} equals ${args_EXACT}")
                    list(APPEND COMPILE_OPTIONS_TO_REMOVE "${compile_option}")
                endif()
            endif()
        endforeach()

        # remove the collected compile options from the target
        foreach(compile_option ${COMPILE_OPTIONS_TO_REMOVE})
            list(REMOVE_ITEM TARGET_COMPILE_OPTIONS "${compile_option}")
        endforeach()
        set_target_properties("${target}" PROPERTIES COMPILE_OPTIONS "${TARGET_COMPILE_OPTIONS}")
    endforeach()
endfunction()
