#version 460 core

#pragma include "shaders/_common.glsl"

void main() {
    initBeat();

    vec2 uv0 = gl_FragCoord.xy / resolution.xy;

    vec4 col_prev = texture(composite, uv0);
    vec4 col_2d = texture(scene2d, uv0);
    vec4 col_3d = texture(scene3d, uv0);

    vec3 col = mix(col_2d.rgb, col_3d.rgb, slider_scene3d);

    if (int(button_tscube_scene.w) % 2 == 1) {
        col = texture(transcendental_cube, uv0).rgb;
    }

    if (int(button_ps_kick.w) % 2 == 1) {
        col += kick;
    }

    col = mix(col, col_prev.rgb, slider_motion_blur);

    outColor = vec4(col, 1);
}