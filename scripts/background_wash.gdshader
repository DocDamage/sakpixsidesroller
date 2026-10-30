shader_type canvas_item;

uniform vec4 haze_color : source_color = vec4(0.22, 0.20, 0.32, 1.0);
uniform float distance_fade : hint_range(0.0, 1.0) = 0.6;
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(mix(source.rgb, haze_color.rgb, distance_fade), source.a) * vertex_color;
}
