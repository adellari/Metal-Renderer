//
//  ContentView.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var SceneData : SceneDataModel
    @State var isSkyboxSelect : Bool = false
    @State var skyboxImage : String?
    //var OIDNHandle = OIDNHandler()
    var viewController: ViewController?
    @State private var Col = Color.blue.opacity(0.5)
    
    init() {
        do {
            let sceneModel = SceneDataModel()
            self._SceneData = StateObject(wrappedValue: sceneModel)
            loadMeshData()
            guard let device = MTLCreateSystemDefaultDevice() else {
                fatalError("Metal is not supported on this device")
            }
            viewController = try ViewController(device: device, sceneData: SceneData)
        } catch {
            fatalError("Failed to create ViewController: \(error)")
        }
    }
    
    var skyboxPreview : Image {
        skyboxImage != nil ? Image(uiImage: UIImage(named: skyboxImage!)!) : Image(systemName: "mountain.2.circle")
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
                
                
                 //DOF Section
                
                Slider(value: $SceneData.focalLength, in: 1 ... 100, onEditingChanged: {_ in
                    viewController?.SceneData.sampleCount = -1
                    print(SceneData.focalLength)
                })
                .offset(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * -0.5)
                .scaleEffect(0.7)
                /*
                Slider(value: $SceneData.aperture, in: 0.1 ... 5, onEditingChanged: {_ in
                    viewController?.SceneData.sampleCount = -1
                    print(SceneData.aperture)
                })
                .offset(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * -0.5)
                .scaleEffect(0.5)
                */
                
                VStack {
                    MaterialMenu(obj: $SceneData.Spheres[0])
                    
                    Button(action: {
                        isSkyboxSelect = true
                    }) {
                        skyboxPreview
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                    }
                    .sheet(isPresented: $isSkyboxSelect)
                    {
                        CustomImagePicker(selectedImage: $skyboxImage)
                    }
                    .onChange(of: skyboxImage) { newImgName in
                        
                        print("changed skybox")
                        SceneData.skybox = newImgName!
                        viewController?.reloadTextures = true
                        SceneData.sampleCount = -1
                    }
                }
                .offset( x: UIScreen.main.bounds.height * 0.1, y: UIScreen.main.bounds.width * -0.45)
            }
            .frame(alignment: .leading)
            
            
            Button(action: {
                //print("hello")
                //print(SceneData.BVH!.BVHTree)
                self.SceneData.Denoiser.initDevice()
                var counter = 0
                let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
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
    
    func loadMeshData() {
        if let meshLoader = SceneData.Meshloader {
            meshLoader.loadModel("gear") { success in
                
                if success{
                    SceneData.Triangles = meshLoader.loadTriangles()
                    loadBVH()
                }
                else {
                    print("failed to load the mesh!")
                }
                
            }
        }
    }
    
    func loadBVH() {
        SceneData.BVH = BVHBuilder(_tris: &SceneData.Triangles)
        //SceneData.BVH!.BuildBVH(tris: &SceneData.Triangles)
        
        if let BVH = SceneData.BVH  {
                BVH.BuildBVH(tris: &SceneData.Triangles)
                print("successfully created BVH tree")
            
        }
        
    }
    
    
}



#Preview {
    ContentView()
}
