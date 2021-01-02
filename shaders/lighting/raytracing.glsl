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
    vec3 dir; //Incoming ray direction
    int steps; //Steps needed to reach the hit

    //Surface information
    vec2 uv;
    vec3 normal;
    int blockID; //ID of block that was hit
};

//Get the voxel data at the specified location
vec4 getVoxelData(uvec3 uvPos) {
    ivec2 vCoord = voxelToTextureSpace(uvPos);
    return texelFetch(shadowcolor0, vCoord, 0);
}

//I believe volume can be increased to trace in a cone, but not sure
bool containsVoxel(uvec3 uvPos) {
    if (1.0 - getVoxelData(uvPos).a > 0.0) return true;
    return false;
}

#define MAX_RAY_STEPS 512 //The amount of steps a ray is allowed to take. Lower max steps = higher performance, but less view distance [64 128 256 512 1024]

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

    for (int i = 0; i < MAX_RAY_STEPS; i++) {
        // mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));
        mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
        sideDist += vec3(mask) * deltaDist;
        uvPos += uvec3(vec3(mask)) * rayStep;

        if (voxelOutOfBounds(uvPos)) break;

        hit = containsVoxel(uvPos);
        steps += 1;
        if (hit) break;
    }

    RayHit rhit;
    rhit.hit = hit;
    rhit.steps = steps;
    rhit.pos = uvPos;
    rhit.dir = ray.dir;

    //Calculate surface information
    vec3 endRayPos = ray.dir / dot(mask * ray.dir, vec3(1)) * dot(mask * (vec3(uvPos) + step(ray.dir, vec3(0)) - ray.pos), vec3(1)) + ray.pos;
    if (abs(mask.x) > 0.0) {
        rhit.uv = endRayPos.yz;
    }
    if (abs(mask.y) > 0.0) {
        rhit.uv = endRayPos.xz;
    }
    if (abs(mask.z) > 0.0) {
        rhit.uv = endRayPos.xy;
    }
    rhit.uv = fract(rhit.uv);
    rhit.normal = vec3(mask) * rayStep;

    return rhit;
}
