// Derived from crt/shaders/guest/advanced/ntsc/ntsc-pass1.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 params_OutputSize;
float4 params_OriginalSize;
float4 params_SourceSize;
uint params_FrameCount;
static const float params_quality = 0.0;
static const float params_ntsc_sat = 1.100000;
static const float params_cust_fringing = 1.0;
static const float params_cust_artifacting = 1.0;
static const float params_ntsc_bright = 1.0;
static const float params_ntsc_scale = 2.500000;
static const float params_ntsc_fields = 0.000000;
static const float params_ntsc_phase = 1.0;
static const float params_ntsc_gamma = 1.0;
static const float params_ntsc_rainbow1 = 0.0;
static const float params_ntsc_taps = 32.0;
static const float params_auto_res = 0.0;
static const float params_ntsc_charp = 10.000000;
static const float params_ntsc_charp3 = 10.000000;
static const float params_speedup = 1.0;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }




uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;
static float2 vs_pix_no;
static float vs_phase;
static float vs_CHROMA_MOD_FREQ;
static float vs_ARTIFACTING;
static float vs_FRINGING;
static float vs_SATURATION;
static float vs_BRIGHTNESS;
static float vs_MERGE;

struct vs_SPIRV_Cross_Input
{
    float4 vs_Position : TEXCOORD0;
    float2 vs_TexCoord : TEXCOORD1;
};

struct vs_SPIRV_Cross_Output
{
    float4 vs_gl_Position : POSITION;
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
float4 packed2 : TEXCOORD2;
};

static float vs_FrameCount;
static float vs_auto_rez;

void vs_vert_main()
{
    vs_FrameCount = float(params_FrameCount);
    vs_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    float res = min(params_ntsc_scale * vs_auto_rez, 1.0f);
    float OriginalSize = params_OriginalSize.x * vs_auto_rez;
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord * float2(params_speedup, 1.0f);
    vs_pix_no = ((vs_vTexCoord * params_OriginalSize.xy) * float2(res, res / vs_auto_rez)) * float2(4.0f, 1.0f);
    float _106;
    if (params_ntsc_phase < 1.5f)
    {
        _106 = (OriginalSize > 300.0f) ? 2.0f : 3.0f;
    }
    else
    {
        _106 = (params_ntsc_phase > 2.5f) ? 3.0f : 2.0f;
    }
    vs_phase = _106;
    if (params_ntsc_phase == 4.0f)
    {
        vs_phase = 3.0f;
    }
    else
    {
        if (params_ntsc_phase == 5.0f)
        {
            vs_phase = 2.0f;
        }
    }
    bool _135 = vs_phase == 2.0f;
    bool _141;
    if (_135)
    {
        _141 = params_ntsc_phase != 5.0f;
    }
    else
    {
        _141 = _135;
    }
    float _142;
    if (_141)
    {
        _142 = 0.83775806427001953125f;
    }
    else
    {
        bool _148 = OriginalSize <= 300.0f;
        bool _154;
        if (!_148)
        {
            _154 = vs_phase == 3.0f;
        }
        else
        {
            _154 = _148;
        }
        _142 = _154 ? 1.0471975803375244140625f : 1.57079637050628662109375f;
    }
    vs_CHROMA_MOD_FREQ = _142;
    vs_ARTIFACTING = params_cust_artifacting;
    vs_FRINGING = params_cust_fringing;
    vs_SATURATION = params_ntsc_sat;
    vs_BRIGHTNESS = params_ntsc_bright;
    vs_MERGE = 0.0f;
    bool _180 = params_ntsc_fields == (-1.0f);
    bool _185;
    if (_180)
    {
        _185 = vs_phase == 3.0f;
    }
    else
    {
        _185 = _180;
    }
    if (_185)
    {
        vs_MERGE = 1.0f;
    }
    else
    {
        if (params_ntsc_fields == 0.0f)
        {
            vs_MERGE = 0.0f;
        }
        else
        {
            if (params_ntsc_fields == 1.0f)
            {
                vs_MERGE = 1.0f;
            }
        }
    }
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
    stage_output.packed0.zw = vs_pix_no;
    stage_output.packed1.x = vs_phase;
    stage_output.packed2.y = vs_CHROMA_MOD_FREQ;
    stage_output.packed2.x = vs_ARTIFACTING;
    stage_output.packed1.w = vs_FRINGING;
    stage_output.packed1.z = vs_SATURATION;
    stage_output.packed1.y = vs_BRIGHTNESS;
    stage_output.packed2.z = vs_MERGE;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }






