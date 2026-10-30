shader_type canvas_item;

uniform float impact : hint_range(0.0, 1.0) = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 tinted = texture(TEXTURE, UV) * sprite_tint;
	tinted.rgb = mix(tinted.rgb, vec3(0.96, 0.98, 1.0), impact * 0.88);
	COLOR = tinted;
}
