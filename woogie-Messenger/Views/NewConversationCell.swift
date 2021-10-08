//
//  NewConversationCell.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/08.
//

import Foundation
import SDWebImage

class NewConversationCell: UITableViewCell {
    static let identifier = "NewConversationCell"
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        
        return imageView
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        userNameLabel.frame = CGRect(x: userImageView.right+20, y: 10, width: contentView.width-20-userImageView.width, height: contentView.height-20)

    }
    
    public func configure(with model: SearchResult){
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                 print("Failed to get img url : \(error)")
            }
        })
    }
}
