shader_type canvas_item;
render_mode unshaded;

uniform vec2 dir = vec2(0.0,1.0);
uniform float speed;

void fragment() {
	vec4 col = texture(TEXTURE, UV + normalize(dir)*TIME*speed);
	COLOR = col;
}