# lux_shader
## Credits
I have taken and modified bits of code from BruceKnowsHow's Octray program, related to voxelization.
Thanks!

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
