//
//  DataTunnel.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//

import Foundation

@MainActor
class DataTunnelVM: ObservableObject {

	@Published var professorData: [Professor] = []
	@Published var ratings = RatingsFetcherModel()
	
	func searchForRatings(professor: String, department: String) async throws -> ProfessorRatings? {
		try await withCheckedThrowingContinuation { continuation in
			ratings.getRatings(professorName: professor, departmentCode: department) { result in
				switch result {
				case .success(let ratings):
					continuation.resume(returning: ratings)
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
		}
	}

	func searchProfessorAndGetRatings(professors: [Professor], departmentCode: String, courseCode: String, termCode: String) async throws {
		professorData = professors
		
		await withTaskGroup(of: (Int, ProfessorRatings?).self) { group in
			for index in professorData.indices {
				let professor = professorData[index]
				
				group.addTask {
					let ratings = try? await self.searchForRatings(professor: professor.name, department: departmentCode)
					return (index, ratings) // Return index and fetched ratings
				}
			}
			
			for await (index, ratings) in group {
				if let ratings = ratings {
					self.professorData[index].difficulty = ratings.difficulty
					self.professorData[index].overallRating = Double(ratings.overallRating) ?? 0.0
					self.professorData[index].wouldTakeAgain = Double(ratings.wouldTakeAgain)
					self.professorData[index].numRatings = ratings.reviewNum
				}
			}
		}
	}
}
