shader_type canvas_item;

uniform float wave_speed = 20.0;
uniform float wave_amplitude = 10.0;
uniform float wave_frequency = 20.0;
uniform vec4 water_color : source_color = vec4(0.0, 0.4, 0.8, 1.0);

void fragment() {
    vec2 uv = UV;
    uv.y += sin((TIME * wave_speed) + (UV.x * wave_frequency)) * (wave_amplitude / 100.0);
    
    // Optional shimmering effect
    float shimmer = 0.05 * sin(TIME * 5.0 + UV.y * 20.0);
    
    COLOR = water_color + vec4(vec3(shimmer), 0.0);
}
