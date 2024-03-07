precision highp float;
#define PI 3.14159265

// Uniforms
uniform float time;
uniform vec2 viewport;
uniform bool speedlines;

// Constants
const float star_number = 20.0;
const float star_reach = 15.0;
const float star_sharpness = 0.1;
const float star_speed = 3000.0;
const float star_trail_length = 25.0;
const float star_trail_width = 2.5;

// Interpolation
varying vec2 f_position;

float rand(float seed) {
    return fract(sin(seed) * 43768.5453);
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float stacked_noise(vec2 seed) {
    float result = 0.0;
    float frequency = 1.0;

    for (int i=0; i<5; i++) { 
        result += noise(seed * frequency) / frequency;
        frequency *= 2.0;
    }

    return result;
}

vec2 rand_star(float index) {
    return vec2(
        rand(index) * viewport.x,
        rand(index + star_number) * viewport.y
    );
}

vec2 spiral(float radius) {
    float theta = log(radius);
    return vec2(
        radius * cos(theta),
        radius * sin(theta)
    );
}

float distance_point_to_line_segment_squared(vec2 P, vec2 A, vec2 B) {
    vec2 AB = B - A;
    float t = dot(P - A, AB) / dot(AB, AB);
    t = clamp(t, 0.0, 1.0);
    vec2 projection = A + t * AB;
    return dot(P - projection, P - projection);
}

float point_in_triangle(vec2 P, vec2 A, vec2 B, vec2 C) {
    vec2 v0 = C - A;
    vec2 v1 = B - A;
    vec2 v2 = P - A;

    float dot00 = dot(v0, v0);
    float dot01 = dot(v0, v1);
    float dot02 = dot(v0, v2);
    float dot11 = dot(v1, v1);
    float dot12 = dot(v1, v2);

    float invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    float v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    if (u >= 0.0 && v >= 0.0 && u + v <= 1.0)
        return 1.0; // Inside triangle
    else
        return 0.0; // Outside triangle
}

float distance_point_to_triangle(vec2 P, vec2 A, vec2 B, vec2 C) {
    if (point_in_triangle(P, A, B, C) > 0.0)
        return 0.0; // Point is inside the triangle

    float dist_PA_squared = dot(P - A, P - A);
    float dist_PB_squared = dot(P - B, P - B);
    float dist_PC_squared = dot(P - C, P - C);

    float dist_edge_AB_squared = distance_point_to_line_segment_squared(P, A, B);
    float dist_edge_BC_squared = distance_point_to_line_segment_squared(P, B, C);
    float dist_edge_CA_squared = distance_point_to_line_segment_squared(P, C, A);

    return sqrt(min(dist_PA_squared, min(dist_PB_squared, min(dist_PC_squared, min(dist_edge_AB_squared, min(dist_edge_BC_squared, dist_edge_CA_squared))))));
}

void main() {
    vec2 pixel_position = gl_FragCoord.xy;
    float background_noise = stacked_noise(f_position - spiral(2.0 * time + 1.0)) + 0.75;
    vec3 pixel_color = vec3(0.0078, 0.0941, 0.1882) * background_noise;

    vec2 center = viewport / 2.0;
    vec2 pixel_to_center = center - pixel_position;
    float pixel_to_center_distance = length(pixel_to_center);

    float star_trail_len = star_trail_length;
    if (speedlines) {
        star_trail_len *= 1.5;
        float angle = atan(pixel_to_center.x / pixel_to_center.y) + 1.5;
        vec2 sample = vec2(0.25 * cos(angle), 0.25 * sin(angle)) * 200.0;
        float noise_value = noise(sample);
        noise_value = noise_value * noise_value * noise_value;
        vec3 line_color = mix(vec3(0.0), vec3(0.4), noise_value);
        pixel_color += line_color * min(pixel_to_center_distance / 500.0, 1.0);
    }
    
    for (float i = 1.0; i <= star_number; ++i) {

        float iteration = i + floor(time / 0.2) * star_number;
        float current_time = mod(time, 0.2);

        vec2 star_position = rand_star(iteration);
        float star_size_mult = (1.5 * rand(iteration + 1.0) + 0.5);
        float star_size = star_size_mult * star_reach;
        float star_angle = rand(iteration + 2.0) * PI;
        float star_time = -rand(iteration + 3.0) / 15.0 + current_time;

        if (star_time < 0.0) {
            continue;
        }

        star_position += normalize(star_position - center) * star_time * star_speed;

        float pixel_to_star = distance(pixel_position, star_position);
        if (pixel_to_star > 500.0) {
            continue;
        }

        star_angle = star_angle + star_time * 11.0;
        vec2 star_direction = pixel_position - star_position;
        float dir_x = star_direction.x;
        float dir_y = star_direction.y;
        float sin_angle = sin(star_angle);
        float cos_angle = cos(star_angle);
        star_direction.x = dir_x * cos_angle - dir_y * sin_angle;
        star_direction.y = dir_x * sin_angle + dir_y * cos_angle;

        vec2 star_distance = abs(star_direction);
        float star_distance_length = length(star_distance);

        float star_core = star_distance_length;
        star_core = star_core * star_core * star_sharpness;
        star_core = max(1.0 - star_core / star_size, 0.0);
        
        float star_shine = sqrt(star_distance.x) * sqrt(star_distance.y);
        star_shine = star_shine * star_shine;
        star_shine = max(1.0 - star_shine / star_size, 0.0);

        vec2 AB = star_position - center;
        vec2 perp = vec2(-AB.y, AB.x);
        perp = normalize(perp);

        float trail_length = star_trail_len * star_size_mult;
        float trail_width = star_trail_width * star_size_mult;

        float trail_range = star_distance_length;
        trail_range = max(1.0 - trail_range / trail_length, 0.0);
        trail_range = trail_range * trail_range;

        vec2 v0 = star_position + perp * trail_width * 0.5;
        vec2 v1 = star_position - perp * trail_width * 0.5;
        vec2 v2 = star_position - normalize(AB) * star_trail_len;

        float star_trail = distance_point_to_triangle(pixel_position, v0, v1, v2);
        star_trail = star_trail * star_trail;
        star_trail = max(1.0 - star_trail / trail_length, 0.0);
        star_trail *= trail_range * 0.75;

        float star_light = (star_core * star_shine + star_trail) * min(star_time * 10.0, 1.0);

        pixel_color += vec3(star_light * 0.8, star_light * 0.75, star_light * 0.7);
    }

    gl_FragColor = vec4(pixel_color, 1.0);
}