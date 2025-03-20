// ターゲットの解像度
uniform vec4 resolution; // vec4(x, y, x/y, y/x)

// ステージのインデックス
// 同じシェーダーを複数回実行する場合に便利かもしれません
uniform int pass_index;

// プログラム起動時からの秒数
uniform float time;

// 前フレームからの経過時間
uniform float time_delta;

// beat == time * BPM / 60
// BPMはコントロールパネルから設定できます。
// uniform float beat;

// コントロールパネルにあるスライダーの値に対応します
uniform float sliders[32];

// コントロールパネルにあるボタンに対応します
// buttons[i] = vec4(intensity, since_last_on, since_last_off, count);
// intensity: NoteOnのvelocityとPolyphonicKeyPressureの値が書き込まれます
// since_last_on: 直近の NoteOn からの経過秒数
// since_last_off: 直近の NoteOff からの経過秒数
// count: NoteOnが何回発行されたかを数え上げる整数値
uniform vec4 buttons[32];

// 32x32x32の乱数テキスチャ。
// パイプラインが読み込まれるたびに再計算されるので
// 　コンパイルなどを走らせるとテキスチャの中身が変わります。
uniform sampler3D noise;

// プログラム開始からのフレーム数
uniform int frame_count;

// オーディオ入力デバイスからの生サンプル.
// r には左チャンネル (モノラルの場合は唯一)　の情報が入ります
// g には右チャンネルの情報が入ります
uniform sampler1D samples;

// 生FFT情報
// r/g は上記と同じく
uniform sampler1D spectrum_raw;

// "いい感じ"なFFT、EQをかけたり音階にゆるく対応しています。
// r/g は上記の同じく
uniform sampler1D spectrum;
uniform sampler1D spectrum_smooth;
uniform sampler1D spectrum_integrated;
uniform sampler1D spectrum_smooth_integrated;

// Bass/Mid/High
uniform vec3 bass;
uniform vec3 bass_smooth;
uniform vec3 bass_integrated;
uniform vec3 bass_smooth_integrated;

uniform vec3 mid;
uniform vec3 mid_smooth;
uniform vec3 mid_integrated;
uniform vec3 mid_smooth_integrated;

uniform vec3 high;
uniform vec3 high_smooth;
uniform vec3 high_integrated;
uniform vec3 high_smooth_integrated;

// 現在の音量, 全サンプルのRMSで計算されてます
// r には左右の平均値、モノラルの場合は音量が入ります
// g には左チャンネルの音量が入ります
// b には右チャンネルの音量が入ります
uniform vec3 volume;
uniform vec3 volume_integrated;
