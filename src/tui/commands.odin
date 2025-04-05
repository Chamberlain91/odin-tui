package oak_tui

DEV_BUILD :: #config(DEV_BUILD, ODIN_DEBUG)

@(require) import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

@(private)
_buffer: [8192]byte

write :: proc(text: string) {
	os.write(os.stdout, transmute([]byte)text)
}

// Reads input from stdin but trims line break characters (\r\n).
@(require_results)
read_input :: proc() -> string {
	return strings.trim_right(read(), "\r\n")
}

// Reads input from stdin. 
@(require_results)
read :: proc() -> string {
	slice.zero(_buffer[:])
	n, err := os.read(os.stdin, _buffer[:])
	if err == nil do return string(_buffer[:n])
	else do return {}
}

enable_alt_buffer :: proc() {
	ENABLE_ALT_BUFFER :: "\e[?1049h"
	write(ENABLE_ALT_BUFFER)
}

disable_alt_buffer :: proc() {
	DISABLE_ALT_BUFFER :: "\e[?1049l"
	write(DISABLE_ALT_BUFFER)
}

erase_screen :: proc() {
	ERASE_SCREEN :: "\e[2J"
	write(ERASE_SCREEN)
}

cursor_move_home :: proc() {
	CURSOR_MOVE_HOME :: "\e[H"
	write(CURSOR_MOVE_HOME)
}
