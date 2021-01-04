vec3 BRDF(Material mat, Light light, vec3 normal, vec3 tangent, vec3 binormal) {
    float NdotL = dot(normal, light.dir);
    // NdotL = clamp(NdotL, 0.25, 1.0);
    return mat.albedo * NdotL;
}
