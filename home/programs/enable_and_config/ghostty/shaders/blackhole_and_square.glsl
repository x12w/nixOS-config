// Ghostty Shader: Black Hole Lensing + Cutout Horizon Mask + Quadtree
//
// iChannel0: Ghostty terminal text/input layer
//
// 特点：
// - 背景使用 Transparency-Based Quadtree
// - 黑洞外部显示被引力透镜扭曲后的四叉树背景
// - 事件视界区域作为透明蒙版，把 shader 背景层抠掉
// - 事件视界内部不显示黑色
// - 事件视界内部不再嵌套另一层四叉树
// - 不添加吸积盘
// - 不添加光子环
// - 不添加辉光
// - 文字层不被黑洞扭曲
// - 文字区域 alpha 强制保护为 1.0

#define PI 3.141592653589793
#define MAX_STEPS 300

#define RS 1.0
#define CAMERA_DIST 10.0
#define SOURCE_Z 32.0

#define s(a) (sin(a))

float rnd(float p, float t)
{
    return 0.5 + 0.5 * s(p + t) * s(p * 2.17 - t) * s(p * 5.7 + t);
}

// ------------------------------------------------------------
// Quadtree background
// ------------------------------------------------------------

vec4 quadtreeRaw(vec2 fragCoord)
{
    float r = 1.0;
    float t = iTime * 0.02;
    float H = iResolution.y;
    float id = 1.0;

    vec2 U = fragCoord.xy;

    U /= H;
    U *= 0.5;

    // 固定偏移，让主要显示区域落在四叉树内部。
    // 不使用 fract，避免重复铺砖产生马赛克感。
    U += vec2(0.20, 0.18);

    vec3 baseColor = vec3(0.01, 0.02, 0.05);
    float currentAlpha = 0.3;
    bool isLine = false;

    for (int i = 0; i < 28; i++)
    {
        vec2 fU = min(U, 1.0 - U);

        if (min(fU.x, fU.y) < 0.42 * r / H)
        {
            isLine = true;
            break;
        }

        float decision = rnd(id, t);

        if (decision > 0.7)
        {
            break;
        }

        vec2 stepU = step(0.5, U);

        id = 4.0 * id + 2.0 * stepU.y + stepU.x;
        U = 2.0 * U - stepU;
        r *= 2.0;

        if (r > H)
        {
            break;
        }

        currentAlpha = clamp(
            currentAlpha + (decision - 0.5) * 0.2,
            0.1,
            0.7
        );
    }

    if (isLine)
    {
        return vec4(baseColor * 0.5, 0.0);
    }

    return vec4(baseColor, currentAlpha);
}

// ------------------------------------------------------------
// Camera
// ------------------------------------------------------------

void makeCamera(
    in vec2 uv,
    out vec3 ro,
    out vec3 rd
)
{
    ro = vec3(0.0, 0.0, -CAMERA_DIST);

    vec3 target = vec3(0.0, 0.0, 0.0);

    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(right, forward));

    float fov = 1.18;

    rd = normalize(forward + uv.x * right * fov + uv.y * up * fov);
}

// ------------------------------------------------------------
// Black hole position
// ------------------------------------------------------------
//
// Ghostty 通常没有鼠标输入，所以默认黑洞固定在屏幕中心。
// 如果你的环境支持 iMouse，可以打开注释里的版本。

vec3 getBlackHolePosition()
{
    return vec3(0.0, 0.0, 0.0);

    /*
    vec2 mouse = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

    if (iMouse.z <= 0.0)
    {
        mouse = vec2(0.0);
    }

    float screenToWorld = CAMERA_DIST * 1.18;

    return vec3(
        -mouse.x * screenToWorld,
         mouse.y * screenToWorld,
         0.0
    );
    */
}

// ------------------------------------------------------------
// Schwarzschild-like ray bending to source plane
// ------------------------------------------------------------

