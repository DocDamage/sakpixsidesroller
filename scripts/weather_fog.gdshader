shader_type canvas_item;
render_mode unshaded;

uniform sampler2D roof_map : filter_nearest, repeat_disable;
uniform float world_width = 12800.0;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 viewport_size = vec2(1280.0,720.0);
uniform float clock = 0.0;
uniform float fog = 0.3;
uniform float wind = 0.4;
uniform float flash = 0.0;
uniform vec4 fog_color : source_color = vec4(0.37,0.49,0.53,1.0);

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0)),f.x),f.y);
}
float height_of(vec4 d){return (d.r*65280.0+d.g*255.0)/65535.0*4000.0-1400.0;}
void fragment(){
	vec2 world=camera_origin+UV*viewport_size;
	vec4 data=texture(roof_map,vec2(clamp(world.x/world_width,0.0,1.0),0.75));
	float floor_y=height_of(data);
	vec2 p=world/vec2(500.0,90.0)-vec2(clock*(0.018+wind*0.025),clock*0.006);
	float n=noise(p)*0.63+noise(p*2.13+7.0)*0.27+noise(p*4.3)*0.10;
	float ground=exp(-pow((world.y-(floor_y-65.0))/130.0,2.0));
	float wisps=smoothstep(0.28,0.72,n);
	float alpha=fog*(0.025+ground*wisps*0.34);
	vec3 col=mix(fog_color.rgb,vec3(0.69,0.78,0.93),flash*2.0);
	alpha=clamp(alpha+flash*0.055,0.0,0.23);
	COLOR=vec4(col,alpha);
}
