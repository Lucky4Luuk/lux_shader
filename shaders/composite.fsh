#include "version.glsl"
#include "settings.glsl"

uniform sampler2D colortex0;

#if DEBUG == TRUE && DEBUG_MODE == DEBUG_VOXEL_OCTREE
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
#endif

varying vec2 texcoord;

// ACES tone mapping curve fit to go from HDR to LDR
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0f, 1.0f);
}

vec4 tonemap(vec4 color) {
	// color.rgb = pow(color.rgb, 2.2); //Linear -> gamma
	//For now, I'm hard coding ACES, but in the future, this should be a user option
	return vec4(ACESFilm(color.rgb), color.a);
}

void main() {
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = tonemap(texture2D(colortex0, texcoord));
	#if DEBUG == TRUE && DEBUG_MODE == DEBUG_VOXEL_OCTREE
	if(texcoord.x > 0.5 || texcoord.y > 0.5) {
        gl_FragData[0] = texture2D(colortex0, texcoord);
    }else {
		vec4 shadow_data = texture2D(shadowcolor0, texcoord * 2);
        gl_FragData[0] = vec4(shadow_data.rgb * (1.0 - shadow_data.a), 1.0);
    }
	#else
	#endif
}
