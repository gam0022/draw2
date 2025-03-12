#version 460 core

#pragma include "./shaders/common.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec4 patternCol = texture(pattern, uv);
    vec4 raymarchingCol = texture(raymarching, uv);

    vec3 col = mix(patternCol.rgb, raymarchingCol.rgb, uv.x > 0.5 ? 0.0 : 1.0);
    col = patternCol.rgb;

    outColor = vec4(col, 1);
}