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

static const float ps__975[5] = { 1.0f, 0.726149022579193115234375f, 0.278037011623382568359375f, 0.056134998798370361328125f, 0.005975999869406223297119140625f };







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
    bool _371 = id < 5.5f;
    bool _380;
    if (!_371)
    {
        _380 = (id > 7.5f) && (id < 8.5f);
    }
    else
    {
        _380 = _371;
    }
    bool tv = _380;
    float base = ((id > 4.5f) && (id < 5.5f)) ? 480.0f : 240.0f;
    bool _393;
    if (id < 0.5f)
    {
        _393 = orig.y > 576.0f;
    }
    else
    {
        bool _409;
        if (tv)
        {
            _409 = orig.y > (base * 1.5f);
        }
        else
        {
            _409 = tv;
        }
        _393 = _409;
    }
    bool scaled = _393;
    if (!scaled)
    {
        return 1.0f;
    }
    for (float k = 2.0f; k <= 16.0f; k += 1.0f)
    {
        float lines = orig.y / k;
        bool _432 = lines == floor(lines);
        bool _440;
        if (_432)
        {
            _440 = lines >= (base * 0.829999983310699462890625f);
        }
        else
        {
            _440 = _432;
        }
        bool _448;
        if (_440)
        {
            _448 = lines <= (base * 1.21000003814697265625f);
        }
        else
        {
            _448 = _440;
        }
        if (_448)
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
    bool _144 = !mon15;
    bool _171;
    if (_144)
    {
        bool _153 = (w == 320.0f) && (h == 200.0f);
        bool _170;
        if (!_153)
        {
            bool _159 = w == 640.0f;
            bool _169;
            if (_159)
            {
                _169 = (h == 350.0f) || (h == 400.0f);
            }
            else
            {
                _169 = _159;
            }
            _170 = _169;
        }
        else
        {
            _170 = _153;
        }
        _171 = _170;
    }
    else
    {
        _171 = _144;
    }
    if (_171)
    {
        return 7.0f;
    }
    bool _182 = (h == 256.0f) || (h == 512.0f);
    bool _191;
    if (!_182)
    {
        _191 = (w == 640.0f) && (h == 200.0f);
    }
    else
    {
        _191 = _182;
    }
    if (_191)
    {
        return 6.0f;
    }
    bool _204;
    if (mon15)
    {
        _204 = (h == 200.0f) || (h == 400.0f);
    }
    else
    {
        _204 = mon15;
    }
    bool _212;
    if (_204)
    {
        _212 = (w == 320.0f) || (w == 640.0f);
    }
    else
    {
        _212 = _204;
    }
    if (_212)
    {
        return 6.0f;
    }
    bool _226 = ((w == 360.0f) || (w == 720.0f)) || (w == 1440.0f);
    bool _244;
    if (_226)
    {
        _244 = (((h == 287.0f) || (h == 574.0f)) || (h == 242.0f)) || (h == 484.0f);
    }
    else
    {
        _244 = _226;
    }
    if (_244)
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
    float _480;
    if (global_LR_CONSOLE < 0.5f)
    {
        float2 param_1 = nat;
        _480 = ps_autoConsole(param_1);
    }
    else
    {
        _480 = global_LR_CONSOLE;
    }
    float id = _480;
    float param_2 = id;
    float4 param_3;
    float4 param_4;
    float param_5;
    ps_consoleTable(param_2, param_3, param_4, param_5);
    float4 a = param_3;
    float4 b = param_4;
    float c = param_5;
    t.id = id;
    bool _509 = (id > 4.5f) && (id < 5.5f);
    bool _516;
    if (_509)
    {
        _516 = nat.x > 700.0f;
    }
    else
    {
        _516 = _509;
    }
    if (_516)
    {
        a.z = 720.0f;
    }
    t.scan = a.w;
    bool _528 = t.scan < 0.5f;
    bool _534;
    if (_528)
    {
        _534 = nat.y > 300.0f;
    }
    else
    {
        _534 = _528;
    }
    t.interlace = float(_534);
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
            float _563;
            if (t.interlace > 0.5f)
            {
                _563 = nat.y * 0.5f;
            }
            else
            {
                _563 = nat.y;
            }
            float lines = _563;
            bool _575 = t.scan < 0.5f;
            bool _584;
            if (_575)
            {
                _584 = lines > (amiga ? 249.5f : 240.5f);
            }
            else
            {
                _584 = _575;
            }
            t.pal = float(_584);
        }
    }
    float base = lerp(a.x, a.y, t.pal);
    t.pclk = (base * orig.x) / a.z;
    float _608;
    if (orig.x < 480.0f)
    {
        _608 = 1.0f;
    }
    else
    {
        _608 = (orig.x < 960.0f) ? 2.0f : 4.0f;
    }
    float cls = _608;
    if (amiga)
    {
        t.pclk = (base * (320.0f * cls)) / a.z;
    }
    bool _631 = t.scan > 0.5f;
    bool _637;
    if (_631)
    {
        _637 = t.scan < 1.5f;
    }
    else
    {
        _637 = _631;
    }
    bool _643;
    if (_637)
    {
        _643 = orig.x > 720.0f;
    }
    else
    {
        _643 = _637;
    }
    if (_643)
    {
        t.pclk = ((78.75f * orig.x) * orig.y) / 786432.0f;
    }
    float _658;
    if (amiga)
    {
        _658 = cls;
    }
    else
    {
        _658 = orig.x / a.z;
    }
    t.hres = _658;
    t.fsc = (t.pal > 0.5f) ? 4.433619022369384765625f : 3.57954502105712890625f;
    t.lineFrac = lerp(b.x, b.y, t.pal);
    t.fieldStep = lerp(b.z, b.w, t.pal);
    float _698;
    if (global_LR_STEADY > 0.5f)
    {
        _698 = 0.0f;
    }
    else
    {
        _698 = float(frameCount % 24u);
    }
    float fc = _698;
    t.framePhase = frac(fc * t.fieldStep);
    t.vsw = ps_mod(fc * c, 2.0f);
    return t;
}

