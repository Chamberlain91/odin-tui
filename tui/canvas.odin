package odin_tui

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
    fg_color: Color,
    bg_color: Color,
}

canvas_create :: proc(size: [2]int) -> Canvas {
    canvas: Canvas = {
        storage = make([]Cell, size.x * size.y),
        size    = size,
    }
    canvas_clear(canvas)
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

canvas_write :: proc(canvas: Canvas, position: [2]int, text: string, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil) {
    fg, fg_ok := fg.(Color)
    bg, bg_ok := bg.(Color)

    position := position
    for ch in text {
        if fg_ok do canvas_set_fg_color(canvas, position, fg)
        if bg_ok do canvas_set_bg_color(canvas, position, bg)
        canvas_set(canvas, position, ch)
        position.x += 1
    }
}

canvas_set_fg_color :: proc(canvas: Canvas, position: [2]int, color: Color) {
    canvas_get_ptr(canvas, position).fg_color = color
}

canvas_set_bg_color :: proc(canvas: Canvas, position: [2]int, color: Color) {
    canvas_get_ptr(canvas, position).bg_color = color
}

// Fill the canvas with ' ' rune, and default colors.
canvas_clear :: proc(canvas: Canvas, rune := ' ', fg := Color.Default, bg := Color.Default) {
    slice.fill(canvas.storage, Cell{rune, fg, bg})
}

// Resizes the canvas, much like realloc.
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

canvas_blit :: proc(canvas: Canvas, offset: [2]int = {0, 0}) {

    process_input()

    save_cursor()
    defer restore_cursor()

    // TODO: Is there a way to query current term color?
    fg_color: Color = cast(Color)0xFF
    bg_color: Color = cast(Color)0xFF
    reset_styles()

    x0 := max(offset.x, 0)
    x1 := min(offset.x + canvas.size.x, _state.size.x)

    y0 := max(offset.y, 0)
    y1 := min(offset.y + canvas.size.y, _state.size.y)

    for y in 0 ..< (y1 - y0) {
        set_cursor_position({x0, y0 + y})
        for x in 0 ..< (x1 - x0) {
            cell := canvas_get_ptr(canvas, {x, y})

            if fg_color != cell.fg_color {
                set_foreground_color(cell.fg_color)
                fg_color = cell.fg_color
            }

            if bg_color != cell.bg_color {
                set_background_color(cell.bg_color)
                bg_color = cell.bg_color
            }

            print(cell.rune)
        }
        move_cursor_next_line()
    }

    print()
}
