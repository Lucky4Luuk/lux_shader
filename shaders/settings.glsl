#ifndef _INCLUDE_SETTINGS_GLSL_
#define _INCLUDE_SETTINGS_GLSL_

#define TRUE 1
#define FALSE 0

//Voxelization
#define LIMIT_Y_AXIS_VOXELIZATION FALSE //Limit the Y axis distance, instead of it having range 0-256. Might increase performance, but will affect tall structures or large objects in the sky. [FALSE TRUE]
#define LOD_LEVELS 4 //The max level of detail of the octree that needs to be generated. Higher levels will require a higher shadowmap texture to store the data, increasing memory usage, but could potentially speed up raytracing. [1 2 4 8]

//Raytracing
#define MAX_RAY_STEPS 256 //The amount of steps a ray is allowed to take. Lower max steps = higher performance, but less view distance [64 128 256 512 1024]

//Surface
#define TEXTURE_RESOLUTION 16 //Resolution of textures in your resourcepack [8 16 32 64 256]

//Shading
#define LAMBERT 0
#define VANILLA 1

#define SHADING_MODEL LAMBERT //different shading models [LAMBERT VANILLA]

#endif
