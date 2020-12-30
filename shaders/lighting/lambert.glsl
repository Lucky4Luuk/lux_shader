#include "lighting/common.glsl"

vec3 BRDF(Material mat, Light light, vec3 normal, vec3 tangent, vec3 binormal) {
    float NdotL = dot(normal, light.dir);
    return mat.albedo;
}
