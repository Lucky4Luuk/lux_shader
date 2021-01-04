//Thanks builderb0y :)
//Code taking pretty much 1:1 from his datamoshing shader.

#ifndef _INCLUDE_REPROJECTION_GLSL_
#define _INCLUDE_REPROJECTION_GLSL_

#include "includes.glsl"

//Calculates the coordinates of the sample location for a fullscreen texture.
//For instance, when sampling the GI buffer, if we move the camera, we need to
//move where we sample, otherwise we will smear the screen with old samples.
vec3 reprojectTexcoords(float currDepth) {
	vec3 currClip = vec3(texcoord, currDepth) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * vec4(currClip, 1.0);
	vec3 currView = tmp.xyz / tmp.w;
	vec3 currPlayer = mat3(gbufferModelViewInverse) * currView;
	vec3 currWorld = currPlayer + cameraPosition;

	vec3 prevPlayer = currWorld - previousCameraPosition;
	vec3 prevView = mat3(gbufferPreviousModelView) * prevPlayer;
	tmp = gbufferPreviousProjection * vec4(prevView, 1.0);
	vec3 prevClip = tmp.xyz / tmp.w;
	vec3 prevScreen = prevClip * 0.5 + 0.5;
	return prevScreen;
}

#endif
