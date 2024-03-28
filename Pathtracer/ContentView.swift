//
//  ContentView.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button(action: {
                print("hello")
            }) {
                Image(systemName: "eye.fill")
                    //.resizable()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
