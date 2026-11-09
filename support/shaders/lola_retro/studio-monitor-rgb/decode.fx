// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.
// Pinned upstream 6383ff7357be32c95baf6d31b4a1b1d3cd5c7069
// Isolated Infinite D3D9 prototype; preset studio-monitor-rgb, explicit arcade timing 8.
row_major float4x4 global_MVP;
static const float global_LR_HDR_SRC = 0.0;
static const float global_LR_CONSOLE = 8;
static const float global_LR_NORM = 0;
static const float global_LR_HDR_SIG = 0.0;
static const float global_LR_CABLE = 3;
static const float global_LR_COMB = 0;
static const float global_LR_YTRAP = 0.75;
static const float global_LR_DBLEND = 0.0;
static const float global_LR_SHARP = 0;
static const float global_LR_SAT = 1;
static const float global_LR_TINT = 0;
static const float global_LR_DEMOD = 1;
static const float global_LR_BRIGHT = 0;
static const float global_LR_CONTRAST = 1;
static const float global_LR_NOISE = 0;
static const float global_LR_STEADY = 1;
static const float global_LR_HDR_BEAM = 0.0;
static const float global_LR_SIG_LO = 0.14;
static const float global_LR_SIG_HI = 0.32;
static const float global_LR_HFOCUS = 0.3;
static const float global_LR_GAMMA = 2.4;
static const float global_LR_PERSIST = 0.04;
static const float global_LR_CONV = 0.05;
static const float global_LR_HDR_MASK = 0.0;
static const float global_LR_MASK_TYPE = 1;
static const float global_LR_MASK_STR = 0.6;
static const float global_LR_MASK_TRIADS = 450;
static const float global_LR_WHITE = 6500;
static const float global_LR_PHOS = 3;
static const float global_LR_HDR_GLASS = 0.0;
static const float global_LR_CURV_X = 0;
static const float global_LR_CURV_Y = 0;
static const float global_LR_CORNER = 0;
static const float global_LR_GLOW = 0.03;
static const float global_LR_GLOW_SIZE = 0.5;
static const float global_LR_VIGNETTE = 0.15;
static const float global_LR_OVERSCAN = 0.03;
static const float global_LR_AMBIENT = 0;
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
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
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
struct ps_Timing
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

static const float ps__1215[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };








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

float ps_upscaleOf(float2 orig)
{
    float id = global_LR_CONSOLE;
    bool _356 = id < 5.5f;
    bool _365;
    if (!_356)
    {
        _365 = (id > 7.5f) && (id < 8.5f);
    }
    else
    {
        _365 = _356;
    }
    bool tv = _365;
    float base = ((id > 4.5f) && (id < 5.5f)) ? 480.0f : 240.0f;
    bool _378;
    if (id < 0.5f)
    {
        _378 = orig.y > 576.0f;
    }
    else
    {
        bool _394;
        if (tv)
        {
            _394 = orig.y > (base * 1.5f);
        }
        else
        {
            _394 = tv;
        }
        _378 = _394;
    }
    bool scaled = _378;
    if (!scaled)
    {
        return 1.0f;
    }
    for (float k = 2.0f; k <= 16.0f; k += 1.0f)
    {
        float lines = orig.y / k;
        bool _417 = lines == floor(lines);
        bool _425;
        if (_417)
        {
            _425 = lines >= (base * 0.829999983310699462890625f);
        }
        else
        {
            _425 = _417;
        }
        bool _433;
        if (_425)
        {
            _433 = lines <= (base * 1.21000003814697265625f);
        }
        else
        {
            _433 = _425;
        }
        if (_433)
        {
            return k;
        }
    }
    return max(1.0f, floor((orig.y / base) + 0.5f));
}