bool traceToSourcePlane(
    inout vec3 pos,
    inout vec3 dir,
    in vec3 blackHolePos,
    out vec3 hitPos
)
{
    vec3 lastPos = pos;

    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec3 rel = pos - blackHolePos;
        float r = length(rel);

        // 进入事件视界：
        // 返回 false，但 mainImage 里不会画黑色，
        // 而是用透明蒙版把背景层抠掉。
        if (r <= RS)
        {
            return false;
        }

        // 穿过背景平面，计算精确交点
        if (lastPos.z < SOURCE_Z && pos.z >= SOURCE_Z)
        {
            float k = (SOURCE_Z - lastPos.z) / max(pos.z - lastPos.z, 1e-6);
            hitPos = mix(lastPos, pos, k);
            return true;
        }

        lastPos = pos;

        float dt = 0.030 + 0.28 * smoothstep(1.0, 24.0, r);

        vec3 relDir = -rel / max(r, 1e-6);

        // 只改变光线方向，不改变速度模长
        vec3 perpendicular = relDir - dir * dot(relDir, dir);

        // Schwarzschild-like 弱场偏折近似
        float curvature = 0.62 * RS / max(r * r, 1e-5);

        // 靠近光子球只增强偏折，不额外画光环
        float photonSphere = 1.5 * RS;
        float nearPhotonSphere = exp(-abs(r - photonSphere) * 1.8);
        float boost = 1.0 + 0.45 * nearPhotonSphere;

        dir = normalize(dir + perpendicular * curvature * boost * dt);

        pos += dir * dt;
    }

    // 万一没有在步进中穿过背景平面，用当前方向外推
    float k = (SOURCE_Z - pos.z) / max(dir.z, 1e-6);
    hitPos = pos + dir * k;

    return true;
}

// ------------------------------------------------------------
// Source plane -> quadtree fragCoord
// ------------------------------------------------------------

vec2 sourcePlaneToFragCoord(vec3 hitPos)
{
    float fov = 1.18;
    float distance = SOURCE_Z + CAMERA_DIST;

    vec2 uv = hitPos.xy / max(distance * fov, 1e-6);

    vec2 fragCoord = uv * iResolution.y + 0.5 * iResolution.xy;

    return fragCoord;
}

// ------------------------------------------------------------
// Screen-space horizon cutout mask
// ------------------------------------------------------------
//
// 这个 mask 只负责把背景层抠掉。
// 它不画黑色，也不画另一层背景。

float horizonCutoutMask(vec2 screenUv, vec3 blackHolePos)
{
    float fov = 1.18;

    // 当前相机固定在 z = -CAMERA_DIST，黑洞在 z = 0。
    // 把黑洞世界坐标近似投影回屏幕坐标。
    vec2 centerUv = -blackHolePos.xy / (CAMERA_DIST * fov);

    float d = length(screenUv - centerUv);

    // 屏幕空间事件视界半径近似。
    float horizonRadius = RS / (CAMERA_DIST * fov);

    // 稍微放大一点点，让抠出的区域更接近视觉上的黑洞阴影。
    horizonRadius *= 1.08;

    // 软边缘透明蒙版：
    // 中心 mask = 1，完全抠掉；
    // 外部 mask = 0，正常显示引力透镜背景。
    float mask = 1.0 - smoothstep(
        horizonRadius * 0.82,
        horizonRadius * 1.08,
        d
    );

    return mask;
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    vec2 q = fragCoord.xy / iResolution.xy;

    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    vec3 ro;
    vec3 rd;

    makeCamera(uv, ro, rd);

    vec3 blackHolePos = getBlackHolePosition();

    vec3 pos = ro;
    vec3 dir = rd;

    vec3 hitPos;

    bool hitBackground = traceToSourcePlane(
        pos,
        dir,
        blackHolePos,
        hitPos
    );

    vec4 shaderOut;

    if (hitBackground)
    {
        vec2 bgCoord = sourcePlaneToFragCoord(hitPos);

        // 正常区域：
        // 显示被引力透镜扭曲后的四叉树背景。
        shaderOut = quadtreeRaw(bgCoord);
    }
    else
    {
        // 进入事件视界的区域：
        // 先不给它画黑，也不给它画另一层背景。
        // 后面统一由 horizonCutoutMask 把 alpha 抠掉。
        shaderOut = vec4(0.0);
    }

    // 透明蒙版：
    // 把黑洞中心区域从 shader 背景层中抠掉。
    float cutout = horizonCutoutMask(uv, blackHolePos);

    shaderOut.a *= 1.0 - cutout;

    // RGB 在 alpha = 0 时理论上不重要。
    // 为了避免某些混合模式下有残色，也一起压低。
    shaderOut.rgb *= 1.0 - cutout;

    // --------------------------------------------------------
    // Ghostty text layer sampling and protection
    // --------------------------------------------------------

    vec4 txt = texture(iChannel0, q);

    // Screen blend，保证文字不会被深色背景压暗
    vec3 mixedRGB = 1.0 - (1.0 - shaderOut.rgb) * (1.0 - txt.rgb);

    // 文字保护：
    // 即使黑洞 cutout 区域经过文字，也不让文字被挖掉。
    float textPresence = clamp(length(txt.rgb) * 3.0, 0.0, 1.0);
    float finalAlpha = mix(shaderOut.a, 1.0, textPresence);

    fragColor = vec4(mixedRGB, finalAlpha);
}
