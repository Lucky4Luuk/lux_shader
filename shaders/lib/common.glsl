#include "../settings.glsl"
#include "../constants.glsl"

struct Material {
    vec3 albedo;
};

struct Light {
    vec3 pos;
    vec3 dir;

    //Types
    // 0. Directional
    // 1. Point light
    int type;
};

vec2 to_uv(in vec3 n)
{
    vec2 uv;

    uv.x = atan(-n.x, n.y);
    uv.x = (uv.x + PI / 2.0) / (PI * 2.0) + PI * (28.670 / 360.0);

    uv.y = acos(n.z) / PI;

    return uv;
}

// Uv range: [0, 1]
vec3 to_polar(in vec2 uv)
{
    float theta = 2.0 * PI * uv.x + - PI / 2.0;
    float phi = PI * uv.y;

    vec3 n;
    n.x = cos(theta) * sin(phi);
    n.y = sin(theta) * sin(phi);
    n.z = cos(phi);

    //n = normalize(n);
    return n;
}
