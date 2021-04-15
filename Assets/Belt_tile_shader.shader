shader_type canvas_item;
render_mode unshaded;

uniform vec2 dir = vec2(0.0,1.0);
uniform int speed : hint_range(0,4) = 2;

float wrapf(float val, float low, float high) {
		return low + high*fract((val-low)/high);
}

void fragment() {
	float displ = fract(TIME);
	vec2 uv = UV+(dir*0.25*float(speed))*displ;
	uv.x = wrapf(uv.x, 0.0, 0.5);
	uv.y = wrapf(uv.y, 0.5, 1.0);
	
	vec4 col = texture(TEXTURE, uv);
	COLOR = col;
}