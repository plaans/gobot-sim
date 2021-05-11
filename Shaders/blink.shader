shader_type canvas_item;

uniform vec4 target_color : hint_color = vec4(1.);
uniform float speed = 1.;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	COLOR = mix(col, target_color, sin(TIME*speed));
}