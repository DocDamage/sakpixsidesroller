shader_type canvas_item;
render_mode unshaded;

uniform sampler2D roof_map : filter_nearest, repeat_disable;
uniform float world_width = 12800.0;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 viewport_size = vec2(1280.0,720.0);
uniform float clock = 0.0;
uniform float rain = 0.5;
uniform float wind = 0.4;
uniform vec4 rain_color : source_color = vec4(0.69,0.79,0.86,1.0);

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float height_of(vec4 data){return (data.r*65280.0+data.g*255.0)/65535.0*4000.0-1400.0;}
vec4 roof(vec2 p){return texture(roof_map,vec2(clamp(p.x/world_width,0.0,1.0),0.25));}
float streak(vec2 world,float layer){
	float slope=0.12+wind*0.27;
	vec2 p=vec2(world.x-world.y*slope,world.y);
	p.y-=clock*(340.0+layer*145.0);
	vec2 cell_size=vec2(27.0-layer*4.0,190.0-layer*23.0);
	vec2 id=floor(p/cell_size);
	float seed=hash(id+layer*43.7);
	vec2 local=mod(p,cell_size);
	float x=(0.12+hash(id+19.3)*0.76)*cell_size.x;
	float y=(0.1+hash(id+8.7)*0.7)*cell_size.y;
	float length=8.0+layer*6.0+seed*9.0;
	float dx=(local.x-x)/(0.38+layer*0.22);
	float dy=local.y-y;
	float tip=smoothstep(0.0,2.0,dy)*(1.0-smoothstep(length-3.0,length,dy));
	return exp(-dx*dx*2.0)*tip*step(seed,rain*0.68)*(0.12+layer*0.055);
}
void fragment(){
	vec2 world=camera_origin+UV*viewport_size;
	vec4 data=roof(world);
	float ceiling=height_of(data);
	float sky=1.0-smoothstep(ceiling-1.0,ceiling+2.0,world.y);
	float drops=streak(world,0.0)+streak(world+vec2(83.0,41.0),1.0)+streak(world+vec2(179.0,29.0),2.0);
	float alpha=drops*sky*data.b*step(0.001,rain);
	// Small ground impacts are anchored to the same exposed surface as the rain.
	float cell=floor(world.x/38.0);
	float seed=hash(vec2(cell,31.0));
	float phase=fract(clock*(1.2+seed*0.7)+seed*17.0);
	float center=(cell+0.18+seed*0.64)*38.0;
	float radius=phase*12.0;
	float dx=abs(world.x-center);
	float dy=world.y-ceiling;
	float ring=exp(-pow((dx-radius)/1.3,2.0))*exp(-pow((dy+0.5)/0.8,2.0))*(1.0-phase);
	float splash=exp(-pow((dx-phase*6.0)/0.75,2.0))*exp(-pow((dy+sin(phase*3.14159)*9.0)/1.2,2.0))*(1.0-phase)*step(phase,0.45);
	alpha+=(ring*0.23+splash*0.15)*rain*data.b;
	COLOR=vec4(rain_color.rgb,clamp(alpha,0.0,0.5));
}