float ps_autoConsole(float2 s)
{
    float w = s.x;
    float h = s.y;
    bool mon15 = global_LR_MON_MM > 0.5f;
    bool _129 = !mon15;
    bool _156;
    if (_129)
    {
        bool _138 = (w == 320.0f) && (h == 200.0f);
        bool _155;
        if (!_138)
        {
            bool _144 = w == 640.0f;
            bool _154;
            if (_144)
            {
                _154 = (h == 350.0f) || (h == 400.0f);
            }
            else
            {
                _154 = _144;
            }
            _155 = _154;
        }
        else
        {
            _155 = _138;
        }
        _156 = _155;
    }
    else
    {
        _156 = _129;
    }
    if (_156)
    {
        return 7.0f;
    }
    bool _167 = (h == 256.0f) || (h == 512.0f);
    bool _176;
    if (!_167)
    {
        _176 = (w == 640.0f) && (h == 200.0f);
    }
    else
    {
        _176 = _167;
    }
    if (_176)
    {
        return 6.0f;
    }
    bool _189;
    if (mon15)
    {
        _189 = (h == 200.0f) || (h == 400.0f);
    }
    else
    {
        _189 = mon15;
    }
    bool _197;
    if (_189)
    {
        _197 = (w == 320.0f) || (w == 640.0f);
    }
    else
    {
        _197 = _189;
    }
    if (_197)
    {
        return 6.0f;
    }
    bool _211 = ((w == 360.0f) || (w == 720.0f)) || (w == 1440.0f);
    bool _229;
    if (_211)
    {
        _229 = (((h == 287.0f) || (h == 574.0f)) || (h == 242.0f)) || (h == 484.0f);
    }
    else
    {
        _229 = _211;
    }
    if (_229)
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

void ps_consoleTable(float id, out float4 a, out float4 b, out float c)
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

ps_Timing ps_getTiming(float2 orig, uint frameCount)
{
    float2 param = orig;
    ps_Timing t;
    t.scale = ps_upscaleOf(param);
    float2 nat = orig / t.scale.xx;
    float _465;
    if (global_LR_CONSOLE < 0.5f)
    {
        float2 param_1 = nat;
        _465 = ps_autoConsole(param_1);
    }
    else
    {
        _465 = global_LR_CONSOLE;
    }
    float id = _465;
    float param_2 = id;
    float4 param_3;
    float4 param_4;
    float param_5;
    ps_consoleTable(param_2, param_3, param_4, param_5);
    float4 a = param_3;
    float4 b = param_4;
    float c = param_5;
    t.id = id;
    bool _494 = (id > 4.5f) && (id < 5.5f);
    bool _501;
    if (_494)
    {
        _501 = nat.x > 700.0f;
    }
    else
    {
        _501 = _494;
    }
    if (_501)
    {
        a.z = 720.0f;
    }
    t.scan = a.w;
    bool _514 = t.scan < 0.5f;
    bool _520;
    if (_514)
    {
        _520 = nat.y > 300.0f;
    }
    else
    {
        _520 = _514;
    }
    t.interlace = float(_520);
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
            float _549;
            if (t.interlace > 0.5f)
            {
                _549 = nat.y * 0.5f;
            }
            else
            {
                _549 = nat.y;
            }
            float lines = _549;
            bool _561 = t.scan < 0.5f;
            bool _570;
            if (_561)
            {
                _570 = lines > (amiga ? 249.5f : 240.5f);
            }
            else
            {
                _570 = _561;
            }
            t.pal = float(_570);
        }
    }
    float base = lerp(a.x, a.y, t.pal);
    t.pclk = (base * orig.x) / a.z;
    float _594;
    if (orig.x < 480.0f)
    {
        _594 = 1.0f;
    }
    else
    {
        _594 = (orig.x < 960.0f) ? 2.0f : 4.0f;
    }
    float cls = _594;
    if (amiga)
    {
        t.pclk = (base * (320.0f * cls)) / a.z;
    }
    bool _617 = t.scan > 0.5f;
    bool _623;
    if (_617)
    {
        _623 = t.scan < 1.5f;
    }
    else
    {
        _623 = _617;
    }
    bool _629;
    if (_623)
    {
        _629 = orig.x > 720.0f;
    }
    else
    {
        _629 = _623;
    }
    if (_629)
    {
        t.pclk = ((78.75f * orig.x) * orig.y) / 786432.0f;
    }
    float _644;
    if (amiga)
    {
        _644 = cls;
    }
    else
    {
        _644 = orig.x / a.z;
    }
    t.hres = _644;
    t.fsc = (t.pal > 0.5f) ? 4.433619022369384765625f : 3.57954502105712890625f;
    t.lineFrac = lerp(b.x, b.y, t.pal);
    t.fieldStep = lerp(b.z, b.w, t.pal);
    float _684;
    if (global_LR_STEADY > 0.5f)
    {
        _684 = 0.0f;
    }
    else
    {
        _684 = float(frameCount % 24u);
    }
    float fc = _684;
    t.framePhase = frac(fc * t.fieldStep);
    t.vsw = ps_mod(fc * c, 2.0f);
    return t;
}

