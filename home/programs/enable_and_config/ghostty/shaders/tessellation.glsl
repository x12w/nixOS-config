// Apollonian Gasket Gasket Fractal with Transparent Cuts - Ghostty Optimized
// inspired by fractalforums.com script

// --- 基础几何参数 ---
const int Iterations = 20; // 迭代次数。如果键盘断连，请将其减小至 10-12
const int pParam = 3;
const int qParam = 3;
const int rParam = 4;
float U = 1.; float V = 1.; float W = 0.;
const float SRadius = 0.01; // 线条粗细

// --- 颜色调整：仅定义底色区域颜色 ---
// 线条区域将是透明的，不需要颜色。
// 底色：极深灰 (用于非文字区域)
const vec3 backGroundColor = vec3(0.01, 0.01, 0.01); 

#define PI 3.14159
vec3 nb, nc, p, q, pA, pB, pC;
float spaceType = 0.;
float aaScale = 0.005;

// --- 核心几何函数 ---
float hdott(vec3 a, vec3 b) { return spaceType * dot(a.xy, b.xy) + a.z * b.z; }
float hdots(vec3 a, vec3 b) { return dot(a.xy, b.xy) + spaceType * a.z * b.z; }
float hlengtht(vec3 v) { return sqrt(abs(hdott(v, v))); }
float hlengths(vec3 v) { return sqrt(abs(hdots(v, v))); }
vec3 hnormalizet(vec3 v) { return v * (1. / hlengtht(v)); }

void init() {
    spaceType = float(sign(qParam * rParam + pParam * rParam + pParam * qParam - pParam * qParam * rParam));
    float cospip = cos(PI / float(pParam)), sinpip = sin(PI / float(pParam));
    float cospiq = cos(PI / float(qParam)), cospir = cos(PI / float(rParam)), sinpir = sin(PI / float(rParam));
    float ncsincos = (cospiq + cospip * cospir) / sinpip;
    nb = vec3(-cospip, sinpip, 0.);
    nc = vec3(-cospir, -ncsincos, sqrt(abs((ncsincos + sinpir) * (-ncsincos + sinpir))));
    if (spaceType == 0.) { nc.z = 0.25; }
    pA = vec3(nb.y * nc.z, -nb.x * nc.z, nb.x * nc.y - nb.y * nc.x);
    pB = vec3(0., nc.z, -nc.y); pC = vec3(0., 0., nb.y);
    q = U * pA + V * pB + W * pC; p = hnormalizet(q);
}

vec3 fold(vec3 pos) {
    for (int i = 0; i < Iterations; i++) {
        pos.x = abs(pos.x);
        float t = -2. * min(0., dot(nb, pos)); pos += t * nb * vec3(1., 1., spaceType);
        t = -2. * min(0., dot(nc, pos)); pos += t * nc * vec3(1., 1., spaceType);
    }
    return pos;
}

float DD(float tha, float r) { return tha * (1. + spaceType * r * r) / (1. + spaceType * spaceType * r * tha); }
float dist2Segment(vec3 z, vec3 n, float r) {
    mat2 smat = mat2(vec2(1., -hdots(p, n)), vec2(-hdott(p, n), 1.));
    vec2 v = smat * vec2(hdott(z, p), hdots(z, n)); v.y = min(0., v.y);
    vec3 pmin = hnormalizet(v.x * p + v.y * n);
    float tha = hlengths(pmin - z) / hlengtht(pmin + z);
    return DD((tha - SRadius) / (1. + spaceType * tha * SRadius), r);
}
float dist2Segments(vec3 z, float r) {
    float da = dist2Segment(z, vec3(1., 0., 0.), r); float db = dist2Segment(z, nb, r);
    float dc = dist2Segment(z, nc * vec3(1., 1., spaceType), r);
    return min(min(da, db), dc);
}

// --- 关键修改：提取线条遮罩而非颜色 ---
float computeLineMask(vec2 pos) {
    float r = length(pos);
    vec3 z3 = vec3(2. * pos, 1. - spaceType * r * r) * 1. / (1. + spaceType * r * r);
    if (spaceType == -1. && r >= 1.) return 0.0; //庞加莱盘外部设为底色
    z3 = fold(z3);
    float ds = dist2Segments(z3, r);
    // 返回 1.0 (在线条上，用于切割) 到 0.0 (底色上，用于保留) 的系数
    return smoothstep(1.0, -1.0, ds * 0.5 / aaScale); 
}

// --- 主渲染逻辑 ---
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 qCoord = fragCoord.xy / iResolution.xy;
    const float scaleFactor = 2.1;
    vec2 uv = scaleFactor * (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    aaScale = 0.5 * scaleFactor / iResolution.y;

    // 动画
    U = sin(0.1 * iTime) * 0.5 + 0.5;
    V = sin(0.2 * iTime) * 0.5 + 0.5;
    W = sin(0.4 * iTime) * 0.5 + 0.5;

    init(); 
    
    // 3. 计算几何线条遮罩 (1.0=线条，0.0=背景)
    float lineMask = computeLineMask(uv);

    // 4. 采样终端文字层
    vec4 txt = texture(iChannel0, qCoord);
    
    // 5. 计算文字存在感
    float textPresence = clamp(length(txt.rgb) * 2.5, 0.0, 1.0);

    // --- 核心修改：基于切割逻辑的混合 ---

    // 1. 颜色 (RGB)：
    // 由于线条是透明的，我们只需要处理底色和文字。
    // 在有文字的地方，强制底色变为纯黑 (vec3(0.0))，保护白色文字。
    // 在没文字的地方，显示 backGroundColor。
    vec3 backgroundRGB = mix(backGroundColor, vec3(0.0), textPresence);
    // 叠加文字
    vec3 finalRGB = backgroundRGB + txt.rgb;

    // 2. 透明度 (Alpha)：实现切割的核心
    // 非文字区域的 Alpha 逻辑：
    //   没线条的区域：0.7 (深色半透明底色)
    //   有线条的区域：0.0 (完全透明切口)
    float shaderAlpha = mix(0.7, 0.4, lineMask); 

    // 叠加文字后的 Final Alpha：
    //   有文字区域：强制 1.0 (纯白实心文字)
    //   无文字区域：显示 shaderAlpha (有线条切口的背景)
    float finalAlpha = mix(shaderAlpha, 1.0, textPresence);

    fragColor = vec4(finalRGB, finalAlpha);
}
