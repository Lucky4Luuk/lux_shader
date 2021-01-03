#include "version.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth; //Probably gonna re-use for roughness/other maps
uniform sampler2D gnormal;
uniform sampler2D composite;

varying vec2 texcoord;

#include "lighting/includes.glsl"
#include "lighting/common.glsl"
#include "lighting/voxelization.glsl"
#include "lighting/raytracing.glsl"
#include "lighting/rt_conversion.glsl"

#if SHADING_MODEL == LAMBERT
#include "lighting/lambert.glsl"
#elif SHADING_MODEL == VANILLA
#include "lighting/vanilla.glsl"
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

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec4 nor_light = texture2D(gnormal, texcoord).rgba;

	Ray ray = rayFromProjMat();
	ray.pos = playerToVoxelSpace(vec3(0.0));

	RayHit hit = traceRay(ray, MAX_RAY_STEPS);

	vec3 final;
	vec3 frameGI;
	vec3 fullGI = texture(GI_TEMPORAL_MAP, texcoord).rgb;

	vec2 uv = atlasUVfromBlockUV(hit.uv, hit.blockUV);
	if (hit.hit) {
		color = texture(TEXTURE_ATLAS, uv).rgb * hit.color;
		vec3 normal = normalize(hit.normal);
		frameGI = calcIndirectLight(hit.rayPos, hit.dir, normal);
		final = calcLight(color, normal, hit.rayPos, hit.dir) + fullGI;
	} else {
		final = calcBRDF(color, to_polar(nor_light.rg), normalize(to_polar(nor_light.ba)));
	}

	/* DRAWBUFFERS:06 */
	gl_FragData[0] = vec4(final, 1.0); //gcolor
	gl_FragData[1] = vec4(fullGI * (31.0 / 32.0) + frameGI * (1.0 / 32.0), 1.0);

	#if DEBUG == TRUE && DEBUG_MODE == DEBUG_NORMALS
	if (hit.hit) gl_FragData[0] = vec4(hit.normal, 1.0); //gcolor
	#endif
}
