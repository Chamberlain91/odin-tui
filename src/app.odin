package app

@(require) import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
import "core:unicode"
import "term"

main :: proc() {

    context = term.scoped_standard_context()

    // This application is useless unless ran interactively.
    if !term.is_interactive() {
        fmt.eprintln("This application does not support non-interactive mode.")
        os.exit(1)
    }

    term.initialize()
    defer term.shutdown()

    loop: for true {

        // Handle events for this iteration.
        term.process_input()

        defer free_all(context.temp_allocator)
        defer time.sleep(time.Millisecond) // stay cool

        term.set_cursor_position({1, 10})

        // Chew threw event queue.
        for term.has_event() {
            switch ev in term.get_event() or_break {
            case term.Size_Event:
            // TODO: Reallocate screen dependant resources
            case term.Mouse_Event:
                term.erase_screen()
                cursor_pos := term.cursor_position()
                defer term.set_cursor_position(cursor_pos)
                defer term.set_foreground_color(.Default)
                term.set_cursor_position(ev.position)
                term.set_foreground_color(.Yellow)
                fmt.printf("x: %i, y: %i", expand_values(ev.position))
            case term.Key_Event:
                if ev.key == .Escape || ev.ch == 'q' {
                    break loop
                } else if !unicode.is_control(ev.ch) {
                    log.infof("key: {}", ev.ch)
                } else {
                    // ...
                }
            }
        }

        cursor_pos := term.cursor_position()
        defer term.set_cursor_position(cursor_pos)
        defer term.set_foreground_color(.Default)

        // TODO: Make zero oriented
        term.set_cursor_position({0, 0})
        fmt.printf("Current time: {}:{}:{}", time.clock(time.now()))
        term.set_cursor_position({0, 1})
        fmt.printf("Terminal size: {}x{}", expand_values(term.size()))
    }
}
