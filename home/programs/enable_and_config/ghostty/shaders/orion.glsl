// orion elenzil 20190521 - Ghostty Optimized Version
const float PI = 3.14159265359;
const float TAU = PI * 2.0;

// 性能提醒：AA（抗锯齿）倍数。
// 1.0 性能最好，2.0 画面更细腻。如果键盘断连，请务必保持 1.0。
#define AA 1.0

vec2 complexMul(in vec2 A, in vec2 B) {
    return vec2((A.x * B.x) - (A.y * B.y), (A.x * B.y) + (A.y * B.x));
}

vec3 hsv2rgb(in vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

struct POI {
    vec2 center;
    float range;
    float maxIter;
};

float mandelEscapeIters(in vec2 C, in float maxIter, in vec2 ocOff, out float cycleLength1, out float cycleLength2) {
    vec2 Z = C;
    vec2 orbitCenter1 = 0.3 * vec2(cos(iTime * 1.00), sin(iTime * 1.00));
    vec2 orbitCenter2 = orbitCenter1 / 0.3 * 0.2;
    orbitCenter1 += ocOff;
    orbitCenter2 += ocOff;
    cycleLength1 = 0.0;
    cycleLength2 = 0.0;
    for (float n = 0.0; n < maxIter; ++n) {
        Z = complexMul(Z, Z) + C;
        if (cycleLength1 == 0.0 && abs(1.0 - length(Z - orbitCenter1)) < 0.015) {
            cycleLength1 = n;
        }
        if (cycleLength2 == 0.0 && abs(0.2 - length(Z - orbitCenter2)) < 0.01) {
            cycleLength2 = n;
        }
        if (dot(Z, Z) > 4.0) {
            return n;
        }
    }
    return maxIter;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    // 1. 基础坐标与文字采样
    vec2 q = XY / iResolution.xy;
    vec4 txt = texture(iChannel0, q);
    float smallWay = min(iResolution.x, iResolution.y);
    vec2 uv = (XY * 2.0 - iResolution.xy)/smallWay;
    
    // 2. 鼠标/参数初始化
    vec2 ocOff = vec2(0.0);
    const POI poi = POI(vec2(-.600, 0.0000), 1.200, 70.0);
    float rng = poi.range;
    float cycleLength1, cycleLength2;
    vec3 col = vec3(0.0);

    // 3. 碎形迭代计算 (包含 AA)
    for( float m = 0.0; m < AA; ++m) {
    for( float n = 0.0; n < AA; ++n) {
        vec2 C = (uv + vec2(m, n) / (AA * smallWay)) * rng + poi.center;
        float escapeIters = mandelEscapeIters(C, poi.maxIter, ocOff, cycleLength1, cycleLength2);
        float f = escapeIters / poi.maxIter;
        if (escapeIters == poi.maxIter) f = 0.0;
        f = pow(f, 0.6) * 0.82;

        vec3 rgb = vec3(f * 0.2, f * 0.6, f * 1.0);
        if (cycleLength1 > 0.0) rgb += vec3(cos(cycleLength1 / 20.0 * TAU) * 0.2 + 0.3);
        if (cycleLength2 > 0.0) rgb += hsv2rgb(vec3(fract(cycleLength2/ 30.0), 0.9, 0.8));
        col += rgb;
    }}
    col /= (AA * AA);

    // --- 4. 核心：Ghostty 文字混合逻辑 ---
    
    // 计算文字存在感
    float textPresence = clamp(length(txt.rgb) * 2.0, 0.0, 1.0);
    
    // 动态压暗：有文字的地方背景变暗 80%，突出白色文字
    vec3 finalLines = mix(col * 0.6, vec3(0.0), textPresence * 0.8);
    
    // 颜色叠加
    vec3 finalRGB = finalLines + txt.rgb;

    // 动态透明度：背景 0.7 透明，文字区域 1.0 不透明
    float finalAlpha = mix(0.3, 1.0, textPresence);

    RGBA = vec4(finalRGB, finalAlpha);
}
