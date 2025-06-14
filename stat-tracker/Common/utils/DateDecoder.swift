//
//  DateDecoder.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 14.6.2025.
//

import Foundation

// MARK: - JSONDecoder Date Decoding Extension

extension JSONDecoder.DateDecodingStrategy {
    static var customISO8601: JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = ISO8601DateFormatter.customISO8601.date(from: dateString) {
                return date
            }
            
            let withoutZFormatter = ISO8601DateFormatter()
            withoutZFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
            if let date = withoutZFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString) to Date.")
        }
    }
}

// MARK: - ISO8601DateFormatter Extension

extension ISO8601DateFormatter {
    static let customISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
