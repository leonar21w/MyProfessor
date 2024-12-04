//
//  searchBar.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//

import SwiftUI

struct SearchBar: View {
	@Binding var userText: String
	@Binding var toggleField: Bool
	var placeholder: String = "Ex. Math 1C"
	
	
	@FocusState private var isFocused: Bool // Focus state for the TextField
	
	var body: some View {
		HStack {
			TextField(placeholder, text: $userText)
				.disableAutocorrection(true)
				.focused($isFocused)
				.onChange(of: userText) { oldValue, newValue in
					if newValue.count > 10 {
						userText = String(newValue.prefix(10)) // Limit to 10 characters
					} //Give feature for indication later
				}
				.onSubmit {
					toggleField.toggle()
					isFocused = false 
				}
			
			Image(systemName: "magnifyingglass")
				.foregroundStyle(Color.primary)
				.onTapGesture {
					toggleField.toggle()
					isFocused = false
				}
		}
		.font(.headline)
		.padding(.horizontal)
		.padding(.vertical, 15)
		.background(
			RoundedRectangle(cornerRadius: 25)
				.fill(Color.gray.opacity(0.5))
				.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
		)
		.accessibilityLabel("Search Bar")
		.accessibilityHint("Enter the course code to search for professors")
	}
}

#Preview {
	SearchBar(userText: .constant(""), toggleField: .constant(false))
}

