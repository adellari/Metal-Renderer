//
//  ContentView.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import SwiftUI

class SceneDataModel: ObservableObject {
    @Published var cameraView: Double = 0.0
}

struct ContentView: View {
    @StateObject var SceneData =  SceneDataModel()
     var viewController: ViewController?

        init() {
            do {
                guard let device = MTLCreateSystemDefaultDevice() else {
                    fatalError("Metal is not supported on this device")
                }
                viewController = try ViewController(device: device, sceneData: SceneData)
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
                //print("hello")
                viewController?.redraw()
                //print(viewController?.imageView)
            }) {
                Image(systemName: "eye.fill")
                    //.resizable()
            }
            Slider(value: $SceneData.cameraView, in: -90.0 ... 90.0, onEditingChanged: {_ in
                viewController?.SceneData = self.SceneData
            print("changed slider")})
        }
        .ignoresSafeArea()
        .onAppear(perform: {
            
        })
        .padding()
    }
    
    func binding(for value: Double) -> Binding<Double> {
            Binding<Double>(
                get: { SceneData.cameraView },
                set: { newValue in
                    SceneData.cameraView = newValue
                }
            )
        }
}



#Preview {
         //var device = MTLCreateSystemDefaultDevice()!
         //var vc = ViewController(device: device)
          //ContentView(viewController: vc)
        ContentView()
}
