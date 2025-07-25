//
//  User.swift
//  SmartLabsNative
//
//  Created by SmartLabs Team
//  Copyright © 2024 SmartLabs. All rights reserved.
//

import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let registration: String
    let email: String
    let cardsNumber: String
    let deviceId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case registration
        case email
        case cardsNumber = "cards_number"
        case deviceId = "device_id"
    }
    
    init(id: Int, name: String, registration: String, email: String, cardsNumber: String, deviceId: Int) {
        self.id = id
        self.name = name
        self.registration = registration
        self.email = email
        self.cardsNumber = cardsNumber
        self.deviceId = deviceId
    }
}

// MARK: - UserManager
class UserManager {
    static let shared = UserManager()
    
    private let userDefaultsKey = "currentUser"
    private let loginStatusKey = "isLoggedIn"
    
    private init() {}
    
    var currentUser: User? {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
                  let user = try? JSONDecoder().decode(User.self, from: data) else {
                return nil
            }
            return user
        }
        set {
            if let user = newValue {
                let data = try? JSONEncoder().encode(user)
                UserDefaults.standard.set(data, forKey: userDefaultsKey)
                UserDefaults.standard.set(true, forKey: loginStatusKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                UserDefaults.standard.set(false, forKey: loginStatusKey)
            }
        }
    }
    
    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: loginStatusKey) && currentUser != nil
    }
    
    func logout() {
        currentUser = nil
    }
}