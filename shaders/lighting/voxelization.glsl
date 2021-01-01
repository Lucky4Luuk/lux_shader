//Taken pretty much entirely from https://github.com/BruceKnowsHow/Octray/blob/master/shaders/lib/raytracing/Voxelization.glsl

//Set up the shadow texture settings
const float shadowDistance           =  232;
const int   shadowMapResolution      = 8192;
const float shadowDistanceRenderMul  =  2.0;
const float shadowIntervalSize       = 0.000001;
const bool  shadowHardwareFiltering0 =    false;

//Variables regarding the biggest possible voxel grid for this setting
const int voxelRadius2   = int(shadowDistance); //Voxel grid radius
const int voxelDiameter2 = 2 * voxelRadius2; //Voxel grid diameter
const ivec3 voxelDimensions2 = ivec3(voxelDiameter2, 256, voxelDiameter2); //Voxel grid size

const int voxelArea2 = voxelDimensions2.x * voxelDimensions2.z; //Voxel grid area (on the xz plane)
const int voxelVolume2 = voxelDimensions2.y * voxelArea2; //Voxel grid volume

//Variables regarding the real voxel grid
int voxelRadius   = int(min(shadowDistance, far)); //Voxel grid radius
int voxelDiameter = 2 * voxelRadius; //Voxel grid diameter
ivec3 voxelDimensions = ivec3(voxelDiameter, 256, voxelDiameter); //Voxel grid size

int voxelArea = voxelDimensions.x * voxelDimensions.z; //Voxel grid area (on the xz plane)
int voxelVolume = voxelDimensions.y * voxelArea; //Voxel grid volume

//Convert a world space position to voxel space
vec3 WorldToVoxelSpace(vec3 position) {
	vec3 WtoV = vec2(0.0, floor(cameraPosition.y)).xyx + vec2(0.0, voxelRadius).yxy + gbufferModelViewInverse[3].xyz + fract(cameraPosition);
	return position + WtoV;
}

//Version of prior function specifically for use in the shadow pass
vec3 WorldToVoxelSpace_ShadowMap(vec3 position) {
	vec3 WtoV = vec2(0.0, floor(cameraPosition.y)).xyx + vec2(0.0, voxelRadius).yxy;
	return position + WtoV;
}

//Convert a voxel space position back to world space
vec3 VoxelToWorldSpace(vec3 position) {
	vec3 WtoV = vec2(0.0, floor(cameraPosition.y)).xyx + vec2(0.0, voxelRadius).yxy + gbufferModelViewInverse[3].xyz + fract(cameraPosition);
	return position - WtoV;
}

//Convert a voxel position to a texture coordinate, for storing it in the shadow buffer
ivec2 VoxelToTextureSpace(uvec3 position, uint LOD) {
	position = position >> LOD;
	position.x = (position.x * voxelDiameter2) >> LOD;
	position.y = (position.y * voxelArea2) >> (LOD*2);

	uint linenum = (position.x + position.y + position.z) + ((voxelVolume2*8) - ((voxelVolume2*8) >> int(LOD*3)))/7;
	return ivec2(linenum % shadowMapResolution, linenum / shadowMapResolution);
}

//Check if a voxel position is within the voxel grid
bool OutOfVoxelBounds(vec3 point) {
	vec3 mid = voxelDimensions / 2.0;

	return any(greaterThanEqual(abs(point - mid), mid-vec3(0.001)));
}

bool OutOfVoxelBounds(uint point, uvec3 uplane) {
	uint comp = (uvec3(voxelDimensions).x & uplane.x) | (uvec3(voxelDimensions).y & uplane.y) | (uvec3(voxelDimensions).z & uplane.z);
	return point >= comp;
}
