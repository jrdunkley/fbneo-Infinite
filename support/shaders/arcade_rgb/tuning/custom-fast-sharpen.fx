// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/custom-fast-sharpen.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_CSHARPEN = 0.00;
static const float params_CCONTR = 0.05;
static const float params_CDETAILS = 1.00;
static const float params_NDEBLUR = 1.00;
static const float params_DEDGE = 0.90;
static const float params_DESHARP = 0.00;
static const float params_DSMART = 0.00;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }




uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;

struct vs_SPIRV_Cross_Input
{
    float4 vs_Position : TEXCOORD0;
    float2 vs_TexCoord : TEXCOORD1;
};

struct vs_SPIRV_Cross_Output
{
    float4 vs_gl_Position : POSITION;
float4 packed0 : TEXCOORD0;
};

void vs_vert_main()
{
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord;
    vs_gl_Position.x = vs_gl_Position.x - vs_gl_HalfPixel.x * vs_gl_Position.w;
    vs_gl_Position.y = vs_gl_Position.y + vs_gl_HalfPixel.y * vs_gl_Position.w;
}

vs_SPIRV_Cross_Output vs_main(vs_SPIRV_Cross_Input stage_input)
{
    vs_Position = stage_input.vs_Position;
    vs_TexCoord = stage_input.vs_TexCoord;
    vs_vert_main();
    vs_SPIRV_Cross_Output stage_output = (vs_SPIRV_Cross_Output)0;
    stage_output.vs_gl_Position = vs_gl_Position;
    stage_output.packed0.xy = vs_vTexCoord;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }







static float2 ps_vTexCoord;
static float4 ps_FragColor;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

static float ps_resmult;

float ps_get_luma(float3 c)
{
    return dot(c, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
}

float3 ps_rgb2yiq(float3 col)
{
    return mul(float3x3(float3(0.29890000820159912109375f, 0.58700001239776611328125f, 0.114000000059604644775390625f), float3(0.595899999141693115234375f, -0.2743999958038330078125f, -0.3215999901294708251953125f), float3(0.21150000393390655517578125f, -0.52289998531341552734375f, 0.311399996280670166015625f)), col);
}

float3 ps_yiq2rgb(float3 yiq)
{
    return mul(float3x3(float3(1.0f, 0.95599997043609619140625f, 0.620999991893768310546875f), float3(1.0f, -0.272000014781951904296875f, -0.64740002155303955078125f), float3(1.0f, -1.10599994659423828125f, 1.70459997653961181640625f)), yiq);
}

void ps_frag_main()
{
    ps_resmult = round(params_OriginalSize.x / 300.0f);
    float2 g01 = float2(((-0.5f) * ps_resmult) * params_OriginalSize.z, 0.0f);
    float2 g21 = float2((0.5f * ps_resmult) * params_OriginalSize.z, 0.0f);
    float3 c01 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + g01).xyz;
    float3 c21 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + g21).xyz;
    float3 c11 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz;
    float3 b11 = (c01 + c21) * 0.5f;
    float contrast = max(max(c11.x, c11.y), c11.z);
    contrast = lerp(2.0f * params_CCONTR, params_CCONTR, contrast);
    float3 mn = min(min(c01, c21), c11);
    float3 mn1 = min(mn, c11 * (1.0f - contrast));
    float3 mx = max(max(c01, c21), c11);
    float3 mx1 = max(mx, c11 * (1.0f + contrast));
    float3 dif = pow((mx1 - mn1) + 9.9999997473787516355514526367188e-06f.xxx, 0.75f.xxx);
    float3 sharpen = lerp((params_CSHARPEN * params_CDETAILS).xxx, params_CSHARPEN.xxx, dif);
    float3 res = clamp(lerp(c11, b11, -sharpen), mn1, mx1);
    if (params_NDEBLUR > 1.125f)
    {
        float2 tex0 = (floor(params_OriginalSize.xy * ps_vTexCoord) + 0.5f.xx) * params_OriginalSize.zw;
        float3 param = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord + (g01 * 2.0f)).xyz;
        float l01 = ps_get_luma(param);
        float3 param_1 = ps_sample_lod0(LIBRA_SAMPLER2D_3, ps_vTexCoord + (g21 * 2.0f)).xyz;
        float l21 = ps_get_luma(param_1);
        float3 param_2 = ps_sample_lod0(LIBRA_SAMPLER2D_3, tex0).xyz;
        float l11 = ps_get_luma(param_2);
        float dth = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).w;
        float DEB = max(lerp(0.375f * params_NDEBLUR, params_NDEBLUR, max(1.0f - params_DSMART, dth)), 1.0f);
        float v11 = min(min(l01, l21), l11);
        l11 = max(max(l01, l21), l11);
        float3 param_3 = c01;
        float3 param_4 = c21;
        float3 param_5 = c11;
        float lmin = min(min(ps_get_luma(param_3), ps_get_luma(param_4)), ps_get_luma(param_5));
        float3 param_6 = c01;
        float3 param_7 = c21;
        float3 param_8 = c11;
        float lmax = max(max(ps_get_luma(param_6), ps_get_luma(param_7)), ps_get_luma(param_8));
        float ln1 = min(lerp(v11, lmin, lmin), lmin);
        float lx1 = max(lerp(lmax, l11, lmax), lmax);
        float3 param_9 = res;
        float r11 = ps_get_luma(param_9);
        float dif1 = max(r11 - ln1, 0.0f) + 9.9999997473787516355514526367188e-06f;
        dif1 = pow(dif1, DEB);
        float dif2 = max(lx1 - r11, 0.0f) + 9.9999997473787516355514526367188e-06f;
        dif2 = pow(dif2, DEB);
        float ratio = dif1 / (dif1 + dif2);
        float lsharpen = lerp(ln1, lx1, ratio);
        lsharpen = min(lsharpen, max(params_DEDGE * lsharpen, r11));
        float3 param_10 = res;
        res = ps_rgb2yiq(param_10);
        v11 = res.x;
        res.x = lsharpen;
        res.x = clamp(((1.0f + params_DESHARP) * res.x) - (params_DESHARP * v11), ln1 * (1.0f - contrast), lx1 * (1.0f + contrast));
        float3 param_11 = res;
        res = max(ps_yiq2rgb(param_11), 0.0f.xxx);
    }
    ps_FragColor = float4(res, 1.0f);
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vTexCoord = stage_input.packed0.xy;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
