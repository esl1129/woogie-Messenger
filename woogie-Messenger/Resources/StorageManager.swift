//
//  StorageManager.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/05.
//

import Foundation
import FirebaseStorage

// MARK: - Error Enum
public enum StorageErrors: Error{
    case failedToUpload
    case failedToGetDownloadUrl
}

// MARK: - Management
final class StorageManager{
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /*
     /images/wook-gmail-com_profile_picture.png
     */
    
    
    /// Uploads picture to firebase storage and returns completion with url String
    public typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    public func uploadProfilePicture(with data: Data,fileName: String, completion: @escaping UploadPictureCompletion){
        
        storage.child("images/\(fileName)").putData(data,metadata: nil, completion: { metadata, error in
            guard error == nil else{
                // failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("image/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    /// Uploads image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data,fileName: String, completion: @escaping UploadPictureCompletion){
        
        storage.child("message_images/\(fileName)").putData(data,metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else{
                // failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    /// Uploads video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL,fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl,metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else{
                // failed
                print("Failed to upload video file to firebase for video")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}

