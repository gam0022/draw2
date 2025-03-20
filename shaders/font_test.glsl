#version 460 core

#pragma include "shaders/_common.glsl"

void main() {
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    vec2 uv = uv0;
    vec3 col = vec3(0, 0, 0);

    initBeat();

    SetAspect(resolution.xy, 20, true, true);
    SetAlign(Align_Left_Bottom);
    SetFontName(NAME_ORBITRON);
    SetFontStyle(STYLE_NORMAL);
    Stack_Char(C_B);
    Stack_Char(C_P);
    Stack_Char(C_M);
    Stack_Char(C_colon);
    col += Render_Char(uv);
    col += Print_Number(uv, bpm, 1, 3);

    uv = uv0;
    SetAspect(resolution.xy, 5, true, true);
    SetAlign(Align_Center_Center);
    SetFontName(NAME_RECEIPT);
    SetFontStyle(STYLE_NORMAL);
    Stack_Char(C_G);
    Stack_Char(C_A);
    Stack_Char(C_M);
    Stack_Char(C_0);
    Stack_Char(C_0);
    Stack_Char(C_2);
    Stack_Char(C_2);
    col += Render_Char(uv);

    outColor = vec4(col, 1);
}