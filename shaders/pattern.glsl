#version 460 core

#pragma include "./shaders/common.glsl"

float sdBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void main() {
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    vec4 prevColor = texture(pattern, uv0);

    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.x;

    initBeat();

    vec3 col = vec3(0);

    vec2 p = uv;

    rot(p, TAU / 8.);

    float a = 10;

    p *= a;
    vec2 grid = floor(p);

    p = mod(p, 1) - 0.5;

    col += sdBox(p, vec2(0.4 * saturate(cos(beat * TAU - (dot(abs(grid), vec2(0.1))))))) < 0.0 ? vec3(1) : vec3(0.0);

    // motion blur
    col = mix(prevColor.rgb, col, slider_motion_blur);

    outColor = vec4(col, 1);
}