bool ps_isPC(float scan)
{
    return (scan > 0.5f) && (scan < 1.5f);
}

float3 ps_origPix(float xs, float y, float k)
{
    bool _967 = xs < 0.0f;
    bool _975;
    if (!_967)
    {
        _975 = xs >= params_OriginalSize.x;
    }
    else
    {
        _975 = _967;
    }
    if (_975)
    {
        return 0.0f.xxx;
    }
    float u = (floor(xs) + 0.5f) * params_OriginalSize.z;
    float3 c = 0.0f.xxx;
    for (float r = 0.0f; r < k; r += 1.0f)
    {
        c += tex2Dlod(LIBRA_SAMPLER2D_3, float4(float2(u, ((y + r) + 0.5f) * params_OriginalSize.w), 0.0, 0.0f)).xyz;
    }
    return c / k.xxx;
}

float ps_dbSign(int k)
{
    return ((abs(k) & 1) == 1) ? (-1.0f) : 1.0f;
}

float2 ps_sig(float s, float y)
{
    if (y < 0.0f)
    {
        return 0.0f.xx;
    }
    return tex2Dlod(LIBRA_SAMPLER2D_2, float4(float2((s + 0.5f) * params_SourceSize.z, (y + 0.5f) * params_SourceSize.w), 0.0, 0.0f)).xy;
}

float ps_nativeLine(float y, ps_Timing t)
{
    return floor(y / t.scale);
}

float ps_physLine(float y, ps_Timing t)
{
    float param = y;
    ps_Timing param_1 = t;
    float l = ps_nativeLine(param, param_1);
    float _725;
    if (t.interlace > 0.5f)
    {
        _725 = floor(l * 0.5f);
    }
    else
    {
        _725 = l;
    }
    return _725;
}

bool ps_oddField(float y, ps_Timing t)
{
    bool _738 = t.interlace > 0.5f;
    bool _748;
    if (_738)
    {
        float param = y;
        ps_Timing param_1 = t;
        _748 = ps_mod(ps_nativeLine(param, param_1), 2.0f) > 0.5f;
    }
    else
    {
        _748 = _738;
    }
    return _748;
}

float ps_vSign(float y, ps_Timing t)
{
    if (t.pal < 0.5f)
    {
        return 1.0f;
    }
    float param = y;
    ps_Timing param_1 = t;
    float param_2 = y;
    ps_Timing param_3 = t;
    float pl = (ps_physLine(param, param_1) + t.vsw) + float(ps_oddField(param_2, param_3));
    return (ps_mod(pl, 2.0f) < 0.5f) ? 1.0f : (-1.0f);
}

float ps_phaseAt(float tUs, float y, ps_Timing t)
{
    float param = y;
    ps_Timing param_1 = t;
    float _757;
    if (ps_oddField(param, param_1))
    {
        _757 = t.fieldStep;
    }
    else
    {
        _757 = 0.0f;
    }
    float fo = _757;
    float param_2 = y;
    ps_Timing param_3 = t;
    return 6.283185482025146484375f * frac(((frac(t.fsc * tUs) + frac(t.lineFrac * ps_physLine(param_2, param_3))) + fo) + t.framePhase);
}

float2 ps_rotate(float2 e, float2 r)
{
    return float2((e.x * r.x) - (e.y * r.y), (e.y * r.x) + (e.x * r.y));
}

