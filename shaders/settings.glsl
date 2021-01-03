#ifndef _INCLUDE_SETTINGS_GLSL_
#define _INCLUDE_SETTINGS_GLSL_

#define TRUE 1
#define FALSE 0

//Voxelization
#define LIMIT_Y_AXIS_VOXELIZATION FALSE //Limit the Y axis distance, instead of it having range 0-256. Might increase performance, but will affect tall structures or large objects in the sky. [FALSE TRUE]
#define LOD_LEVELS 4 //The max level of detail of the octree that needs to be generated. Higher levels will require a higher shadowmap texture to store the data, increasing memory usage, but could potentially speed up raytracing. [1 2 4 8]

//Raytracing
#define MAX_RAY_STEPS 256 //The amount of steps a ray is allowed to take. Lower max steps = higher performance, but less view distance [64 128 256 512 1024]
#define MAX_SKY_SAMPLES 8 //The amount of samples for sky contribution taken. More samples = less noise/performance [0 4 8 16 32 64]
#define MAX_INDIRECT_SAMPLES 32 //The amount of samples for indirect light. More samples = less noise/performance [4 8 16 32 64 128]
#define MAX_BOUNCES 1 //The amount of bounces light is allowed to do. More bounces = more accurate light, but less performance [1 2 4 8]

//Surface
#define TEXTURE_RESOLUTION 16 //Resolution of textures in your resourcepack [8 16 32 64 256]

//Shading
#define LAMBERT 0
#define VANILLA 1

#define SHADING_MODEL LAMBERT //different shading models [LAMBERT VANILLA]

//Debug options
#define DEBUG_NONE 0
#define DEBUG_VOXEL_OCTREE 1
#define DEBUG_NORMALS 2

#define DEBUG FALSE //Enable debug view [FALSE TRUE]
#define DEBUG_MODE DEBUG_NONE //What debug view to show [DEBUG_NONE DEBUG_VOXEL_OCTREE DEBUG_NORMALS]

//Lighting stuff
const float sunPathRotation = -40.0;
vec3 skyColor = vec3(135.0, 206.0, 235.0) / 255.0; //TODO: Dynamic over time of day, or perhaps gather from sky rays?
float sunLightPower = 1.0;

#endif
