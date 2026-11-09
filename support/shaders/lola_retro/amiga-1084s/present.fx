// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.
// Pinned upstream 6383ff7357be32c95baf6d31b4a1b1d3cd5c7069
// Isolated Infinite D3D9 prototype; preset amiga-1084s, explicit arcade timing 8.
row_major float4x4 global_MVP;
static const float global_LR_HDR_SRC = 0.0;
static const float global_LR_CONSOLE = 8;
static const float global_LR_NORM = 0;
static const float global_LR_HDR_SIG = 0.0;
static const float global_LR_CABLE = 3;
static const float global_LR_COMB = 0;
static const float global_LR_YTRAP = 0.75;
static const float global_LR_DBLEND = 0.0;
static const float global_LR_SHARP = 0.1;
static const float global_LR_SAT = 1.12;
static const float global_LR_TINT = 0;
static const float global_LR_DEMOD = 0;
static const float global_LR_BRIGHT = 0;
static const float global_LR_CONTRAST = 1.05;
static const float global_LR_NOISE = 0;
static const float global_LR_STEADY = 1;
static const float global_LR_HDR_BEAM = 0.0;
static const float global_LR_SIG_LO = 0.2;
static const float global_LR_SIG_HI = 0.42;
static const float global_LR_HFOCUS = 0.45;
static const float global_LR_GAMMA = 2.4;
static const float global_LR_PERSIST = 0.05;
static const float global_LR_CONV = 0.25;
static const float global_LR_HDR_MASK = 0.0;
static const float global_LR_MASK_TYPE = 2;
static const float global_LR_MASK_STR = 0.5;
static const float global_LR_MASK_TRIADS = 470;
static const float global_LR_WHITE = 6500;
static const float global_LR_PHOS = 3;
static const float global_LR_HDR_GLASS = 0.0;
static const float global_LR_CURV_X = 0;
static const float global_LR_CURV_Y = 0;
static const float global_LR_CORNER = 0;
static const float global_LR_GLOW = 0.06;
static const float global_LR_GLOW_SIZE = 0.5;
static const float global_LR_VIGNETTE = 0.25;
static const float global_LR_OVERSCAN = -0.015;
static const float global_LR_AMBIENT = 0.002;
static const float global_LR_HDR_MON = 0.0;
static const float global_LR_MON_MM = 1;
static const float global_LR_MON_SIZE = 14;
static const float global_LR_MON_PITCH = 0.42;
static const float global_LR_MON_SPOT_LO = 0.28;
static const float global_LR_MON_SPOT_HI = 0.65;
static const float global_LR_MON_CORNER = 1.5;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
static const float vs__46[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };





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
static const float ps__107[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };







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

float ps_hash13(inout float3 p3)
{
    p3 = frac(p3 * 0.103100001811981201171875f);
    p3 += dot(p3, p3.zyx + 31.31999969482421875f.xxx).xxx;
    return frac((p3.x + p3.y) * p3.z);
}

void ps_frag_main()
{
    float3 c = pow(max(tex2Dlod(LIBRA_SAMPLER2D_2, float4(ps_vTexCoord, 0.0, 0.0f)).xyz, 0.0f.xxx), 0.4545454680919647216796875f.xxx);
    float2 fc = ps_vTexCoord * params_OutputSize.xy;
    float3 param = float3(fc, 1.0f);
    float _81 = ps_hash13(param);
    c += ((_81 - 0.5f) / 255.0f).xxx;
    ps_FragColor = float4(c, 1.0f);
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
