#version 460 core

#pragma include "shaders/_common.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec4 col_2d = texture(scene2d, uv);
    vec4 col_3d = texture(scene3d, uv);

    vec3 col = mix(col_2d.rgb, col_3d.rgb, slider_scene3d);

    if (int(buttons[20].w) % 2 == 1) {
        col = texture(transcendental_cube, uv).rgb;
    }

    // col = texture(font_test, uv).rgb;

    outColor = vec4(col, 1);
}