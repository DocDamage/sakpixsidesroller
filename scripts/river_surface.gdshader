// Adapted for Witching Hour from the supplied REEBOO Labs side-view water shader.
// Original: Shaders/Shader Kit/addons/water_kit/shaders/water_2d_side.gdshader
// Uses a pause-aware game clock; original kit files are preserved.
// REEBOO Labs Water Kit - 2D side-view water (platformers)
// Put it on a ColorRect; the top edge of the rect is the air above the water.
// Rolling surface waves, a bright surface line, see-through refraction of what is behind,
// depth gradient and light rays. Water2DSide (scripts/water_2d_side.gd) adds splash ripples
// (spring columns), splash particles and buoyancy for RigidBody2D, and fills in the
// set_by_script uniforms at runtime.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms set_by_script;
// Rest height of the surface, in pixels below the top of the rect (room for waves).
uniform float surface_offset = 24.0;
// Spring-column heights in pixels (up = positive), spaced spring_spacing pixels apart.
uniform float springs[128];
uniform int spring_count = 0;
uniform float spring_spacing = 8.0;

group_uniforms waves;
uniform float game_time = 0.0;
uniform float weather_rain = 0.0;
uniform float weather_wind = 0.0;
uniform float wave_height = 4.0;
uniform float wave_length = 190.0;
uniform float wave_speed = 1.0;

group_uniforms color;
uniform vec4 surface_color : source_color = vec4(0.85, 0.97, 1.0, 1.0);
// Alpha of these two = how much they cover what is behind the water.
uniform vec4 shallow_color : source_color = vec4(0.20, 0.62, 0.80, 0.45);
uniform vec4 deep_color : source_color = vec4(0.04, 0.16, 0.36, 0.92);
uniform float depth_falloff = 240.0;
uniform float line_width = 3.0;
uniform float highlight_band = 18.0;
// Self-lit look for lava / acid (adds the shallow color on top). 0 = off.
uniform float glow : hint_range(0.0, 2.0) = 0.0;

group_uniforms refraction;
uniform sampler2D noise_texture : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float refraction_strength : hint_range(0.0, 20.0) = 5.0;
uniform float rays_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec4 rays_color : source_color = vec4(0.80, 0.95, 1.0, 1.0);

group_uniforms style;
uniform float pixel_size : hint_range(0.0, 16.0, 1.0) = 0.0;
uniform float color_steps : hint_range(0.0, 8.0, 1.0) = 0.0;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

float quant(float x, float steps) {
	return steps > 0.5 ? floor(x * steps + 0.5) / steps : x;
}

void fragment() {
	float t = game_time;
	vec2 p = v_local;
	bool pix = pixel_size > 0.5;
	if (pix) {
		p = (floor(p / pixel_size) + 0.5) * pixel_size;
	}
	float x = p.x;
	float wave = wave_height * (0.6 * sin(x / wave_length * 6.2831853 + t * wave_speed * 1.9)
			+ 0.4 * sin(x / (wave_length * 0.43) * 6.2831853 - t * wave_speed * 2.7));
	float spring = 0.0;
	wave += weather_wind*sin(x*0.083-t*4.0)*0.7+weather_rain*sin(x*0.31+t*7.0)*0.22;
	if (spring_count > 1) {
		float fi = clamp(x / spring_spacing, 0.0, float(spring_count - 1));
		int i0 = int(floor(fi));
		int i1 = min(i0 + 1, spring_count - 1);
		spring = mix(springs[i0], springs[i1], fract(fi));
	}
	float sy = surface_offset - wave - spring;
	if (pix) {
		sy = floor(sy / pixel_size + 0.5) * pixel_size;
	}
	float d = p.y - sy;
	float a = pix ? step(0.0, d) : clamp(d + 0.5, 0.0, 1.0);
	if (a <= 0.0) {
		discard;
	}
	vec2 off = vec2(sin(p.y * 0.07 + t * 2.1), cos(p.x * 0.05 + t * 1.7)) * refraction_strength * SCREEN_PIXEL_SIZE;
	vec3 bg = textureLod(screen_texture, SCREEN_UV + off * smoothstep(0.0, 12.0, d), 0.0).rgb;
	float k = quant(smoothstep(0.0, depth_falloff, d), color_steps);
	vec4 wc = mix(shallow_color, deep_color, k);
	vec3 col = mix(bg, wc.rgb, wc.a);
	col += shallow_color.rgb * glow * (1.0 - k * 0.6);

	float u = (p.x + p.y * 0.45) / 900.0;
	float r1 = texture(noise_texture, vec2(u * 3.0 + t * 0.01, t * 0.015)).r;
	float r2 = texture(noise_texture, vec2(u * 7.0 - t * 0.013, 0.5 + t * 0.011)).g;
	float rays = smoothstep(0.55, 0.85, r1 * 0.6 + r2 * 0.4) * (1.0 - smoothstep(0.0, depth_falloff * 0.9, d));
	rays = quant(rays, color_steps);
	col += rays_color.rgb * rays * rays_strength;

	float line = pix ? step(d, line_width) : 1.0 - smoothstep(line_width - 0.75, line_width + 0.75, d);
	float band = quant(1.0 - smoothstep(0.0, highlight_band, d), color_steps) * 0.3;
	col = mix(col, surface_color.rgb, clamp(max(line, band) * surface_color.a, 0.0, 1.0));
	float rain_ripple = pow(max(0.0,sin(x*0.19+sin(floor(x/17.0)*21.3)*8.0-t*5.5)),12.0);
	col += surface_color.rgb*rain_ripple*weather_rain*exp(-max(d,0.0)*0.34)*0.12;
	COLOR = vec4(col, a);
}
