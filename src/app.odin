package app

import "chess"
@(require) import "core:fmt"
@(require) import "core:log"
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
    term.show_cursor(false)
    term.enable_mouse()

    canvas: tui.Canvas
    tui.canvas_resize(&canvas, term.size())

    game := chess.Default

    loop: for true {
        defer free_all(context.temp_allocator)

        // Handle events for this iteration.
        term.process_input()

        // ...
        tui.canvas_blit(canvas)

        // ...
        tui.canvas_clear(canvas)

        // ...
        draw_chess_board(canvas, game)

        for do #partial switch ev in term.get_event() or_break {
        case term.Size_Event:
            tui.canvas_resize(&canvas, ev.size)
        case term.Mouse_Event:
            if ev.button != .Left do continue
            if ev.pressed {
                x_offset := (canvas.size.x - VISUAL_BOARD_WIDTH) / 2
                y_offset := (canvas.size.y - VISUAL_BOARD_HEIGHT) / 2
                xi, yi := (ev.position.x - x_offset) / 4, (ev.position.y - y_offset) / 2
                if xi >= 0 && xi < 8 && yi >= 0 && yi < 8 {
                    game.selected = cast(chess.Position)(xi + (yi * 8))
                }
            }
        // TODO
        case term.Key_Event:
            if ev.control == .Sig_Quit || ev.control == .EOF || ev.key == .Escape || ev.str == "q" {
                break loop // Ctrl+\, Ctrl+D, Escape, or "q"
            }
        // TODO
        }

        time.sleep(time.Millisecond)
    }
}

draw_chess_board :: proc(canvas: tui.Canvas, game: chess.Game) {

    // Box drawing palette
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

    x_offset := (canvas.size.x - VISUAL_BOARD_WIDTH) / 2
    y_offset := (canvas.size.y - VISUAL_BOARD_HEIGHT) / 2

    if game.current_side {
        tui.canvas_write(canvas, {x_offset + 1, y_offset - 1}, "White", .Cyan)
    } else {
        tui.canvas_write(canvas, {x_offset + 1, y_offset - 1}, "Black", .Magenta)
    }

    for yi in 0 ..< 8 {
        y := y_offset + (yi * 2)
        for xi in 0 ..< 8 {
            x := x_offset + (xi * 4)

            // Get the piece at this position.
            i := cast(chess.Position)((yi * 8) + xi)
            piece := chess.get_piece(game, i)

            // Top edge of the cell.
            if yi == 0 {
                tui.canvas_set(canvas, {x + 0, y}, xi == 0 ? BR : LBR)
            } else {
                tui.canvas_set(canvas, {x + 0, y}, xi == 0 ? RTB : LRTB)
            }
            tui.canvas_set(canvas, {x + 1, y}, H)
            tui.canvas_set(canvas, {x + 2, y}, H)
            tui.canvas_set(canvas, {x + 3, y}, H)

            // Body of the cell (left edge, middle, right edge)
            tui.canvas_set(canvas, {x + 0, y + 1}, V)
            tui.canvas_set(canvas, {x + 1, y + 1}, ' ')
            {
                set_cell_color(canvas, {x + 2, y + 1}, piece, i == game.selected)
                tui.canvas_set(canvas, {x + 2, y + 1}, get_piece_rune(piece))
            }
            tui.canvas_set(canvas, {x + 3, y + 1}, ' ')
        }
        // Right edge of the board.
        tui.canvas_set(canvas, {x_offset + 32, y + 0}, yi == 0 ? LB : LTB)
        tui.canvas_set(canvas, {x_offset + 32, y + 1}, V)
    }
    // Bottom edge of the board.
    for xi in 0 ..< 8 {
        x := x_offset + (xi * 4)
        tui.canvas_set(canvas, {x + 0, y_offset + 16}, xi == 0 ? TR : LRT)
        tui.canvas_set(canvas, {x + 1, y_offset + 16}, H)
        tui.canvas_set(canvas, {x + 2, y_offset + 16}, H)
        tui.canvas_set(canvas, {x + 3, y_offset + 16}, H)
    }
    // Bottom right corner.
    tui.canvas_set(canvas, {x_offset + 32, y_offset + 16}, TL)

    set_cell_color :: proc(canvas: tui.Canvas, position: [2]int, piece: chess.Piece, highlight: bool) {

        if highlight {

            if chess.is_white(piece) {
                tui.canvas_set_bg_color(canvas, position, .Cyan)
            } else if chess.is_black(piece) {
                tui.canvas_set_bg_color(canvas, position, .Magenta)
            } else {
                tui.canvas_set_bg_color(canvas, position, .White)
            }

            tui.canvas_set_fg_color(canvas, position, .Black)

        } else {

            tui.canvas_set_bg_color(canvas, position, .Default)

            if chess.is_white(piece) {
                tui.canvas_set_fg_color(canvas, position, .Cyan)
            } else if chess.is_black(piece) {
                tui.canvas_set_fg_color(canvas, position, .Magenta)
            } else {
                tui.canvas_set_fg_color(canvas, position, .White)
            }
        }
    }

    get_piece_rune :: proc(piece: chess.Piece) -> rune {
        #partial switch piece {
        case .BRook, .WRook:
            return 'R'
        case .BKnight, .WKnight:
            return 'H' // horse...?
        case .BBishop, .WBishop:
            return 'B'
        case .BQueen, .WQueen:
            return 'Q'
        case .BKing, .WKing:
            return 'K'
        case .BPawn, .WPawn:
            return 'P'
        case:
            return ' '
        }
    }
}

VISUAL_BOARD_WIDTH :: 8 * 4
VISUAL_BOARD_HEIGHT :: 8 * 2
