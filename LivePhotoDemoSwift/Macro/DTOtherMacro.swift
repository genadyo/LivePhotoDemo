//
//  DTOtherMacro.swift
//  动图
//
//  Created by 孙国林 on 2017/11/8.
//  Copyright © 2017年 欧巴刚弄死他. All rights reserved.
//

import Foundation

extension DateFormatter {
    class func private_new() -> DateFormatter {
        let fmt = DateFormatter.init()
        fmt.dateFormat = "HH:mm:ss.sss"
        return fmt
    }
}

private let formatter = DateFormatter.private_new()

/// 自定义日志输出
public func DTLog(_ format: String, _ args: CVarArg..., file : String = #file, line : UInt = #line) {
    #if DEBUG
        DTLog("\(Thread.isMainThread ? "[Main]" : "[Child]")\((file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: ""))[\(line)][\(formatter.string(from: Date.init()))]:\(String.init(format: format, arguments: args))")
    #endif
}
