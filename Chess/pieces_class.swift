//
//  pieces_class.swift
//  Chess
//

import UIKit

// en_passant keeps track of previous move
var en_passant = Bool()
// just_moved_2 keeps track of new move
var just_moved_2 = Bool()
var en_passant_coor = (0, 0)

// to keep track for castling
var kings_moved = [false, false]
// white left, white right, black left, black right
var rooks_moved = [false, false, false, false]

// keep track of moves to check repetition
var move = [[[41, 21, 31, 51, 61, 31, 21, 41],
             [11, 11, 11, 11, 11, 11, 11, 11],
             [0, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0],
             [0, 0, 0, 0, 0, 0, 0, 0],
             [10, 10, 10, 10, 10, 10, 10, 10],
             [40, 20, 30, 50, 60, 30, 20, 40]]: 1]


class piece {
    var color = Int()
    var pieces = [[Int]]()
    var original: (Int, Int) = (0, 0)
    var new: (Int, Int) = (0, 0)
    var type = Int()
    

    // 0 = false
    // 1 = true
    // 2 = game won
    // 3 = game tied (stalemate or repetition)
    // 4 = promote (true)
    
    func can_move() -> (Int, [[Int]]) {
        var outcome = (false, pieces)
        
        if type == 1 {
            // pawn
            outcome = pawn(original_coordinates: original, new_coordinates: new, board_pieces: pieces, testing_check: false)
            
        } else if type == 2 {
            // knight
            outcome = knight(original_coordinates: original, new_coordinates: new, board_pieces: pieces)
            
        } else if type == 3 {
            // bishop
            outcome = bishop(original_coordinates: original, new_coordinates: new, board_pieces: pieces)
//            print(outcome.0)
//            print(original, new)
//            for i in 0...7 {
//                print(outcome.1[i])
//            }
            
            
        } else if type == 4 {
            // rook
            outcome = rook(original_coordinates: original, new_coordinates: new, board_pieces: pieces)
            
        } else if type == 5 {
            // queen
            outcome = queen(original_coordinates: original, new_coordinates: new, board_pieces: pieces)
            
        } else if type == 6 {
            // king
            outcome = king(original_coordinates: original, new_coordinates: new, board_pieces: pieces)
            
        }
        
        if outcome.0 == false {
            return (0, outcome.1)
        }
        
        if in_check_mate(board_state: outcome.1, player: 1 - color) == true {
            return (2, outcome.1)
        }
        
        
        if in_check(board_state: outcome.1, player: color) == true {
            // makes a move that leaves them in check
            return (0, pieces)
        }
        
        // for promotion
        if promoted == true {
            return (4, outcome.1)
        }
        
        // check if the other player was left in stalemate (if so stop game)
        if in_stale_mate(board_state: outcome.1, player: 1 - color) == true {
            return (3, outcome.1)
        }
        
        
        // move was valid! so if moved
        if just_moved_2 == true {
            en_passant = true
            just_moved_2 = false
        } else {
            en_passant = false
        }
        
        
        // check if rooks moved
        if outcome.1[0][0] == 0 {
            rooks_moved[2] = true
        } else if outcome.1[0][7] == 0 {
            rooks_moved[3] = true
        } else if outcome.1[7][0] == 0 {
            rooks_moved[0] = true
        } else if outcome.1[7][7] == 0 {
            rooks_moved[1] = true
        }
        
        // check if king moved
        if color == 0 && outcome.1[7][4] == 0 {
            kings_moved[0] = true
        } else if outcome.1[0][4] == 0 {
            kings_moved[1] = true
        }
        
        
        if repetition(board_pieces: outcome.1) == true {
            return (3, outcome.1)
        }

        // valid move!
        return (1, outcome.1)
    }

