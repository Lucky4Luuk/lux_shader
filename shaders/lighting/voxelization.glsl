//Taken pretty much entirely from https://github.com/BruceKnowsHow/Octray/blob/master/shaders/lib/raytracing/Voxelization.glsl

//Set up the shadow texture settings
// const float shadowDistance           =  232;
// const int   shadowMapResolution      = 8192;
// const float shadowDistanceRenderMul  =  2.0;
// const float shadowIntervalSize       = 0.000001;
// const bool  shadowHardwareFiltering0 =    false;
const int shadowMapResolution = 4096;
const float shadowDistance = 64;

//Variables regarding the real voxel grid
const int voxelRadius = int(shadowDistance);
ivec3 voxelDimensions = ivec3(2 * voxelRadius, 256, 2 * voxelRadius);
ivec3 center = voxelDimensions / 2;

bool voxelOutOfBounds(vec3 voxelSpaceCoord) {
    return any(greaterThanEqual(abs(voxelSpaceCoord - center), center-vec3(0.001)));
}

vec3 playerToVoxelSpace(vec3 playerSpaceCoord) {
    return playerSpaceCoord + vec3(voxelRadius, cameraPosition.y, voxelRadius);
}

ivec2 voxelToTextureSpace(uvec3 voxelSpaceCoord) {
    uint index = voxelSpaceCoord.x +
                 voxelSpaceCoord.z * uint(2 * voxelRadius) +
                 voxelSpaceCoord.y * uint(4 * voxelRadius * voxelRadius);

    return ivec2(index % uint(shadowMapResolution), index / uint(shadowMapResolution));
}
