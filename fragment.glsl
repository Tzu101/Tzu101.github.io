precision highp float;

// Uniforms
uniform float time;
uniform vec2 viewport;

// Constants
const float star_number = 1.0;
const float star_reach = 1500.0;

void main() {
    vec3 pixel_color = vec3(0.0078, 0.0941, 0.1882);
    /*vec2 pixel_position = gl_FragCoord.xy;

    for (float i = 0.0; i < star_number; ++i) {
        vec2 star_position = viewport / 2.0;

        vec2 star_direction = pixel_position - star_position;

        float star_core = length(star_direction);
        star_core = star_core * star_core;
        star_core = max(1.0 - star_core / star_reach, 0.0);
        
        float star_shine = abs(star_direction.x * star_direction.y);
        star_shine = star_shine * star_shine;
        star_shine = max(1.0 - star_shine / star_reach, 0.0);

        float star_light = star_core * 0.5 + star_shine * 0.5;

        pixel_color += vec3(star_light * 0.8, star_light * 0.6, 0.0);
    }*/

    gl_FragColor = vec4(pixel_color, 1.0);
}