#version 440

#pragma include "shaders/_common.glsl"

void main()
{
    float ins = 1;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 col = texture(composite, uv).rgb;
    vec3 bloom_blur = texture(post_bloom_blur, uv).rgb;
    col = col + bloom_blur * ins;
    outColor = vec4(col, 1);
}