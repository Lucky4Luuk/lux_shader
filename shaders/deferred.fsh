#include "version.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth; //Probably gonna re-use for roughness/other maps
uniform sampler2D gnormal;
uniform sampler2D composite;

varying vec2 texcoord;

#include "lib/includes.glsl"
#include "lib/common.glsl"
#include "lib/voxelization.glsl"
#include "lib/raytracing.glsl"
#include "lib/rt_conversion.glsl"
#include "lib/reprojection.glsl"
#include "lib/denoise.glsl"

#if SHADING_MODEL == LAMBERT
#include "lib/lambert.glsl"
#elif SHADING_MODEL == VANILLA
#include "lib/vanilla.glsl"
#else
#error SHADING_MODEL must be set to a correct value
#endif

//Calculate BRDF
vec3 calcBRDF(vec3 color, vec3 normal, vec3 lightDir) { //vec4 tangent
	Material mat;
	mat.albedo = color;
	Light light;
	light.dir = lightDir;
	return BRDF(mat, light, normal, vec3(0.0), vec3(0.0));
}

vec3 worldPosFromDepth(float depth) {
	float z = depth * 2.0 - 1.0; //Map range

	vec4 clipSpacePosition = vec4(texcoord * 2.0 - 1.0, z, 1.0); //Map texcoord range
	vec4 viewSpacePosition = gbufferProjectionInverse * clipSpacePosition;

	viewSpacePosition /= viewSpacePosition.w;

	vec4 worldSpacePosition = gbufferModelViewInverse * viewSpacePosition;

	return worldSpacePosition.xyz;
}

void main() {
	float currDepth = texture(depthtex0, texcoord).r;

	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec4 nor_light = texture2D(gnormal, texcoord).rgba;

	Ray ray = rayFromProjMat();
	ray.pos = playerToVoxelSpace(vec3(0.0));

	//Calculate ray position from depth buffer
	// vec3 viewPos = viewPosFromDepth(currDepth);
	// ray.pos += ray.dir * viewPos.z;
	// ray.pos -= ray.dir;
	ray.pos = playerToVoxelSpace(worldPosFromDepth(currDepth));

	// RayHit hit = traceRay(ray, MAX_RAY_STEPS);

	vec3 final;
	vec3 frameGI;
	ivec2 tc = ivec2(gl_FragCoord.xy);
	vec3 giUV = reprojectTexcoords(currDepth);
	float giUVErr = max(abs(giUV.x - 0.5), abs(giUV.y - 0.5));
	//Checking error will remove the weird smearing on the outer border of pixels
	vec3 fullGI = (giUVErr > 0.49999) ? vec3(0.0) : texture(GI_TEMPORAL_MAP, giUV.xy, 0).rgb;

	vec3 normal = to_polar(nor_light.xy);
	frameGI = calcIndirectLight(ray.pos, ray.dir, -normal);
	int blockID = int(nor_light.z * 255.0);
	final = calcLight(blockID, color, -normal, ray.pos, ray.dir) + fullGI;

	/* DRAWBUFFERS:06 */
	// float samplesToStore = 128.0 / MAX_INDIRECT_SAMPLES;
	float samplesToStore = 32.0;
	gl_FragData[0] = vec4(final, 1.0); //gcolor
	gl_FragData[1] = vec4(fullGI * ((samplesToStore - 1.0) / samplesToStore) + frameGI * (1.0 / samplesToStore), 1.0);

	#if DEBUG == TRUE && DEBUG_MODE == DEBUG_NORMALS
	if (hit.hit) gl_FragData[0] = vec4(hit.normal, 1.0); //gcolor
	#endif
}
