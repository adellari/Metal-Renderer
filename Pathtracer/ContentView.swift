//
//  ContentView.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import SwiftUI

class SceneDataModel: ObservableObject {
    @Published var cameraView: Double = 0.0
    @Published var sampleCount : Int = 0
    @Published var cameraOffset: (Float, Float, Float) = (0.0, 0.0, 1.0)
    @Published var focalLength: Double = 4
    @Published var aperture: Double = 1
    @Published var Spheres : [Sphere] = [Sphere(), Sphere()] {
        didSet{
            //print("hi, there was a change to the spheres")
            sampleCount = -2
            //print(Spheres)
        }
    }
}

struct ContentView: View {
    @StateObject var SceneData =  SceneDataModel()
    var OIDNHandle = OIDNHandler()
    var viewController: ViewController?
    @State private var Col = Color.blue.opacity(0.5)
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
            
            ZStack(alignment: .bottomLeading) {
                
                
                viewController?.imageView.asSwiftUIView()
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                //print(value.translation)
                                SceneData.cameraOffset = (Float(value.translation.width), Float(value.translation.height), SceneData.cameraOffset.2)
                                SceneData.sampleCount = -1
                                viewController?.SceneData = self.SceneData
                                //print("image view is being dragged")
                            }
                    )
                    .gesture(
                        MagnifyGesture()
                            .onChanged{ value in
                                SceneData.cameraOffset = (SceneData.cameraOffset.0, SceneData.cameraOffset.1, Float(value.magnification))
                                SceneData.sampleCount = -1
                                
                                //print(value.magnification)
                            }
                    )
                
                Slider(value: $SceneData.focalLength, in: 1 ... 100, onEditingChanged: {_ in
                    viewController?.SceneData.sampleCount = -1
                    print(SceneData.focalLength)
                })
                .offset(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * -0.5)
                .scaleEffect(0.7)
                
                Slider(value: $SceneData.aperture, in: 0.1 ... 5, onEditingChanged: {_ in
                    viewController?.SceneData.sampleCount = -1
                    print(SceneData.aperture)
                })
                .offset(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * -0.5)
                .scaleEffect(0.5)
                
                MaterialMenu(obj: $SceneData.Spheres[0])
                    
                    .offset( x: UIScreen.main.bounds.height * 0.1, y: UIScreen.main.bounds.width * -0.45)
                    //.padding([.leading, .bottom])
                    //.frame(alignment: .trailing)
            }
            .frame(alignment: .leading)
            
            
            Button(action: {
                print("hello")
                OIDNHandle.initializeDevice()
                //OIDNHandle.setImages()
                var counter = 0
                let timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in 
                    viewController?.redraw()
                    SceneData.sampleCount += 1
                    viewController?.SceneData = self.SceneData
                    
                    counter += 1
                }
                Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                    viewController?.redraw()
                    SceneData.sampleCount += 1
                    viewController?.SceneData = self.SceneData
                    
                    counter += 1
                    if self.SceneData.sampleCount >= 800000 {
                        timer.invalidate()
                    }
                }
                
                
                
                
                
                //print(viewController?.imageView)
            }) {
                Image(systemName: "eye.fill")
                    //.resizable()
            }
            /*
            Slider(value: $SceneData.cameraView, in: -90.0 ... 90.0, onEditingChanged: {_ in
                viewController?.SceneData = self.SceneData
            print("changed slider")})
            
            */
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
