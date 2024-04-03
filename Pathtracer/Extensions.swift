//
//  Extensions.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 4/2/24.
//

import SwiftUI

extension UIImageView {
    func asSwiftUIView() -> some View {
        return ImageViewWrapper(uiImageView: self)
    }
}

struct ImageViewWrapper: UIViewRepresentable {
    let uiImageView: UIImageView

    func makeUIView(context: Context) -> UIImageView {
        return uiImageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Update the view if needed
    }
}
