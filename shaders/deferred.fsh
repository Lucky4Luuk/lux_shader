#include "version.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth; //Probably gonna re-use for roughness/other maps
uniform sampler2D gnormal;
uniform sampler2D composite;

varying vec2 texcoord;
varying vec3 sunVec;

#include "lighting/common.glsl"

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

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec4 nor_light = texture2D(gnormal, texcoord).rgba;
	vec3 final = calc_light(color, nor_light);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(final, 1.0); //gcolor
}
