//
//  Reusables.swift
//  MyProfessor3
//
//  Created by Leonard on 11/17/24.
//


import SwiftUI

struct MyProfessorLogo: View {
	var body: some View {
		ZStack{
			HStack{
				myProfessorBox
			}
		}
	}
	
	private var myProfessorBox: some View {
		ZStack(alignment: .center) {
			myProfessorBoxContent
			coloredDots
				.offset(x: 25)
		}
	}
	
	private var coloredDots: some View {
		HStack{
			Circle()
				.foregroundStyle(Color.customGreen)
				.frame(width: 16, height: 16)
			Circle()
				.foregroundStyle(Color(red: 1, green: 0.74, blue: 0.35))
				.frame(width: 16, height: 16)
			Circle()
				.foregroundStyle(Color(red: 0.85, green: 0.38, blue: 0.38))
				.frame(width: 16, height: 16)
			
			
		}
	}
	
	private var myProfessorBoxContent: some View {
		Text("My\nProfessor")
			.font(.system(size: 32, weight: .semibold, design: .default))
			.foregroundColor(.black)
			.padding(5)
	}

}

extension Color {
	static let customGreen = Color(UIColor(red: 146/255, green: 199/255, blue: 114/255, alpha: 1.0))
}


#Preview {
	MyProfessorLogo()
}
