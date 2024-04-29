//
//  MaterialMenu.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 4/27/24.
//

//
//  FloatingButton.swift
//  sandbox
//
//  Created by Adellar Irankunda on 12/8/23.
//

import SwiftUI
import simd


struct MaterialProp
{
    var id : Int
    var icon : String
    var name : String
    var red: Double = 0
    var green: Double = 0
    var blue: Double = 0
    var aux1 : Double = 0   //auxilary value eg. smoothness, index of refraction
    var aux2 : Double = 1   //auxilary value
    var expanded = false
}

struct MaterialMenu: View {
    @State private var isExpanded = true
    @Binding public var obj: Sphere
    let buttonsCount = 4 // The total number of secondary buttons
    let radius: CGFloat = 50 // The radius of the circular pattern
    @State var focus = 0
    @State var MaterialOptions : [MaterialProp] = [MaterialProp(id: 0, icon: "moonphase.first.quarter.inverse", name: "Transmission", expanded: true), MaterialProp(id: 1, icon: "moon.circle.fill", name: "Specular"), MaterialProp(id: 2, icon: "moonphase.full.moon", name: "Diffuse"), MaterialProp(id: 3, icon: "microbe.circle.fill", name: "Emission")]
    
    var body: some View {
        VStack {
            ForEach(0..<buttonsCount, id: \.self) { index in
                let _name = MaterialOptions[index].name
                HStack {
                    Button(action: {
                        MaterialOptions[index].expanded.toggle()
                        focus = MaterialOptions[index].expanded ? index : -1
                        if (focus > -1)
                        {
                            loadProperties(var: index)
                        }
                        
                        print("Option \(index)")
                    }) {
                        Image(systemName: MaterialOptions[index].icon)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 45, height: 45)
                            .background(Circle().fill(Material.thin))
                            .clipShape(Circle())
                        
                            .foregroundColor(.gray)
                            .shadow(radius: 2)
                    }
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 7)
                        
                            .fill(Material.ultraThin)
                        //.foregroundColor(.gray)
                        VStack{
                            Text(_name)
                            Divider()
                                .frame(width: 120)
                            
                            Slider(value: $MaterialOptions[index].red, onEditingChanged: { _ in
                                updateProperties(var: index)
                            })
                                .tint(.red)
                               
                            Slider(value: $MaterialOptions[index].green, onEditingChanged: { _ in
                                updateProperties(var: index)
                            })
                                .tint(.green)
                            
                            Slider(value: $MaterialOptions[index].blue, onEditingChanged: { _ in
                                updateProperties(var: index)
                            })
                                .tint(.blue)
                            
                            if (_name == "Specular" || _name ==  "Transmission" || _name == "Emission"){
                                HStack{
                                    Slider(value: $MaterialOptions[index].aux1, onEditingChanged: { _ in
                                        updateProperties(var: index)
                                    })
                                        .tint(.black)
                                    Text( (_name == "Specular" || _name == "Transmission") ? "Smoothness" : "Intensity")
                                        .font(.system(size: 12))
                                        .fontWeight(.light)
                                }
                                if (_name == "Transmission")
                                {
                                    HStack{
                                        Slider(value: $MaterialOptions[index].aux2, in: 0 ... 2, onEditingChanged: { _ in
                                            updateProperties(var: index)
                                        })
                                            .tint(.black)
                                        Text("IOR")
                                            .fontWeight(.ultraLight)
                                    }
                                }
                                
                                
                            }
                            
                            
                        }
                        .animation(.default, value: MaterialOptions[index].expanded)
                        .padding()
                        .font(.headline)
                        
                    }
                    
                    .frame(width: MaterialOptions[index].expanded ? UIScreen.main.bounds.width * 0.7 : 0, height: MaterialOptions[index].expanded ? UIScreen.main.bounds.height * 0.2 : radius)
                    //.offset(x: 0, y: )
                    .opacity(MaterialOptions[index].expanded ? 1 : 0)
                    .scaleEffect( (focus == index || focus == -1) ? 1 : 0.01)
                    .animation(.default, value: MaterialOptions[index].expanded)
                    
                    
                    
                }
                //.offset(x: 0,
                //        y: isExpanded ? CGFloat(index + 1) * radius : 0)
                .opacity((focus == index || focus == -1) ? 1 : 0.01)
                .animation(.default, value: MaterialOptions[index].expanded)
            }
            
        }
        .animation(.default, value: isExpanded)
    }
    
    func loadProperties(var id : Int){
        var Sph : Sphere = obj
        var prop : float3 = float3()
        var aux : float2 = float2()
        
        switch(id)
        {
        case 0:
            prop = Sph.refractiveColor
            aux = float2(Sph.internalSmoothness, Sph.IOR)
            break
            
        case 1:
            prop = Sph.specular
            aux = float2(Sph.smoothness, Sph.IOR)
            break
            
        case 2:
            prop = Sph.albedo
            break
            
        default:
            prop = Sph.emission
            aux = float2()  //we don't need to set this for the time being
            
        }
        
        MaterialOptions[id].red = Double(prop.x)
        MaterialOptions[id].green = Double(prop.y)
        MaterialOptions[id].blue = Double(prop.z)
        
        MaterialOptions[id].aux1 = Double(aux.x)
        MaterialOptions[id].aux2 = Double(aux.y)
    }
    
    func updateProperties(var id : Int){
        var prop : float3 = float3(Float(MaterialOptions[id].red), Float(MaterialOptions[id].green), Float(MaterialOptions[id].blue))
        var aux : float2 = float2(Float(MaterialOptions[id].aux1), Float(MaterialOptions[id].aux1))
        
        
        switch(id)
        {
        case 0:
            obj.refractiveColor = prop
            obj.internalSmoothness = aux.x
            obj.IOR = aux.y
            break
            
        case 1:
            obj.specular = prop
            obj.smoothness = aux.x
            break
            
        case 2:
            obj.albedo = prop
            break
            
        default:
            obj.emission = prop
            break
            
        }
        
        print("values supposedly updated")
    }
    
    func toggle() {
        isExpanded.toggle()
    }
}



#Preview {
    //var sphere : Sphere = Sphere()
    //MaterialMenu(obj: $sphere)
    Text("hi")
}

