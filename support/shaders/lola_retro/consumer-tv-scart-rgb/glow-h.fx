// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.
// Pinned upstream 6383ff7357be32c95baf6d31b4a1b1d3cd5c7069
// Isolated Infinite D3D9 prototype; preset consumer-tv-scart-rgb, explicit arcade timing 8.
row_major float4x4 global_MVP;
static const float global_LR_HDR_SRC = 0.0;
static const float global_LR_CONSOLE = 8;
static const float global_LR_NORM = 0;
static const float global_LR_HDR_SIG = 0.0;
static const float global_LR_CABLE = 3;
static const float global_LR_COMB = 0;
static const float global_LR_YTRAP = 0.75;
static const float global_LR_DBLEND = 0.0;
static const float global_LR_SHARP = 0.35;
static const float global_LR_SAT = 1.25;
static const float global_LR_TINT = 0;
static const float global_LR_DEMOD = 0;
static const float global_LR_BRIGHT = 0;
static const float global_LR_CONTRAST = 1.05;
static const float global_LR_NOISE = 0;
static const float global_LR_STEADY = 1;
static const float global_LR_HDR_BEAM = 0.0;
static const float global_LR_SIG_LO = 0.2;
static const float global_LR_SIG_HI = 0.44;
static const float global_LR_HFOCUS = 0.5;
static const float global_LR_GAMMA = 2.4;
static const float global_LR_PERSIST = 0.08;
static const float global_LR_CONV = 0.4;
static const float global_LR_HDR_MASK = 0.0;
static const float global_LR_MASK_TYPE = 2;
static const float global_LR_MASK_STR = 0.5;
static const float global_LR_MASK_TRIADS = 360;
static const float global_LR_WHITE = 8500;
static const float global_LR_PHOS = 0;
static const float global_LR_HDR_GLASS = 0.0;
static const float global_LR_CURV_X = 0;
static const float global_LR_CURV_Y = 0;
static const float global_LR_CORNER = 0;
static const float global_LR_GLOW = 0.06;
static const float global_LR_GLOW_SIZE = 0.5;
static const float global_LR_VIGNETTE = 0.3;
static const float global_LR_OVERSCAN = 0.05;
static const float global_LR_AMBIENT = 0.002;
static const float global_LR_HDR_MON = 0.0;
static const float global_LR_MON_MM = 0;
static const float global_LR_MON_SIZE = 15;
static const float global_LR_MON_PITCH = 0.28;
static const float global_LR_MON_SPOT_LO = 0.3;
static const float global_LR_MON_SPOT_HI = 0.45;
static const float global_LR_MON_CORNER = 1.4;
float4 params_SourceSize;
float4 params_OriginalSize;
float4 params_OutputSize;
uint params_FrameCount;
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
float4 vs_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
struct vs_Timing
{
    float pclk;
    float fsc;
    float lineFrac;
    float fieldStep;
    float framePhase;
    float vsw;
    float pal;
    float scan;
    float interlace;
    float scale;
    float id;
    float hres;
};

static const float vs__725[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };





uniform float4 vs_gl_HalfPixel;

static float4 vs_gl_Position;
static float4 vs_Position;
static float2 vs_vTexCoord;
static float2 vs_TexCoord;
static float vs_vScale;
static float vs_vUnit;

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

float vs_mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 vs_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float3 vs_mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 vs_mod(float4 x, float4 y)
{
    return x - y * floor(x / y);
}