float ps_decoderType(ps_Timing t, float cable)
{
    if (global_LR_DEMOD > 0.5f)
    {
        return global_LR_DEMOD;
    }
    return ((t.pal < 0.5f) && (cable < 2.5f)) ? 2.0f : 1.0f;
}

float3 ps_decodeRGB(float Y, float2 uv, float dec)
{
    if (dec < 1.5f)
    {
        return float3(Y + (1.13982999324798583984375f * uv.y), (Y - (0.3946500122547149658203125f * uv.x)) - (0.5806000232696533203125f * uv.y), Y + (2.0321099758148193359375f * uv.x));
    }
    bool us = dec < 2.5f;
    float ar = radians(us ? 112.0f : 95.0f);
    float gr = us ? 0.829999983310699462890625f : 0.7799999713897705078125f;
    float ag = radians(us ? 252.0f : 240.0f);
    float gg = 0.300000011920928955078125f;
    float ry = (((uv.x * cos(ar)) + (uv.y * sin(ar))) * gr) / 0.4920000135898590087890625f;
    float gy = (((uv.x * cos(ag)) + (uv.y * sin(ag))) * gg) / 0.4920000135898590087890625f;
    return float3(Y + ry, Y + gy, Y + (uv.x / 0.4920000135898590087890625f));
}

