shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform sampler2D bed_map : filter_nearest, repeat_disable;
uniform float world_surface_y=1320.0;
uniform float game_time=0.0;
uniform float width=1200.0;
uniform float depth=360.0;
uniform float current=35.0;
uniform float weather_rain=0.0;
uniform float weather_wind=0.0;
uniform vec4 ripples[4];
uniform vec4 shallow_color : source_color=vec4(0.12,0.31,0.34,0.29);
uniform vec4 deep_color : source_color=vec4(0.025,0.07,0.12,0.58);
varying vec2 local;

void vertex(){local=VERTEX;}
float hash(float x){return fract(sin(x*127.1)*43758.5453);}
void fragment(){
	float t=game_time;
	float x=local.x;
	float wave=sin(x*0.018+t*1.2)*2.1+sin(x*0.041-t*1.8)*1.15+sin(x*0.11+t*2.8)*0.35;
	wave+=sin(x*0.22+t*5.0)*weather_rain*0.35+weather_wind*sin(x*0.063-t*3.0);
	float wake=0.0;
	for(int i=0;i<4;i++){
		float distance=abs(x-ripples[i].x);
		float age=ripples[i].y;
		float envelope=exp(-abs(distance-age*95.0)*0.035)*exp(-age*1.6);
		wave+=sin(distance*0.105-age*10.0)*envelope*ripples[i].z;
		wake+=envelope*min(ripples[i].z*0.045,0.3);
	}
	float d=local.y-12.0-wave;
	if(d<0.0){discard;}
	vec4 bed=texture(bed_map,vec2(clamp(x/width,0.0,1.0),0.5));
	float bed_y=(bed.r*65280.0+bed.g*255.0)/65535.0*4000.0-1400.0;
	if(local.y-12.0>bed_y-world_surface_y){discard;}
	vec2 px=SCREEN_PIXEL_SIZE;
	vec2 normal=vec2(cos(x*0.018+t*1.2)*0.9+cos(x*0.041-t*1.8)*0.6,sin(x*0.035-t));
	vec2 refracted=SCREEN_UV+normal*px*vec2(2.2,1.1)*smoothstep(0.0,25.0,d);
	vec3 behind=texture(screen_texture,refracted).rgb;
	vec2 mirror=SCREEN_UV-vec2(0.0,2.0*d*px.y);
	mirror+=vec2(normal.x*3.0*px.x,sin(x*0.08-t*2.2)*px.y);
	vec3 reflection=texture(screen_texture,clamp(mirror,vec2(0.001),vec2(0.999))).rgb;
	float absorption=1.0-exp(-d/165.0);
	vec4 water=mix(shallow_color,deep_color,absorption);
	vec3 col=mix(behind,water.rgb,water.a);
	float fresnel=0.36*exp(-d/105.0);
	col=mix(col,reflection*vec3(0.72,0.87,0.91),fresnel);
	float flowx=x-t*current;
	float caustic=pow(max(0.0,sin(flowx*0.037+sin(d*0.041+t)*2.0)*sin(flowx*0.019-d*0.053+t*0.7)),8.0);
	col+=vec3(0.10,0.26,0.23)*caustic*0.23*(1.0-absorption);
	float shore=max(exp(-min(x,width-x)/23.0),exp(-max(0.0,bed_y-world_surface_y)/38.0));
	float foam=(1.0-smoothstep(0.0,2.8,d))*(0.3+shore*0.55);
	float rivulet=pow(max(0.0,sin(flowx*0.067+sin(flowx*0.015)*3.0)),18.0)*exp(-d/14.0);
	col=mix(col,vec3(0.65,0.81,0.78),clamp(foam+(rivulet*0.14+wake*0.4)*exp(-d/9.0)+weather_rain*pow(max(0.0,sin(x*0.2-t*6.0)),12.0)*exp(-d/6.0)*0.13,0.0,0.8));
	COLOR=vec4(col,clamp(d*0.75,0.0,1.0));
}