float vs_upscaleOf(float2 orig)
{
    float id = global_LR_CONSOLE;
    bool _294 = id < 5.5f;
    bool _303;
    if (!_294)
    {
        _303 = (id > 7.5f) && (id < 8.5f);
    }
    else
    {
        _303 = _294;
    }
    bool tv = _303;
    float base = ((id > 4.5f) && (id < 5.5f)) ? 480.0f : 240.0f;
    bool _316;
    if (id < 0.5f)
    {
        _316 = orig.y > 576.0f;
    }
    else
    {
        bool _332;
        if (tv)
        {
            _332 = orig.y > (base * 1.5f);
        }
        else
        {
            _332 = tv;
        }
        _316 = _332;
    }
    bool scaled = _316;
    if (!scaled)
    {
        return 1.0f;
    }
    for (float k = 2.0f; k <= 16.0f; k += 1.0f)
    {
        float lines = orig.y / k;
        bool _355 = lines == floor(lines);
        bool _363;
        if (_355)
        {
            _363 = lines >= (base * 0.829999983310699462890625f);
        }
        else
        {
            _363 = _355;
        }
        bool _371;
        if (_363)
        {
            _371 = lines <= (base * 1.21000003814697265625f);
        }
        else
        {
            _371 = _363;
        }
        if (_371)
        {
            return k;
        }
    }
    return max(1.0f, floor((orig.y / base) + 0.5f));
}

float vs_autoConsole(float2 s)
{
    float w = s.x;
    float h = s.y;
    bool mon15 = global_LR_MON_MM > 0.5f;
    bool _66 = !mon15;
    bool _93;
    if (_66)
    {
        bool _75 = (w == 320.0f) && (h == 200.0f);
        bool _92;
        if (!_75)
        {
            bool _81 = w == 640.0f;
            bool _91;
            if (_81)
            {
                _91 = (h == 350.0f) || (h == 400.0f);
            }
            else
            {
                _91 = _81;
            }
            _92 = _91;
        }
        else
        {
            _92 = _75;
        }
        _93 = _92;
    }
    else
    {
        _93 = _66;
    }
    if (_93)
    {
        return 7.0f;
    }
    bool _104 = (h == 256.0f) || (h == 512.0f);
    bool _113;
    if (!_104)
    {
        _113 = (w == 640.0f) && (h == 200.0f);
    }
    else
    {
        _113 = _104;
    }
    if (_113)
    {
        return 6.0f;
    }
    bool _126;
    if (mon15)
    {
        _126 = (h == 200.0f) || (h == 400.0f);
    }
    else
    {
        _126 = mon15;
    }
    bool _134;
    if (_126)
    {
        _134 = (w == 320.0f) || (w == 640.0f);
    }
    else
    {
        _134 = _126;
    }
    if (_134)
    {
        return 6.0f;
    }
    bool _148 = ((w == 360.0f) || (w == 720.0f)) || (w == 1440.0f);
    bool _166;
    if (_148)
    {
        _166 = (((h == 287.0f) || (h == 574.0f)) || (h == 242.0f)) || (h == 484.0f);
    }
    else
    {
        _166 = _148;
    }
    if (_166)
    {
        return 6.0f;
    }
    if (((h >= 336.0f) && (h <= 400.0f)) && (w >= 400.0f))
    {
        return 9.0f;
    }
    if (h > 300.0f)
    {
        return 5.0f;
    }
    if (w > 420.0f)
    {
        return 4.0f;
    }
    if (w <= 300.0f)
    {
        return 1.0f;
    }
    if (h >= 232.0f)
    {
        return 4.0f;
    }
    return 2.0f;
}

