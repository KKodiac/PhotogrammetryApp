//
//  String+Extensions.swift
//  HeadModelMaker
//
//  Created by TUKorea on 2022/11/28.
//

import Foundation

extension String {
    func deletePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
