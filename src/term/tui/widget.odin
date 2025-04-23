package oak_tui

import term ".."
import "core:slice"

Widget :: struct {
    position: [2]int,
    size:     [2]int,
    variant:  union {
        ^Window,
    },
}

Window :: struct {
    using _: Widget,
    title:   string,
}

Canvas :: struct {
    storage: []Cell,
    size:    [2]int,
}

Cell :: struct {
    rune:     rune,
    fg_color: term.Color,
    bg_color: term.Color,
}

canvas_create :: proc(size: [2]int) -> Canvas {
    canvas: Canvas = {
        storage = make([]Cell, size.x * size.y),
        size    = size,
    }
    return canvas
}

canvas_destroy :: proc(canvas: Canvas) {
    delete(canvas.storage)
}

canvas_get_ptr :: proc(canvas: Canvas, position: [2]int) -> ^Cell {
    return &canvas.storage[position.x + (position.y * canvas.size.x)]
}

canvas_get :: proc(canvas: Canvas, position: [2]int) -> Cell {
    return canvas_get_ptr(canvas, position)^
}

canvas_set :: proc(canvas: Canvas, position: [2]int, rune: rune) {
    canvas_get_ptr(canvas, position).rune = rune
}

canvas_set_fg_color :: proc(canvas: Canvas, position: [2]int, color: term.Color) {
    canvas_get_ptr(canvas, position).fg_color = color
}

canvas_set_bg_color :: proc(canvas: Canvas, position: [2]int, color: term.Color) {
    canvas_get_ptr(canvas, position).bg_color = color
}

// Fill the canvas with ' ' rune, and default colors.
canvas_clear :: proc(canvas: Canvas) {
    slice.fill(canvas.storage, Cell{' ', .Default, .Default})
}

canvas_resize :: proc(canvas: ^Canvas, size: [2]int, blit := true) {

    new_canvas := canvas_create(size)

    if blit {
        for y in 0 ..< min(canvas.size.y, size.y) {
            for x in 0 ..< min(canvas.size.x, size.x) {
                canvas_get_ptr(new_canvas, {x, y})^ = canvas_get(canvas^, {x, y})
            }
        }
    }

    canvas_destroy(canvas^)
    canvas^ = new_canvas
}

canvas_blit :: proc(canvas: Canvas) {

    term.save_cursor()
    defer term.restore_cursor()

    // TODO: Is there a way to query current term color?
    fg_color: term.Color = cast(term.Color)0xFF
    bg_color: term.Color = cast(term.Color)0xFF
    term.reset_styles()

    for y in 0 ..< canvas.size.y {
        term.set_cursor_position({0, y})
        for x in 0 ..< canvas.size.x {
            cell := canvas_get_ptr(canvas, {x, y})

            if fg_color != cell.fg_color {
                term.set_foreground_color(cell.fg_color)
                fg_color = cell.fg_color
            }

            if bg_color != cell.bg_color {
                term.set_background_color(cell.bg_color)
                bg_color = cell.bg_color
            }

            term.print(cell.rune)
        }
        term.move_cursor_next_line()
    }

    term.print()
}
