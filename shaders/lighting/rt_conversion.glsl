#define TEXTURE_RESOLUTION 16 //Resolution of textures in your resourcepack [8 16 32 64 256]

vec2 ATLAS_SIZE = textureSize(TEXTURE_ATLAS, 0).xy;

vec2 atlasUVfromBlockUV(vec2 uv, vec2 blockUV) {
	vec2 uvScale = (vec2(TEXTURE_RESOLUTION * TEXTURE_RESOLUTION) / ATLAS_SIZE) * 0.5;
	vec2 finalUV = uv + blockUV * uvScale;
	return finalUV;
}
