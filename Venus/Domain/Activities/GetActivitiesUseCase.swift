//
//  GetActivitiesUseCase.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol GetActivitiesUseCaseProtocol {
    func execute() async -> [Activity]
}

class GetActivitiesUseCase: GetActivitiesUseCaseProtocol {
    private let repository: ActivityRepositoryProtocol
    
    init(repository: ActivityRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async -> [Activity] {
        return await repository.getActivities()
    }
}
