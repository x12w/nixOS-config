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

// 方块透明度范围（现在由方块大小驱动，见 mainImage 里的映射）
// 大方块 → 不透明度高（透明度低）→ 接近 ALPHA_MAX（不设满，保留一点通透）
// 小方块 → 不透明度低（透明度高）→ 接近 ALPHA_MIN（最小方块完全透明）
#define ALPHA_MIN 0.0
#define ALPHA_MAX 0.85

// 大小 → 透明度 的曲线指数：
// 1.0 = 线性；<1.0 让大小对比更明显（小方块更快变透明）；>1.0 更平缓
#define SIZE_ALPHA_CURVE 0.6

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

// 双边滤波强度：越大越能阻止文字渗色成重影（按亮度差把文字从模糊里剔除）
#define BILATERAL_STRENGTH 40.0

// 雾化强度，别太高，否则会发灰发蓝
#define FROST_STRENGTH 0.34

// 文字保护强度
#define TEXT_PROTECT 3.8

// 分割线（四叉树边框）的固定不透明度
#define BG_ALPHA 0.55


vec4 blurTerminal(vec2 uv, float amount)
{
    vec2 px = 1.0 / iResolution.xy;

    float r = amount * MAX_BLUR_RADIUS * BLUR_STRENGTH;

    // 中心采样及其亮度，作为双边滤波的参考
    vec4 center = texture(iChannel0, uv);
    float centerLum = length(center.rgb);

    // 采样偏移（单位 r）与基础权重
    vec2  off[17];
    float wgt[17];
    off[0]  = vec2( 0.0,  0.0); wgt[0]  = 0.16;
    off[1]  = vec2( 1.0,  0.0); wgt[1]  = 0.08;
    off[2]  = vec2(-1.0,  0.0); wgt[2]  = 0.08;
    off[3]  = vec2( 0.0,  1.0); wgt[3]  = 0.08;
    off[4]  = vec2( 0.0, -1.0); wgt[4]  = 0.08;
    off[5]  = vec2( 1.0,  1.0); wgt[5]  = 0.07;
    off[6]  = vec2(-1.0,  1.0); wgt[6]  = 0.07;
    off[7]  = vec2( 1.0, -1.0); wgt[7]  = 0.07;
    off[8]  = vec2(-1.0, -1.0); wgt[8]  = 0.07;
    off[9]  = vec2( 2.0,  0.0); wgt[9]  = 0.045;
    off[10] = vec2(-2.0,  0.0); wgt[10] = 0.045;
    off[11] = vec2( 0.0,  2.0); wgt[11] = 0.045;
    off[12] = vec2( 0.0, -2.0); wgt[12] = 0.045;
    off[13] = vec2( 3.5,  1.5); wgt[13] = 0.025;
    off[14] = vec2(-3.5,  1.5); wgt[14] = 0.025;
    off[15] = vec2( 1.5, -3.5); wgt[15] = 0.025;
    off[16] = vec2(-1.5, -3.5); wgt[16] = 0.025;

    vec4 col = vec4(0.0);
    float wsum = 0.0;

    for (int i = 0; i < 17; i++) {
        vec2 suv = uv + off[i] * r * px;
        vec4 s = texture(iChannel0, suv);
        // 与中心亮度差异越大，权重越低：文字（高对比）不再渗进背景
        float dlum = length(s.rgb) - centerLum;
        float bw = 1.0 / (1.0 + dlum * dlum * BILATERAL_STRENGTH);
        float w = wgt[i] * bw;
        col += s * w;
        wsum += w;
    }

    if (wsum > 1e-4) col /= wsum;

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
    }

    // --- 2.5 方块大小 → 透明度映射 ---
    // r 每细分一层翻倍（r = 2^depth），所以 r 越大 = 方块越小。
    // 大方块（r 小）→ 不透明度高（透明度低）→ 接近 ALPHA_MAX
    // 小方块（r 大）→ 不透明度低（透明度高）→ 接近 ALPHA_MIN
    float maxLogR = log2(max(H, 1.0));            // r 最多增长到 H
    float sizeFactor = clamp(log2(r) / maxLogR, 0.0, 1.0); // 0=最大块, 1=最小块
    float currentAlpha = mix(ALPHA_MAX, ALPHA_MIN, pow(sizeFactor, SIZE_ALPHA_CURVE));

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
    // 分割线（边框）固定使用 BG_ALPHA，作为深色网格框架。
    // 方块区域直接用 currentAlpha —— 完全由大小决定透明度，
    // 不再用 BG_ALPHA 兜底，这样「大方块不透明、小方块透明」才看得见。
    float finalAlpha;

    if (isLine) {
        finalAlpha = BG_ALPHA;
    } else {
        finalAlpha = currentAlpha;
    }

    // 文字区域保持不透明
    finalAlpha = mix(finalAlpha, 1.0, textPresence);

    fragColor = vec4(mixedRGB, finalAlpha);
}
