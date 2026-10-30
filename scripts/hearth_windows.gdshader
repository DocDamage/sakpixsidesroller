shader_type canvas_item;
uniform vec4 pane_rect = vec4(22.0, 22.0, 2.0, 3.0);
uniform float warmth = 0.0;
uniform float clock = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 p = floor(UV * vec2(textureSize(TEXTURE, 0)));
	bool pane = p.x >= pane_rect.x && p.x < pane_rect.x + pane_rect.z
		&& p.y >= pane_rect.y && p.y < pane_rect.y + pane_rect.w;
	if (pane && texel.a > 0.5 && max(max(texel.r, texel.g), texel.b) < 0.18) {
		float flicker = 0.84 + sin(clock * 2.2) * 0.035;
		texel.rgb = mix(texel.rgb, vec3(1.0, 0.67, 0.30), warmth * flicker);
	}
	COLOR = texel * sprite_tint;
}
