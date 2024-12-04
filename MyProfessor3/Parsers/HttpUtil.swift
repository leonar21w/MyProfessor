//
//  HttpUtil.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//

import Foundation
import SwiftSoup


//Inherit this class and make the children
//the children will be observable & interact with views directly
class HttpUtil {
	
	func getSoup(url: String) async throws -> Document {
		
		guard let url = URL(string: url) else {
			throw URLError(.badURL)
		}
		
		let (data, response) = try await URLSession.shared.data(from: url)
		if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
			throw URLError(.badServerResponse)
		}
		
		guard let htmlpage = String(data: data, encoding: .utf8) else {
			throw URLError(.cannotDecodeContentData)
		}
		
		return try SwiftSoup.parse(htmlpage)
		//Html for any page
	}
	
	func convertName(_ name: String) -> String {
		let parts = name.split(separator: ",")
		guard parts.count == 2 else {
			return name
		}
		
		let lastName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
		let firstName = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
		
		let formattedName = "\(firstName.capitalized) \(lastName.capitalized)"
		return formattedName
	}

	
	
}

