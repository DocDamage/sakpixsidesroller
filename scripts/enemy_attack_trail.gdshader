shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0,0.78,0.46,1.0);
void fragment() {
	vec4 source = texture(TEXTURE,UV);
	float core = smoothstep(0.75,1.0,min(source.r,min(source.g,source.b)));
	COLOR = vec4(mix(tint.rgb,vec3(1.0),core*0.75),source.a*tint.a);
}
