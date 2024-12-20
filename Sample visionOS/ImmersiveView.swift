//
//  ImmersiveView.swift
//  Sample visionOS
//
//  Created by DINEY B ALVES on 7/2/23.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive") {
                content.add(immersiveContentEntity)

                // Add an ImageBasedLight for the immersive content
                if let imageBasedLightURL = Bundle.main.url(forResource: "ImageBasedLight", withExtension: "exr"),
                   let imageBasedLightImageSource = CGImageSourceCreateWithURL(imageBasedLightURL as CFURL, nil),
                   let imageBasedLightImage = CGImageSourceCreateImageAtIndex(imageBasedLightImageSource, 0, nil),
                   let imageBasedLightResource = try? await EnvironmentResource.generate(fromEquirectangular: imageBasedLightImage) {
                    let imageBasedLightSource = ImageBasedLightComponent.Source.single(imageBasedLightResource)

                    let imageBasedLight = Entity()
                    imageBasedLight.components.set(ImageBasedLightComponent(source: imageBasedLightSource))
                    content.add(imageBasedLight)

                    immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageBasedLight))
                }

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
}

struct ImmersiveView_Previews: PreviewProvider {
	static var previews: some View {
		ImmersiveView()
			.previewLayout(.sizeThatFits)
	}
}
