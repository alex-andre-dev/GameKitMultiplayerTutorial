//
//  GameViewController.swift
//  GameCenterMultiplayer
//
//  Created by Pedro Contine on 29/06/20.
//

import UIKit
import GameKit
import SnapKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var sendMessageBtn: UIButton!
    @IBOutlet weak var player1: UIImageView!
    @IBOutlet weak var progressPlayer1: UIProgressView!
    @IBOutlet weak var player2: UIImageView!
    @IBOutlet weak var progressPlayer2: UIProgressView!
    @IBOutlet weak var buttonAttack: UIButton!
    @IBOutlet weak var labelTime: UILabel!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var txtField: UITextField!
    
    var match: GKMatch?
    private var timer: Timer!
    
    private var gameModel: GameModel! {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gameModel = GameModel()
        match?.delegate = self
        
        scrollView.contentOffset = CGPoint(x: 0, y: 1)
        
        //Mirror player 2 images
        player2.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        savePlayers()
        createContraints()
        
        if getLocalPlayerType() == .one, timer == nil {
            self.initTimer()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    private func initTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            let player = self.getLocalPlayerType()
            if player == .one, self.gameModel.time >= 1 {
                print(self.gameModel.time)
                self.gameModel.time -= 1
                self.sendData()
            }
        })
    }
    
    private func savePlayers() {
        guard let player2Name = match?.players.first?.displayName else { return }
        let player1 = Player(displayName: GKLocalPlayer.local.displayName)
        let player2 = Player(displayName: player2Name)
        
        gameModel.players = [player1, player2]
        
        gameModel.players.sort { (player1, player2) -> Bool in
            player1.displayName < player2.displayName
        }
        
        sendData()
    }
    
    private func getLocalPlayerType() -> PlayerType {
        if gameModel.players.first?.displayName == GKLocalPlayer.local.displayName {
            return .one
        } else {
            return .two
        }
    }
    
    private func updateUI() {
        guard gameModel.players.count >= 2 else { return }
        
        labelTime.text = "\(gameModel.time)"
        player1.image = gameModel.players[0].status.image(player: .one)
        progressPlayer1.progress = gameModel.players[0].life / 100.0
        player2.image = gameModel.players[1].status.image(player: .two)
        progressPlayer2.progress = gameModel.players[1].life / 100.0
        label.text = gameModel.messages + "\n"
        
        let player = getLocalPlayerType()
        buttonAttack.backgroundColor = player.color()
    }
    
    @IBAction func buttonAttackPressed() {
        let localPlayer = getLocalPlayerType()
        
        //Change status to attacking
        gameModel.players[localPlayer.index()].status = .attack
        gameModel.players[localPlayer.enemyIndex()].status = .hit
        gameModel.players[localPlayer.enemyIndex()].life -= 10

        sendData()
        
        //Reset status after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.gameModel.players[localPlayer.index()].status = .idle
            self.gameModel.players[localPlayer.enemyIndex()].status = .idle
            self.sendData()
        }
    }
    @IBAction func SendMessage(_ sender: Any) {
        if var text = txtField.text {
            text = GKLocalPlayer.local.displayName + ":" + text
            gameModel.messages = gameModel.messages + text + "\n"
        }
        txtField.text = nil
        sendData()
    }
    
    private func sendData() {
        guard let match = match else { return }
        
        do {
            guard let data = gameModel.encode() else { return }
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Send data failed")
        }
    }
    
    func createContraints() {
        scrollView.snp.makeConstraints{ make in
            make.top.equalTo(buttonAttack.snp.bottom).offset(50)
            make.bottom.equalToSuperview().inset(50)
            make.width.equalToSuperview().offset(100)
        }
        label.snp.makeConstraints{ make in
            make.edges.equalTo(scrollView)
        }
        txtField.snp.makeConstraints{ make in
            make.top.equalTo(scrollView.snp.bottom).offset(10)
            make.width.equalTo(335)
            make.height.equalTo(34)
            make.left.equalTo(label.snp.left)

        }
        sendMessageBtn.snp.makeConstraints{ make in
            make.top.equalTo(txtField.snp.top)
            make.left.equalTo(txtField.snp.right)
            make.width.equalTo(34)
            make.height.equalTo(34)

        }
    }
    @objc func keyboardWillShow(sender: NSNotification) {
         self.view.frame.origin.y = -370
    }

    @objc func keyboardWillHide(sender: NSNotification) {
         self.view.frame.origin.y = 0
   }
}

extension GameViewController: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let model = GameModel.decode(data: data) else { return }
        gameModel = model
    }
}
