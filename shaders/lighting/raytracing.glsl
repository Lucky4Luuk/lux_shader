//Taken pretty much entirely from https://github.com/BruceKnowsHow/Octray/blob/master/shaders/lib/raytracing/RT_Encoding.glsl

// Packing functions for sending midTexCoord through the shadow depth buffer
// Outputs a float in the range (-1.0, 1.0), which is what gl_Position.z takes in
const vec3 bits = vec3(0.0, 12.0, 12.0);
float packTexcoord(vec2 coord) {
	float matID = floor(255.0)*0;

	coord.rg = floor(coord.rg * exp2(bits.gb));

	float result = 0.0;

	result += matID;
	result += coord.r * exp2(bits.r);
	result += coord.g * exp2(bits.r + bits.g);

	result = exp2(bits.r + bits.g + bits.b) - result; // Flip the priority ordering of textures. This causes the top-grass texture to have priority over side-grass
	result = result / exp2(bits.r + bits.g + bits.b - 1.0) - 1.0; // Compact into range (-1.0, 1.0)

	return result;
}

// The unpacking function takes a float in the range (0.0, 1.0), since this is what is read from the depth buffer
vec2 unpackTexcoord(float enc) {
	enc *= exp2(bits.r + bits.g + bits.b); // Expand from range (-1.0, 1.0)
	enc  = exp2(bits.r + bits.g + bits.b) - enc; // Undo the priority flip

	vec2 coord;
	float matID = mod(floor(enc), exp2(bits.r));
	coord.r = mod(floor(enc / exp2(bits.r      )), exp2(bits.g));
	coord.g = mod(floor(enc / exp2(bits.r + bits.g)), exp2(bits.b));

	return coord * (exp2(-bits.gb));
}

// RGB -> HSV
vec3 RT_hsv(vec3 c) {
	const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV -> RGB
vec3 RT_rgb(vec3 c) {
	const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);

	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
