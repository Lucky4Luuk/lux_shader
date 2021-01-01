#include "version.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth; //Probably gonna re-use for roughness/other maps
uniform sampler2D gnormal;
uniform sampler2D composite;

varying vec2 texcoord;
varying vec3 sunVec;

#include "lighting/includes.glsl"
#include "lighting/common.glsl"
#include "lighting/voxelization.glsl"
#include "lighting/raytracing.glsl"

#if SHADING_MODEL == LAMBERT
#include "lighting/lambert.glsl"
#elif SHADING_MODEL == VANILLA
#include "lighting/vanilla.glsl"
#else
#error SHADING_MODEL must be set to a correct value
#endif

vec3 calc_light(vec3 color, vec4 nor_light) { //vec4 tangent
	Material mat;
	mat.albedo = color;
	Light light;
	light.dir = normalize(to_polar(nor_light.ba));
	vec3 normal = to_polar(nor_light.rg);
	return BRDF(mat, light, normal, vec3(0.0), vec3(0.0));
}

vec2 tc = gl_FragCoord.xy / viewSize;

vec3 GetWorldSpacePosition(vec2 coord, float depth) {
	vec4 pos = vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
	pos = gbufferProjectionInverse * pos;
	pos /= pos.w;
	pos.xyz = mat3(gbufferModelViewInverse) * pos.xyz;

	return pos.xyz;
}

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec4 nor_light = texture2D(gnormal, texcoord).rgba;
	vec3 final = calc_light(color, nor_light);

	// Ray ray = rayFromProjMat();
	// ray.pos = WorldToVoxelSpace(ray.pos);

	vec3 vPos = WorldToVoxelSpace(vec3(0.0));
	vec3 wDir = normalize(GetWorldSpacePosition(tc, 1.0));
	Ray ray = Ray(vPos, wDir);

	int steps = 1;
	RayHit hit = traceRay(ray, steps);
	ray.pos = hit.pos - hit.plane * exp2(-12);
	//steps is hier 9

	for (int i = 1; i < MAX_RAY_STEPS; i++) {
		hit = traceRay(ray, steps);
		ray.pos = hit.pos - hit.plane * exp2(-12);
		if (hit.hit || steps > MAX_RAY_STEPS) break;
	}
	//steps is hier nog steeds 9

	// final *= 0.5;
	// final += vec3(float(steps) / float(MAX_RAY_STEPS)) * 0.5;
	// final = vec3(float(hit.hit));
	// final = vec3(float(steps * 1) / float(MAX_RAY_STEPS));
	// if (steps < 10) final = vec3(0.0, 0.0, 1.0);
	// if (hit.hit) final = vec3(float(steps) / float(MAX_RAY_STEPS) * 0.5 + 0.5, 0.0, 0.0);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(final, 1.0); //gcolor
}
