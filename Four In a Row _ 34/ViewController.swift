//
//  ViewController.swift
//  Four In a Row _ 34
//
//  Created by KhoiLe on 08/08/2021.
//

import UIKit
import GameplayKit

class ViewController: UIViewController {
    @IBOutlet var columnButtons: [UIButton]!
    
    var placeChips = [[UIView]]()
    var board: Board!
    
    //minimize losses and maximize gains
    var strategist: GKMinmaxStrategist!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for _ in 0 ..< Board.width {
            placeChips.append([UIView]())
        }
        
        strategist = GKMinmaxStrategist()
        strategist.maxLookAheadDepth = 7
        //if two ways return one result, just send me the first one
        strategist.randomSource = nil
        //random the returned result
        //strategist.randomSource = GKARC4RandomSource()
        
        resetBoard()
    }

    @IBAction func makeMove(_ sender: UIButton) {
        let column = sender.tag
        
        if let row = board.nextEmptySlot(in: column) {
            board.add(chip: .red, in: column)
            addChip(inColumn: column, row: row, color: .red)
            continueGame()
        }
    }
    
    func resetBoard() {
        board = Board()
        strategist.gameModel = board
        
        updateUI()
        
        for i in 0 ..< placeChips.count {
            for chip in placeChips[i] {
                chip.removeFromSuperview()
            }
            
            placeChips[i].removeAll(keepingCapacity: true)
        }
    }
    
    func addChip(inColumn column: Int, row: Int, color: UIColor) {
        let button = columnButtons[column]
        let size = min(button.frame.width, button.frame.height / 6)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        if (placeChips[column].count < row + 1) {
            let newChip = UIView()
            newChip.frame = rect
            newChip.isUserInteractionEnabled = true
            newChip.backgroundColor = color
            newChip.layer.cornerRadius = size / 2
            newChip.center = positionForChip(inColumn: column, row: row)
            newChip.transform = CGAffineTransform(translationX: 0, y: -800)
            view.addSubview(newChip)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                newChip.transform = CGAffineTransform.identity
            })
            
            placeChips[column].append(newChip)
        }
    }
    
    func positionForChip(inColumn column: Int, row: Int) -> CGPoint {
        let button = columnButtons[column]
        let size = min(button.frame.width, button.frame.height / 6)
        
        let xOffset = button.frame.midX
        var yOffset = button.frame.maxY - size / 2
        yOffset -= size * CGFloat(row)
        return CGPoint(x: xOffset, y: yOffset)
    }
    
    func updateUI() {
        title = "\(board.currentPlayer.name)'s turn"
        
        if board.currentPlayer.chip == .black {
            startAIMove()
        }
    }
    
    func continueGame() {
        var gameOverTitle: String? = nil
        
        if board.isWin(for: board.currentPlayer) {
            gameOverTitle = "\(board.currentPlayer.name) wins!"
        } else if board.isFull() {
            gameOverTitle = "Draw!"
        }
        
        if gameOverTitle != nil {
            let arlet = UIAlertController(title: gameOverTitle, message: nil, preferredStyle: .alert)
            let arletAction = UIAlertAction(title: "Play again", style: .default) {
                [unowned self] (action) in
                self.resetBoard()
            }
            
            arlet.addAction(arletAction)
            present(arlet, animated: true)
            
            return
        }
        
        board.currentPlayer = board.currentPlayer.opponent
        updateUI()
    }
    
    func startAIMove() {
        //avoid user hitting the button while AI is thinking
        columnButtons.forEach { $0.isEnabled = false}
        
        //create a spinner present that AI is thinking
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: spinner)
        
        //Dispatch the AI to the background thread
        DispatchQueue.global().async { [unowned self] in
            //get the current time
            let strategistTime = CFAbsoluteTimeGetCurrent()
            //run get column for AI
            guard let column = columnForAIMove() else { return }
            //get the current time again then minus the delay for column strategy
            let delta = CFAbsoluteTimeGetCurrent() - strategistTime
            
            let aiTimeCeiling = 1.0
            let delay = aiTimeCeiling - delta
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.makeAIMove(in: column)
            }
            
        }
    }
    
    func columnForAIMove() -> Int? {
        if let aiMove = strategist.bestMove(for: board.currentPlayer) as? Move {
            return aiMove.column
        }
        
        return nil
    }
    
    func makeAIMove(in column: Int) {
        columnButtons.forEach { $0.isEnabled = true}
        navigationItem.leftBarButtonItem = nil
        
        if let row = board.nextEmptySlot(in: column) {
            board.add(chip: board.currentPlayer.chip, in: column)
            addChip(inColumn: column, row: row, color: board.currentPlayer.color)
            
            continueGame()
        }
    }
}

