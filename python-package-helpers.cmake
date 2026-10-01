# Declares a python package that lives in a local source directory, so it can be
# installed by name with ev_install_pip_package() from anywhere in the project.
function(ev_declare_pip_package)
    set(one_value_args
        NAME
        SOURCE_DIRECTORY
    )

    cmake_parse_arguments(
        "args"
        "" # no optional arguments
        "${one_value_args}"
        ""
        ${ARGN}
    )

    if("${args_NAME}" STREQUAL "")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: NAME is required")
    endif()

    cmake_path(ABSOLUTE_PATH args_SOURCE_DIRECTORY NORMALIZE)

    set(TARGET_NAME "ev_pip_package_${args_NAME}")
    add_custom_target(${TARGET_NAME})

    set_target_properties(${TARGET_NAME}
        PROPERTIES
            SOURCE_DIRECTORY "${args_SOURCE_DIRECTORY}"
    )
endfunction()

function(ev_add_pip_package)
    message(DEPRECATION "ev_add_pip_package() is deprecated, use ev_declare_pip_package() instead")
    ev_declare_pip_package(${ARGN})
endfunction()

# Installs a python package into the current python environment.
#
# If NAME has been declared with ev_declare_pip_package(), it is installed from its
# source directory, optionally EDITABLE. Otherwise it is installed from the package
# index, pinned to VERSION if given. FORCE reinstalls it even if it is up to date.
#
# ev_install_pip_package(
#     NAME <name>
#     [VERSION <version>]
#     [EDITABLE]
#     [FORCE]
# )
function(ev_install_pip_package)
    set(options
        EDITABLE
        FORCE
        LOCAL
    )

    set(one_value_args
        NAME
        VERSION
    )

    cmake_parse_arguments(
        "args"
        "${options}"
        "${one_value_args}"
        ""
        ${ARGN}
    )

    if("${args_NAME}" STREQUAL "")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: NAME is required")
    endif()

    if(args_LOCAL)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: LOCAL (--user) was removed, packages are installed into the active python venv")
    endif()

    set(PIP_INSTALL_FLAGS "")
    if(args_FORCE)
        list(APPEND PIP_INSTALL_FLAGS FORCE)
    endif()

    set(TARGET_NAME "ev_pip_package_${args_NAME}")

    if(TARGET ${TARGET_NAME})
        if(NOT "${args_VERSION}" STREQUAL "")
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: VERSION cannot be used for ${args_NAME}, it is declared with a source directory which determines the version")
        endif()
        if(args_EDITABLE)
            list(APPEND PIP_INSTALL_FLAGS EDITABLE)
        endif()
        get_target_property(SOURCE_DIRECTORY ${TARGET_NAME} SOURCE_DIRECTORY)
        _ev_pip_install_from_directory(
            NAME "${args_NAME}"
            SOURCE_DIRECTORY "${SOURCE_DIRECTORY}"
            ${PIP_INSTALL_FLAGS}
        )
    else()
        if(args_EDITABLE)
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: EDITABLE requires ${args_NAME} to be declared with ev_declare_pip_package()")
        endif()
        _ev_pip_install_from_index(
            NAME "${args_NAME}"
            VERSION "${args_VERSION}"
            ${PIP_INSTALL_FLAGS}
        )
    endif()
endfunction()

