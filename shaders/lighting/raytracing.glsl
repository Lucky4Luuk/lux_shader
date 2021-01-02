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
    return Ray(origin, normalize(direction));
}

struct RayHit {
    bool hit; //True if the ray hit something, false if it reached the max distance without hitting anything
    vec3 pos; //Hit position
    vec3 dir; //Incoming ray direction

    vec3 plane; //No idea

    int blockID; //ID of block that was hit
    int steps; //Steps needed to reach the hit
};

//Get the voxel data at the specified location
vec4 getVoxelData(uvec3 uvPos, uint LOD) {
    ivec2 vCoord = VoxelToTextureSpace(uvPos, LOD);
    return texelFetch(shadowtex0, vCoord, 0);
}

//I believe volume can be increased to trace in a cone, but not sure
bool containsVoxel(uvec3 uvPos, float volume, uint LOD) {
    if (getVoxelData(uvPos, LOD).x != volume) return true;
    return false;
}

#define MAX_RAY_STEPS 512 //The amount of steps a ray is allowed to take. Lower max steps = higher performance, but less view distance [64 128 256 512 1024]

//Takes a ray in voxel space and traces it through the voxel data.
//See notes in README

#define BinaryDot(a, b) ((a.x & b.x) | (a.y & b.y) | (a.z & b.z))
#define BinaryMix(a, b, c) ((a & (~c)) | (b & c))

float BinaryDotF(vec3 v, uvec3 uplane) {
	uvec3 u = floatBitsToUint(v);
	return uintBitsToFloat(BinaryDot(u, uplane));
}

float MinComp(vec3 v, out vec3 minCompMask) {
	float minComp = min(v.x, min(v.y, v.z));
	minCompMask.xy = 1.0 - clamp((v.xy - minComp) * 1e35, 0.0, 1.0);
	minCompMask.z = 1.0 - minCompMask.x - minCompMask.y;
	return minComp;
}

float MinComp(vec3 v, out uvec3 minCompMask) {
	ivec3 ia = floatBitsToInt(v);
	ivec3 iCompMask;
	iCompMask.xy = ((ia.xy - ia.yx) & (ia.xy - ia.zz)) >> 31;
	iCompMask.z = (-1) ^ iCompMask.x ^ iCompMask.y;

	minCompMask = uvec3(iCompMask);

	return intBitsToFloat(BinaryDot(ia, iCompMask));
}

uvec3 GetMinCompMask(vec3 v) {
	ivec3 ia = floatBitsToInt(v);
	ivec3 iCompMask;
	iCompMask.xy = ((ia.xy - ia.yx) & (ia.xy - ia.zz)) >> 31;
	iCompMask.z = (-1) ^ iCompMask.x ^ iCompMask.y;

	return uvec3(iCompMask);
}

uvec2 GetNonMinComps(uvec3 xyz, uvec3 uplane) {
	return BinaryMix(xyz.xz, xyz.yy, uplane.xz);
}

uint GetMinComp(uvec3 xyz, uvec3 uplane) {
	return BinaryDot(xyz, uplane);
}

uvec3 SortMinComp(uvec3 xyz, uvec3 uplane) {
	uvec3 ret;
	ret.xy = GetNonMinComps(xyz, uplane);
	ret.z  = xyz.x ^ xyz.y ^ xyz.z ^ ret.x ^ ret.y;
	return ret;
}

uvec3 UnsortMinComp(uvec3 uvw, uvec3 uplane) {
	uvec3 ret;
	ret.xz = BinaryMix(uvw.xy, uvw.zz, uplane.xz);
	ret.y = uvw.x ^ uvw.y ^ uvw.z ^ ret.x ^ ret.z;
	return ret;
}

RayHit traceRay(Ray ray, inout int steps) {
    vec3 vPos = ray.pos;
    vec3 wDir = ray.dir;
    float volume = 1.0;

    uvec3 dirIsPositive = uvec3(max(sign(wDir), 0));
	uvec3 boundary = uvec3(vPos) + dirIsPositive;
	uvec3 uvPos = uvec3(vPos);

	uvec3 vvPos = uvPos;
	vec3 fPos = fract(vPos);

	uint LOD = 0;
	uint hit = 0;
	vec4 data;
	ivec2 vCoord;

	while (true) {
		vec3 distToBoundary = (boundary - vPos) / wDir;
		uvec3 uplane = GetMinCompMask(distToBoundary);
		vec3 plane = vec3(-uplane);

		uvec3 isPos = SortMinComp(dirIsPositive, uplane);

		uint nearBound = GetMinComp(boundary, uplane);

		uvec3 newPos;
		newPos.z = nearBound + isPos.z - 1;
		if ( LOD >= 8 || OutOfVoxelBounds(newPos.z, uplane) || steps >= MAX_RAY_STEPS ) { break; }
        steps += 1;

		float tLength = BinaryDotF(distToBoundary, uplane);
		newPos.xy = GetNonMinComps(ivec3(floor(fPos + wDir * tLength)) + vvPos, uplane);
		uint oldPos = GetMinComp(uvPos, uplane);
		uvPos = UnsortMinComp(newPos, uplane);

		uint shouldStepUp = uint((newPos.z >> (LOD+1)) != (oldPos >> (LOD+1)));
		LOD = min(LOD + shouldStepUp, 7);
		vCoord = VoxelToTextureSpace(uvPos, LOD);
		data = texelFetch(shadowtex0, vCoord, 0);
		hit = uint(data.x != volume);
		uint miss = 1-hit;
		LOD -= hit;

		boundary.xy  = ((newPos.xy >> LOD) + isPos.xy) << LOD;
		boundary.z   = nearBound + miss * ((isPos.z * 2 - 1) << LOD);
		boundary     = UnsortMinComp(boundary, uplane);
	}

    RayHit rhit;
    rhit.pos = vPos + wDir * MinComp((boundary - vPos) / wDir, rhit.plane);
    rhit.hit = bool(hit);
    rhit.plane *= sign(-wDir);
    rhit.blockID = int(data.y * 255.0);
    return rhit;
}