static float ps_BRIGHTNESS;
static float ps_FRINGING;
static float ps_ARTIFACTING;
static float ps_SATURATION;
static float2 ps_vTexCoord;
static float4 ps_FragColor;
static float ps_phase;
static float ps_MERGE;
static float2 ps_pix_no;
static float ps_CHROMA_MOD_FREQ;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
float4 packed1 : TEXCOORD1;
float4 packed2 : TEXCOORD2;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

static float ps_FrameCount;
static float ps_auto_rez;
static float3x3 ps_mix_mat;

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

float ps_smothstep(float e0, float e1, float x)
{
    return clamp((x - e0) / (e1 - e0), 0.0f, 1.0f);
}

float3 ps_rgb2yiq(float3 col)
{
    return mul(float3x3(float3(0.29890000820159912109375f, 0.58700001239776611328125f, 0.114000000059604644775390625f), float3(0.595899999141693115234375f, -0.2743999958038330078125f, -0.3215999901294708251953125f), float3(0.21150000393390655517578125f, -0.52289998531341552734375f, 0.311399996280670166015625f)), col);
}

float ps_get_luma(float3 c)
{
    return dot(c, float3(0.29890000820159912109375f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
}

void ps_frag_main()
{
    ps_FrameCount = float(params_FrameCount);
    ps_auto_rez = lerp(1.0f, 0.5f, clamp((params_auto_res * round(params_OriginalSize.x / 300.0f)) - 1.0f, 0.0f, 1.0f));
    ps_mix_mat = float3x3(float3(ps_BRIGHTNESS, ps_FRINGING, ps_FRINGING), float3(ps_ARTIFACTING, 2.0f * ps_SATURATION, 0.0f), float3(ps_ARTIFACTING, 0.0f, 2.0f * ps_SATURATION));
    if (ps_vTexCoord.x > 1.0f)
    {
        ps_FragColor = 0.0f.xxxx;
    }
    else
    {
        float res = params_ntsc_scale * ps_auto_rez;
        float mit = params_ntsc_taps;
        bool _135 = params_ntsc_charp > 0.25f;
        bool _141;
        if (_135)
        {
            _141 = ps_phase == 2.0f;
        }
        else
        {
            _141 = _135;
        }
        if (_141)
        {
            mit = clamp(mit, 8.0f, min(params_ntsc_taps, 14.0f));
        }
        float param = 16.0f;
        float param_1 = 8.0f;
        float param_2 = mit;
        mit = ps_smothstep(param, param_1, param_2) * 0.324999988079071044921875f;
        float3 col = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord).xyz;
        float3 param_3 = col;
        float3 yiq = ps_rgb2yiq(param_3);
        yiq.x = pow(yiq.x, params_ntsc_gamma);
        float lum = yiq.x;
        if (params_ntsc_phase == 4.0f)
        {
            float2 dx = float2(params_OriginalSize.z / ps_auto_rez, 0.0f);
            float3 param_4 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord - dx).xyz;
            float c1 = ps_get_luma(param_4);
            float3 param_5 = ps_sample_lod0(LIBRA_SAMPLER2D_2, ps_vTexCoord + dx).xyz;
            float c2 = ps_get_luma(param_5);
            float mix01 = min(5.0f * abs(c1 - c2), 1.0f);
            c1 = pow(c1, params_ntsc_gamma);
            c2 = pow(c2, params_ntsc_gamma);
            yiq.x = lerp(min(0.5f * (yiq.x + max(c1, c2)), max(yiq.x, min(c1, c2))), yiq.x, mix01);
        }
        float3 tmp = yiq;
        float3 yiq2 = yiq;
        float3 yiqs = yiq;
        float3 yiqz = yiq;
        if (ps_MERGE > 0.5f)
        {
            float _267;
            if (ps_phase < 2.5f)
            {
                _267 = 3.1415927410125732421875f * (ps_mod(ps_pix_no.y, 2.0f) + ps_mod(ps_FrameCount + 1.0f, 2.0f));
            }
            else
            {
                _267 = 2.0944998264312744140625f * (ps_mod(ps_pix_no.y, 3.0f) + ps_mod(ps_FrameCount + 1.0f, 2.0f));
            }
            float chroma_phase2 = _267;
            float mod_phase2 = chroma_phase2 + (ps_pix_no.x * ps_CHROMA_MOD_FREQ);
            float i_mod2 = cos(mod_phase2);
            float q_mod2 = sin(mod_phase2);
            float3 _310 = yiq2;
            float2 _312 = _310.yz * float2(i_mod2, q_mod2);
            yiq2.y = _312.x;
            yiq2.z = _312.y;
            yiq2 = mul(ps_mix_mat, yiq2);
            float3 _323 = yiq2;
            float2 _325 = _323.yz * float2(i_mod2, q_mod2);
            yiq2.y = _325.x;
            yiq2.z = _325.y;
            float3 _330 = yiq2;
            float2 _336 = lerp(_330.yz, tmp.yz, mit.xx);
            yiq2.y = _336.x;
            yiq2.z = _336.y;
            if (res > 1.02499997615814208984375f)
            {
                mod_phase2 = chroma_phase2 + ((ps_pix_no.x * ps_CHROMA_MOD_FREQ) * res);
                i_mod2 = cos(mod_phase2);
                q_mod2 = sin(mod_phase2);
                float3 _361 = yiqs;
                float2 _363 = _361.yz * float2(i_mod2, q_mod2);
                yiqs.y = _363.x;
                yiqs.z = _363.y;
                yiq2.x = dot(yiqs, ps_mix_mat[0]);
            }
        }
        float _378;
        if (ps_phase < 2.5f)
        {
            _378 = 3.1415927410125732421875f * (ps_mod(ps_pix_no.y, 2.0f) + ps_mod(ps_FrameCount, 2.0f));
        }
        else
        {
            _378 = 2.0944998264312744140625f * (ps_mod(ps_pix_no.y, 3.0f) + ps_mod(ps_FrameCount, 2.0f));
        }
        float chroma_phase = _378;
        float mod_phase = chroma_phase + (ps_pix_no.x * ps_CHROMA_MOD_FREQ);
        float i_mod = cos(mod_phase);
        float q_mod = sin(mod_phase);
        float3 _413 = yiq;
        float2 _415 = _413.yz * float2(i_mod, q_mod);
        yiq.y = _415.x;
        yiq.z = _415.y;
        yiq = mul(ps_mix_mat, yiq);
        float3 _426 = yiq;
        float2 _428 = _426.yz * float2(i_mod, q_mod);
        yiq.y = _428.x;
        yiq.z = _428.y;
        float3 _433 = yiq;
        float2 _439 = lerp(_433.yz, tmp.yz, mit.xx);
        yiq.y = _439.x;
        yiq.z = _439.y;
        if (res > 1.02499997615814208984375f)
        {
            mod_phase = chroma_phase + ((ps_pix_no.x * ps_CHROMA_MOD_FREQ) * res);
            i_mod = cos(mod_phase);
            q_mod = sin(mod_phase);
            float3 _463 = yiqz;
            float2 _465 = _463.yz * float2(i_mod, q_mod);
            yiqz.y = _465.x;
            yiqz.z = _465.y;
            yiq.x = dot(yiqz, ps_mix_mat[0]);
        }
        if (params_ntsc_phase == 4.0f)
        {
            yiq.x = lum;
            yiq2.x = lum;
        }
        if (ps_MERGE > 0.5f)
        {
            bool _491 = params_ntsc_rainbow1 < 0.5f;
            bool _497;
            if (!_491)
            {
                _497 = ps_phase > 2.5f;
            }
            else
            {
                _497 = _491;
            }
            if (_497)
            {
                yiq = (yiq + yiq2) * 0.5f;
            }
            else
            {
                yiq.x = 0.5f * (yiq.x + yiq2.x);
            }
        }
        ps_FragColor = float4(yiq, lum);
    }
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_BRIGHTNESS = stage_input.packed1.y;
    ps_FRINGING = stage_input.packed1.w;
    ps_ARTIFACTING = stage_input.packed2.x;
    ps_SATURATION = stage_input.packed1.z;
    ps_vTexCoord = stage_input.packed0.xy;
    ps_phase = stage_input.packed1.x;
    ps_MERGE = stage_input.packed2.z;
    ps_pix_no = stage_input.packed0.zw;
    ps_CHROMA_MOD_FREQ = stage_input.packed2.y;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
