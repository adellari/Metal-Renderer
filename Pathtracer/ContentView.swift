//
//  ContentView.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import SwiftUI


struct ContentView: View {
    var viewController: ViewController?

        init() {
            do {
                guard let device = MTLCreateSystemDefaultDevice() else {
                    fatalError("Metal is not supported on this device")
                }
                viewController = try ViewController(device: device)
            } catch {
                fatalError("Failed to create ViewController: \(error)")
            }
        }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            viewController?.imageView.asSwiftUIView()
            
            Button(action: {
                print("hello")
                print(viewController?.imageView)
            }) {
                Image(systemName: "eye.fill")
                    //.resizable()
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: {
            viewController?.redraw()
        })
        .padding()
    }
}

#Preview {
         //var device = MTLCreateSystemDefaultDevice()!
         //var vc = ViewController(device: device)
          //ContentView(viewController: vc)
        ContentView()
}
