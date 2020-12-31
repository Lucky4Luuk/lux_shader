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

#define LAMBERT 0
#define VANILLA 1

#define SHADING_MODEL LAMBERT //different shading models [LAMBERT VANILLA]
