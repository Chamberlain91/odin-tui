package oak_tui

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"

@(private = "file", init)
override_log_headers :: proc() {
    log.Level_Headers = [?]string {
        0 ..< 10 = "[D] ",
        10 ..< 20 = "[I] ",
        20 ..< 30 = "[W] ",
        30 ..< 40 = "[E] ",
        40 ..< 50 = "[F] ",
    }
}

@(private = "file")
Console_Opts :: log.Options{.Level, .Terminal_Color}

@(private = "file")
File_Opts :: log.Options{.Level, .Short_File_Path, .Line, .Procedure} | log.Full_Timestamp_Opts

@(require_results, deferred_in_out = destroy_scoped_logger)
create_scoped_logger :: proc(allocator := context.allocator) -> runtime.Logger {
    return create_logger(allocator)
}

@(private = "file")
destroy_scoped_logger :: proc(allocator := context.allocator, logger := context.logger) {
    destroy_logger(logger, allocator)
}

create_logger :: proc(allocator := context.allocator) -> runtime.Logger {

    // Attempt to make the file logger.
    log_file, log_err := os.open("latest.log", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0666)
    if log_err == nil {
        return log.create_file_logger(log_file, DEV_BUILD ? .Debug : .Info, opt = File_Opts, allocator = allocator)
    }

    fmt.eprintf("Unable to open log file: {}", log_err)
    return runtime.default_logger()
}

destroy_logger :: proc(logger := context.logger, allocator := context.allocator) {
    log.destroy_file_logger(logger, allocator)
}
