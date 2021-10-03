//
//  extensions.swift
//  woogie-Messenger
//
//  Created by 임재욱 on 2021/10/03.
//

import Foundation
import UIKit

extension UIView {
    public var width: CGFloat{
        return self.frame.size.width
    }
    public var height: CGFloat{
        return self.frame.size.height
    }
    public var top: CGFloat{
        return self.frame.origin.y
    }
    public var bottom: CGFloat{
        return self.frame.size.height +  self.frame.origin.y
    }
    
    public var left: CGFloat{
        return self.frame.origin.x
    }
    public var right: CGFloat{
        return self.frame.size.width +  self.frame.origin.x
    }
}