function(ev_create_pip_install_dist_target)
    set(oneValueArgs
        PACKAGE_NAME
        PACKAGE_SOURCE_DIRECTORY
    )
    set(multiValueArgs
        DEPENDS
    )
    cmake_parse_arguments(
        "arg"
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if("${arg_PACKAGE_NAME}" STREQUAL "")
        message(FATAL_ERROR "PACKAGE_NAME is required")
    endif()

    if("${arg_PACKAGE_SOURCE_DIRECTORY}" STREQUAL "")
        set(arg_PACKAGE_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        message(DEBUG "ev_create_pip_install_dist_target: no PACKAGE_SOURCE_DIRECTORY provided, using: ${arg_PACKAGE_SOURCE_DIRECTORY}")
    endif()

    set(CHECK_DONE_FILE "${CMAKE_BINARY_DIR}/${arg_PACKAGE_NAME}_pip_install_dist_installed")
    add_custom_command(
        OUTPUT
            "${CHECK_DONE_FILE}"
        COMMENT
            "Installing ${arg_PACKAGE_NAME} from distribution"
        WORKING_DIRECTORY
            ${arg_PACKAGE_SOURCE_DIRECTORY}

        # Remove build dir from pip
        COMMAND
            ${CMAKE_COMMAND} -E remove_directory build
        COMMAND
            ${Python3_EXECUTABLE} -m pip install --force-reinstall .
        COMMAND
            ${CMAKE_COMMAND} -E remove_directory build
        COMMAND
            ${CMAKE_COMMAND} -E touch "${CHECK_DONE_FILE}"
    )

    set(TARGET_NAME "${arg_PACKAGE_NAME}_pip_install_dist")
    add_custom_target(${TARGET_NAME}
        DEPENDS
        "${CHECK_DONE_FILE}"
        DEPENDS
        ${arg_DEPENDS}
    )
    set_target_properties(${TARGET_NAME}
        PROPERTIES
        PACKAGE_SOURCE_DIRECTORY "${arg_PACKAGE_SOURCE_DIRECTORY}"
    )
endfunction()

function(ev_create_pip_install_local_target)
    set(oneValueArgs
        PACKAGE_NAME
        PACKAGE_SOURCE_DIRECTORY
    )
    set(multiValueArgs
        DEPENDS
    )
    cmake_parse_arguments(
        "arg"
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if("${arg_PACKAGE_NAME}" STREQUAL "")
        message(FATAL_ERROR "PACKAGE_NAME is required")
    endif()

    if("${arg_PACKAGE_SOURCE_DIRECTORY}" STREQUAL "")
        set(arg_PACKAGE_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        message(DEBUG "ev_create_pip_install_local_target: no PACKAGE_SOURCE_DIRECTORY provided, using: ${arg_PACKAGE_SOURCE_DIRECTORY}")
    endif()

    set(TARGET_NAME "${arg_PACKAGE_NAME}_pip_install_local")
    add_custom_target(${TARGET_NAME}

        # Remove build dir from pip
        COMMAND
            ${CMAKE_COMMAND} -E remove_directory build
        COMMAND
            ${Python3_EXECUTABLE} -m pip install --force-reinstall -e .
        WORKING_DIRECTORY
            ${arg_PACKAGE_SOURCE_DIRECTORY}
        DEPENDS
            ${arg_DEPENDS}
        COMMENT
            "Installing ${arg_PACKAGE_NAME} via user-mode from build"
    )
    set_target_properties(${TARGET_NAME}
        PROPERTIES
        PACKAGE_SOURCE_DIRECTORY "${arg_PACKAGE_SOURCE_DIRECTORY}"
    )
endfunction()

function(ev_create_pip_install_targets)
    set(oneValueArgs
        PACKAGE_NAME
        PACKAGE_SOURCE_DIRECTORY
    )
    set(multiValueArgs
        DIST_DEPENDS
        LOCAL_DEPENDS
    )
    cmake_parse_arguments(
        "arg"
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    ev_create_pip_install_dist_target(
        PACKAGE_NAME ${arg_PACKAGE_NAME}
        PACKAGE_SOURCE_DIRECTORY ${arg_PACKAGE_SOURCE_DIRECTORY}
        DEPENDS ${arg_DIST_DEPENDS}
    )
    ev_create_pip_install_local_target(
        PACKAGE_NAME ${arg_PACKAGE_NAME}
        PACKAGE_SOURCE_DIRECTORY ${arg_PACKAGE_SOURCE_DIRECTORY}
        DEPENDS ${arg_LOCAL_DEPENDS}
    )
endfunction()

function(ev_create_python_wheel_targets)
    set(oneValueArgs
        PACKAGE_NAME
        PACKAGE_SOURCE_DIRECTORY
        INSTALL_PREFIX
    )
    set(multiValueArgs
        DEPENDS
    )
    cmake_parse_arguments(
        "EV_CREATE_PYTHON_WHEEL_TARGETS"
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if("${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}" STREQUAL "")
        message(FATAL_ERROR "PACKAGE_NAME is required")
    endif()

    if("${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_SOURCE_DIRECTORY}" STREQUAL "")
        set(EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    if(NOT DEFINED ${EV_CREATE_PYTHON_WHEEL_TARGETS_INSTALL_PREFIX})
        if("${${PROJECT_NAME}_WHEEL_INSTALL_PREFIX}" STREQUAL "")
            message(FATAL_ERROR
                "No install prefix for wheel specified, please set ${PROJECT_NAME}_WHEEL_INSTALL_PREFIX, use the INSTALL_PREFIX argument or use macro ev_setup_cmake_variables_python_wheel() to set a default value."
            )
        else()
            set(EV_CREATE_PYTHON_WHEEL_TARGETS_INSTALL_PREFIX ${${PROJECT_NAME}_WHEEL_INSTALL_PREFIX})
        endif()
    endif()

    set(WHEEL_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/dist_${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME})
    set(CHECK_DONE_FILE ${CMAKE_CURRENT_BINARY_DIR}/${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}_build_wheel_done)

    add_custom_target(${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}_build_wheel
        DEPENDS
            "${CHECK_DONE_FILE}"
    )

    set(USE_WHEELS "ON" CACHE STRING "Enable or disable the use of python wheels - if off switch to tar.gz format")
    message(DEBUG "USE_WHEELS is set to: ${USE_WHEELS}")

    if(USE_WHEELS)
        ev_is_python_venv_active(RESULT_VAR IS_PYTHON_VENV_ACTIVE)
        get_property(BUILD_PACKAGE_INSTALLED GLOBAL PROPERTY "EV_PIP_BUILD_INSTALLED_${Python3_EXECUTABLE}")
        if(IS_PYTHON_VENV_ACTIVE AND NOT BUILD_PACKAGE_INSTALLED)
            ev_install_pip_package(NAME build)
            set_property(GLOBAL PROPERTY "EV_PIP_BUILD_INSTALLED_${Python3_EXECUTABLE}" TRUE)
        endif()
        set(PACKAGE_BUILD_COMMAND ${Python3_EXECUTABLE} -m build --wheel --outdir ${WHEEL_OUTDIR} .)
        set(PACKAGE_REMOVE_DIR_COMMAND ${CMAKE_COMMAND} -E rm -rf build src/*.egg-info)
    else()
        set(PACKAGE_BUILD_COMMAND ${Python3_EXECUTABLE} setup.py sdist --dist-dir ${WHEEL_OUTDIR})
        set(PACKAGE_REMOVE_DIR_COMMAND ${CMAKE_COMMAND} -E rm -rf src/*.egg-info)
    endif()

    add_custom_command(
        OUTPUT
        "${CHECK_DONE_FILE}"

        COMMAND
            ${PACKAGE_BUILD_COMMAND}
        COMMAND
            ${PACKAGE_REMOVE_DIR_COMMAND}
        COMMAND
            ${CMAKE_COMMAND} -E touch "${CHECK_DONE_FILE}"
        WORKING_DIRECTORY
            ${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_SOURCE_DIRECTORY}
        DEPENDS
            ${EV_CREATE_PYTHON_WHEEL_TARGETS_DEPENDS}
        COMMENT
            "Building Python package for module ${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}"
    )

    add_custom_target(${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}_install_wheel
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${EV_CREATE_PYTHON_WHEEL_TARGETS_INSTALL_PREFIX}
        COMMAND
            ${CMAKE_COMMAND} -E copy_directory ${WHEEL_OUTDIR} ${EV_CREATE_PYTHON_WHEEL_TARGETS_INSTALL_PREFIX}/
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS
            ${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME}_build_wheel
        COMMENT
            "Copy Python package for module ${EV_CREATE_PYTHON_WHEEL_TARGETS_PACKAGE_NAME} to ${EV_CREATE_PYTHON_WHEEL_TARGETS_INSTALL_PREFIX}"
    )
endfunction()

macro(ev_setup_cmake_variables_python_wheel)
    set(${PROJECT_NAME}_WHEEL_INSTALL_PREFIX "" CACHE PATH "Path to install python package to")

    if(${PROJECT_NAME}_WHEEL_INSTALL_PREFIX STREQUAL "")
        if(NOT ${WHEEL_INSTALL_PREFIX} STREQUAL "")
            set(${PROJECT_NAME}_DEFAULT_WHEEL_INSTALL_PREFIX "${WHEEL_INSTALL_PREFIX}")
            message(DEBUG "${PROJECT_NAME}_WHEEL_INSTALL_PREFIX not set, using: WHEEL_INSTALL_PREFIX=${${PROJECT_NAME}_DEFAULT_WHEEL_INSTALL_PREFIX}")
        else()
            set(${PROJECT_NAME}_DEFAULT_WHEEL_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/../dist-wheels")
            message(DEBUG "${PROJECT_NAME}_WHEEL_INSTALL_PREFIX and WHEEL_INSTALL_PREFIX not set, using default: \${CMAKE_INSTALL_PREFIX}/../dist-wheels=${${PROJECT_NAME}_DEFAULT_WHEEL_INSTALL_PREFIX}")
        endif()

        set(${PROJECT_NAME}_WHEEL_INSTALL_PREFIX "${${PROJECT_NAME}_DEFAULT_WHEEL_INSTALL_PREFIX}" CACHE PATH "Path to install python package to" FORCE)
    endif()

    message(DEBUG "${PROJECT_NAME}_WHEEL_INSTALL_PREFIX=${${PROJECT_NAME}_WHEEL_INSTALL_PREFIX}")
endmacro()

function(ev_pip_install_local)
    message(DEPRECATION "ev_pip_install_local() is deprecated, declare the package with ev_declare_pip_package() and use ev_install_pip_package(NAME <name> EDITABLE) instead")

    set(options
        FORCE
    )
    set(oneValueArgs
        PACKAGE_NAME
        PACKAGE_SOURCE_DIRECTORY
    )
    set(multiValueArgs
        DEPENDS
    )
    cmake_parse_arguments(
        "EV_PIP_INSTALL_LOCAL"
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if("${EV_PIP_INSTALL_LOCAL_PACKAGE_NAME}" STREQUAL "")
        message(FATAL_ERROR "PACKAGE_NAME is required")
    endif()

    if("${EV_PIP_INSTALL_LOCAL_PACKAGE_SOURCE_DIRECTORY}" STREQUAL "")
        set(EV_PIP_INSTALL_LOCAL_PACKAGE_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    set(PIP_INSTALL_FLAGS EDITABLE)
    if(EV_PIP_INSTALL_LOCAL_FORCE)
        list(APPEND PIP_INSTALL_FLAGS FORCE)
    endif()

    _ev_pip_install_from_directory(
        NAME "${EV_PIP_INSTALL_LOCAL_PACKAGE_NAME}"
        SOURCE_DIRECTORY "${EV_PIP_INSTALL_LOCAL_PACKAGE_SOURCE_DIRECTORY}"
        ${PIP_INSTALL_FLAGS}
    )
endfunction()

# Installs the package found in SOURCE_DIRECTORY, unless this version has already been
# installed in the same mode; a stamp file in CMAKE_BINARY_DIR records that.
function(_ev_pip_install_from_directory)
    cmake_parse_arguments(
        "args"
        "EDITABLE;FORCE"
        "NAME;SOURCE_DIRECTORY"
        ""
        ${ARGN}
    )

    execute_process(
        COMMAND
            ${Python3_EXECUTABLE} -c "from setuptools import setup; setup()" --version
        WORKING_DIRECTORY
            ${args_SOURCE_DIRECTORY}
        OUTPUT_VARIABLE
            SOURCE_VERSION
        ERROR_VARIABLE
            SOURCE_VERSION_ERROR
        RESULT_VARIABLE
            SOURCE_VERSION_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT SOURCE_VERSION_RESULT EQUAL 0)
        message(FATAL_ERROR "Could not determine the version of ${args_NAME} in ${args_SOURCE_DIRECTORY}:\n${SOURCE_VERSION_ERROR}")
    endif()

    # keep only the last line, setuptools may print discovery output before the version
    string(REGEX REPLACE "^.*\n" "" SOURCE_VERSION "${SOURCE_VERSION}")

    set(PIP_INSTALL_ARGS "")
    if(args_EDITABLE)
        set(STAMP_PREFIX "${CMAKE_BINARY_DIR}/${args_NAME}_pip_install_local_installed_")
        list(APPEND PIP_INSTALL_ARGS -e)
    else()
        set(STAMP_PREFIX "${CMAKE_BINARY_DIR}/${args_NAME}_pip_install_installed_")
    endif()
    set(CHECK_DONE_FILE "${STAMP_PREFIX}${SOURCE_VERSION}")

    if(args_FORCE OR NOT EXISTS "${CHECK_DONE_FILE}")
        message(STATUS "${args_NAME} not found, installing.")
        if(args_FORCE)
            list(PREPEND PIP_INSTALL_ARGS --force-reinstall)
        endif()
        execute_process(
            COMMAND
                ${Python3_EXECUTABLE} -m pip install ${PIP_INSTALL_ARGS} .
            WORKING_DIRECTORY
                ${args_SOURCE_DIRECTORY}
            RESULT_VARIABLE PIP_INSTALL_RESULT
        )
        if(NOT PIP_INSTALL_RESULT EQUAL 0)
            message(FATAL_ERROR "Could not install ${args_NAME} from ${args_SOURCE_DIRECTORY}")
        endif()
        # the other mode and older versions are no longer what is installed
        file(GLOB STALE_STAMPS
            "${CMAKE_BINARY_DIR}/${args_NAME}_pip_install_local_installed_*"
            "${CMAKE_BINARY_DIR}/${args_NAME}_pip_install_installed_*"
        )
        if(STALE_STAMPS)
            file(REMOVE ${STALE_STAMPS})
        endif()
        file(TOUCH "${CHECK_DONE_FILE}")
    endif()

    message(STATUS "Using ${args_NAME} from ${args_SOURCE_DIRECTORY} version: ${SOURCE_VERSION}")
endfunction()

# Sets OUT_VAR to the installed version of package NAME, or to an empty string if it is
# not installed.
function(_ev_pip_installed_version NAME OUT_VAR)
    execute_process(
        COMMAND
            ${Python3_EXECUTABLE} -m pip --disable-pip-version-check show ${NAME}
        OUTPUT_VARIABLE PIP_SHOW_OUTPUT
        ERROR_QUIET
        RESULT_VARIABLE PIP_SHOW_RESULT
    )
    set(INSTALLED_VERSION "")
    if(PIP_SHOW_RESULT EQUAL 0 AND PIP_SHOW_OUTPUT MATCHES "(^|\n)Version: ([^\n]+)")
        set(INSTALLED_VERSION "${CMAKE_MATCH_2}")
    endif()
    set(${OUT_VAR} "${INSTALLED_VERSION}" PARENT_SCOPE)
endfunction()

# Installs package NAME from the package index, unless it is already installed in the
# requested VERSION (or in any version, if no VERSION is given).
function(_ev_pip_install_from_index)
    cmake_parse_arguments(
        "args"
        "FORCE"
        "NAME;VERSION"
        ""
        ${ARGN}
    )

    _ev_pip_installed_version(${args_NAME} INSTALLED_VERSION)

    set(REQUIREMENT "${args_NAME}")
    if(NOT "${args_VERSION}" STREQUAL "")
        set(REQUIREMENT "${args_NAME}==${args_VERSION}")
    endif()

    if(args_FORCE
            OR "${INSTALLED_VERSION}" STREQUAL ""
            OR (NOT "${args_VERSION}" STREQUAL "" AND NOT "${INSTALLED_VERSION}" STREQUAL "${args_VERSION}"))
        message(STATUS "Installing ${REQUIREMENT}")
        set(PIP_INSTALL_ARGS --quiet --disable-pip-version-check)
        if(args_FORCE)
            list(APPEND PIP_INSTALL_ARGS --force-reinstall)
        endif()
        execute_process(
            COMMAND
                ${Python3_EXECUTABLE} -m pip install ${PIP_INSTALL_ARGS} ${REQUIREMENT}
            RESULT_VARIABLE PIP_INSTALL_RESULT
        )
        if(NOT PIP_INSTALL_RESULT EQUAL 0)
            message(FATAL_ERROR "Could not install ${REQUIREMENT}")
        endif()
        _ev_pip_installed_version(${args_NAME} INSTALLED_VERSION)
    endif()

    message(STATUS "Using ${args_NAME} version: ${INSTALLED_VERSION}")
endfunction()
