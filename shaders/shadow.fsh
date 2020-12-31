varying vec2 texcoord;
uniform sampler2D texture;
uniform int blockEntityId;

void main() {
    vec4 color = texture2D(texture, texcoord);

    //Remove the beacon beam
	if(blockEntityId == 10089.0) color *= 0.0;

	gl_FragData[0] = color;
}
