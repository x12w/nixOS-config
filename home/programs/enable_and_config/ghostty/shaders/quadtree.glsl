// Ghostty Shader: Transparency-Based Quadtree (Glacial Speed)
// Based on: https://www.shadertoy.com/view/lljSDy

#define s(a)       ( sin(a) )
// 极慢速度：0.02 倍速，适合作为安静的代码背景
#define rnd(p)     ( .5+.5*s(p+t)*s(p*2.17-t)*s(p*5.7+t) )

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    // --- 1. 变量初始化 ---
    // t 进行了极度减速处理
    float r = 1.0, t = iTime * 0.02, H = iResolution.y, id = 1.0;
    vec2 q = fragCoord.xy / iResolution.xy; // 文本采样坐标
    vec2 U = fragCoord.xy;
    
    U /= H;
    U *= 0.5; // 还原原版缩放比例
    
    // --- 2. 基础底色设定 ---
    // 统一使用深色调，背景透明度设为基础值
    vec3 baseColor = vec3(0.01, 0.02, 0.05); 
    float currentAlpha = 0.3; // 起始透明度
    bool isLine = false;

    // --- 3. 核心迭代逻辑 (28层深度) ---
    for (int i=0; i<28; i++) {
        vec2 fU = min(U, 1.0 - U);
        
        // 分割线检测逻辑
        if (min(fU.x, fU.y) < 0.3 * r / H) { 
            isLine = true; 
            break; 
        } 
        
        // 决策：当前方块是否继续细分
        float decision = rnd(id);
        if (decision > 0.7) break; 

        // 迭代子单元
        vec2 stepU = step(0.5, U);
        id = 4.0 * id + 2.0 * stepU.y + stepU.x;
        U = 2.0 * U - stepU;
        r *= 2.0;
        
        if (r > H) break;
        
        // --- 透明度梯度核心逻辑 ---
        // 每一层嵌套，透明度都会根据 decision 产生微妙的变化
        // 这样不同的方块即使颜色一样，也会因为透明度不同而产生层次感
        currentAlpha = clamp(currentAlpha + (decision - 0.5) * 0.2, 0.1, 0.7);
    }

    // --- 4. 线条与背景合成 ---
    vec4 shaderOut;
    if (isLine) {
        // 划分线条：透明度最高 (全透明)
        shaderOut = vec4(baseColor * 0.5, 0.0);
    } else {
        // 方块内部：按计算出的透明度显示
        shaderOut = vec4(baseColor, currentAlpha);
    }

    // --- 5. 文字层采样与混合 (Screen Blend) ---
    vec4 txt = texture(iChannel0, q);
    
    // 滤色混合算法，保证文字清晰
    vec3 mixedRGB = 1.0 - (1.0 - shaderOut.rgb) * (1.0 - txt.rgb);
    
    // 文字保护逻辑：有文字的地方 Alpha 强制设为 1.0，防止文字变淡
    float textPresence = clamp(length(txt.rgb) * 3.0, 0.0, 1.0);
    float finalAlpha = mix(shaderOut.a, 1.0, textPresence);

    fragColor = vec4(mixedRGB, finalAlpha);
}
