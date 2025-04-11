#!/usr/bin/env bash
set -e

EXECUTABLE=tui-app.out
    
# Development builds (--dev) allow conditional compilation of extra developer oriented  features 
# such as imgui, or logging to a terminal. Debug builds are development builds, but with debug
# symbols and lowered optimizations enable use of debuggers such as LLDB or GDB.
# Take note that:
# --debug will have ODIN_DEBUG and DEV_BUILD defined
# --dev will have only DEV_BUILD defined

print_usage () {

    echo "Usage: $0 [flags]"
    echo
    echo "    --run       Runs the executable, if compilation succeeded."
    echo "    --debug     Enables development features, debug symbols, and lowers optimizations."
    echo "    --dev       Enables development features (e.g. imgui, logs, etc)"
    echo
    echo "    --sanitize  Enables address sanitizer."
    echo "    --help      Shows this help."
    echo
    echo "    --define name:value"
    echo "        Specifies the value of a #config(name, value) in the project."
    echo

    exit
}

ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
    --run)      SHOULD_RUN=1;     shift ;;
    --debug)    IS_DEBUG_BUILD=1; shift ;;
    --dev)      IS_DEV_BUILD=1;   shift ;;
    --sanitize) USE_SANITIZER=1;  shift ;;
    --help)     print_usage ;;
    --define)
        shift
        IFS=: read -r NAME VALUE <<< "$1"
        BUILD_FLAGS+=(-define:$NAME=$VALUE)
        shift
        ;;
    -*|--*)
        echo "Unknown option '$1'"
        exit 1
        ;;
    *)
        ARGS+=("$1")
        shift
        ;;
    esac
done

set -- "${ARGS[@]}" # restore position args

if [ "$#" -gt 0 ]; then
    echo "Too many arguments"
    echo
    print_usage
fi

# Set default build flags
BUILD_FLAGS+=(-strict-style)
BUILD_FLAGS+=(-error-pos-style:unix)

# Resolve build flags for build type (optimized or debug)
if [ ! -z ${IS_DEBUG_BUILD} ]; then
    BUILD_FLAGS+=(-o:minimal)
    BUILD_FLAGS+=(-debug)
else
    BUILD_FLAGS+=(-o:speed)
fi

# Resolve build flags for build type (development or release)
# Note: Debug builds are always development builds
if [ ! -z ${IS_DEV_BUILD} ]; then
    BUILD_FLAGS+=(-define:DEV_BUILD=true)
else
    BUILD_FLAGS+=(-warnings-as-errors)
    BUILD_FLAGS+=(-vet)
fi

# Add flags when using the address sanitizer
if [ ! -z ${USE_SANITIZER} ]; then
    BUILD_FLAGS+=(-sanitize:address)
fi

# Compile the Odin project
echo Building...

odin build ./src ${BUILD_FLAGS[@]} \
    -out:$EXECUTABLE

# Optionally run the executable
if [ ! -z ${SHOULD_RUN} ]; then
    echo Running...
    echo --------------------------------
    ./$EXECUTABLE
fi
