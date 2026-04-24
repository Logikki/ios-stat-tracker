//
//  UserEntity+CoreDataProperties.swift
//  
//
//  Created by Roni Koskinen on 11.7.2025.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var profileVisibility: ProfileVisibility?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var friends: [LightUser]?
    @NSManaged public var friendRequests: [LightUser]?
    @NSManaged public var leagues: [League]?
    @NSManaged public var matches: [Game]?

}
