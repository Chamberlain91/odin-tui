package app

@(require) import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
import "core:unicode"
import "term"
import "term/tui"

main :: proc() {

    context = term.scoped_standard_context()

    // This application is useless unless ran interactively.
    if !term.is_interactive() {
        fmt.eprintln("This application does not support non-interactive mode.")
        os.exit(1)
    }

    term.initialize()
    defer term.shutdown()

    term.enable_alternate_screen()
    term.enable_mouse()

    snake_game()
}

snake_game :: proc() {

    canvas: tui.Canvas

    term.set_cursor_position({0, 0})

    loop: for true {

        // Handle events for this iteration.
        term.process_input()

        defer free_all(context.temp_allocator)
        defer time.sleep(time.Millisecond)

        for do switch ev in term.get_event() or_break {
        case term.Size_Event:
            tui.canvas_resize(&canvas, ev.size)
        case term.Paste_Event:
            fmt.print(ev)
            term.move_cursor_next_line()
        case term.Mouse_Event:
            fmt.print(ev)
            term.move_cursor_next_line()
        case term.Key_Event:
            if term.is_key(ev, .Q) || term.is_key(ev, .Escape) do break loop
            fmt.print(ev)
            term.move_cursor_next_line()
        }
    }
}

whatever :: proc() {

    loop: for true {

        // Handle events for this iteration.
        term.process_input()

        defer free_all(context.temp_allocator)
        defer time.sleep(time.Millisecond) // stay cool

        term.set_cursor_position({1, 10})

        {
            term.save_cursor()
            defer term.restore_cursor()
            defer term.set_foreground_color(.Default)

            term.reset() // default style and color
            term.set_cursor_position({0, 0})

            for color in term.Color {
                term.set_foreground_color(color, bright = false)
                fmt.printf("[{}, normal] Current time: {}:{}:{}", color, time.clock(time.now()))
                term.move_cursor_next_line()

                term.set_foreground_color(color, bright = true)
                fmt.printf("[{}, bright] Current time: {}:{}:{}", color, time.clock(time.now()))
                term.move_cursor_next_line()
            }

            for style in term.Style {
                term.set_style(style, true)

                term.set_foreground_color(.Red, bright = true)
                fmt.printf("[{}, bright] Terminal size: {}x{}", style, expand_values(term.size()))
                term.move_cursor_next_line()

                term.set_foreground_color(.Red, bright = false)
                fmt.printf("[{}, normal] Terminal size: {}x{}", style, expand_values(term.size()))
                term.move_cursor_next_line()

                term.set_style(style, false)
            }
        }

        // Chew threw event queue.
        for do #partial switch ev in term.get_event() or_break {
        case term.Mouse_Event:
            term.save_cursor()
            defer term.restore_cursor()
            defer term.set_foreground_color(.Default)
            term.erase_screen()
            term.set_cursor_position(ev.position)
            term.set_foreground_color(.Yellow)
            fmt.print("X")
        case term.Key_Event:
            log.info(ev)
            if ev.key == .Escape || ev.str == "q" {
                break loop
            }
        }
    }
}
