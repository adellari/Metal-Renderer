# Metal Pathtracer
Metal implementation of my first pathtracer https://github.com/adellari/Pathtracer/
## Roadmap
- ~~Diffuse & Specular BRDF~~

- ~~Transparency/translucency BSDF~~

- ~~HDR Rendertarget~~

- ~~Triangle Support~~

- ~~Realtime Object editing~~

- ~~Pinhole -> Real lens with Depth of field~~

- ~~Implement Intel Open Image denoiser~~ (IODN build for iOS in PR at https://github.com/RenderKit/oidn/pull/220)

- GLTF import via GLTFKit (Primitives: Complete, Materials: Upcoming, Texturing: Upcoming)

- Bounding Volume Heirarchy acceleration (In-progress)

- Multiple Importance Sampling

- RGB Channel Sampling -> Spectral Sampling

## Progress Captures

### Object Editing (Added 04/29/24)


https://github.com/adellari/Metal-Renderer/assets/13017691/c1e97881-7f86-4392-be75-7e3bf8a989b2

| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
|<img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-09.png">  04/09/24 |  <img width="600" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-24-0.PNG"> 04/24/24 Transparent BSDF|<img width="600" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-24-1.PNG"> 04/24/24 |
| <img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/material-edit1.gif"> 04/29/24 Scene Material Editing |  <img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/DoF-On.PNG"> 04/30/24 Depth of Field Support (near fPoint)|<img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/DoF-Off.PNG"> 04/30/24 Depth of Field Support (far fPoint)|
 <img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/5-9-1.PNG"> 05/09/24 OIDN denoiser at 50 spp |  ![Skybox_Initial](https://github.com/adellari/Metal-Renderer/assets/13017691/1861275f-7efb-40bd-a086-3bff06dc2fcf) 05/23/24 Environment Lighting via Skybox | ![Mesh_Second](https://github.com/adellari/Metal-Renderer/assets/13017691/3df799d4-4557-433a-8bb3-ecc64fb8fdff) 05/30/24 GLTF Primitive Loading|


