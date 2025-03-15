#version 460 core

#pragma include "./shaders/common.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec4 patternCol = texture(pattern, uv);
    vec4 raymarchingCol = texture(raymarching, uv);

    vec3 col = mix(patternCol.rgb, raymarchingCol.rgb, slider_raymarching);

    outColor = vec4(col, 1);
}