//
//  Constants.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation

public struct Constants {
    struct UserDefaultsKeys {
        static let logDirUrl = "logDirUrl"
        static let currentLogFileNumber = "currentLogFileNumber"
        static let dateOfLastLog = "dateOfLastLog"
        static let numberOfLogFiles = "numOfLogFiles"
    }

    public struct Separators {
        /// The between used file records
        public static let logRecordSeparator = "|>"
    }

    public struct Queues {
        public static let serial = "com.swift.loggerSerial"
        public static let concurrent = "com.swift.loggerConcurrent"
    }
}
