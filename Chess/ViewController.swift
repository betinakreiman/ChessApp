//
//  ViewController.swift
//  Chess
//

import UIKit

var promoted = false
var promote_coordinates = (0, 0)

class ViewController: UIViewController {

    @IBOutlet weak var board: UIImageView!
    
    // board keeping track of pieces
    var board_state = [[Int]]()

    // define that each tile is a button
    var buttons = [[UIButton]]()
    
    var isPlaying = true
    
    // 0 = white, 1 = black
    var playerTurn = 0
    
    var button_selected = false
    var button = Int()
    
    let labels = ["White Player's Turn", "Black Player's Turn", "Draw", "White Player Won!", "Black Player Won!", "Pick a Piece"]
    
    let pieces_dictionary = [0: "",
                             10: "Pieces/pawn_white.jpg",
                             20: "Pieces/knight_white.jpg",
                             30: "Pieces/bishop_white.jpg",
                             40: "Pieces/rook_white.jpg",
                             50: "Pieces/queen_white.jpg",
                             60: "Pieces/king_white.jpg",
                             11: "Pieces/pawn_black.jpg",
                             21: "Pieces/knight_black.jpg",
                             31: "Pieces/bishop_black.jpg",
                             41: "Pieces/rook_black.jpg",
                             51: "Pieces/queen_black.jpg",
                             61: "Pieces/king_black.jpg"]

    var label_turn = UILabel()

    var tile_size = CGFloat(0)

    var center_screen = (CGFloat(0), CGFloat(0))

    // knight, bishop, rook, queen
    var promotion_buttons = [UIButton](repeating: UIButton(), count: 4)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // getting screen dimensions
        let screen = UIScreen.main.bounds
        let screenWidth = screen.size.width
        
        center_screen = (self.view.center.x, self.view.center.y)
        
        // set board size and location
        board.frame.size.width = screenWidth * 0.95
        board.frame.size.height = screenWidth * 0.95
        board.center.x = center_screen.0
        board.center.y = center_screen.1
        
        // size of one tile (aka piece)
        tile_size = board.frame.size.width / 8.0
        
