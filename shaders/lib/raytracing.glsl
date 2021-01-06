#include "../settings.glsl"
#include "../constants.glsl"
#include "rt_conversion.glsl"
#include "blockmapping.glsl"
#include "random.glsl"
#include "../constants.glsl"

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
    int blockID; //ID of block that was hit, see block.properties
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
RayHit traceRay(Ray ray, int max_steps, int maxLod = 0) {
    int lod = 0;
    uvec3 uvPos = uvec3(ray.pos);

    vec3 rayInv = 1.0 / ray.dir;
    ivec3 rayStep = ivec3(sign(ray.dir));
    vec3 deltaDist = abs(vec3(length(ray.dir)) / ray.dir);
    vec3 sideDist = (sign(ray.dir) * (vec3(uvPos) - ray.pos) + (sign(ray.dir) * 0.5) + 0.5) * deltaDist;

    vec3 mask;

    bool hit = false;
    int steps = 0;
    vec2 atlasUV;
    vec2 color;
    int blockID;

    float t = 0;

    for (int i = 0; i < max_steps; i++) {
        uvPos = uvPos >> lod;
        mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
        sideDist = sideDist + vec3(mask) * deltaDist;
        uvPos += uvec3(vec3(mask)) * rayStep;
        uvPos = uvPos << lod;

        if (voxelOutOfBounds(uvPos)) break;

        vec4 data = getVoxelData(uvPos, lod);
        color = data.xy; //HSV without V
        blockID = int(data.w * 255.0);
        hit = (1.0 - data.w) > 0.0;
        steps += 1;
        if (i % 16 == 15) lod = min(lod + 1, maxLod);
        if (hit) break;
    }

    float depth = getVoxelDepth(uvPos, 0);
    atlasUV = unpackTexcoord(depth);

    RayHit rhit;
    rhit.hit = hit;
    rhit.steps = steps;
    rhit.pos = uvPos;
    rhit.dir = ray.dir;
    rhit.color = RT_rgb(vec3(color, 1.0));
    rhit.blockID = blockID;

    vec3 mini = (vec3(uvPos) - ray.pos + 0.5 - 0.5 * vec3(rayStep)) * rayInv;
    t = max(mini.x, max(mini.y, mini.z));

    //Calculate surface information
    // vec3 endRayPos = ray.dir / dot(mask * ray.dir, vec3(1)) * dot(mask * (vec3(uvPos) + step(ray.dir, vec3(0)) - ray.pos), vec3(1)) + ray.pos;
    vec3 endRayPos = ray.pos + ray.dir * t;
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

vec3 sampleHemisphere(vec3 normal, inout uvec2 rng) {
    // vec2 uv = vec2(2.0 * rng - 1.0, rng);
    vec2 uv = random_vec2(rng);
    // vec2 uv = get_random(rng);
    uv.x = 2.0 * uv.x - 1.0;
    float a = PI * 2.0 * uv.y;
    vec2 b = sqrt(1.0 - uv.x*uv.x) * vec2(cos(a), sin(a));
    return normalize(normal + vec3(b.x, b.y, uv.x));
}

vec3 generateUnitVector(vec2 hash) {
    hash.x *= TAU; hash.y = hash.y * 2.0 - 1.0;
    return vec3(vec2(sin(hash.x), cos(hash.x)) * sqrt(1.0 - hash.y * hash.y), hash.y);
}

vec3 sampleCone(vec3 normal, float angle, inout uvec2 rng) {
    vec2 xy = random_vec2(rng);
    vec3 dir = generateUnitVector(xy);
    float noiseAngle = acos(dot(dir, normal)) * (angle / PI);
    return sin(noiseAngle) * normalize(cross(normal, dir)) + cos(noiseAngle) * normal;
}

float castShadowRay(vec3 surfacePos, vec3 lightDir) {
    Ray ray;
    ray.pos = surfacePos - lightDir * 0.0002; //Small offset to avoid clipping the current voxel immediately
    ray.dir = lightDir;

    RayHit hit = traceRay(ray, 96); //96 steps because light leaking
    return float(1 - int(hit.hit));
}

//TODO: Find a better place for this function
float calcLight(int blockID, vec3 normal, vec3 rayPos, vec3 rayDir) { //rayPos is position of hit, rayDir is incoming ray direction
	vec3 sunVec = normalize(sunDirection);
    float emissive = float(isEmissive(blockID)) * 7.5;
	return emissive * sunLightPower;
    // return NdotL + emissive;
}

vec3 sampleSky(vec3 direction) {
    // float d = pow(max(dot(direction, normalize(sunDirection)), 0.0), 300.0) * 60;
    float d = 0.0;
    return skyColor * 0.15 * ceil(sunAngle) + d;
    // return vec3(0.8, 0.85, 0.95) + d;
}

vec3 calcIndirectBounce(vec3 rayPos, vec3 rayDir, vec3 normal, inout uvec2 rng) {
    vec3 accumLight = vec3(0.0);
    vec3 colorMask = vec3(1.0);
    vec3 pos = rayPos - normal * 0.02; //Small offset to avoid clipping the current voxel immediately
    for (int b = 0; b < MAX_BOUNCES; b++) {
        float NdotL = dot(normal, -sunDirection);
        Ray ray;
        ray.pos = pos;
        ray.dir = sampleHemisphere(-normal, rng);

        RayHit hit = traceRay(ray, MAX_RAY_STEPS);
        if (hit.hit) {
            vec2 uv = atlasUVfromBlockUV(hit.uv, hit.blockUV);
            vec3 color = texture(TEXTURE_ATLAS, uv).rgb * hit.color;
            colorMask *= color;
            float directLight = calcLight(hit.blockID, hit.normal, hit.rayPos, hit.dir);
            accumLight += directLight * color * colorMask;
            normal = hit.normal;
            pos = hit.rayPos - normal * 0.02;
        } else {
            float skyIntensity = 1.0;
            accumLight += sampleSky(rayDir) * skyIntensity;
            break;
        }
    }
    return accumLight;
}

vec3 calcIndirectLight(vec3 rayPos, vec3 rayDir, vec3 normal) {
    vec3 sunVec = normalize(sunDirection);
    vec3 gi = vec3(0.0);
    // uint rng = uint(seed * 1024.0);
    // uint rng = uint((rayPos.x + rayPos.y + rayPos.z + seed) * 1046527.0);
    vec3 p = rayPos + fract(cameraPosition.y);
    uvec2 rng = uvec2((p.xz + p.y + seed) * 1046527.0);
    for (int i = 0; i < MAX_INDIRECT_SAMPLES; i++) {
        gi += calcIndirectBounce(rayPos, rayDir, normal, rng);
    }
    return gi / MAX_INDIRECT_SAMPLES;
}

vec3 calcSunLight(vec3 rayPos, vec3 rayDir, vec3 normal) {
    vec3 sunVec = normalize(sunDirection);
    vec3 totalLight = vec3(0.0);

    //Main ray
    Ray ray;
    ray.pos = rayPos - normal * 0.005;
    ray.dir = sunVec;

    RayHit hit = traceRay(ray, 48, 0);
    if (!hit.hit) totalLight = vec3(1.0);

    vec3 p = rayPos + fract(cameraPosition.y);
    uvec2 rng = uvec2((p.xz + p.y + seed) * 1046527.0);

    const int MAX_SUN_SAMPLES = 2;
    for (int i = 0; i < MAX_SUN_SAMPLES; i++) {
        // ray.dir = sampleCone(sunVec, 30, rng); //Something seems wrong here, inverting the direction changes nothing about the result
        ray.dir = sampleHemisphere(sunVec, rng);
        RayHit hit = traceRay(ray, 32, 0);
        if (!hit.hit) totalLight += vec3(1.0) / MAX_SUN_SAMPLES;
    }

    return totalLight;
}
