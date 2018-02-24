//
//  String+removingHtmlEntities.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 07.12.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

public extension String {
    var removingHtmlEntities: String? {
        guard let encodedData = self.data(using: .utf8) else {
            return self
        }
        var returnValue = self
        return returnValue
    }
}
