//
//  UserProfileRepositoryProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol UserProfileRepositoryProtocol {
    func save(profile: UserProfile) async throws
    func load() async throws -> UserProfile?
    func delete() async throws
}
