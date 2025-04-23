package chess

Position :: distinct u8

Invalid_Position: Position = 0xFF

Piece :: enum u8 {
    None,
    BPawn,
    BRook,
    BKnight,
    BBishop,
    BQueen,
    BKing,
    WPawn,
    WRook,
    WKnight,
    WBishop,
    WQueen,
    WKing,
}

Game :: struct {
    board:        [64]Piece,
    selected:     Position,
    current_side: bool,
}

get_piece :: proc(game: Game, position: Position) -> Piece {
    return game.board[position]
}

is_white :: proc(piece: Piece) -> bool {
    #partial switch piece {
    case .WRook, .WKnight, .WBishop, .WQueen, .WKing, .WPawn:
        return true
    case:
        return false
    }
}

is_black :: proc(piece: Piece) -> bool {
    #partial switch piece {
    case .BRook, .BKnight, .BBishop, .BQueen, .BKing, .BPawn:
        return true
    case:
        return false
    }
}

Move :: struct {
    from: Position,
    to:   Position,
}

Default: Game = {
    board    = _inital_pieces,
    selected = Invalid_Position,
}

@(rodata, private = "file")
_inital_pieces := [64]Piece {
    .BRook,
    .BKnight,
    .BBishop,
    .BQueen,
    .BKing,
    .BBishop,
    .BKnight,
    .BRook,
    .BPawn,
    .BPawn,
    .BPawn,
    .BPawn,
    .BPawn,
    .BPawn,
    .BPawn,
    .BPawn,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .None,
    .WPawn,
    .WPawn,
    .WPawn,
    .WPawn,
    .WPawn,
    .WPawn,
    .WPawn,
    .WPawn,
    .WRook,
    .WKnight,
    .WBishop,
    .WQueen,
    .WKing,
    .WBishop,
    .WKnight,
    .WRook,
}
