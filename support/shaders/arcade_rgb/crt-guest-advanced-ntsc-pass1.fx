// Derived from crt/shaders/guest/advanced/crt-guest-advanced-ntsc-pass1.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_SIGMA_HOR = 0.80;
static const float params_HSHARPNESS = 1.60;
static const float params_S_SHARP = 1.10;
static const float params_HARNG = 0.30;
static const float params_HSHARP = 1.20;
static const float params_spike = 1.0;
static const float params_filter_res = 1.0;
static const float params_MAXS = 0.18;
static const float params_auto_res = 0.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
float4 LIBRA_SAMPLER2D_2_size;
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

void vs_vert_main()
{
    float _24;
    if (params_OriginalSize.y < 375.0f)
    {
        _24 = lerp(1.0f, 1.85000002384185791015625f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _24 = 1.0f;
    }
    vs_auto_rez = _24;
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord * 1.000010013580322265625f;
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



float ps_gaussian(float x, float xscale)
{
    return exp(((-x) * x) * xscale);
}

void ps_frag_main()
{
    float _29;
    if (params_OriginalSize.y < 375.0f)
    {
        _29 = lerp(1.0f, 1.85000002384185791015625f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    }
    else
    {
        _29 = 1.0f;
    }
    ps_auto_rez = _29;
    uint _70_dummy_parameter;
    float2 prescalex = float2(int2(float2(LIBRA_SAMPLER2D_2_size.xy))) / params_OriginalSize.xy;
    float4 SourceSize = params_OriginalSize * float4(prescalex.x, prescalex.y, 1.0f / prescalex.x, 1.0f / prescalex.y);
    float f = frac(SourceSize.x * ps_vTexCoord.x);
    f = 0.5f - f;
    float2 tex = (floor(SourceSize.xy * ps_vTexCoord) * SourceSize.zw) + (SourceSize.zw * 0.5f);
    float3 color = 0.0f.xxx;
    float scolor = 0.0f;
    float2 dx = float2(SourceSize.z, 0.0f);
    float w = 0.0f;
    float swsum = 0.0f;
    float wsum = 0.0f;
    float3 cmax = 0.0f.xxx;
    float3 cmin = 1.0f.xxx;
    float xscale = max(prescalex.x * 0.4000000059604644775390625f, 1.0f) * ps_auto_rez;
    float hsharpness = (params_HSHARPNESS * xscale) * params_filter_res;
    xscale = 1.0f / ((((((2.0f * params_SIGMA_HOR) * params_SIGMA_HOR) * xscale) * xscale) * params_filter_res) * params_filter_res);
    float param = hsharpness;
    float param_1 = xscale;
    float sharp = ps_gaussian(param, param_1) * params_S_SHARP;
    float maxsharp = params_MAXS;
    float FPR = hsharpness;
    float FPRi = 1.0f / hsharpness;
    float fpx = 0.0f;
    float sp = 0.0f;
    float sw = 0.0f;
    float ts = 0.02500000037252902984619140625f;
    float3 luma = float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f);
    float _204 = ceil(2.0f * FPR);
    float _207 = -_204;
    float LOOPSIZE = _204;
    float n = _207;
    do
    {
        float3 pixel = ps_sample_lod0(LIBRA_SAMPLER2D_2, tex + (dx * n)).xyz;
        float param_2 = n + f;
        float param_3 = xscale;
        w = ps_gaussian(param_2, param_3) - sharp;
        fpx = (abs(n + f) - FPR) * FPRi;
        if (w < 0.0f)
        {
            w = max(w, lerp(-maxsharp, 0.0f, pow(clamp(fpx, 0.0f, 1.0f), params_HSHARP)));
        }
        else
        {
            cmax = max(cmax, pixel);
            cmin = min(cmin, pixel);
            sw = w * (dot(pixel, luma) + ts);
            sp = max(max(pixel.x, pixel.y), pixel.z);
            scolor += (sw * sp);
            swsum += sw;
        }
        color += (pixel * w);
        wsum += w;
        n += 1.0f;
    } while (n <= LOOPSIZE);
    color /= wsum.xxx;
    scolor /= swsum;
    color = clamp(lerp(clamp(color, cmin, cmax), color, params_HARNG.xxx), 0.0f.xxx, 1.0f.xxx);
    scolor = clamp(lerp(max(max(color.x, color.y), color.z), scolor, params_spike), 0.0f, 1.0f);
    ps_FragColor = float4(color, scolor);
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
