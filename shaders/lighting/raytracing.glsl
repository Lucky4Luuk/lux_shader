#include "../settings.glsl"
#include "../constants.glsl"
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
    float blockLight;
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
RayHit traceRay(Ray ray, int max_steps) {
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
    float blockLight;

    int LOD = 0;
    float t = 0;

    for (int i = 0; i < max_steps; i++) {
        mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
        // vec3 mini = (vec3(uvPos) - ray.pos + 0.5 - 0.5 * vec3(rayStep)) * rayInv;
        // t = max(mini.x, max(mini.y, mini.z));
        sideDist = sideDist + vec3(mask) * deltaDist;
        uvPos += uvec3(vec3(mask)) * rayStep; //* (LOD + 1)

        if (voxelOutOfBounds(uvPos)) break;

        vec4 data = getVoxelData(uvPos, 0);
        color = data.xy; //HSV without V
        blockLight = data.z;
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
    rhit.color = RT_rgb(vec3(color, 1.0));
    rhit.blockLight = blockLight;

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

int flat_idx = int(dot(gl_FragCoord.xy, vec2(1, 4096)));
void encrypt_tea(inout uvec2 arg) {
	uvec4 key = uvec4(0xa341316c, 0xc8013ea4, 0xad90777d, 0x7e95761e);
	uint v0 = arg[0], v1 = arg[1];
	uint sum = 0u;
	uint delta = 0x9e3779b9u;

	for(int i = 0; i < 32; i++) {
		sum += delta;
		v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1]);
		v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3]);
	}
	arg[0] = v0;
	arg[1] = v1;
}

vec2 get_random(inout uint seed) {
  	uvec2 arg = uvec2(flat_idx, seed++);
  	encrypt_tea(arg);
  	return fract(vec2(arg) / vec2(0xffffffffu));
}

uint wang_hash(inout uint seed) {
    seed = uint(seed ^ uint(61)) ^ uint(seed >> uint(16));
    seed *= uint(9);
    seed = seed ^ (seed >> 4);
    seed *= uint(0x27d4eb2d);
    seed = seed ^ (seed >> 15);
    return seed;
}

float RandomFloat01(inout uint state) {
    return float(wang_hash(state)) / 4294967296.0;
}

vec2 get_random_vec2(inout uint rng) {
    return vec2(RandomFloat01(rng), RandomFloat01(rng));
}

vec3 sampleHemisphere(vec3 normal, inout uint rng) {
    // vec2 uv = vec2(2.0 * rng - 1.0, rng);
    // vec2 uv = get_random_vec2(rng); //Fast but completely broken
    vec2 uv = get_random(rng); //Slow but alright, still a bit noisy though
    uv.x = 2.0 * uv.x - 1.0;
    float a = PI * 2.0 * uv.y;
    vec2 b = sqrt(1.0 - uv.x*uv.x) * vec2(cos(a), sin(a));
    return normalize(normal + vec3(b.x, b.y, uv.x));
}

float castShadowRay(vec3 surfacePos, vec3 lightDir) {
    Ray ray;
    ray.pos = surfacePos + lightDir * 0.0002; //Small offset to avoid clipping the current voxel immediately
    ray.dir = lightDir;

    RayHit hit = traceRay(ray, MAX_RAY_STEPS);
    return float(1 - int(hit.hit));
}

//TODO: Find a better place for this function
vec3 calcLight(vec3 color, vec3 normal, vec3 rayPos, vec3 rayDir) { //rayPos is position of hit, rayDir is incoming ray direction
	vec3 sunVec = normalize(sunDirection);
	float atten = castShadowRay(rayPos, sunVec);
	float NdotL = dot(normal, -sunVec);
	//Sky contribution
	float skyContribution = atten * NdotL; //Wherever there is no shadow, the sky can be seen?
	vec3 skyLight = skyColor * skyContribution;
	skyLight *= 0.15; //Multiplier to not overdo sky contribution
	return color * clamp(atten * NdotL, 0.0, 1.0) * sunLightPower + skyLight; //Clamp is only to fake the sky contribution for now
}

vec3 calcIndirectLight(vec3 rayPos, vec3 rayDir, vec3 normal) {
    vec3 sunVec = normalize(sunDirection);
    vec3 gi = vec3(0.0);
    uint rng = uint(seed * 100.0);
    for (int i = 0; i < MAX_INDIRECT_SAMPLES; i++) {
        Ray ray;
        ray.pos = rayPos - normal * 0.02; //Small offset to avoid clipping the current voxel immediately
        ray.dir = sampleHemisphere(-normal, rng);

        RayHit hit = traceRay(ray, MAX_RAY_STEPS / 16);
        if (hit.hit) {
            vec2 uv = atlasUVfromBlockUV(hit.uv, hit.blockUV);
            vec3 color = texture(TEXTURE_ATLAS, uv).rgb * hit.color;
        	float atten = castShadowRay(hit.rayPos, sunVec);
        	float NdotL = dot(hit.normal, -sunVec);
            float skyContribution = atten * NdotL; //Wherever there is no shadow, the sky can be seen?
        	vec3 skyLight = skyColor * skyContribution * 0.5;
            gi += color * clamp(atten * NdotL, 0.0, 1.0) * sunLightPower + skyLight;
        }
    }
    return gi / MAX_INDIRECT_SAMPLES;
}
