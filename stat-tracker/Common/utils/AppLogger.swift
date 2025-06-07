//
//  AppLogger.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 5.6.2025.
//

import Foundation
import os.log

public struct AppLogger {

    private static let appLifecycleLogger = OSLog(subsystem: "logikki.stat-tracker", category: "AppLifecycle")

    private static let networkLogger = OSLog(subsystem: "logikki.stat-tracker", category: "Network")

    private static let authLogger = OSLog(subsystem: "logikki.stat-tracker", category: "Authentication")

    public static func info(_ message: String, category: String = "General") {
        self.log(message, type: .info, category: category)
    }

    public static func debug(_ message: String, category: String = "General") {
        self.log(message, type: .debug, category: category)
    }

    public static func error(_ message: String, category: String = "General") {
        self.log(message, type: .error, category: category)
    }

    public static func fault(_ message: String, category: String = "General") {
        self.log(message, type: .fault, category: category)
    }

    private static func log(_ message: String, type: OSLogType, category: String) {
        let logger: OSLog

        switch category {
        case "AppLifecycle":
            logger = appLifecycleLogger
        case "Network":
            logger = networkLogger
        case "Authentication":
            logger = authLogger
        default:
            logger = OSLog(subsystem: "com.yourcompany.stat-tracker", category: category)
        }
        
        os_log("%{public}@", log: logger, type: type, message)
    }
}
