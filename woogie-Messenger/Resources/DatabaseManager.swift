//
//  DatabaseManager.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/03.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
}

// MARK: - Account Management
extension DatabaseManager{
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser){
        database.child("users").child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName,
        ])
    }
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        database.child("users").child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
}

struct ChatAppUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String{
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
//    let profilePictureURL: String
}