    // checks whether player (color) is in check
    func in_check(board_state: [[Int]], player: Int) -> Bool {
        let king_positions = get_king_positions(board: board_state, player: player)
        
        // go through each piece of other player and see whether their spot to kings spot is true (then in check)
        for i in 0...7 {
            for j in 0...7 {
                if board_state[i][j] > 0 && board_state[i][j] % 10 != player {
                    let type_piece = Int(board_state[i][j] / 10)
                    var outcome_move = (false, board_state)
                    var piece = 0
                    
                    if type_piece == 1 {
                        piece = 1
                        outcome_move = pawn(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state, testing_check: true)
                    } else if type_piece == 2 {
                        piece = 2
                        outcome_move = knight(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state)
                    } else if type_piece == 3 {
                        piece = 3
                        outcome_move = bishop(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state)
                    } else if type_piece == 4 {
                        piece = 4
                        outcome_move = rook(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state)
                    } else if type_piece == 5 {
                        piece = 5
                        outcome_move = queen(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state)
                    } else if type_piece == 6 {
                        piece = 6
                        outcome_move = king(original_coordinates: (i, j), new_coordinates: king_positions, board_pieces: board_state)
                    }
                    
                    if outcome_move.0 == true {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // check whether new board checkmates other player 
    func in_check_mate(board_state: [[Int]], player: Int) -> Bool {
        if in_check(board_state: board_state, player: player) == false {
            return false
        }
        
        // check all possible moves, if a move leaves person not in check then false
        for row in 0...7 {
            for col in 0...7 {
                if board_state[row][col] != 0 && board_state[row][col] % 10 == player {
                    if test_moves_in_check(original_piece: (row, col), board_state: board_state, player: player) == false {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func test_moves_in_check(original_piece: (Int, Int), board_state: [[Int]], player: Int) -> Bool {
        let type_piece = Int(board_state[original_piece.0][original_piece.1] / 10)
        
        for i in 0...7 {
            for j in 0...7 {
                if !(i == original_piece.0 && j == original_piece.1) {
                    if board_state[i][j] == 0 || board_state[i][j] % 10 != player {
                        var outcome_move = (false, board_state)
                        
                        if type_piece == 1 {
                            outcome_move = pawn(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state, testing_check: true)
                        } else if type_piece == 2 {
                            outcome_move = knight(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state)
                        } else if type_piece == 3 {
                            outcome_move = bishop(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state)
                        } else if type_piece == 4 {
                            outcome_move = rook(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state)
                        } else if type_piece == 5 {
                            outcome_move = queen(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state)
                        } else if type_piece == 6 {
                            outcome_move = king(original_coordinates: original_piece, new_coordinates: (i, j), board_pieces: board_state)
                        }
                        
                        if outcome_move.0 == true {
                            if in_check(board_state: outcome_move.1, player: player) == false {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    // find the king on onte board and return its position
    func get_king_positions(board: [[Int]], player: Int) -> (Int, Int) {
        var king_positions: (Int, Int) = (0, 0)
        
        for i in 0...7 {
            for j in 0...7 {
                if board[i][j] % 10 == player && Int(board[i][j] / 10) == 6 {
                    king_positions = (i, j)
                    return king_positions
                }
            }
        }
        
        return king_positions
    }
    
    // checks whether the player is in stale mate position (called after move has just been made)
    func in_stale_mate(board_state: [[Int]], player: Int) -> Bool {
        if in_check(board_state: board_state, player: player) == true {
            return false
        }

        // get positions of the king
        let king_positions = get_king_positions(board: board_state, player: player)

        // make sure only pieces on board are king and stuck pawn pieces
        for i in 0...7 {
            for j in 0...7 {
                if board_state[i][j] % 10 == player && board_state[i][j] > 0 {
                    if Int(board_state[i][j] / 10) == 1 {
                        var pawn_ahead_row = i - 1
                        if color == 1 {
                            pawn_ahead_row = i + 1
                        }

                        if board_state[pawn_ahead_row][j] == 0 {
                            return false
                        }

                        // check whether pawn could capture another piece
                        if j != 0 {
                            if board_state[pawn_ahead_row][j - 1] != 0 {
                                return false
                            }
                        }

                        if j != 7 {
                            if board_state[pawn_ahead_row][j + 1] != 0 {
                                return false
                            }
                        }
                    } else if Int(board_state[i][j] / 10) != 6 {
                        return false
                    }
                }
            }
        }

        let moved_king_positions = [(king_positions.0 - 1, king_positions.1),
                                    (king_positions.0 + 1, king_positions.1),
                                    (king_positions.0 - 1, king_positions.1 - 1),
                                    (king_positions.0 - 1, king_positions.1 + 1),
                                    (king_positions.0 + 1, king_positions.1 - 1),
                                    (king_positions.0 + 1, king_positions.1 + 1),
                                    (king_positions.0, king_positions.1 - 1),
                                    (king_positions.0, king_positions.1 + 1)]


        // check all moves for king if not in check return false
        for i in 0...7 {
            if check_move_stale_mate(original: king_positions, new_pieces: moved_king_positions[i], color_piece: player, board: board_state) == false {
                return false
            }
        }

        return true
    }

    // similar to king() but takes in input the pieces making it easier to check stale mate
    // checks whether new move is in NOT in check mate
    func check_move_stale_mate(original: (Int, Int), new_pieces: (Int, Int), color_piece: Int, board: [[Int]]) -> Bool {
        if new_pieces.0 == -1 || new_pieces.1 == -1 {
            return true
        }

        var new_board = board
        new_board[new_pieces.0][new_pieces.1] = new_board[original.0][original.1]
        new_board[original.0][original.1] = 0

        if in_check(board_state: new_board, player: color_piece) == true {
            return true
        }

        return false
    }
    
    
    // checks repetition (if so draw)
    func repetition(board_pieces: [[Int]]) -> Bool {
        if move[board_pieces] != nil {
            move[board_pieces] = move[board_pieces]! + 1
            if move[board_pieces] == 3 {
                return true
            }
        } else  {
            move[board_pieces] = 1
        }
        
        return false
    }
    
    // the following functions are to see whether each piece can move to a new spot
    
    func pawn(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]], testing_check: Bool) -> (Bool, [[Int]]) {
        var new_board = board_pieces
        
        // make sure moved row
        if new_coordinates.0 == original_coordinates.0 {
            return (false, board_pieces)
        }
        
        // check if move greater than 3 pieces in column or 2 in row
        if abs(new_coordinates.1 - original_coordinates.1) > 1 || abs(new_coordinates.0 - original_coordinates.0) > 2 {
            return (false, board_pieces)
        }
    
        
        let color = board_pieces[original_coordinates.0][original_coordinates.1] % 10
        
        // check whether pawn moved forward and not backward
        if new_coordinates.0 < original_coordinates.0 && color == 1 {
            return (false, board_pieces)
        } else if new_coordinates.0 > original_coordinates.0 && color == 0 {
            return (false, board_pieces)
        }
        
        
        // check if in same column
        if original_coordinates.1 == new_coordinates.1 {
            // check whether new spot has a tile in it
            if board_pieces[new_coordinates.0][new_coordinates.1] != 0 {
                return (false, board_pieces)
            }
            
            // if in starting spot can move forward 2 if not only 1
            if abs(original_coordinates.0 - new_coordinates.0) == 2 {
                
                // check whether spot ahead has tile
                var middle_coor = new_coordinates
                if color == 0 {
                    middle_coor.0 += 1
                } else {
                    middle_coor.0 -= 1
                }

                if board_pieces[middle_coor.0][middle_coor.1] != 0 {
                    return (false, board_pieces)
                }
                
                var starting_row = 6
                if color == 1 {
                    starting_row = 1
                }
                
                if original_coordinates.0 != starting_row {
                    return (false, board_pieces)
                }
                
                // keep track for en passant
                just_moved_2 = true
                en_passant_coor = new_coordinates
            }
        } else {
            // capturing! (en passant or normally)
            
            // can't move forward 2 and 1 to the side
            if abs(new_coordinates.0 - original_coordinates.0) == 2 {
                return (false, board_pieces)
            }
            
            // can't move to empty spot unless en passant
            if board_pieces[new_coordinates.0][new_coordinates.1] == 0 {
                if en_passant == false {
                    return (false, board_pieces)
                }
                
                if new_coordinates.1 != en_passant_coor.1 {
                    return (false, board_pieces)
                }
                
                if color == 0 {
                    if new_coordinates.0 == (en_passant_coor.0 - 1) {
                        new_board[en_passant_coor.0][en_passant_coor.1] = 0
                    } else {
                        return (false, board_pieces)
                    }
                } else {
                    if new_coordinates.0 == (en_passant_coor.0 + 1) {
                        new_board[en_passant_coor.0][en_passant_coor.1] = 0
                    } else {
                        return (false, board_pieces)
                    }
                }
                
            }
            
            // check whether new spot has piece of same color
            if board_pieces[new_coordinates.0][new_coordinates.1] != 0 && board_pieces[new_coordinates.0][new_coordinates.1] % 10 == color {
                return (false, board_pieces)
            }
            
        }
        
        // moves w/ 2 or moves only 1 forward
        new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
        new_board[original_coordinates.0][original_coordinates.1] = 0
        
        
        // check if pawn in last row and change to queen if so
        var last_row = 0
        if color == 1 {
            last_row = 7
        }
        
        if new_coordinates.0 == last_row && testing_check == false {
            new_board[new_coordinates.0][new_coordinates.1] = 1 * 10 + color
            if in_check(board_state: new_board, player: color) {
                return (false, board_pieces)
            }
            promoted = true
        }
        
        return (true, new_board)
    }
    
    
    
    func rook(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]]) -> (Bool, [[Int]]) {
        var new_board = board_pieces
        
        // rook can move left, right, up, down (same for each color)
        // need to check whether a piece is in the way
        
        if (original_coordinates.1 == new_coordinates.1) {
            // same column
            var smaller_row = original_coordinates.0
            var bigger_row = new_coordinates.0
            if bigger_row < smaller_row {
                smaller_row = new_coordinates.0
                bigger_row = original_coordinates.0
            }
            
            // to only check pieces in middle (not starting piece or end piece)
            if bigger_row - smaller_row > 1 {
                // check if piece in way
                for i in (smaller_row + 1)...(bigger_row - 1) {
                    if board_pieces[i][original_coordinates.1] != 0 {
                        return (false, board_pieces)
                    }
                }
            }
            
        } else if (original_coordinates.0 == new_coordinates.0) {
            // same row
            var smaller_col = original_coordinates.1
            var bigger_col = new_coordinates.1
            if bigger_col < smaller_col {
                smaller_col = new_coordinates.1
                bigger_col = original_coordinates.1
            }
            
            if bigger_col - smaller_col > 1 {
                // check if piece in way
                for i in (smaller_col + 1)...(bigger_col - 1) {
                    if board_pieces[original_coordinates.0][i] != 0 {
                        return (false, board_pieces)
                    }
                }
            }
        } else {
            return (false, board_pieces)
        }
        
        new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
        new_board[original_coordinates.0][original_coordinates.1] = 0
        
        return (true, new_board)
    }
    
    func knight(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]]) -> (Bool, [[Int]]) {
        var new_board = board_pieces

        // two options to move
        if abs(new_coordinates.0 - original_coordinates.0) == 1 {
            // up/down 1, left/right 2
            if abs(new_coordinates.1 - original_coordinates.1) != 2 {
                return (false, board_pieces)
            }
        } else if abs(new_coordinates.0 - original_coordinates.0) == 2 {
            // up/down 2, left/right 1
            if abs(new_coordinates.1 - original_coordinates.1) != 1 {
                return (false, board_pieces)
            }
            
        } else {
            return (false, board_pieces)
        }
        
        new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
        new_board[original_coordinates.0][original_coordinates.1] = 0
        
        return (true, new_board)
    }
    
    func bishop(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]]) -> (Bool, [[Int]]) {
//        print()
//        print()
//
//        for i in 0...7 {
//            print(board_pieces[i])
//        }
//
        var new_board = board_pieces
        
        // make sure change in column is same as change in row then check whether piece is interfering
        if abs(new_coordinates.0 - original_coordinates.0) != abs(new_coordinates.1 - original_coordinates.1) {
            return (false, board_pieces)
        }
        
        if abs(new_coordinates.0 - original_coordinates.0) > 1 {
            var checking_row = original_coordinates.0
            var checking_col = original_coordinates.1
            
            var row_add = 1
            var col_add = 1
            
            if new_coordinates.0 < original_coordinates.0 {
                row_add = -1
            }
            if new_coordinates.1 < original_coordinates.1 {
                col_add = -1
            }
            
            for _ in 2...abs(new_coordinates.0 - original_coordinates.0) {
                checking_row = checking_row + row_add
                checking_col = checking_col + col_add
                
                if board_pieces[checking_row][checking_col] != 0 {
                    return (false, board_pieces)
                }
            }
        }
        
        new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
        new_board[original_coordinates.0][original_coordinates.1] = 0
        
        return (true, new_board)
    }
    
    
    func queen(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]]) -> (Bool, [[Int]]) {
        // can move like a rook or like a bishop so checking if either are true
        let rook_outcome = rook(original_coordinates: original_coordinates, new_coordinates: new_coordinates, board_pieces: board_pieces)
        if rook_outcome.0 == true {
            return rook_outcome
        }
        
        return bishop(original_coordinates: original_coordinates, new_coordinates: new_coordinates, board_pieces: board_pieces)
    }
    
    func king(original_coordinates: (Int, Int), new_coordinates: (Int, Int), board_pieces: [[Int]]) -> (Bool, [[Int]]) {
        var new_board = board_pieces
        
        // make sure change in row and column is less than 2
        if abs(new_coordinates.1 - original_coordinates.1) > 1 {
            
            // check castle
            if kings_moved[color] == false {
                
                // check both sides manually
                if color == 0 {
                    if new_coordinates.0 == 7 && new_coordinates.1 == 6 {
                        if rooks_moved[1] == false {
                            if new_board[7][5] == 0 {
                                new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
                                new_board[7][5] = 40
                                new_board[7][7] = 0
                                new_board[original_coordinates.0][original_coordinates.1] = 0
                                return (true, new_board)
                            }
                        }
                    } else if new_coordinates.0 == 7 && new_coordinates.1 == 2 {
                        if rooks_moved[0] == false {
                            if new_board[7][1] == 0 && new_board[7][3] == 0 {
                                new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
                                new_board[7][3] = 40
                                new_board[7][0] = 0
                                new_board[original_coordinates.0][original_coordinates.1] = 0
                                return (true, new_board)
                            }
                            
                        }
                    }
                } else {
                    if new_coordinates.0 == 0 && new_coordinates.1 == 6 {
                        if rooks_moved[3] == false {
                            if new_board[0][5] == 0 {
                                new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
                                new_board[0][5] = 41
                                new_board[0][7] = 0
                                new_board[original_coordinates.0][original_coordinates.1] = 0
                                return (true, new_board)
                            }
                        }
                    } else if new_coordinates.0 == 0 && new_coordinates.1 == 2 {
                        if rooks_moved[2] == false {
                            if new_board[0][1] == 0 && new_board[0][3] == 0 {
                                new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
                                new_board[0][3] = 41
                                new_board[0][0] = 0
                                new_board[original_coordinates.0][original_coordinates.1] = 0
                                return (true, new_board)
                            }
                        }
                    }
                }
            }
            
            return (false, new_board)
        }
        
        
        if abs(new_coordinates.0 - original_coordinates.0) > 1 {
            return (false, new_board)
        }
        
        new_board[new_coordinates.0][new_coordinates.1] = new_board[original_coordinates.0][original_coordinates.1]
        new_board[original_coordinates.0][original_coordinates.1] = 0
        
        return (true, new_board)
    }
}
