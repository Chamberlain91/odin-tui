package app

@(require) import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
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

    term.show_cursor(false)
    defer term.show_cursor(true)

    canvas: tui.Canvas
    tui.canvas_resize(&canvas, term.size())

    player: [2]int = {10, 10}

    loop: for true {
        defer free_all(context.temp_allocator)

        // Handle events for this iteration.
        term.process_input()

        // ...
        tui.canvas_blit(canvas)

        // ...
        tui.canvas_clear(canvas)
        tui.canvas_set(canvas, player, '@')

        draw_chess_board(canvas)

        for do #partial switch ev in term.get_event() or_break {
        case term.Size_Event:
            tui.canvas_resize(&canvas, ev.size)
        case term.Mouse_Event:
            player = ev.position
        case term.Key_Event:
            if ev.control == .Sig_Quit || ev.control == .EOF || ev.key == .Escape || ev.str == "q" {
                break loop // Ctrl+\, Ctrl+D, Escape, or "q"
            }
            if ev.key == .LeftArrow || ev.str == "a" {
                player.x -= 1
            }
            if ev.key == .RightArrow || ev.str == "d" {
                player.x += 1
            }
            if ev.key == .UpArrow || ev.str == "w" {
                player.y -= 1
            }
            if ev.key == .DownArrow || ev.str == "s" {
                player.y += 1
            }
        }

        time.sleep(time.Millisecond)
    }

    draw_chess_board :: proc(canvas: tui.Canvas) {

        BR :: '┌'
        TR :: '└'
        LB :: '┐'
        TL :: '┘'
        LBR :: '┬'
        LTB :: '┤'
        RTB :: '├'
        LRT :: '┴'
        LRTB :: '┼'
        H :: '─'
        V :: '│'

        for yi in 0 ..< 8 {
            y := yi * 2
            for xi in 0 ..< 8 {
                x := xi * 4
                if yi == 0 {
                    tui.canvas_set(canvas, {x + 0, y}, xi == 0 ? BR : LBR)
                } else {
                    tui.canvas_set(canvas, {x + 0, y}, xi == 0 ? RTB : LRTB)
                }
                tui.canvas_set(canvas, {x + 1, y}, H)
                tui.canvas_set(canvas, {x + 2, y}, H)
                tui.canvas_set(canvas, {x + 3, y}, H)

                tui.canvas_set(canvas, {x + 0, y + 1}, V)
                tui.canvas_set(canvas, {x + 1, y + 1}, ' ')
                tui.canvas_set(canvas, {x + 2, y + 1}, '·')
                tui.canvas_set(canvas, {x + 3, y + 1}, ' ')
            }
            tui.canvas_set(canvas, {32, y + 0}, yi == 0 ? LB : LTB)
            tui.canvas_set(canvas, {32, y + 1}, V)
        }
        for xi in 0 ..< 8 {
            x := xi * 4
            tui.canvas_set(canvas, {x + 0, 16}, xi == 0 ? TR : LRT)
            tui.canvas_set(canvas, {x + 1, 16}, H)
            tui.canvas_set(canvas, {x + 2, 16}, H)
            tui.canvas_set(canvas, {x + 3, 16}, H)
        }
        tui.canvas_set(canvas, {32, 16}, TL)
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

            term.reset_styles() // default style and color
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
