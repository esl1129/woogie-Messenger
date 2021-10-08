//
//  DatabaseManager.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/03.
//

import Foundation
import FirebaseDatabase
import MessageKit

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

extension DatabaseManager{
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value){ snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}
// MARK: - Account Management
extension DatabaseManager{
    /// Exists User
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
            completion(true)
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
                    completion(true)
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
                    completion(true)
                })
            }
        })
    }
    
    /// Get All Users in Firebase (for Conversation in NewConversationsViewController)
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
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
                  return
              }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User not Found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            default: break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ]
            ]
            let recipient_newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ]
            ]
            
            /// Update recipient Conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                    
                }else{
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            /// Update Current User Conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // Conversation array exists for current user
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    
                })
            }else{
                // conversation array does not exists
                userNode["conversations"] = [newConversationData]
                
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    /// Finish Creating Conversation
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
        default:
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name,
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding convo: \(conversationID)")
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else{
                          return nil
                      }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
            
        })
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            /*
             let collectionMessage: [String:Any] = [
             "id": firstMessage.messageId,
             "type": firstMessage.kind.messageKindString,
             "content": message,
             "date": dateString,
             "sender_email": currentUserEmail,
             "is_read": false,
             "name": name,33
             ]
             */
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let is_read = dictionary["is_read"] as? Bool,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else{
                    return nil
                }
                var kind: MessageKind?
                if type == "photo"{
                    guard let imageUrl = URL(string: content), let placeHolder = UIImage(systemName: "eye.slash") else{
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeHolder, size: CGSize(width: 200, height: 200))
                    kind = .photo(media)
                }else if type == "video"{
                    guard let imageUrl = URL(string: content), let placeHolder = UIImage(named: "video_placeholder") else{
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeHolder, size: CGSize(width: 200, height: 200))
                    kind = .video(media)
                }else{
                    kind = .text(content)
                }
                guard let finalKind = kind else{
                    return nil
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            })
            completion(.success(messages))
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String,otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        // add new message to messages
        // update sender latest message
        // update sender recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
            default:
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name,
            ]
            
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages){ error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String:Any]] else {
                        completion(false)
                        return
                    }
                    let updateValue: [String: Any] = [
                        "date":dateString,
                        "is_read": false,
                        "message": message
                    ]
                    var targetConversation: [String: Any]?
                    var position = 0
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updateValue
                    guard let finalCoversation = targetConversation else {
                        return
                    }
                    currentUserConversations[position] = finalCoversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue( currentUserConversations, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String:Any]] else {
                                completion(false)
                                return
                            }
                            let updateValue: [String: Any] = [
                                "date":dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var targetConversation: [String: Any]?
                            var position = 0
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updateValue
                            guard let finalCoversation = targetConversation else {
                                return
                            }
                            otherUserConversations[position] = finalCoversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue( otherUserConversations, withCompletionBlock: { error, _ in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                                                
                                completion(true)

                            })
                        })
                    })
                })
            }
        })
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        print("Deleting conversation with id: \(conversationId)")
        // Get all conversations for current user
        // delete Conversation in collection with target id
        // reset Conversations for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value){ snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId{
                        print("Found Conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations,withCompletionBlock: { error, _ in
                    guard error == nil else{
                        completion(false)
                        print("Failed to write new conversation array")
                        return
                    }
                    print("Deleted conversation")
                    completion(true)
                })
            }
        }
    }
}

