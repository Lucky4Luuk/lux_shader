#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normalmap;
uniform sampler2D specular;
uniform sampler2D shadow;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	gl_FragData[0] = color; //gcolor
	gl_FragData[2] = vec4(normal, 1.0);
}

//attribute vec3 at_tangent;
//at_tangent.xyz, cross(normal, at_tangent.xyz) * at_tangent.w
