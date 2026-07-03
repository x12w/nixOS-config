// Ghostty Shader: Dark Transparent Quadtree Background
// Based on: https://www.shadertoy.com/view/lljSDy

#define s(a)       ( sin(a) )
#define rnd(p)     ( .5+.5*s(p+t)*s(p*2.17-t)*s(p*5.7+t) )

// -----------------------------
// 可调参数
// -----------------------------

// 动画速度
#define TIME_SCALE 0.02

// 方块颜色：暗石墨色，不偏淡蓝
#define BASE_COLOR vec3(0.032, 0.036, 0.060)

// 方块透明度范围
#define ALPHA_MIN 0.36
#define ALPHA_MAX 0.86

// 背景先整体压暗
#define BG_DIM_STRENGTH 0.24

// 深色透明 tint，模拟 kitty 风格深色透明底
#define DARK_TINT_COLOR vec3(0.010, 0.012, 0.024)
#define DARK_TINT_STRENGTH 0.54

// 图案增强
#define PATTERN_BOOST 1.75

// 模糊参数
#define MAX_BLUR_RADIUS 14.0
#define BLUR_STRENGTH 2.4

// 雾化强度，别太高，否则会发灰发蓝
#define FROST_STRENGTH 0.34

// 文字保护强度
#define TEXT_PROTECT 3.8

// 深色底 alpha
// 数值越大，整体越不透明、越暗
#define BG_ALPHA 0.66


vec4 blurTerminal(vec2 uv, float amount)
{
    vec2 px = 1.0 / iResolution.xy;

    float r = amount * MAX_BLUR_RADIUS * BLUR_STRENGTH;

    vec4 col = texture(iChannel0, uv) * 0.16;

    col += texture(iChannel0, uv + vec2( r, 0.0) * px) * 0.08;
    col += texture(iChannel0, uv + vec2(-r, 0.0) * px) * 0.08;
    col += texture(iChannel0, uv + vec2(0.0,  r) * px) * 0.08;
    col += texture(iChannel0, uv + vec2(0.0, -r) * px) * 0.08;

    col += texture(iChannel0, uv + vec2( r,  r) * px) * 0.07;
    col += texture(iChannel0, uv + vec2(-r,  r) * px) * 0.07;
    col += texture(iChannel0, uv + vec2( r, -r) * px) * 0.07;
    col += texture(iChannel0, uv + vec2(-r, -r) * px) * 0.07;

    col += texture(iChannel0, uv + vec2( r * 2.0, 0.0) * px) * 0.045;
    col += texture(iChannel0, uv + vec2(-r * 2.0, 0.0) * px) * 0.045;
    col += texture(iChannel0, uv + vec2(0.0,  r * 2.0) * px) * 0.045;
    col += texture(iChannel0, uv + vec2(0.0, -r * 2.0) * px) * 0.045;

    col += texture(iChannel0, uv + vec2( r * 3.5,  r * 1.5) * px) * 0.025;
    col += texture(iChannel0, uv + vec2(-r * 3.5,  r * 1.5) * px) * 0.025;
    col += texture(iChannel0, uv + vec2( r * 1.5, -r * 3.5) * px) * 0.025;
    col += texture(iChannel0, uv + vec2(-r * 1.5, -r * 3.5) * px) * 0.025;

    return col;
}


void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    // --- 1. 变量初始化 ---
    float r = 1.0;
    float t = iTime * TIME_SCALE;
    float H = iResolution.y;
    float id = 1.0;

    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 U = fragCoord.xy;

    U /= H;
    U *= 0.5;

    vec3 baseColor = BASE_COLOR;
    float currentAlpha = 0.52;
    bool isLine = false;

    // --- 2. 四叉树迭代 ---
    for (int i = 0; i < 28; i++) {
        vec2 fU = min(U, 1.0 - U);

        // 分割线检测
        if (min(fU.x, fU.y) < 0.3 * r / H) {
            isLine = true;
            break;
        }

        float decision = rnd(id);

        if (decision > 0.7) break;

        vec2 stepU = step(0.5, U);
        id = 4.0 * id + 2.0 * stepU.y + stepU.x;
        U = 2.0 * U - stepU;
        r *= 2.0;

        if (r > H) break;

        currentAlpha = clamp(
            currentAlpha + (decision - 0.5) * 0.22,
            ALPHA_MIN,
            ALPHA_MAX
        );
    }

    // --- 3. 根据透明度计算模糊强度 ---
    float blurAmount = smoothstep(ALPHA_MIN, ALPHA_MAX, currentAlpha);

    // 分割线不显示方块图案，但保留深色底
    if (isLine) {
        blurAmount = 0.0;
    }

    // --- 4. 采样终端纹理 ---
    vec4 txtSharp = texture(iChannel0, q);
    vec4 txtBlur  = blurTerminal(q, blurAmount);

    // 文字检测：亮度越高越可能是文字
    float textPresence = clamp(length(txtSharp.rgb) * TEXT_PROTECT, 0.0, 1.0);
    float nonText = 1.0 - textPresence;

    // 非文字区域使用模糊，文字区域使用清晰纹理
    vec3 terminalRGB = mix(txtBlur.rgb, txtSharp.rgb, textPresence);

    // --------------------------------------------------
    // 5. kitty 风格深色透明底
    // --------------------------------------------------

    // 先压暗背景
    terminalRGB *= 1.0 - BG_DIM_STRENGTH * nonText;

    // 再叠深色 tint，让背景统一变成深色透明感
    terminalRGB = mix(
        terminalRGB,
        DARK_TINT_COLOR,
        DARK_TINT_STRENGTH * nonText
    );

    // --------------------------------------------------
    // 6. 轻微雾化，用于放大模糊区域差异
    // --------------------------------------------------
    vec3 frostColor = vec3(0.070, 0.060, 0.095);
    float frostMask = blurAmount * FROST_STRENGTH * nonText;

    terminalRGB = mix(terminalRGB, frostColor, frostMask);

    // --------------------------------------------------
    // 7. 四叉树方块图案增强
    // --------------------------------------------------
    float patternMask = currentAlpha * PATTERN_BOOST;

    if (isLine) {
        patternMask = 0.0;
    }

    patternMask = clamp(patternMask, 0.0, 1.0);

    vec3 patternColor = baseColor;

    vec3 mixedRGB = mix(
        terminalRGB,
        patternColor,
        patternMask * 0.74
    );

    // 给方块一点点可见度增强，但保持暗色
    if (!isLine) {
        mixedRGB += baseColor * blurAmount * 0.16 * nonText;
    }

    // 文字区域强制回到清晰文字，避免被暗化/雾化/图案污染
    mixedRGB = mix(mixedRGB, txtSharp.rgb, textPresence);

    // --------------------------------------------------
    // 8. Alpha 合成
    // --------------------------------------------------

    // 关键：
    // 分割线区域也保留 BG_ALPHA，不再完全透明漏出桌面。
    // 非分割线区域使用四叉树 alpha，但最低不低于 BG_ALPHA。
    float finalAlpha;

    if (isLine) {
        finalAlpha = BG_ALPHA;
    } else {
        finalAlpha = max(currentAlpha, BG_ALPHA);
    }

    // 文字区域保持不透明
    finalAlpha = mix(finalAlpha, 1.0, textPresence);

    fragColor = vec4(mixedRGB, finalAlpha);
}
