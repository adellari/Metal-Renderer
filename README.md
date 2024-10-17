# Metal Pathtracer
Metal implementation of my first pathtracer https://github.com/adellari/Pathtracer/
## Roadmap
- ~~Diffuse & Specular BRDF~~

- ~~Transparency/translucency BSDF~~

- ~~HDR Rendertarget~~

- ~~Triangle Support~~

- ~~Realtime Object editing~~

- ~~Pinhole -> Real lens with Depth of field~~

- ~~Implement Intel Open Image denoiser~~ (contributed OIDN iOS build configuration, added to OIDN v2.3.0)

- GLTF import via GLTFKit (Primitives: Complete, Materials: Upcoming, Texturing: Upcoming)

- Bounding Volume Heirarchy (BVH) acceleration (In-progress)

- Multiple Importance Sampling

- RGB Channel Sampling -> Spectral Sampling

- Switch to MTKView

## Progress Captures

### Object Editing (Added 04/29/24)


https://github.com/adellari/Metal-Renderer/assets/13017691/c1e97881-7f86-4392-be75-7e3bf8a989b2

|  |  |  |
|:-------------------------:|:-------------------------:|:-------------------------:|
| <img width="600" alt="" src="https://github.com/adellari/Metal-Renderer/assets/13017691/6d9af684-7292-443f-8077-58d248441e8a"> <br> 06/28/24 Mesh Renderered w/ Environment Lighting | <img width="600" alt="" src="https://github.com/adellari/Metal-Renderer/assets/13017691/b2b725a9-0a6a-49db-bf5f-a294c5a1e6ed"><br>06/28/24 Mesh Rendered w/o Environment Lighting | <img width="600" alt="" src="https://github.com/adellari/Metal-Renderer/assets/13017691/a2c1f29e-0775-4305-a688-7e7add5f2f2c"><br>06/23/24 Debugging BVH Traversal |
| <img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/assets/13017691/3df799d4-4557-433a-8bb3-ecc64fb8fdff"><br>05/30/24 GLTF Primitive Loading | <img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/assets/13017691/1861275f-7efb-40bd-a086-3bff06dc2fcf"><br>05/23/24 Environment Lighting via Skybox | <img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/5-9-1.PNG"><br>05/09/24 OIDN denoiser at 50 spp |
| <img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/DoF-Off.PNG"><br>04/30/24 Depth of Field Support (far fPoint) | <img width="1604" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/DoF-On.PNG"><br>04/30/24 Depth of Field Support (near fPoint) | <img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/material-edit1.gif"><br>04/29/24 Scene Material Editing |
| <img width="600" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-24-1.PNG"><br>04/24/24 | <img width="600" alt="screen shot 2017-08-07 at 12 18 15 pm" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-24-0.PNG"><br>04/24/24 Transparent BSDF | <img width="300" alt="Initial metal render to texture" src="https://github.com/adellari/Metal-Renderer/blob/main/Captures/4-09.png"><br>04/09/24 |