float3 ps_srcPix(float xs, float y, float k)
{
    bool _832 = xs < 0.0f;
    bool _844;
    if (!_832)
    {
        _844 = xs >= params_SourceSize.x;
    }
    else
    {
        _844 = _832;
    }
    if (_844)
    {
        return 0.0f.xxx;
    }
    float u = (floor(xs) + 0.5f) * params_SourceSize.z;
    float3 c = 0.0f.xxx;
    for (float r = 0.0f; r < k; r += 1.0f)
    {
        c += tex2Dlod(LIBRA_SAMPLER2D_2, float4(float2(u, ((y + r) + 0.5f) * params_SourceSize.w), 0.0, 0.0f)).xyz;
    }
    return c / k.xxx;
}

float ps_dbSign(int k)
{
    return ((abs(k) & 1) == 1) ? (-1.0f) : 1.0f;
}

float ps_nativeLine(float y, ps_Timing t)
{
    return floor(y / t.scale);
}

bool ps_oddField(float y, ps_Timing t)
{
    bool _752 = t.interlace > 0.5f;
    bool _762;
    if (_752)
    {
        float param = y;
        ps_Timing param_1 = t;
        _762 = ps_mod(ps_nativeLine(param, param_1), 2.0f) > 0.5f;
    }
    else
    {
        _762 = _752;
    }
    return _762;
}

float ps_physLine(float y, ps_Timing t)
{
    float param = y;
    ps_Timing param_1 = t;
    float l = ps_nativeLine(param, param_1);
    float _739;
    if (t.interlace > 0.5f)
    {
        _739 = floor(l * 0.5f);
    }
    else
    {
        _739 = l;
    }
    return _739;
}