        // make reset button
        let reset = UIButton(frame: CGRect(x: 0, y: 0, width: tile_size * 2, height: tile_size))
        reset.center.x = self.view.center.x
        reset.center.y = board.center.y - board.frame.size.height * 3/4
        reset.setTitle("Reset", for: .normal)
        reset.setTitleColor(UIColor(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        reset.addTarget(self, action: #selector(reset_game(_:)),
                                  for: .touchUpInside)
        reset.layer.cornerRadius = 10
        reset.backgroundColor = UIColor(red: 224/255, green: 226/255, blue: 228/255, alpha: 1.0)
        self.view.addSubview(reset)
        
        // make label for whose players turn it is
        label_turn = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth, height: tile_size))
        label_turn.center.x = self.view.center.x
        label_turn.center.y = board.center.y - board.frame.size.height * 5/8
        label_turn.textAlignment = .center
        label_turn.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        self.view.addSubview(label_turn)
        
        
        // for promotion
        let y_coordinate = center_screen.1 + center_screen.1 * 0.95 * 3 / 4
        let x_coordinates = [self.view.center.x - tile_size * 1.5, self.view.center.x - tile_size * 0.5, self.view.center.x + tile_size * 0.5, self.view.center.x + tile_size * 1.5]
        for i in 0...3 {
            promotion_buttons[i] = UIButton(frame: CGRect(x: 0, y: 0, width: tile_size, height: tile_size))
            promotion_buttons[i].center.x = x_coordinates[i]
            promotion_buttons[i].center.y = y_coordinate
            promotion_buttons[i].tag = 2 + i
            promotion_buttons[i].isHidden = true
            promotion_buttons[i].addTarget(self, action: #selector(promote_button(_:)),
                                           for: .touchUpInside)
            self.view.addSubview(promotion_buttons[i])
        }
        
        
        start_game()
        
        
        
    }
    
    @IBAction func reset_game(_ sender: UIButton) {
        move = [[[41, 21, 31, 51, 61, 31, 21, 41],
                 [11, 11, 11, 11, 11, 11, 11, 11],
                 [0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0],
                 [10, 10, 10, 10, 10, 10, 10, 10],
                 [40, 20, 30, 50, 60, 30, 20, 40]]: 1]
        
        en_passant = Bool()

        just_moved_2 = Bool()
        en_passant_coor = (0, 0)

        kings_moved = [false, false]

        rooks_moved = [false, false, false, false]
        
        promoted = false
        
        for i in 0...3 {
            promotion_buttons[i].isHidden = true
        }
        
        start_game()
    }
    
    
    func start_game() {
        // initilize board
        initilize_board()

        // make the buttons
        make_buttons()

        // show board
        show_board()

        playerTurn = 0
        
        label_turn.text = labels[0]
        
        isPlaying = true
    }

    
    func initilize_board() {
        // set board with pieces in starting spots
        board_state = [[41, 21, 31, 51, 61, 31, 21, 41],
                       [11, 11, 11, 11, 11, 11, 11, 11],
                       [0, 0, 0, 0, 0, 0, 0, 0],
                       [0, 0, 0, 0, 0, 0, 0, 0],
                       [0, 0, 0, 0, 0, 0, 0, 0],
                       [0, 0, 0, 0, 0, 0, 0, 0],
                       [10, 10, 10, 10, 10, 10, 10, 10],
                       [40, 20, 30, 50, 60, 30, 20, 40]]
    
    }
    
    
    func make_buttons() {
        // get x, y coordinate of first tile (then will add to these coordinates accordingly)
        let x_coor = board.center.x - (board.frame.size.width / 2.0)
        let y_coor = board.center.y - (board.frame.size.height / 2.0)
        
        // makes the 64 buttons (1 for each tile)
        for row in 0...7 {
            var new_row = [UIButton]()
            
            for col in 0...7 {
                let newButton = UIButton(frame: CGRect(x: CGFloat(x_coor) + CGFloat(col) * tile_size,
                                                       y: CGFloat(y_coor) + CGFloat(row) * tile_size,
                                                       width: tile_size,
                                                       height: tile_size))
                
                // to keep track of which button is which
                newButton.tag = row * 10 + col
                
                self.view.addSubview(newButton)
                
                // when button is pressed, calls function to move pieces
                newButton.addTarget(self, action: #selector(action(_:)),
                                  for: .touchUpInside)
                
                new_row.append(newButton)
            }
            buttons.append(new_row)
        }
    }
    
    
    // given board_state this function makes the pieces visible on the app
    func show_board() {
        for row in 0...7 {
            for col in 0...7 {
                let piece_name = pieces_dictionary[board_state[row][col]]
                buttons[row][col].setImage(UIImage(named: piece_name!), for: .normal)
                self.view.addSubview(buttons[row][col])
            }
        }
    }
    
    
    // given the sender.tag get the row and column
    func coordinates(tag: Int) -> (Int, Int) {
        var x_coor: Int = 0
        let y_coor: Int = tag % 10
        if tag >= 10 {
            x_coor = Int(tag / 10)
        }
        return (x_coor, y_coor)
    }
    
    // when a tile is clicked, move pieces
    @IBAction func action(_ sender: UIButton) {
        if isPlaying == true {
            let coor = coordinates(tag: sender.tag)
            
            if button_selected == false {
                // check whether piece is correct color and is actual piece not blank
                if board_state[coor.0][coor.1] % 10 == playerTurn && board_state[coor.0][coor.1] != 0{
                    // piece is selected to be moved
                    button_selected = true
                    button = sender.tag
                }
                
            } else {
                // new location is selected to move piece to
                if movable(original_spot: button, new_spot: sender.tag) == true {
                    show_board()

                    playerTurn = 1 - playerTurn
                    
                    if isPlaying != false {
                        label_turn.text = labels[playerTurn]
                    }
                    
                    button_selected = false
                }
            }
        }
    }
    
    // sees whether piece can be moved or not
    func movable(original_spot: Int, new_spot: Int) -> Bool {
        // check whether new spot is same spot
        if original_spot == new_spot {
            return false
        }
        
        let original_coor = coordinates(tag: original_spot)
        let new_coor = coordinates(tag: new_spot)
        
        // checks whether new spot has tile of same color
        if board_state[new_coor.0][new_coor.1] != 0 && board_state[original_coor.0][original_coor.1] % 10 == board_state[new_coor.0][new_coor.1] % 10 {
            // make button selected the new piece
            button = new_spot
            return false
        }
        
        let new_piece = piece()
        new_piece.pieces = board_state
        new_piece.color = board_state[original_coor.0][original_coor.1] % 10
        new_piece.original = original_coor
        new_piece.new = new_coor
        new_piece.type = Int(board_state[original_coor.0][original_coor.1] / 10)
    
        let moved = new_piece.can_move()
        board_state = moved.1
        
        if moved.0 == 0 {
            button_selected = false
            return false
        }
        
        if moved.0 == 3 {
            // stale mate or repetition
            isPlaying = false
            label_turn.text = labels[2]
        }
        
        if moved.0 == 2 {
            isPlaying = false
            label_turn.text = labels[3 + playerTurn]
        }
        
        if moved.0 == 4 {
            // promote piece, update board, then return true
            isPlaying = false
            promote_coordinates = new_coor
            promote()
            return false
        }
    
        return true
    }
    
    func promote() {
        label_turn.text = labels[5]
        for i in 0...3 {
            promotion_buttons[i].setImage(UIImage(named: pieces_dictionary[promotion_buttons[i].tag * 10 + playerTurn]!), for: .normal)
            promotion_buttons[i].isHidden = false
        }
    }
    
    
    @IBAction func promote_button(_ sender: UIButton) {
        board_state[promote_coordinates.0][promote_coordinates.1] = sender.tag * 10 + playerTurn
        
        isPlaying = true
        
        show_board()
        
        promoted = false
        
        button_selected = false
        
        playerTurn = 1 - playerTurn
        
        let check_mate = piece()
        if check_mate.in_check_mate(board_state: board_state, player: playerTurn) == true {
            isPlaying = false
            label_turn.text = labels[3 + (1 - playerTurn)]
        }
        
        if isPlaying != false {
            label_turn.text = labels[playerTurn]
        }
        
        for i in 0...3 {
            promotion_buttons[i].isHidden = true
        }
    }
}



/// Sources
///
/// Pieces
/// https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
