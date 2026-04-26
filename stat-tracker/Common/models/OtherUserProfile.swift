//
//  OtherUserProfile.swift
//  stat-tracker
//

import Foundation

public enum LimitedAccessReason: String, Decodable {
    case `private` = "private"
    case notFriends = "not_friends"
}

/// Response model for GET /api/user/:username.
/// When `visible` is false only `username` and `reason` are populated.
public struct OtherUserProfile: Decodable {
    public let visible: Bool
    public let username: String
    // Full view
    public let id: String?
    public let name: String?
    public let profileVisibility: ProfileVisibility?
    public let matches: [Game]?
    public let leagues: [League]?
    public let friends: [LightUser]?
    // Limited view
    public let reason: LimitedAccessReason?
}
