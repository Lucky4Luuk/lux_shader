#include "../settings.glsl"
#include "rt_conversion.glsl"

struct Ray {
    vec3 pos; //Origin
    vec3 dir; //Direction
};

//Returns a ray in view space
Ray rayFromProjMat() {
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    uv = uv * 2.0 - 1.0; //Map from [0, 1] to [-1, 1] on both axis
    vec3 origin = (gbufferProjectionInverse * vec4(uv, -1.0, 1.0) * near).xyz;
    vec3 direction = (gbufferProjectionInverse * vec4(uv * (far - near), far + near, far - near)).xyz;
    direction = mat3(gbufferModelViewInverse) * direction;
    return Ray(origin, normalize(direction));
}

struct RayHit {
    bool hit; //True if the ray hit something, false if it reached the max distance without hitting anything
    uvec3 pos; //Hit position in voxel space
    vec3 rayPos; //Final position of the ray
    vec3 dir; //Incoming ray direction
    int steps; //Steps needed to reach the hit

    //Surface information
    vec2 blockUV;
    vec2 uv;
    vec3 normal;
    int blockID; //ID of block that was hit
    vec3 color; //Block color
};

//Get the voxel data at the specified location
vec4 getVoxelData(uvec3 uvPos, int lod) {
    ivec2 vCoord = voxelToTextureSpace(uvPos, lod);
    return texelFetch(shadowcolor0, vCoord, 0);
}

float getVoxelDepth(uvec3 uvPos, int lod) {
    ivec2 vCoord = voxelToTextureSpace(uvPos, lod);
    return texelFetch(shadowtex0, vCoord, 0).r;
}

//Takes a ray in voxel space and traces it through the voxel data.
//See notes in README
RayHit traceRay(Ray ray) {
    uvec3 uvPos = uvec3(ray.pos);

    ivec3 rayStep = ivec3(sign(ray.dir));
    vec3 deltaDist = abs(vec3(length(ray.dir)) / ray.dir);
    vec3 sideDist = (sign(ray.dir) * (vec3(uvPos) - ray.pos) + (sign(ray.dir) * 0.5) + 0.5) * deltaDist;

    vec3 mask;

    bool hit = false;
    int steps = 0;
    vec2 atlasUV;
    vec3 color;

    int LOD = 0;

    for (int i = 0; i < MAX_RAY_STEPS; i++) {
        mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
        sideDist = sideDist + vec3(mask) * deltaDist;
        uvPos += uvec3(vec3(mask)) * rayStep; //* (LOD + 1)

        if (voxelOutOfBounds(uvPos)) break;

        vec4 data = getVoxelData(uvPos, 0);
        color = data.xyz;
        hit = (1.0 - data.w) > 0.0;
        steps += 1;
        if (hit) break;
    }

    float depth = getVoxelDepth(uvPos, 0);
    atlasUV = unpackTexcoord(depth);

    RayHit rhit;
    rhit.hit = hit;
    rhit.steps = steps;
    rhit.pos = uvPos;
    rhit.dir = ray.dir;
    rhit.color = color;

    //Calculate surface information
    vec3 endRayPos = ray.dir / dot(mask * ray.dir, vec3(1)) * dot(mask * (vec3(uvPos) + step(ray.dir, vec3(0)) - ray.pos), vec3(1)) + ray.pos;
    if (abs(mask.x) > 0.0) {
        rhit.blockUV = endRayPos.yz;
    }
    if (abs(mask.y) > 0.0) {
        rhit.blockUV = endRayPos.xz;
    }
    if (abs(mask.z) > 0.0) {
        rhit.blockUV = endRayPos.xy;
    }
    rhit.blockUV = fract(rhit.blockUV);
    rhit.uv = atlasUV;
    rhit.normal = vec3(mask) * rayStep;
    rhit.rayPos = endRayPos;

    return rhit;
}
