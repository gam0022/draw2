#version 440

#pragma include "shaders/_common.glsl"

float brightness(vec3 c) { return max(max(c.r, c.g), c.b); }

void main() {
    float bloom_thresshold = 1.05;
    float softKnee = 0.5;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 color = texture(post_layer1, uv);
    vec3 m = color.rgb;
    float br = brightness(m);

    float knee = bloom_thresshold * softKnee + 1e-5;
    vec3 curve = vec3(bloom_thresshold - knee, knee * 2.0, 0.25 / knee);
    float rq = clamp(br - curve.x, 0.0, curve.y);
    rq = curve.z * rq * rq;

    m *= max(rq, br - bloom_thresshold) / max(br, 1e-5);
    m = max(m, vec3(0.0));

    outColor = vec4(m, color.a);
}