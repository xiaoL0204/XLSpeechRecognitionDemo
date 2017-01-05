//
//  XLSpeechRecognitionConstant.swift
//  XLSpeechRecognitionDemo
//
//  Created by xiaoL on 17/1/4.
//  Copyright © 2017年 xiaolin. All rights reserved.
//

import UIKit

let S_SCREEN_WIDTH = UIScreen.main.bounds.size.width
let S_SCREEN_HEIGHT = UIScreen.main.bounds.size.height



extension UIView{
    public var s_x:CGFloat{
        get{
            return self.frame.origin.x
        }
        set{
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    public var s_y:CGFloat{
        get{
            return self.frame.origin.y
        }
        set{
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    public var s_width:CGFloat{
        get{
            return self.frame.size.width
        }
        set{
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    public var s_height:CGFloat{
        get{
            return self.frame.size.height
        }
        set{
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    public var s_centerX:CGFloat{
        get{
            return self.center.x
        }
        set{
            var center:CGPoint = self.center
            center.x = newValue
            self.center = center
        }
    }
    public var s_centerY:CGFloat{
        get{
            return self.center.y
        }
        set{
            var center:CGPoint = self.center
            center.y = newValue
            self.center = center
        }
    }
    
}
