//
//  GameModel.swift
//  GameCenterMultiplayer
//
//  Created by Pedro Contine on 29/06/20.
//

import Foundation
import UIKit

struct GameModel: Codable {
    var players: [Player] = []
    var time: Int = 60
    var messages: String = ""
    
}

extension GameModel {
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    static func decode(data: Data) -> GameModel? {
        return try? JSONDecoder().decode(GameModel.self, from: data)
    }
}
