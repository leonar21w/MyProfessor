//
//  RatingsFetcherModel.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.

import Foundation
import SwiftSoup

struct ProfessorRatings {
	var difficulty: Double
	var wouldTakeAgain: Int
	var overallRating: String
	var reviewNum: Int
}

enum RatingsFetcherError: Error {
	case invalidURL
	case dataLoadingFailed
	case htmlParsingFailed
	case noResultsFound

	var localizedDescription: String {
		switch self {
		case .invalidURL:
			return "The URL provided is invalid."
		case .dataLoadingFailed:
			return "Failed to load data from the server."
		case .htmlParsingFailed:
			return "Unable to parse the HTML document."
		case .noResultsFound:
			return "No matching results found for the provided input."
		}
	}
}

class RatingsFetcherModel: ObservableObject {
	
	func getRatings(professorName: String, departmentCode: String, completion: @escaping (Result<ProfessorRatings?, Error>) -> Void) {
		let baseUrl = "https://www.ratemyprofessors.com/search/professors/1967?q=\(professorName)"
		guard let url = URL(string: baseUrl) else {
			completion(.failure(RatingsFetcherError.invalidURL))
			return
		}

		URLSession.shared.dataTask(with: url) { data, response, error in
			if let error = error {
				completion(.failure(error))
				return
			}

			guard let data = data, let html = String(data: data, encoding: .utf8) else {
				completion(.failure(RatingsFetcherError.dataLoadingFailed))
				return
			}

			do {
				let soup = try SwiftSoup.parse(html)
				let teacherCards = try soup.select("a[class^=TeacherCard_]")
				var bestMatch: ProfessorRatings?

				for card in teacherCards {
					let department = try card.select("div[class^=CardSchool__Department]").first()?.text() ?? ""
					let nameFromCard = try card.select("div[class^=CardName__StyledCardName]").first()?.text() ?? ""

					if self.matchDepartment(department: department, departmentCode: departmentCode),
					   self.similarNames(name1: professorName, name2: nameFromCard) {
						if let ratings = self.buildRatings(card: card),
						   ratings.reviewNum > (bestMatch?.reviewNum ?? 0) {
							bestMatch = ratings
						}
					}
				}

				if let match = bestMatch {
					completion(.success(match))
				} else {
					completion(.failure(RatingsFetcherError.noResultsFound))
				}
			} catch {
				completion(.failure(RatingsFetcherError.htmlParsingFailed))
			}
		}.resume()
	}


	func matchDepartment(department: String, departmentCode: String) -> Bool {
		return department.lowercased().contains(departmentCode.lowercased())
	}

	
	func similarNames(name1: String, name2: String) -> Bool {
		let normalized1 = name1.lowercased().replacingOccurrences(of: "-", with: " ")
		let normalized2 = name2.lowercased().replacingOccurrences(of: "-", with: " ")

		let name1Components = normalized1.split(separator: " ")
		let name2Components = normalized2.split(separator: " ")

		
		for part1 in name1Components {
			if name2Components.contains(where: { $0 == part1 }) {
				return true
			}
		}
		return false
	}


	func buildRatings(card: Element) -> ProfessorRatings? {
		do {
			let ratingRow = try card.select("div[class^=CardNumRating_]")
			guard ratingRow.count > 3 else { return nil }

			let reviewNumText = try ratingRow[3].text().replacingOccurrences(of: "ratings", with: "").trimmingCharacters(in: .whitespaces)
			guard let reviewNum = Int(reviewNumText), reviewNum > 0 else { return nil }

			let feedbackRows = try card.select("div[class^=CardFeedback_]")
			var wouldTakeAgain = 0
			var difficulty = 0.0

			for feedback in feedbackRows {
				let text = try feedback.text().lowercased()
				if text.contains("would take again") {
					let value = try feedback.select("div").last()?.text().replacingOccurrences(of: "%", with: "")
					wouldTakeAgain = Int(value ?? "") ?? -1
				} else if text.contains("level of difficulty") {
					let value = try feedback.select("div").last()?.text()
					difficulty = Double(value ?? "") ?? 0.0
				}
			}

			let overallRating = try ratingRow[2].text()
			return ProfessorRatings(difficulty: difficulty, wouldTakeAgain: wouldTakeAgain, overallRating: overallRating, reviewNum: reviewNum)
		} catch {
			return nil
		}
	}
}

