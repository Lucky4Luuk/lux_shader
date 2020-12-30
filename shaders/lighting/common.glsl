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
