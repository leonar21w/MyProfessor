//
//  ProfessorsFetcher.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//
import Foundation
import SwiftSoup

@MainActor
class ProfessorsFetcher: HttpUtil, ObservableObject {

	let winterTerm2025 = ["term_code": "W2025", "term_text": "Winter 2025"]
	let summerTerm2024 = ["term_code": "M2024", "term_text": "Summer 2024"]
	
	
	func emptyInstance() -> [Professor] {
		return [
			Professor(
				name: "",
				allSchedules: ["": [""]],
				numRatings: 0,
				difficulty: 0.0,
				overallRating: 0.0,
				wouldTakeAgain: 0.0
			)
		]
	}

	
	func getTerms() async throws -> [[String: String]] {
		var termsFetched = try await getTermsInternal()
		
		if !termsFetched.contains(where: { $0 == winterTerm2025 }) {
			termsFetched.insert(winterTerm2025, at: 0)
			termsFetched.removeAll { $0["term_code"] == summerTerm2024["term_code"] }
		}
		
		
		return termsFetched
	}
	
	func getTermsInternal() async throws -> [[String: String]] {
		
		let url = "https://www.deanza.edu/schedule/"
		
		do {
			let soup = try await getSoup(url: url)
			
			let sections = try soup.select("fieldset")
			guard !sections.isEmpty else {
				print("No sections found.")
				return []
			}
			
			let buttons = try sections[0].select("button")
			var terms: [[String: String]] = []
			
			for button in buttons {
				if button.hasClass("btn-term") {
					let termCode = try button.attr("value")
					let termText = try button.text()
					
					terms.append([
						"term_code": termCode,
						"term_text": termText
					])
				}
			}
			return terms
		} catch {
			print("Error while fetching terms: \(error)")
			return []
		}
	}
	
	func getProfessorData(departmentCode: String, courseCode: String, termCode: String) async throws -> [Professor] {
			let url = "https://www.deanza.edu/schedule/listings.html?dept=\(departmentCode)&t=\(termCode)"
			do {
				let soup = try await getSoup(url: url)
				let result = try soup.select("table.table.table-schedule.table-hover.mix-container")

				guard !result.isEmpty else { return emptyInstance() }

				let rows = try result[0].select("tr")
				return buildProfessorTable(rows: rows, fullCourseCode: "\(departmentCode) \(courseCode)")
			} catch {
				print("Error fetching or processing data: \(error)")
				return emptyInstance()
			}
		}
	
	
	private func buildProfessorTable(rows: Elements, fullCourseCode: String) -> [Professor] {
		var professorTable: [String: Professor] = [:]

		for row in rows.array() {
			do {
				let columns = try row.select("td")
				guard columns.size() > 7, try columns[1].text() == fullCourseCode else { continue }

				let professorName = try columns[7].text()
				let classCode = try columns[0].text()
				let schedules = buildSchedules(rows: rows, startRowIndex: rows.array().firstIndex(of: row) ?? 0)

				if var professor = professorTable[professorName] {
					professor.allSchedules[classCode] = schedules
					professorTable[professorName] = professor
				} else {
					let newProfessor = Professor(
						name: convertName(professorName),
						allSchedules: [classCode: schedules],
						numRatings: 0,
						difficulty: 0.0,
						overallRating: 0.0,
						wouldTakeAgain: 0.0
					)
					professorTable[professorName] = newProfessor
				}
			} catch {
				print("Error processing row: \(error)")
			}
		}

		return Array(professorTable.values)
	}


	
	

	private func buildSchedule(columns: [Element], daysCol: Int, hoursCol: Int, locationCol: Int) -> String? {
		
		do {
			let daysInWeek = try getDays(columns[daysCol].text())
			let hours = try columns[hoursCol].text()
			if hours.contains("TBA") {
				return nil
			} else {
				let location = try columns[locationCol].text()
				let schedule = "\(daysInWeek) - \(hours)/\(location)"
				return schedule
			}
		} catch {
			print("error")
		}
		return nil
	}
	
	func buildSchedules(rows: Elements, startRowIndex: Int) -> [String] {
		var schedules: [String] = []
		
		do {
			let columns = try rows[startRowIndex].select("td")
			var schedule = buildSchedule(columns: columns.array(), daysCol: 5, hoursCol: 6, locationCol: 8)
			schedules.append(formatSchedule(schedule))
			
			var nextRow = startRowIndex + 1
			while nextRow < rows.size() {
				let colsForNextRow = try? rows[nextRow].select("td")
				if (colsForNextRow ?? Elements()).size() < 7 {
					schedule = buildSchedule(columns: (colsForNextRow ?? Elements()).array(), daysCol: 1, hoursCol: 2, locationCol: 4) ?? ""
					if schedule != "" {
						schedules.append(schedule ?? "")
					}
					nextRow += 1
				}
				else {
					break
				}
			}
		}
		catch {
			print("error happened in build schedules")
		}
		return schedules
	}
	
	private func getDays(_ input: String) -> String {
		return input.replacingOccurrences(of: "·", with: "")
	}
	
	func formatSchedule(_ schedule: String?) -> String {
		return schedule ?? "No schedule/ONLINE"
	}
}

struct Professor {
	var name: String
	var allSchedules: [String: [String]] // classCode: [schedules]
	var numRatings: Int
	var difficulty: Double
	var overallRating: Double
	var wouldTakeAgain: Double
}

