package app

@(require) import "core:fmt"
import "core:os"
import "core:time"
import "term"

main :: proc() {

    when ODIN_DEBUG {
        context.allocator = term.create_scoped_tracking_allocator()
        context.temp_allocator = term.create_scoped_tracking_allocator(context.temp_allocator)
    }
    context.logger = term.create_scoped_logger()

    // This application is useless unless ran interactively.
    if !term.is_interactive() {
        fmt.eprintln("This application does not support non-interactive mode.")
        os.exit(1)
    }

    term.initialize()
    defer term.shutdown()

    loop: for true {
        defer free_all(context.temp_allocator)
        defer time.sleep(time.Millisecond) // stay cool

        // Handle events for this iteration.
        term.process_input()

        // Chew threw event queue.
        for term.has_event() {

            extra: string

            switch ev in term.get_event() or_break {
            case term.Mouse_Event:
                term.set_cursor_position(ev.position)
                extra = fmt.tprint(ev)
            case term.Size_Event:
                extra = fmt.tprint(ev)
            case term.Key_Event:
                if ev.key == .Escape || ev.ch == 'q' {
                    break loop
                }
                extra = fmt.tprint(ev)
            }

            cursor_pos := term.cursor_position()

            term.set_foreground_color(.Yellow)
            fmt.printf("x: %i, y: %i", expand_values(cursor_pos))

            if len(extra) > 0 {
                term.set_foreground_color(.Cyan)
                term.set_cursor_position(cursor_pos + {0, 1})
                fmt.printf("event: %v", extra)
            }

            term.set_foreground_color(.Default)
            term.set_cursor_position(cursor_pos)
        }

        // TODO: Make zero oriented
        term.set_cursor_position({1, 1})
        fmt.printf("Current time: {}:{}:{}", time.clock(time.now()))
        term.set_cursor_position({1, 2})
        fmt.printf("Terminal size: {}x{}", expand_values(term.size()))
    }
}
