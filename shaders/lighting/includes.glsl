uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform float near;
uniform float far;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform sampler2D shadowtex0;
