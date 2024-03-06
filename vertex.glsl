precision highp float;

attribute vec2 a_position;

varying vec2 f_position;

void main() {
    f_position = a_position;
    gl_Position = vec4(a_position, 0, 1);
}