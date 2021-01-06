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
	vec3 normal = to_polar(nor_light.xy);
	int blockID = int(nor_light.z * 255.0);
	if (blockID == 255) {
		/* DRAWBUFFERS:06 */
		gl_FragData[0] = vec2(1.0,0.0).xyyy;
		return;
	}

	Ray ray = rayFromProjMat();
	ray.pos = playerToVoxelSpace(vec3(0.0));

	//Calculate ray position from depth buffer
	// vec3 viewPos = viewPosFromDepth(currDepth);
	// ray.pos += ray.dir * viewPos.z;
	// ray.pos -= ray.dir;
	ray.pos = playerToVoxelSpace(worldPosFromDepth(currDepth));

	float samplesToStore = 64.0;

	vec3 final;
	ivec2 tc = ivec2(gl_FragCoord.xy);
	vec3 giUV = reprojectTexcoords(currDepth);
	float giUVErr = max(abs(giUV.x - 0.5), abs(giUV.y - 0.5));
	//Checking error will remove the weird smearing on the outer border of pixels
	vec4 giData = texture(GI_TEMPORAL_MAP, giUV.xy, 0);
	if (giUVErr > 0.49999) giData = vec4(0.0);
	vec3 fullGI = giData.rgb;

	vec3 sunLight = calcSunLight(ray.pos, ray.dir, -normal);
	vec3 frameGI = calcIndirectLight(ray.pos, ray.dir, -normal) + sunLight;
	vec3 finalGI = fullGI * giData.a + frameGI * (1.0 - giData.a);
	finalGI /= giData.a;
	vec3 light = vec3(calcLight(blockID, -normal, ray.pos, ray.dir)) + finalGI;
	final = color * light;

	float sampleMod = 1.0 / samplesToStore;
	float fastMod = clamp(giData.a + sampleMod * MAX_INDIRECT_SAMPLES, 0.0, 1.0);
	/* DRAWBUFFERS:06 */
	gl_FragData[0] = vec4(final, 1.0); //gcolor
	gl_FragData[1] = vec4(fullGI * (1.0 - sampleMod) + frameGI * sampleMod, fastMod);

	#if DEBUG == TRUE && DEBUG_MODE == DEBUG_NORMALS
	gl_FragData[0] = vec4(normal, 1.0); //gcolor
	#endif

	#if DEBUG == TRUE && DEBUG_MODE == DEBUG_DEPTH
	gl_FragData[0] = vec4(vec3(currDepth), 1.0);
	#endif
}
