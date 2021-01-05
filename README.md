# lux_shader
## Credits
I have taken and modified bits of code from BruceKnowsHow's Octray program, related to voxelization.
The entire voxelization was implemented by Spheya however.
Thanks!

## TODO
- Octree traversal to improve the speed of raytracing outside
- Instead of octree traversal, we should do the raytracing in composite.fsh, and use the 3 depth buffers we have available to jump our ray to the surface of a solid object, and we can use 1 of the 3 depth textures to check for translucent objects in the way, to do refraction.
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
