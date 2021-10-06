//
//  ChatViewController.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/05.
//

import UIKit
import MessageKit

struct Message: MessageType{
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType{
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Joe Smith")
    override func viewDidLoad() {
        super.viewDidLoad()
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Test 1")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Test 1, Test 2, Test 3")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.row]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}