float ps_phaseAt(float tUs, float y, ps_Timing t)
{
    float param = y;
    ps_Timing param_1 = t;
    float _771;
    if (ps_oddField(param, param_1))
    {
        _771 = t.fieldStep;
    }
    else
    {
        _771 = 0.0f;
    }
    float fo = _771;
    float param_2 = y;
    ps_Timing param_3 = t;
    return 6.283185482025146484375f * frac(((frac(t.fsc * tUs) + frac(t.lineFrac * ps_physLine(param_2, param_3))) + fo) + t.framePhase);
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

float2 ps_enc(float n, float y, float fs, ps_Timing T, float trap, float blend)
{
    float ppx = T.pclk / fs;
    float xs = (n + 0.5f) * ppx;
    float param = xs;
    float param_1 = y;
    float param_2 = T.scale;
    float3 c = ps_srcPix(param, param_1, param_2);
    float Y = dot(c, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
    if (blend > 0.0f)
    {
        float sp = T.scale;
        float j0 = floor(xs / sp);
        float param_3 = (j0 + 0.5f) * sp;
        float param_4 = y;
        float param_5 = T.scale;
        float y0 = dot(ps_srcPix(param_3, param_4, param_5), float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
        float a = 0.0f;
        for (int k = -4; k <= 4; k++)
        {
            float param_6 = ((j0 + float(k)) + 0.5f) * sp;
            float param_7 = y;
            float param_8 = T.scale;
            float yk = dot(ps_srcPix(param_6, param_7, param_8), float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
            int param_9 = k;
            a += ((ps__975[abs(k)] * ps_dbSign(param_9)) * (yk - y0));
        }
        Y -= ((blend * a) / 3.12913608551025390625f);
    }
    float param_10 = n / fs;
    float param_11 = y;
    ps_Timing param_12 = T;
    float ph = ps_phaseAt(param_10, param_11, param_12);
    float sigUs = 0.088333331048488616943359375f;
    float2 uv = 0.0f.xx;
    float ws = 0.0f;
    for (int k_1 = -8; k_1 <= 8; k_1++)
    {
        float u = float(k_1) * 0.4000000059604644775390625f;
        float w = exp(((-0.5f) * u) * u);
        float param_13 = xs + ((u * sigUs) * T.pclk);
        float param_14 = y;
        float param_15 = T.scale;
        float3 cc = ps_srcPix(param_13, param_14, param_15);
        float yy = dot(cc, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
        uv += (float2(0.4920000135898590087890625f * (cc.z - yy), 0.87699997425079345703125f * (cc.x - yy)) * w);
        ws += w;
    }
    uv /= ws.xx;
    if (trap > 0.0f)
    {
        float sigT = 0.26499998569488525390625f;
        float da = ((6.283185482025146484375f * T.fsc) * 0.25f) * sigT;
        float2 rp = float2(cos(da), sin(da));
        float2 e = float2(cos(ph - (12.0f * da)), sin(ph - (12.0f * da)));
        float2 yb = 0.0f.xx;
        float wt = 0.0f;
        for (int k_2 = -12; k_2 <= 12; k_2++)
        {
            float u_1 = float(k_2) * 0.25f;
            float w_1 = exp(((-0.5f) * u_1) * u_1);
            float param_16 = xs + ((u_1 * sigT) * T.pclk);
            float param_17 = y;
            float param_18 = T.scale;
            float yy_1 = dot(ps_srcPix(param_16, param_17, param_18), float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
            yb += (e.yx * (w_1 * yy_1));
            wt += w_1;
            e = float2((e.x * rp.x) - (e.y * rp.y), (e.y * rp.x) + (e.x * rp.y));
        }
        Y -= (((trap * 2.0f) * ((yb.x * sin(ph)) + (yb.y * cos(ph)))) / wt);
    }
    float param_19 = y;
    ps_Timing param_20 = T;
    return float2(Y, (uv.x * sin(ph)) + ((ps_vSign(param_19, param_20) * uv.y) * cos(ph)));
}

float ps_hash13(inout float3 p3)
{
    p3 = frac(p3 * 0.103100001811981201171875f);
    p3 += dot(p3, p3.zyx + 31.31999969482421875f.xxx).xxx;
    return frac((p3.x + p3.y) * p3.z);
}

void ps_frag_main()
{
    float2 param = params_OriginalSize.xy;
    uint param_1 = params_FrameCount;
    ps_Timing T = ps_getTiming(param, param_1);
    float SW = params_OutputSize.x;
    float fs = (T.pclk * SW) / params_SourceSize.x;
    float n = floor(ps_vTexCoord.x * SW);
    float y = floor(ps_vTexCoord.y * params_SourceSize.y);
    float cable = global_LR_CABLE;
    bool _1271 = cable > 2.5f;
    bool _1280;
    if (!_1271)
    {
        _1280 = ps_mod(y, T.scale) > 0.5f;
    }
    else
    {
        _1280 = _1271;
    }
    if (_1280)
    {
        ps_FragColor = 0.0f.xxxx;
        return;
    }
    float _1289;
    if (cable < 1.5f)
    {
        _1289 = global_LR_YTRAP;
    }
    else
    {
        _1289 = 0.0f;
    }
    float trap = _1289;
    float _1299;
    if (cable > 1.5f)
    {
        _1299 = global_LR_DBLEND;
    }
    else
    {
        _1299 = 0.0f;
    }
    float blend = _1299;
    float param_2 = n;
    float param_3 = y;
    float param_4 = fs;
    ps_Timing param_5 = T;
    float param_6 = trap;
    float param_7 = blend;
    float2 a = ps_enc(param_2, param_3, param_4, param_5, param_6, param_7);
    float2 r;
    if (cable < 0.5f)
    {
        float comp = a.x + a.y;
        float param_8 = n - (0.800000011920928955078125f * fs);
        float param_9 = y;
        float param_10 = fs;
        ps_Timing param_11 = T;
        float param_12 = trap;
        float param_13 = 0.0f;
        float2 g = ps_enc(param_8, param_9, param_10, param_11, param_12, param_13);
        comp += (0.119999997317790985107421875f * (g.x + g.y));
        float seed = float(params_FrameCount % 997u);
        float3 param_14 = float3(n, y, seed);
        float _1367 = ps_hash13(param_14);
        comp += ((_1367 - 0.5f) * global_LR_NOISE);
        float3 param_15 = float3(floor(n / 7.0f), y, seed + 3.0f);
        float _1384 = ps_hash13(param_15);
        comp += (((_1384 - 0.5f) * global_LR_NOISE) * 0.800000011920928955078125f);
        float param_16 = y;
        ps_Timing param_17 = T;
        comp += ((sin((ps_nativeLine(param_16, param_17) * 0.04500000178813934326171875f) + (seed * 0.37000000476837158203125f)) * global_LR_NOISE) * 0.119999997317790985107421875f);
        r = float2(comp, 0.0f);
    }
    else
    {
        if (cable < 1.5f)
        {
            r = float2(a.x + a.y, 0.0f);
        }
        else
        {
            r = a;
        }
    }
    ps_FragColor = float4(r, 0.0f, 1.0f);
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
