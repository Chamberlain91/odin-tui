@SETLOCAL ENABLEDELAYEDEXPANSION
@ECHO OFF

SET "EXECUTABLE=tui-app.exe"

REM Development builds (--dev) allow conditional compilation of extra developer oriented 
REM features such as imgui, or logging to a terminal. Debug builds are development builds, but
REM with debug symbols and lowered optimizations enable use of debuggers such as LLDB or GDB.
REM Take note that:
REM --debug will have ODIN_DEBUG and DEV_BUILD defined
REM --dev will have only DEV_BUILD defined

GOTO :parse

:print_usage

    ECHO Usage: %~nx0 [flags]
    ECHO.
    ECHO     --run       Runs the executable, if compilation succeeded.
    ECHO     --debug     Enables development features, debug symbols, and lowers optimizations.
    ECHO     --dev       Enables development features (e.g. imgui, logs, etc)
    ECHO.
    ECHO     --sanitize  Enables address sanitizer.
    ECHO     --help      Shows this help.
    ECHO.
    ECHO     --define name:value
    ECHO         Specifies the value of a #config(name, value) in the project.
    ECHO.
    ECHO     --show-defines
    ECHO         Displays all defineable configuration value.
    ECHO.
    
    GOTO :eof

:parse

    REM No arguments provided
    IF "%~1" EQU "" GOTO :main

    REM Arguments
    IF /i "%~1" EQU "--help"         CALL :print_usage            & EXIT 0
    IF /i "%~1" EQU "--sanitize"     SET USE_SANITIZER=1  & SHIFT & GOTO :parse
    IF /i "%~1" EQU "--debug"        SET IS_DEBUG_BUILD=1 & SHIFT & GOTO :parse
    IF /i "%~1" EQU "--dev"          SET IS_DEV_BUILD=1   & SHIFT & GOTO :parse
    IF /i "%~1" EQU "--run"          SET SHOULD_RUN=1     & SHIFT & GOTO :parse
    IF /i "%~1" EQU "--define"       SHIFT & GOTO :read_define    & GOTO :parse
    IF /i "%~1" EQU "--show-defines" SET SHOW_DEFINES=1   & SHIFT & GOTO :parse

    REM Unknown argument
    ECHO Unknown argument "%~1"
    ECHO.
    
    CALL :print_usage
    
    EXIT 1

:main

    REM Set default build flags
    SET BUILD_FLAGS=!BUILD_FLAGS! -strict-style -error-pos-style:unix

    REM Resolve build flags for build type (optimized or debug)
    IF DEFINED IS_DEBUG_BUILD (
        SET BUILD_FLAGS=!BUILD_FLAGS! -o:minimal -debug
        SET SHOW_WINDOWS_CONSOLE=1
    ) else (
        SET BUILD_FLAGS=!BUILD_FLAGS! -o:speed
    )

    REM Resolve build flags for build type (development or release)
    REM Note: Debug builds are always development builds
    IF DEFINED IS_DEV_BUILD (
        SET BUILD_FLAGS=!BUILD_FLAGS! -define:DEV_BUILD=true
        SET SHOW_WINDOWS_CONSOLE=1
    ) else (
        SET BUILD_FLAGS=!BUILD_FLAGS! -warnings-as-errors -vet
    )

    @REM REM Windows executables can selectively show the console.
    @REM IF DEFINED SHOW_WINDOWS_CONSOLE (
    @REM     SET BUILD_FLAGS=!BUILD_FLAGS! -subsystem:console
    @REM ) else (
    @REM     SET BUILD_FLAGS=!BUILD_FLAGS! -subsystem:windows
    @REM )

    REM Add flags when using the address sanitizer
    IF DEFINED USE_SANITIZER (
        SET BUILD_FLAGS=!BUILD_FLAGS! -sanitize:address
    )

    REM ...
    IF DEFINED SHOW_DEFINES (
        SET BUILD_FLAGS=!BUILD_FLAGS! -show-defineables
    )

    REM Compile the Odin project
    ECHO Building...
    
    odin build ./src %BUILD_FLAGS% ^
        -out:%EXECUTABLE%

    CALL :check_error

    REM Optionally run the executable
    IF DEFINED SHOULD_RUN (
        ECHO Running...
        ECHO --------------------------------
        CALL !EXECUTABLE!
        CALL :check_error
    )

:check_error

    IF NOT !ERRORLEVEL! EQU 0 ( 
        REM Operation failed, cannot continue.
        EXIT !ERRORLEVEL! 
    ) ELSE ( 
        REM Seems fine, return from check_error.
        EXIT /B 
    )

:read_define

    FOR /f "tokens=1,* delims=:" %%A IN ("%~1") DO (
        SET BUILD_FLAGS=!BUILD_FLAGS! -define:%%A=%%~B
    )

    SHIFT & GOTO :parse
