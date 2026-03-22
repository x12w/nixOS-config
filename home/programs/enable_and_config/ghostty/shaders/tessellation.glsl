const int Iterations = 20;
const int pParam = 3;
const int qParam = 3;
const int rParam = 4;
float U = 1.; float V = 1.; float W = 0.;
const float SRadius = 0.01;
const vec3 segColor = vec3(1.0, 1.0, 1.0); // 白色线条
const vec3 backGroundColor = vec3(0.02, 0.02, 0.02); // 极深背景

#define PI 3.14159
vec3 nb, nc, p, q, pA, pB, pC;
float spaceType = 0.;
float aaScale = 0.005;

// --- 几何函数 (保持原样) ---
float hdott(vec3 a, vec3 b) { return spaceType * dot(a.xy, b.xy) + a.z * b.z; }
float hdots(vec3 a, vec3 b) { return dot(a.xy, b.xy) + spaceType * a.z * b.z; }
float hlengtht(vec3 v) { return sqrt(abs(hdott(v, v))); }
float hlengths(vec3 v) { return sqrt(abs(hdots(v, v))); }
vec3 hnormalizet(vec3 v) { return v * (1. / hlengtht(v)); }
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

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
vec3 color(vec2 pos) {
    float r = length(pos);
    vec3 z3 = vec3(2. * pos, 1. - spaceType * r * r) * 1. / (1. + spaceType * r * r);
    if (spaceType == -1. && r >= 1.) return backGroundColor;
    z3 = fold(z3);
    float ds = dist2Segments(z3, r);
    return mix(segColor, backGroundColor, smoothstep(-1., 1., ds * 0.5 / aaScale));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 qCoord = fragCoord.xy / iResolution.xy;
    const float scaleFactor = 2.1;
    vec2 uv = scaleFactor * (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    aaScale = 0.5 * scaleFactor / iResolution.y;
    U = sin(0.1*iTime)*.5+.5; V = sin(0.2*iTime)*.5+.5; W = sin(0.4*iTime)*.5+.5;
    init(); 
    vec3 tessCol = color(uv);

    // 采样文字层
    vec4 txt = texture(iChannel0, qCoord);

    // 核心逻辑：差值混合
    // 如果文字(1,1,1)遇到线条(1,1,1)，结果是(0,0,0)黑色
    // 如果文字(1,1,1)遇到背景(0,0,0)，结果是(1,1,1)白色
    vec3 finalRGB = abs(txt.rgb - tessCol * 0.5); 

    fragColor = vec4(finalRGB, 1.0);
}
