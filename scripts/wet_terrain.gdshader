shader_type canvas_item;

uniform sampler2D roof_map : filter_nearest, repeat_disable;
uniform float world_width = 12800.0;
uniform float surface_y = 600.0;
uniform float wetness = 0.5;
uniform float clock = 0.0;
varying vec2 world;
varying vec4 tint;

void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;tint=COLOR;}
void fragment(){
	vec4 source=texture(TEXTURE,UV)*tint;
	vec4 data=texture(roof_map,vec2(clamp(world.x/world_width,0.0,1.0),0.25));
	float top=(data.r*65280.0+data.g*255.0)/65535.0*4000.0-1400.0;
	float exposed=(1.0-smoothstep(1.0,4.0,abs(top-surface_y)))*data.b;
	float w=wetness*exposed;
	float depth=max(0.0,world.y-surface_y);
	float glint=pow(max(0.0,sin(world.x*0.037+sin(clock*0.33)*0.15)),14.0);
	vec3 col=source.rgb*(1.0-w*0.14);
	col+=vec3(0.26,0.34,0.39)*glint*w*exp(-depth*0.42)*0.34;
	COLOR=vec4(col,source.a);
}
