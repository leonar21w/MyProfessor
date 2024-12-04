//
//  ResultsView.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//

import SwiftUI

struct ResultsView: View {

	@State var showLoading: Bool = true
	
	//parameters
	@State var departmentCode: String
	@State var courseCode: String
	@State var termCode: String
	
	@State var quarterYearForUI: String
	
	@StateObject var dataVM = DataTunnelVM()
	@StateObject var getProfessors = ProfessorsFetcher()
	@State var professorData: [Professor] = []
	
	
	var body: some View {
		ZStack{
			VStack{
				HStack {
					MyProfessorLogo()
						.padding()
					classDetails
						.padding()
				}
				
				if !showLoading {
					ListProfessors
				} else {
					ProgressView()
				}
				
				Spacer()
				
			}
		}.onAppear {
			Task {
				try await callProfessorData()
			}
		}
	}
	
	fileprivate func callProfessorData() async throws {
		do {
			let fetchedData = try await getProfessors.getProfessorData(
				departmentCode: departmentCode,
				courseCode: courseCode,
				termCode: termCode
			)
			
			await MainActor.run {
				professorData = fetchedData
				showLoading.toggle()
			}
			
			try await dataVM.searchProfessorAndGetRatings(
				professors: fetchedData,
				departmentCode: departmentCode,
				courseCode: courseCode,
				termCode: termCode
			)
		} catch {
			print("Error occurred: \(error)")
		}
	}
	
	private var ListProfessors: some View {
		ScrollView {
			VStack(alignment: .leading) {
				
				if dataVM.professorData.isEmpty {
					Text("We couldn't find a course using that code, double check your search.")
						.font(.headline)
						.foregroundStyle(Color.red.opacity(0.9))
						.fontWeight(.bold)
				}
				else {
					ForEach(dataVM.professorData, id: \.name) { professor in
						VStack(alignment: .leading, spacing: 2) {
							professorHeader(professor: professor)
							professorRatings(professor: professor)
							professorSchedules(professor: professor)
						}
						.padding(.bottom)
					}.padding()
				}
			}
		}
	}

	private func professorHeader(professor: Professor) -> some View {
		HStack {
			Text(professor.name)
				.font(.system(size: 20))
				.fontWeight(.semibold)
				.foregroundStyle(Color.black)
			Text("\(professor.numRatings) reviews")
				.font(.footnote)
				.fontWeight(.light)
				.foregroundStyle(Color.gray)
			Spacer()
		}
	}
	
	private func professorRatings(professor: Professor) -> some View {
		HStack {
			HStack {
				Circle()
					.foregroundStyle(Color.customGreen)
					.frame(width: 16, height: 16)
				Text("Difficulty: \(professor.difficulty, specifier: "%.1f")")
					.font(.footnote)
					.fontWeight(.medium)
			}
			
			HStack {
				Circle()
					.foregroundStyle(Color(red: 1, green: 0.74, blue: 0.35))
					.frame(width: 16, height: 16)
				Text("Rating: \(professor.overallRating, specifier: "%.1f")")
					.font(.footnote)
					.fontWeight(.medium)
			}
			
			HStack {
				Circle()
					.foregroundStyle(Color(red: 0.85, green: 0.38, blue: 0.38))
					.frame(width: 16, height: 16)
				Text("Recommend: \(professor.wouldTakeAgain, specifier: "%.0f")%")
					.font(.footnote)
					.fontWeight(.medium)
			}
		}
		.background(RoundedRectangle(cornerRadius: 25).fill(Color.gray.opacity(0.2)))
	}

	private func professorSchedules(professor: Professor) -> some View {
		VStack(alignment: .leading) {
			ForEach(professor.allSchedules.map { ($0.key, $0.value) }, id: \.0) { classCode, schedules in
				VStack(alignment: .leading, spacing: 5) {
					Text(classCode)
						.font(.subheadline)
						.foregroundStyle(Color.black)
						.fontWeight(.semibold)
						.padding(10)
						.background(
							RoundedRectangle(cornerRadius: 18)
								.fill(Color.gray.opacity(0.2))
						)
					
					ForEach(schedules.indices, id: \.self) { index in
						HStack{
							let splitSchedule = schedules[index].split(separator: "/")
							Text(splitSchedule.first ?? "Cant Find Date and Time")
								.font(.subheadline)
								.foregroundStyle(Color.black)
							Text(splitSchedule.last ?? "Cant get location")
								.font(.subheadline)
								.foregroundStyle(Color.black)
								.padding(10)
								   .background(
									   RoundedRectangle(cornerRadius: 25)
										   .stroke(Color.black, lineWidth: 1)
								   )
						}
						.padding(10)
						.background(RoundedRectangle(cornerRadius: 25).fill(Color.gray.opacity(0.2)))
						
					}
				}
				.padding(.vertical, 5)
			}
		}
	}

	


	
	

	
	
	private var classDetails: some View {
		VStack(spacing: 0) {
			Text("\(departmentCode) \(courseCode)")
				.foregroundStyle(Color.black)
			Text(quarterYearForUI)
				.foregroundStyle(Color.gray.opacity(0.5))
		}
		.font(.system(size: 32, weight: .semibold, design: .default))
	}
}

#Preview {
	ResultsView(departmentCode: "MATH", courseCode: "1C", termCode: "W2025", quarterYearForUI: "")
}
