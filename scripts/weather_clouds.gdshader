shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float cover = 0.5;
uniform float wind = 0.4;
uniform float flash = 0.0;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 viewport_size = vec2(1280.0,720.0);
uniform vec4 cloud_color : source_color = vec4(0.13,0.18,0.24,1.0);

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0)),f.x),f.y);
}
float fbm(vec2 p) {
	float n=0.0; float a=0.5;
	for(int i=0;i<4;i++){ n+=noise(p)*a; p=p*2.03+vec2(9.3,4.7); a*=0.5; }
	return n;
}
void fragment() {
	vec2 p=(UV*viewport_size+camera_origin*vec2(0.12,0.025))/vec2(560.0,190.0);
	p.x-=clock*(0.009+wind*0.018);
	float body=fbm(p);
	float detail=fbm(p*2.7+vec2(clock*0.006,0.0));
	float clouds=smoothstep(0.62-cover*0.32,0.82-cover*0.28,body+detail*0.18);
	float altitude=1.0-smoothstep(0.40,0.92,UV.y);
	float alpha=clamp((clouds*0.69+cover*0.10)*cover*altitude,0.0,0.76);
	vec3 color=mix(cloud_color.rgb,cloud_color.rgb*1.65,smoothstep(0.32,0.7,body));
	color=mix(color,vec3(0.68,0.77,0.91),flash*2.0);
	COLOR=vec4(color,alpha);
}
