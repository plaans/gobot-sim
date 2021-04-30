shader_type canvas_item;
render_mode unshaded;

uniform vec2 dir = vec2(-1.0,0.0);
uniform float speed = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV + normalize(dir)*TIME*speed);
	COLOR = col;
}