void ps_frag_main()
{
    float2 param = params_OriginalSize.xy;
    uint param_1 = params_FrameCount;
    ps_Timing T = ps_getTiming(param, param_1);
    float SW = params_SourceSize.x;
    float fs = (T.pclk * SW) / params_OriginalSize.x;
    float n = floor(ps_vTexCoord.x * SW);
    float y = floor(ps_vTexCoord.y * params_SourceSize.y);
    float st = ((T.interlace > 0.5f) ? 2.0f : 1.0f) * T.scale;
    float cable = global_LR_CABLE;
    if (ps_mod(y, T.scale) > 0.5f)
    {
        ps_FragColor = 0.0f.xxxx;
        return;
    }
    float Y;
    float2 uv;
    if (cable > 2.5f)
    {
        float xs = ((n + 0.5f) * T.pclk) / fs;
        float param_2 = T.scan;
        float sigPx = (0.132499992847442626953125f / (ps_isPC(param_2) ? 85.0f : 6.5f)) * T.pclk;
        float db = global_LR_DBLEND;
        float sp = T.scale;
        float j0 = floor(xs / sp);
        float3 alt[5];
        for (int i = 0; i < 5; i++)
        {
            alt[i] = 0.0f.xxx;
        }
        if (db > 0.0f)
        {
            float3 p[13];
            for (int i_1 = 0; i_1 < 13; i_1++)
            {
                float param_3 = ((j0 + float(i_1 - 6)) + 0.5f) * sp;
                float param_4 = y;
                float param_5 = T.scale;
                p[i_1] = ps_origPix(param_3, param_4, param_5);
            }
            for (int i_2 = 0; i_2 < 5; i_2++)
            {
                float3 a = 0.0f.xxx;
                for (int k = -4; k <= 4; k++)
                {
                    int param_6 = k;
                    a += ((p[(i_2 + 4) + k] - p[i_2 + 4]) * (ps__1215[abs(k)] * ps_dbSign(param_6)));
                }
                alt[i_2] = (a * db) / 3.12913608551025390625f.xxx;
            }
        }
        float3 acc = 0.0f.xxx;
        float ws = 0.0f;
        for (int k_1 = -3; k_1 <= 3; k_1++)
        {
            float w = exp((-0.5f) * float(k_1 * k_1));
            float xt = xs + (float(k_1) * sigPx);
            float param_7 = xt;
            float param_8 = y;
            float param_9 = T.scale;
            float3 v = ps_origPix(param_7, param_8, param_9);
            if (db > 0.0f)
            {
                v -= alt[clamp(int(floor(xt / sp) - j0) + 2, 0, 4)];
            }
            acc += (v * w);
            ws += w;
        }
        float3 c = acc / ws.xxx;
        Y = dot(c, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
        uv = float2(0.4920000135898590087890625f * (c.z - Y), 0.87699997425079345703125f * (c.x - Y));
    }
    else
    {
        bool pal = T.pal > 0.5f;
        bool sv = cable > 1.5f;
        bool _1359 = (((global_LR_COMB > 0.5f) && (!sv)) && (!pal)) && (cable > 0.5f);
        bool _1368;
        if (_1359)
        {
            _1368 = abs(T.lineFrac - 0.5f) < 0.0500000007450580596923828125f;
        }
        else
        {
            _1368 = _1359;
        }
        bool comb = _1368;
        float fcY;
        float notch;
        float fcC;
        if (cable < 0.5f)
        {
            fcY = pal ? 3.599999904632568359375f : 2.7999999523162841796875f;
            notch = 0.949999988079071044921875f;
            fcC = 0.5f;
        }
        else
        {
            if (!sv)
            {
                float _1387;
                if (comb)
                {
                    _1387 = 4.19999980926513671875f;
                }
                else
                {
                    _1387 = pal ? 4.19999980926513671875f : 3.2999999523162841796875f;
                }
                fcY = _1387;
                notch = comb ? 0.0f : 0.920000016689300537109375f;
                fcC = pal ? 0.800000011920928955078125f : 0.60000002384185791015625f;
            }
            else
            {
                fcY = pal ? 5.0f : 4.599999904632568359375f;
                notch = 0.0f;
                fcC = pal ? 1.0f : 0.89999997615814208984375f;
            }
        }
        float tn = n / fs;
        float sh = global_LR_SHARP * 1.39999997615814208984375f;
        float s1 = 0.132499992847442626953125f / fcY;
        float s2 = s1 * 2.5f;
        float mY = max(1.0f, ceil((0.25f * s2) * fs));
        float nY = min(ceil(((3.0f * s2) * fs) / mY), 12.0f);
        float c1 = (((-0.5f) * mY) * mY) / (((s1 * s1) * fs) * fs);
        float c2 = (((-0.5f) * mY) * mY) / (((s2 * s2) * fs) * fs);
        float a1 = 0.0f;
        float a2 = 0.0f;
        float w1s = 0.0f;
        float w2s = 0.0f;
        int nYi = int(nY);
        int _1479 = -nYi;
        for (int k_2 = _1479; k_2 <= nYi; k_2++)
        {
            float u = float(k_2);
            float w1 = exp((c1 * u) * u);
            float w2 = exp((c2 * u) * u);
            float sp_1 = n + (u * mY);
            float param_10 = sp_1;
            float param_11 = y;
            float s0 = ps_sig(param_10, param_11).x;
            if (comb)
            {
                float param_12 = sp_1;
                float param_13 = y - st;
                s0 = 0.5f * (s0 + ps_sig(param_12, param_13).x);
            }
            a1 += (w1 * s0);
            a2 += (w2 * s0);
            w1s += w1;
            w2s += w2;
        }
        Y = (((1.0f + sh) * a1) / w1s) - ((sh * a2) / w2s);
        float sc = 0.132499992847442626953125f / fcC;
        float mC = max(1.0f, ceil((0.1500000059604644775390625f * sc) * fs));
        float nC = min(ceil(((3.0f * sc) * fs) / mC), 20.0f);
        float cw = (((-0.5f) * mC) * mC) / (((sc * sc) * fs) * fs);
        float param_14 = y;
        ps_Timing param_15 = T;
        float vs = ps_vSign(param_14, param_15);
        float param_16 = y - st;
        ps_Timing param_17 = T;
        float vsp = ps_vSign(param_16, param_17);
        float _1612;
        if (pal)
        {
            _1612 = 0.0f;
        }
        else
        {
            _1612 = radians(global_LR_TINT);
        }
        float tint = _1612;
        if (cable < 0.5f)
        {
            float ea = ((-6.283185482025146484375f) * T.fsc) * 0.800000011920928955078125f;
            tint += atan2(0.119999997317790985107421875f * sin(ea), 1.0f + (0.119999997317790985107421875f * cos(ea)));
        }
        float param_18 = tn;
        float param_19 = y;
        ps_Timing param_20 = T;
        float ph0 = ps_phaseAt(param_18, param_19, param_20) + tint;
        float da = ((6.283185482025146484375f * T.fsc) * mC) / fs;
        float2 rp = float2(cos(da), sin(da));
        float2 e0 = float2(cos(ph0), sin(ph0));
        float a0 = ph0 - (nC * da);
        a0 -= (6.283185482025146484375f * floor((a0 / 6.283185482025146484375f) + 0.5f));
        float2 e = float2(cos(a0), sin(a0));
        float2 acc_1 = 0.0f.xx;
        float2 accp = 0.0f.xx;
        float wcs = 0.0f;
        int nCi = int(nC);
        int _1698 = -nCi;
        float _1731;
        float _1776;
        for (int k_3 = _1698; k_3 <= nCi; k_3++)
        {
            float u_1 = float(k_3);
            float w_1 = exp((cw * u_1) * u_1);
            float sp_2 = n + (u_1 * mC);
            float param_21 = sp_2;
            float param_22 = y;
            float2 v0 = ps_sig(param_21, param_22);
            if (sv)
            {
                _1731 = v0.y;
            }
            else
            {
                _1731 = v0.x;
            }
            float s0_1 = _1731;
            if (comb)
            {
                float param_23 = sp_2;
                float param_24 = y - st;
                s0_1 = 0.5f * (v0.x - ps_sig(param_23, param_24).x);
            }
            acc_1 += (e.yx * (w_1 * s0_1));
            if (pal)
            {
                float param_25 = sp_2;
                float param_26 = y - st;
                float2 vp = ps_sig(param_25, param_26);
                if (sv)
                {
                    _1776 = vp.y;
                }
                else
                {
                    _1776 = vp.x;
                }
                accp += (e.yx * (w_1 * _1776));
            }
            wcs += w_1;
            float2 param_27 = e;
            float2 param_28 = rp;
            e = ps_rotate(param_27, param_28);
        }
        float2 cs = float2(acc_1.x, vs * acc_1.y) * 2.0f;
        uv = cs / wcs.xx;
        if (((!sv) && (!comb)) && (notch > 0.0f))
        {
            float hf = ((1.0f + sh) * exp(((((-19.739200592041015625f) * s1) * s1) * T.fsc) * T.fsc)) - (sh * exp(((((-19.739200592041015625f) * s2) * s2) * T.fsc) * T.fsc));
            Y -= ((notch * hf) * ((uv.x * e0.y) + ((vs * uv.y) * e0.x)));
        }
        if (pal)
        {
            float param_29 = tn;
            float param_30 = y - st;
            ps_Timing param_31 = T;
            float dl = ps_phaseAt(param_29, param_30, param_31) - (ph0 - tint);
            float2 rd = float2(cos(dl), sin(dl));
            float2 csp = float2((accp.x * rd.x) + (accp.y * rd.y), vsp * ((accp.y * rd.x) - (accp.x * rd.y))) * 2.0f;
            uv = (uv + (csp / wcs.xx)) * 0.5f;
        }
        if (cable < 0.5f)
        {
            float ea_1 = ((-6.283185482025146484375f) * T.fsc) * 0.800000011920928955078125f;
            Y /= 1.12000000476837158203125f;
            uv /= length(float2(1.0f + (0.119999997317790985107421875f * cos(ea_1)), 0.119999997317790985107421875f * sin(ea_1))).xx;
        }
    }
    uv *= (global_LR_SAT * global_LR_CONTRAST);
    Y = (Y * global_LR_CONTRAST) + global_LR_BRIGHT;
    ps_Timing param_32 = T;
    float param_33 = cable;
    float param_34 = Y;
    float2 param_35 = uv;
    float param_36 = ps_decoderType(param_32, param_33);
    float3 rgb = ps_decodeRGB(param_34, param_35, param_36);
    ps_FragColor = float4(clamp(rgb, 0.0f.xxx, 1.0f.xxx), 1.0f);
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
