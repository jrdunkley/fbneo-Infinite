// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/linearize-ntsc.slang; see SOURCES and original shader notices.
float4 global_SourceSize;
row_major float4x4 global_MVP;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
static const float params_GAMMA_INPUT = 2.0;
static const float params_inter = 375.0;
static const float params_interm = 2.0;
static const float params_iscan = 0.20;
static const float params_intres = 0.0;
static const float params_iscans = 0.25;
static const float params_downsample_levelx = 0.0;
static const float params_downsample_levely = 0.0;
float params_gamma_out = 1.95;
static const float params_hiscan = 0.0;
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

void vs_vert_main()
{
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

float ps_mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 ps_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float3 ps_mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 ps_mod(float4 x, float4 y)
{
    return x - y * floor(x / y);
}

float3 ps_fetch_pixel(float2 coord)
{
    float2 dx = float2(global_SourceSize.z, 0.0f) * params_downsample_levelx;
    float2 dy = float2(0.0f, global_SourceSize.w) * params_downsample_levely;
    float2 d1 = dx + dy;
    float2 d2 = dx - dy;
    float sum = 15.0f;
    float3 result = ((((((((ps_sample_lod0(LIBRA_SAMPLER2D_2, coord).xyz * 3.0f) + (ps_sample_lod0(LIBRA_SAMPLER2D_2, coord + dx).xyz * 2.0f)) + (ps_sample_lod0(LIBRA_SAMPLER2D_2, coord - dx).xyz * 2.0f)) + (ps_sample_lod0(LIBRA_SAMPLER2D_2, coord + dy).xyz * 2.0f)) + (ps_sample_lod0(LIBRA_SAMPLER2D_2, coord - dy).xyz * 2.0f)) + ps_sample_lod0(LIBRA_SAMPLER2D_2, coord + d1).xyz) + ps_sample_lod0(LIBRA_SAMPLER2D_2, coord - d1).xyz) + ps_sample_lod0(LIBRA_SAMPLER2D_2, coord + d2).xyz) + ps_sample_lod0(LIBRA_SAMPLER2D_2, coord - d2).xyz;
    return result / sum.xxx;
}

float3 ps_plant(float3 tar, float r)
{
    float t = max(max(tar.x, tar.y), tar.z) + 9.9999997473787516355514526367188e-06f;
    return (tar * r) / t.xxx;
}

void ps_frag_main()
{
    float3 c1 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz;
    float3 c2 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + float2(0.0f, params_OriginalSize.w)).xyz;
    if ((params_downsample_levelx + params_downsample_levely) > 0.02500000037252902984619140625f)
    {
        float2 param = ps_vTexCoord;
        c1 = ps_fetch_pixel(param);
        float2 param_1 = ps_vTexCoord + float2(0.0f, params_OriginalSize.w);
        c2 = ps_fetch_pixel(param_1);
    }
    float3 c = c1;
    float intera = 1.0f;
    float gamma_in = params_GAMMA_INPUT;
    float m1 = max(max(c1.x, c1.y), c1.z);
    float m2 = max(max(c2.x, c2.y), c2.z);
    float3 df = abs(c1 - c2);
    float d = max(max(df.x, df.y), df.z);
    if (params_interm == 2.0f)
    {
        d = lerp(0.100000001490116119384765625f * d, 10.0f * d, step(m1 / (m2 + 9.9999997473787516355514526367188e-05f), m2 / (m1 + 9.9999997473787516355514526367188e-05f)));
    }
    float r = m1;
    float yres_div = 1.0f;
    if (params_intres > 1.25f)
    {
        yres_div = params_intres;
    }
    bool hscan = params_hiscan > 0.5f;
    bool _287 = params_inter <= (params_OriginalSize.y / yres_div);
    bool _293;
    if (_287)
    {
        _293 = params_interm > 0.5f;
    }
    else
    {
        _293 = _287;
    }
    bool _299;
    if (_293)
    {
        _299 = params_intres != 1.0f;
    }
    else
    {
        _299 = _293;
    }
    bool _305;
    if (_299)
    {
        _305 = params_intres != 0.5f;
    }
    else
    {
        _305 = _299;
    }
    if (_305 || hscan)
    {
        intera = 0.25f;
        float line_no = floor(ps_mod(params_OriginalSize.y * ps_vTexCoord.y, 2.0f));
        float frame_no = floor(ps_mod(float(params_FrameCount), 2.0f));
        float ii = abs(line_no - frame_no);
        bool _336 = params_interm < 3.5f;
        bool _344;
        if (!_336)
        {
            _344 = params_interm > 5.5f;
        }
        else
        {
            _344 = _336;
        }
        if (_344)
        {
            if (params_interm == 6.0f)
            {
                c = lerp(c2, c1, ii.xxx);
            }
            else
            {
                float3 param_2 = lerp(c2, c2 * c2, params_iscans.xxx);
                float param_3 = max(max(c2.x, c2.y), c2.z);
                c2 = ps_plant(param_2, param_3);
                r = max(m1 * ii, (1.0f - params_iscan) * min(m1, m2));
                float3 param_4 = lerp(lerp(c1, c2, min(lerp(m1, 1.0f - m2, min(m1, 1.0f - m1)) / (d + 9.9999997473787516355514526367188e-06f), 1.0f).xxx), c1, ii.xxx);
                float param_5 = r;
                c = ps_plant(param_4, param_5);
                if (params_interm == 3.0f)
                {
                    c = lerp(c2, c1, ii.xxx) * (1.0f - (0.5f * params_iscan));
                }
            }
        }
        if (params_interm == 4.0f)
        {
            float3 param_6 = lerp(c, c * c, (0.5f * params_iscans).xxx);
            float param_7 = max(max(c.x, c.y), c.z);
            c = ps_plant(param_6, param_7) * (1.0f - (0.5f * params_iscan));
        }
        if (params_interm == 5.0f)
        {
            c = lerp(c2, c1, 0.5f.xxx);
            float3 param_8 = lerp(c, c * c, (0.5f * params_iscans).xxx);
            float param_9 = max(max(c.x, c.y), c.z);
            c = ps_plant(param_8, param_9) * (1.0f - (0.5f * params_iscan));
        }
        if (hscan)
        {
            c = c1;
        }
    }
    c = pow(c, gamma_in.xxx);
    if (ps_vTexCoord.x > 0.5f)
    {
        gamma_in = intera;
    }
    else
    {
        gamma_in = 1.0f / gamma_in;
    }
    ps_FragColor = float4(c, gamma_in);
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
