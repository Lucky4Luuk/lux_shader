//Set up the shadow texture settings
// const float shadowDistance           =  232;
// const int   shadowMapResolution      = 8192;
// const float shadowDistanceRenderMul  =  2.0;
// const float shadowIntervalSize       = 0.000001;
// const bool  shadowHardwareFiltering0 =    false;
const int shadowMapResolution = 8192;
const float shadowDistance = 64;

//Variables regarding the real voxel grid
const int voxelizationRadius = int(shadowDistance);
#if LIMIT_Y_AXIS_VOXELIZATION == TRUE
ivec3 voxelDimensions = ivec3(2 * voxelizationRadius, 2 * voxelizationRadius, 2 * voxelizationRadius);
#else
ivec3 voxelDimensions = ivec3(2 * voxelizationRadius, 256, 2 * voxelizationRadius);
#endif
int voxelizationVolume = voxelDimensions.x * voxelDimensions.y * voxelDimensions.z;
ivec3 voxelizationCenter = voxelDimensions / 2;

bool voxelOutOfBounds(vec3 voxelSpaceCoord) {
    return any(greaterThanEqual(abs(voxelSpaceCoord - voxelizationCenter), voxelizationCenter-vec3(0.001)));
}

bool voxelOutOfBounds(uvec3 voxelSpaceCoord) {
    return any(greaterThanEqual(voxelSpaceCoord, uvec3(voxelDimensions)));
}

vec3 playerToVoxelSpace(vec3 playerSpaceCoord) {
    vec3 fraction = fract(cameraPosition);

    #ifdef LIMIT_Y_AXIS_VOXELIZATION
        return playerSpaceCoord + voxelizationCenter + fraction;
    #else
        fraction.y = 0.0;
        return playerSpaceCoord + vec3(voxelizationCenter.x, cameraPosition.y, voxelizationCenter.z) + fraction;
    #endif
}

ivec2 voxelToTextureSpace(uvec3 voxelSpaceCoord, int lod) {
    voxelSpaceCoord >>= lod;

    uint index = voxelSpaceCoord.x +
                 ((voxelSpaceCoord.z * uint(2 * voxelizationRadius)) >> lod) +
                 ((voxelSpaceCoord.y * uint(4 * voxelizationRadius * voxelizationRadius)) >> (lod * 2));

    index += 2 * (voxelizationVolume - (voxelizationVolume >> (lod * 3)));

    return ivec2(index % uint(shadowMapResolution), index / uint(shadowMapResolution));
}
