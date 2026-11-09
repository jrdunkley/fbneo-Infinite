// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/hd/gaussian_horizontal.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_LinearizePassSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_SIZEH = 6.0;
static const float params_SIGMA_H = 1.20;
static const float params_FINE_GLOW = 1.0;
static const float params_m_glow = 1.000000;
static const float params_m_glow_cutoff = 0.12;
static const float params_m_glow_low = 0.35;
static const float params_m_glow_high = 5.0;
static const float params_m_glow_dist = 1.0;
static const float params_m_glow_mask = 1.0;
static const float params_auto_res = 0.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
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

static float vs_auto_rez;
static float vs_FINE_GLOW;

void vs_vert_main()
{
    float _24;
    if (params_OriginalSize.y < 375.0f)
    {
        _24 = lerp(1.0f, 2.0f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _24 = 1.0f;
    }
    vs_auto_rez = _24;
    float _51;
    if (params_FINE_GLOW > 0.5f)
    {
        _51 = params_FINE_GLOW;
    }
    else
    {
        _51 = lerp(0.75f, 0.5f, -params_FINE_GLOW);
    }
    vs_FINE_GLOW = _51;
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

static float ps_auto_rez;
static float ps_FINE_GLOW;
static float ps_invsqrsigma;

float3 ps_plant(float3 tar, float r)
{
    float t = max(max(tar.x, tar.y), tar.z) + 9.9999997473787516355514526367188e-06f;
    return (tar * r) / t.xxx;
}

float ps_gaussian(float x)
{
    return exp(((-x) * x) * ps_invsqrsigma);
}

void ps_frag_main()
{
    float _35;
    if (params_OriginalSize.y < 375.0f)
    {
        _35 = lerp(1.0f, 2.0f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _35 = 1.0f;
    }
    ps_auto_rez = _35;
    float _62;
    if (params_FINE_GLOW > 0.5f)
    {
        _62 = params_FINE_GLOW;
    }
    else
    {
        _62 = lerp(0.75f, 0.5f, -params_FINE_GLOW);
    }
    ps_FINE_GLOW = _62;
    ps_invsqrsigma = 1.0f / ((((2.0f * params_SIGMA_H) * params_SIGMA_H) * ps_auto_rez) * ps_auto_rez);
    float4 SourceSize1 = params_OriginalSize * float4(ps_FINE_GLOW, ps_FINE_GLOW, 1.0f / ps_FINE_GLOW, 1.0f / ps_FINE_GLOW);
    float f = frac(SourceSize1.x * ps_vTexCoord.x);
    f = 0.5f - f;
    float2 tex = (floor(SourceSize1.xy * ps_vTexCoord) * SourceSize1.zw) + (SourceSize1.zw * 0.5f);
    float3 color = 0.0f.xxx;
    float2 dx = float2(SourceSize1.z, 0.0f);
    float wsum = 0.0f;
    float _168 = (-params_SIZEH) * ps_auto_rez;
    float n = _168;
    do
    {
        float3 pixel = ps_sample_lod0(LIBRA_SAMPLER2D_2, tex + (dx * n)).xyz;
        if (params_m_glow > 0.5f)
        {
            pixel = max(pixel - params_m_glow_cutoff.xxx, 0.0f.xxx);
            float3 param = pixel;
            float param_1 = max(max(max(pixel.x, pixel.y), pixel.z) - params_m_glow_cutoff, 0.0f);
            pixel = ps_plant(param, param_1);
        }
        float param_2 = n + f;
        float w = ps_gaussian(param_2);
        color += (pixel * w);
        wsum += w;
        n += 1.0f;
    } while (n <= (params_SIZEH * ps_auto_rez));
    color /= wsum.xxx;
    ps_FragColor = float4(color, 1.0f);
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
