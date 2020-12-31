#include "version.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in vec2 vTexcoord[];

out vec2 texcoord;

void main() {
    for (int i = 0; i < 3; ++i) {
        gl_Position = gl_in[i].gl_Position;
        texcoord = vTexcoord[i];
        EmitVertex();
    }
}