void vs_consoleTable(float id, out float4 a, out float4 b, out float c)
{
    if (id < 1.5f)
    {
        a = float4(5.3693180084228515625f, 5.32034206390380859375f, 256.0f, 0.0f);
        b = float4(0.3333333432674407958984375f, 0.16666667163372039794921875f, 0.3333333432674407958984375f, 0.0f);
        c = 0.0f;
    }
    else
    {
        if (id < 2.5f)
        {
            a = float4(6.71164703369140625f, 6.65042781829833984375f, 320.0f, 0.0f);
            b = 0.0f.xxxx;
            c = 1.0f;
        }
        else
        {
            if (id < 3.5f)
            {
                a = float4(5.3693180084228515625f, 5.32034206390380859375f, 256.0f, 0.0f);
                b = 0.0f.xxxx;
                c = 1.0f;
            }
            else
            {
                if (id < 4.5f)
                {
                    a = float4(6.71164703369140625f, 6.652800083160400390625f, 320.0f, 0.0f);
                    b = float4(0.5f, 0.75f, 0.5f, 0.5f);
                    c = 0.0f;
                }
                else
                {
                    if (id < 5.5f)
                    {
                        a = float4(13.5f, 13.5f, 640.0f, 0.0f);
                        b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                        c = 0.0f;
                    }
                    else
                    {
                        if (id < 6.5f)
                        {
                            a = float4(7.1590900421142578125f, 7.0937900543212890625f, 320.0f, 0.0f);
                            b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                            c = 0.0f;
                        }
                        else
                        {
                            if (id < 7.5f)
                            {
                                a = float4(12.5874996185302734375f, 12.5874996185302734375f, 320.0f, 1.0f);
                                b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                                c = 0.0f;
                            }
                            else
                            {
                                if (id < 8.5f)
                                {
                                    a = float4(6.71164703369140625f, 6.71164703369140625f, 320.0f, 0.0f);
                                    b = float4(0.5f, 0.75f, 0.5f, 0.5f);
                                    c = 0.0f;
                                }
                                else
                                {
                                    a = float4(16.0f, 16.0f, 496.0f, 2.0f);
                                    b = float4(0.5f, 0.75f, 0.75f, 0.875f);
                                    c = 0.0f;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

vs_Timing vs_getTiming(float2 orig, uint frameCount)
{
    float2 param = orig;
    vs_Timing t;
    t.scale = vs_upscaleOf(param);
    float2 nat = orig / t.scale.xx;
    float _415;
    if (global_LR_CONSOLE < 0.5f)
    {
        float2 param_1 = nat;
        _415 = vs_autoConsole(param_1);
    }
    else
    {
        _415 = global_LR_CONSOLE;
    }
    float id = _415;
    float param_2 = id;
    float4 param_3;
    float4 param_4;
    float param_5;
    vs_consoleTable(param_2, param_3, param_4, param_5);
    float4 a = param_3;
    float4 b = param_4;
    float c = param_5;
    t.id = id;
    bool _443 = (id > 4.5f) && (id < 5.5f);
    bool _450;
    if (_443)
    {
        _450 = nat.x > 700.0f;
    }
    else
    {
        _450 = _443;
    }
    if (_450)
    {
        a.z = 720.0f;
    }
    t.scan = a.w;
    bool _463 = t.scan < 0.5f;
    bool _469;
    if (_463)
    {
        _469 = nat.y > 300.0f;
    }
    else
    {
        _469 = _463;
    }
    t.interlace = float(_469);
    bool amiga = (id > 5.5f) && (id < 6.5f);
    if (global_LR_NORM > 1.5f)
    {
        t.pal = 1.0f;
    }
    else
    {
        if (global_LR_NORM > 0.5f)
        {
            t.pal = 0.0f;
        }
        else
        {
            float _498;
            if (t.interlace > 0.5f)
            {
                _498 = nat.y * 0.5f;
            }
            else
            {
                _498 = nat.y;
            }
            float lines = _498;
            bool _510 = t.scan < 0.5f;
            bool _519;
            if (_510)
            {
                _519 = lines > (amiga ? 249.5f : 240.5f);
            }
            else
            {
                _519 = _510;
            }
            t.pal = float(_519);
        }
    }
    float base = lerp(a.x, a.y, t.pal);
    t.pclk = (base * orig.x) / a.z;
    float _543;
    if (orig.x < 480.0f)
    {
        _543 = 1.0f;
    }
    else
    {
        _543 = (orig.x < 960.0f) ? 2.0f : 4.0f;
    }
    float cls = _543;
    if (amiga)
    {
        t.pclk = (base * (320.0f * cls)) / a.z;
    }
    bool _566 = t.scan > 0.5f;
    bool _572;
    if (_566)
    {
        _572 = t.scan < 1.5f;
    }
    else
    {
        _572 = _566;
    }
    bool _578;
    if (_572)
    {
        _578 = orig.x > 720.0f;
    }
    else
    {
        _578 = _572;
    }
    if (_578)
    {
        t.pclk = ((78.75f * orig.x) * orig.y) / 786432.0f;
    }
    float _593;
    if (amiga)
    {
        _593 = cls;
    }
    else
    {
        _593 = orig.x / a.z;
    }
    t.hres = _593;
    t.fsc = (t.pal > 0.5f) ? 4.433619022369384765625f : 3.57954502105712890625f;
    t.lineFrac = lerp(b.x, b.y, t.pal);
    t.fieldStep = lerp(b.z, b.w, t.pal);
    float _634;
    if (global_LR_STEADY > 0.5f)
    {
        _634 = 0.0f;
    }
    else
    {
        _634 = float(frameCount % 24u);
    }
    float fc = _634;
    t.framePhase = frac(fc * t.fieldStep);
    t.vsw = vs_mod(fc * c, 2.0f);
    return t;
}

bool vs_isAmiga(vs_Timing t)
{
    bool _390 = t.id > 5.5f;
    bool _396;
    if (_390)
    {
        _396 = t.id < 6.5f;
    }
    else
    {
        _396 = _390;
    }
    return _396;
}

float2 vs_consoleUnit(vs_Timing t)
{
    vs_Timing param = t;
    float2 _662;
    if (vs_isAmiga(param))
    {
        _662 = float2(t.hres, (t.interlace > 0.5f) ? 2.0f : 1.0f);
    }
    else
    {
        _662 = 1.0f.xx;
    }
    return _662;
}

void vs_vert_main()
{
    vs_gl_Position = mul(vs_Position, global_MVP);
    vs_vTexCoord = vs_TexCoord;
    float2 param = params_OriginalSize.xy;
    uint param_1 = params_FrameCount;
    vs_Timing T = vs_getTiming(param, param_1);
    vs_vScale = T.scale;
    vs_Timing param_2 = T;
    vs_vUnit = vs_consoleUnit(param_2).x;
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
    stage_output.packed0.z = vs_vScale;
    stage_output.packed0.w = vs_vUnit;
    return stage_output;
}

float4 ps_sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }
static const float ps__160[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };







static float ps_vUnit;
static float2 ps_vTexCoord;
static float ps_vScale;
static float4 ps_FragColor;

struct ps_SPIRV_Cross_Input
{
float4 packed0 : TEXCOORD0;
};

struct ps_SPIRV_Cross_Output
{
    float4 ps_FragColor : COLOR0;
};

void ps_frag_main()
{
    float dx = (params_OutputSize.z * global_LR_GLOW_SIZE) * ps_vUnit;
    float2 tc = ps_vTexCoord;
    if (ps_vScale > 1.5f)
    {
        float lines = params_SourceSize.y / ps_vScale;
        tc.y = ((floor(tc.y * lines) * ps_vScale) + 0.5f) * params_SourceSize.w;
    }
    float3 acc = 0.0f.xxx;
    float ws = 0.0f;
    for (int k = -6; k <= 6; k++)
    {
        float w = exp(((-0.5f) * float(k * k)) / 9.0f);
        float2 p = tc + float2(float(k) * dx, 0.0f);
        float3 c = (tex2Dlod(LIBRA_SAMPLER2D_2, float4(p - float2(0.25f * dx, 0.0f), 0.0, 0.0f)).xyz + tex2Dlod(LIBRA_SAMPLER2D_2, float4(p + float2(0.25f * dx, 0.0f), 0.0, 0.0f)).xyz) * 0.5f;
        acc += (pow(c, global_LR_GAMMA.xxx) * w);
        ws += w;
    }
    ps_FragColor = float4(acc / ws.xxx, 1.0f);
}

ps_SPIRV_Cross_Output ps_main(ps_SPIRV_Cross_Input stage_input)
{
    ps_vUnit = stage_input.packed0.w;
    ps_vTexCoord = stage_input.packed0.xy;
    ps_vScale = stage_input.packed0.z;
    ps_frag_main();
    ps_SPIRV_Cross_Output stage_output;
    stage_output.ps_FragColor = float4(ps_FragColor);
    return stage_output;
}

technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }
