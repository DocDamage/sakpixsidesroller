shader_type canvas_item;
uniform float clock = 0.0;
uniform float wind_force = 1.0;

void vertex() {
	float tip = 1.0 - UV.y;
	float phase = MODEL_MATRIX[3].x * 0.008;
	VERTEX.x += (sin(clock * 1.5 + phase + UV.y * 1.3)+sin(clock*0.37+phase)*0.25) * tip * tip * 0.55 * wind_force;
}
