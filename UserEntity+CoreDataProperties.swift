//
//  UserEntity+CoreDataProperties.swift
//
//
//  Created by Roni Koskinen on 11.7.2025.
//
//

import CoreData
import Foundation

public extension UserEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var profileVisibility: ProfileVisibility?
    @NSManaged var username: String?
    @NSManaged var email: String?
    @NSManaged var friends: [LightUser]?
    @NSManaged var friendRequests: [LightUser]?
    @NSManaged var leagues: [League]?
    @NSManaged var matches: [Game]?
}
