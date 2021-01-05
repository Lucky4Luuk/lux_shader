# lux_shader
## Credits
I have taken and modified bits of code from BruceKnowsHow's Octray program, related to voxelization.
The entire voxelization was implemented by Spheya however.
Thanks!

## TODO
- Octree traversal to improve the speed of raytracing outside
- Instead of octree traversal, I should instead jump my ray to the surface according to the depth buffer. Then, in composite.fsh, I can check the depth buffer for translucent blocks, and do a proper trace from there instead. When the ray refracts, I will be forced to trace a full ray regardless, so I can separate this
- In the GI step, sample the skybox, for nice soft shadows (sun has a size) and better sun contribution (also fixes bug with attenuation)
- Invalidate old GI samples based on depth to remove lots of artifacting
- Implement a proper lighting model
- Implement reflection (and possibly refraction)
- Implement different block types
- Denoise the GI samples stored
- Compose all passes correctly, so entities and such are still visible

## Notes
### Voxelization
Voxelization is done in the shadow pass.

### Raytracing
Raytracing is done in the deferred pass.

### LOD
In both the voxelization as well as the raytracing itself, there is mention of a variable called `LOD`.
Essentially, it jumps up a LOD when there's no voxels in the current "voxel" checked.
This means that, the bigger the LOD, the bigger area is evaluated. The way it's voxelized makes this possible.
If there is a voxel inside the volume checked, it will go down a LOD and trace further.
