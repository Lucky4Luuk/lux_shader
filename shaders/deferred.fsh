#version 120

uniform sampler2D gcolor;
uniform sampler2D gdepth; //Probably gonna re-use for roughness/other maps
uniform sampler2D gnormal;
uniform sampler2D composite;

varying vec2 texcoord;
varying vec3 sunVec;

uniform float timeAngle;

vec3 lightVec = sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675));

#include "lighting/common.glsl"

#if SHADING_MODEL == LAMBERT
#include "lighting/lambert.glsl"
#elif SHADING_MODEL == VANILLA
#include "lighting/vanilla.glsl"
#else
#error SHADING_MODEL must be set to a correct value
#endif

vec3 calc_light(vec3 color, vec3 normal) {
	Material mat;
	mat.albedo = color;
	Light light;
	light.dir = sunVec;
	return BRDF(mat, light, normal, vec3(0.0), vec3(0.0));
}

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec3 normal = texture2D(gnormal, texcoord).rgb;
	vec3 final = calc_light(color, normal);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(final, 1.0); //gcolor
}
