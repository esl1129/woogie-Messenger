//
//  DatabaseManager.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/03.
//

import Foundation
import FirebaseDatabase

struct ChatAppUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String{
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String{
        // wook-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}

public enum DatabaseErrors: Error{
    case failedToFetch
}

final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    static func safeEmail(emailAddress: String) -> String{
        return emailAddress.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
    }
}

// MARK: - Account Management
extension DatabaseManager{
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName,
        ], withCompletionBlock:{ error, _ in
            guard error == nil else{
                print("Failed to write to database")
                completion(false)
                return
            }
        })
        
        self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            if var usersCollection = snapshot.value as? [[String:String]]{
                // append to user dictionary
                let newElement = [
                    "name":user.firstName + " " + user.lastName,
                    "email":user.safeEmail
                ]
                usersCollection.append(newElement)
                self.database.child("users").setValue(usersCollection,withCompletionBlock: { error, _ in
                    guard error == nil else{
                        print("Failed to write to database")
                        completion(false)
                        return
                    }
                })
            }else{
                // create that array
                let newCollection: [[String: String]] = [[
                        "name":user.firstName + " " + user.lastName,
                        "email":user.safeEmail
                    ]]
                self.database.child("users").setValue(newCollection,withCompletionBlock: { error, _ in
                    guard error == nil else{
                        print("Failed to write to database")
                        completion(false)
                        return
                    }
                })
            }
        })
    }
    
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}

// MARK: - Sending messages / Conversations
extension DatabaseManager{
    /// Creates a new conversatin with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String,Error>) -> Void){
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
    }
}

