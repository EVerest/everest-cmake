include_guard(GLOBAL)

# This macro sets up Go for the project. It will check
# if the Go installation is available and if so, it
# will set the GO_EXECUTABLE variable to the path of
# the Go executable. It will also set the GO_VERSION
# variable to the version of Go installed.
macro(setup_go)
    find_program(GO_EXECUTABLE go REQUIRED)
    execute_process(
        COMMAND ${GO_EXECUTABLE} version
        OUTPUT_VARIABLE _GO_VERSION_OUTPUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(REGEX MATCH "go version go([0-9]+\\.[0-9]+\\.[0-9]+)" GO_VERSION "${_GO_VERSION_OUTPUT}")
    message(STATUS "Go found: ${GO_EXECUTABLE}")
    message(STATUS "Go version: ${GO_VERSION}")

    set(_GO_SETUP_DONE TRUE)
endmacro()
