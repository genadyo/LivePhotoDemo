//
//  DTColorMacro.swift
//  动图
//
//  Created by 孙国林 on 2017/11/8.
//  Copyright © 2017年 欧巴刚弄死他. All rights reserved.
//

import UIKit

public func HEXACOLOR(value : UInt, alpha : CGFloat) -> UIColor {
    return UIColor.init(red:   CGFloat((value & 0xff0000) >> 16) / 255.0,
                        green: CGFloat((value & 0xff00) >> 8) / 255.0,
                        blue:  CGFloat(value & 0xff) / 255.0,
                        alpha: alpha)
}

public func HEXCOLOR(value : UInt) -> UIColor {
    return HEXACOLOR(value: value, alpha: 1)
}

public func RGBACOLOR(red : UInt, green : UInt, blue : UInt, alpha : CGFloat) -> UIColor {
    return UIColor.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
}

public func RGBCOLOR(red : UInt, green : UInt, blue : UInt) -> UIColor {
    return RGBACOLOR(red: red, green: green, blue: blue, alpha: 1)
}


