//
//  ActivityRepositoryProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol ActivityRepositoryProtocol {
    func getActivities() async -> [Activity]
}
