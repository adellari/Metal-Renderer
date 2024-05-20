//
//  SkyboxPicker.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/19/24.
//

import SwiftUI

struct AssetImage: Identifiable {
    let id = UUID()
    let name: String
}

let assetImages = [
    AssetImage(name: "greenhouse-sky"),
    AssetImage(name: "desert-sky"),
    AssetImage(name: "desert1-sky"),
    AssetImage(name: "cliffs-sky")
]

struct CustomImagePicker: View {
    @Binding var selectedImage: String?
    //@Binding var sampleCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                    ForEach(assetImages) { asset in
                        Button(action: {
                            selectedImage = asset.name
                            //sampleCount = -2
                            dismiss()
                        }) {
                            Image(asset.name)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select a Skybox")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

