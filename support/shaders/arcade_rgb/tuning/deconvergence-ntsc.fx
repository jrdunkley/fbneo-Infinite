// Tunable adaptation; fixed original and notices are in the parent folder.
// Derived from crt/shaders/guest/advanced/deconvergence-ntsc.slang; see SOURCES and original shader notices.
row_major float4x4 global_MVP;
float4 global_SourceSize;
float4 global_OriginalSize;
float4 global_OutputSize;
uint global_FrameCount;
float global_bloom = 0.0;
float global_halation = 0.0;
static const float global_slotms = 1.0;
static const float global_mask_gamma = 2.549998;
float global_gamma_out = 1.95;
static const float global_overscanX = 0.0;
static const float global_overscanY = 0.0;
static const float global_VShift = 0.0;
static const float global_intres = 0.0;
static const float global_c_shape = 0.25;
static const float global_barspeed = 50.0;
static const float global_barintensity = 0.0;
static const float global_bardir = 0.0;
static const float global_sborder = 0.75;
static const float global_bloom_dist = 0.0;
float global_deconr;
static const float global_decons = 1.0;
static const float global_addnoised = 0.0;
static const float global_noiseresd = 2.0;
static const float global_noisetype = 0.0;
static const float global_deconrr = 2.500000;
static const float global_deconrg = 0.0;
static const float global_deconrb = -2.500000;
static const float global_deconrry = 2.500000;
static const float global_deconrgy = 0.0;
static const float global_deconrby = 2.500000;
static const float global_dctypex = 0.0;
static const float global_dctypey = 0.0;
static const float global_post_br = 1.0;
static const float global_maskboost = 3.000000;
static const float global_smoothmask = 0.0;
static const float global_gamma_c = 1.0;
static const float global_gamma_c2 = 1.0;
static const float global_m_glow = 1.000000;
static const float global_m_glow_low = 0.35;
static const float global_m_glow_high = 5.0;
static const float global_m_glow_dist = 1.0;
static const float global_m_glow_mask = 1.0;
static const float global_smask_mit = 0.0;
#ifndef RC_mask_zoom
#define RC_mask_zoom 0.0
#endif
static const float global_mask_zoom = RC_mask_zoom;
static const float global_no_scanlines = 0.0;
static const float global_bmask = 0.0;
static const float global_bmask1 = 0.0;
static const float global_hmask1 = 0.35;
static const float global_mzoom_sh = 0.0;
static const float global_mclip = 0.0;
static const float global_edgemask = 0.0;
static const float global_oimage = 0.0;
static const float global_interm = 2.0;
static const float params_IOS = 0.0;
static const float params_OS = 1.0;
static const float params_BLOOM = 0.0;
float params_brightboost = 1.40;
float params_brightboost1 = 1.10;
static const float params_csize = 0.0;
static const float params_bsize1 = 0.0;
float params_warpX = 0.0;
float params_warpY = 0.0;
float params_glow = 0.08;
#ifndef RC_shadowMask
#define RC_shadowMask 4.000000
#endif
static const float params_shadowMask = RC_shadowMask;
#ifndef RC_masksize
#define RC_masksize 1.0
#endif
float params_masksize = RC_masksize;
float params_slotmask = 0.0;
float params_slotmask1 = 0.0;
#ifndef RC_slotwidth
#define RC_slotwidth 0.0
#endif
static const float params_slotwidth = RC_slotwidth;
#ifndef RC_double_slot
#define RC_double_slot 2.0
#endif
static const float params_double_slot = RC_double_slot;
static const float params_mcut = 0.000000;
float params_maskDark = 1.100000;
float params_maskLight = 0.700000;
#ifndef RC_maskstr
#define RC_maskstr 1.000000
#endif
float params_maskstr = RC_maskstr;
static const float params_mshift = 0.500000;
static const float params_mask_layout = 0.0;
static const float params_mask_bloom = 0.0;
static const float params_hiscan = 0.0;
static const float params_pr_scan = 0.10;
texture Image7; sampler2D LIBRA_SAMPLER2D_7 : register(s5) = sampler_state { Texture = <Image7>; };
texture Image5; sampler2D LIBRA_SAMPLER2D_5 : register(s3) = sampler_state { Texture = <Image5>; };
texture Image4; sampler2D LIBRA_SAMPLER2D_4 : register(s2) = sampler_state { Texture = <Image4>; };
texture Image3; sampler2D LIBRA_SAMPLER2D_3 : register(s1) = sampler_state { Texture = <Image3>; };
texture Image2; sampler2D LIBRA_SAMPLER2D_2 : register(s0) = sampler_state { Texture = <Image2>; };
texture Image6; sampler2D LIBRA_SAMPLER2D_6 : register(s4) = sampler_state { Texture = <Image6>; };
texture Image8; sampler2D LIBRA_SAMPLER2D_8 : register(s6) = sampler_state { Texture = <Image8>; };
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
static const float ps__1840[15] = { 2.0f, 3.0f, 3.0f, 6.0f, 6.0f, 2.400000095367431640625f, 3.400000095367431640625f, 2.400000095367431640625f, 3.25f, 3.400000095367431640625f, 4.400000095367431640625f, 4.25f, 7.400000095367431640625f, 6.25f, 5.25f };













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

float2 ps_Overscan(inout float2 pos, float dx, float dy)
{
    pos = (pos * 2.0f) - 1.0f.xx;
    pos *= float2(dx, dy);
    return (pos * 0.5f) + 0.5f.xx;
}

float2 ps_Warp(inout float2 pos)
{
    pos = (pos * 2.0f) - 1.0f.xx;
    pos = lerp(pos, float2(pos.x * rsqrt(1.0f - ((global_c_shape * pos.y) * pos.y)), pos.y * rsqrt(1.0f - ((global_c_shape * pos.x) * pos.x))), float2(params_warpX, params_warpY) / global_c_shape.xx);
    return (pos * 0.5f) + 0.5f.xx;
}

void ps_fetch_pixel(inout float3 c, inout float3 b, inout float3 g, float2 coord, float2 bcoord)
{
    float stepx = global_OutputSize.z;
    float stepy = global_OutputSize.w;
    float ds = global_decons;
    float2 dx = float2(stepx, 0.0f);
    float2 dy = float2(0.0f, stepy);
    float posx = (2.0f * coord.x) - 1.0f;
    float posy = (2.0f * coord.y) - 1.0f;
    if (global_dctypex > 0.02500000037252902984619140625f)
    {
        posx = sign(posx) * pow(abs(posx), 1.0499999523162841796875f - global_dctypex);
        dx *= posx;
    }
    if (global_dctypey > 0.02500000037252902984619140625f)
    {
        posy = sign(posy) * pow(abs(posy), 1.0499999523162841796875f - global_dctypey);
        dy *= posy;
    }
    float2 rc = (dx * global_deconrr) + (dy * global_deconrry);
    float2 gc = (dx * global_deconrg) + (dy * global_deconrgy);
    float2 bc = (dx * global_deconrb) + (dy * global_deconrby);
    float r1 = ps_sample_lod0(LIBRA_SAMPLER2D_7, coord + rc).x;
    float g1 = ps_sample_lod0(LIBRA_SAMPLER2D_7, coord + gc).y;
    float b1 = ps_sample_lod0(LIBRA_SAMPLER2D_7, coord + bc).z;
    float3 d = float3(r1, g1, b1);
    c = clamp(lerp(c, d, ds.xxx), 0.0f.xxx, 1.0f.xxx);
    r1 = ps_sample_lod0(LIBRA_SAMPLER2D_5, bcoord + rc).x;
    g1 = ps_sample_lod0(LIBRA_SAMPLER2D_5, bcoord + gc).y;
    b1 = ps_sample_lod0(LIBRA_SAMPLER2D_5, bcoord + bc).z;
    d = float3(r1, g1, b1);
    float3 _1423 = lerp(b, d, min(ds, 1.0f).xxx);
    g = _1423;
    b = _1423;
    r1 = ps_sample_lod0(LIBRA_SAMPLER2D_4, bcoord + rc).x;
    g1 = ps_sample_lod0(LIBRA_SAMPLER2D_4, bcoord + gc).y;
    b1 = ps_sample_lod0(LIBRA_SAMPLER2D_4, bcoord + bc).z;
    d = float3(r1, g1, b1);
    g = lerp(g, d, min(ds, 1.0f).xxx);
}

float ps_igc(float mc)
{
    return pow(mc, global_gamma_c);
}

float3 ps_Mask(inout float2 pos, float mx, float mb)
{
    float3 mask = float3(params_maskDark, params_maskDark, params_maskDark);
    float3 one = 1.0f.xxx;
    if (params_shadowMask == 0.0f)
    {
        float mc = 1.0f - max(params_maskstr, 0.0f);
        pos.x = frac(pos.x * 0.5f);
        if (pos.x < 0.4900000095367431640625f)
        {
            mask.x = 1.0f;
            mask.y = mc;
            mask.z = 1.0f;
        }
        else
        {
            mask.x = mc;
            mask.y = 1.0f;
            mask.z = mc;
        }
    }
    else
    {
        if (params_shadowMask == 1.0f)
        {
            float _line = params_maskLight;
            float odd = 0.0f;
            if (frac(pos.x / 6.0f) < 0.4900000095367431640625f)
            {
                odd = 1.0f;
            }
            if (frac((pos.y + odd) / 2.0f) < 0.4900000095367431640625f)
            {
                _line = params_maskDark;
            }
            pos.x = floor(ps_mod(pos.x, 3.0f));
            if (pos.x < 0.5f)
            {
                mask.x = params_maskLight;
            }
            else
            {
                if (pos.x < 1.5f)
                {
                    mask.y = params_maskLight;
                }
                else
                {
                    mask.z = params_maskLight;
                }
            }
            mask *= _line;
        }
        else
        {
            if (params_shadowMask == 2.0f)
            {
                pos.x = floor(ps_mod(pos.x, 3.0f));
                if (pos.x < 0.5f)
                {
                    mask.x = params_maskLight;
                }
                else
                {
                    if (pos.x < 1.5f)
                    {
                        mask.y = params_maskLight;
                    }
                    else
                    {
                        mask.z = params_maskLight;
                    }
                }
            }
            else
            {
                if (params_shadowMask == 3.0f)
                {
                    pos.x += (pos.y * 3.0f);
                    pos.x = frac(pos.x / 6.0f);
                    if (pos.x < 0.300000011920928955078125f)
                    {
                        mask.x = params_maskLight;
                    }
                    else
                    {
                        if (pos.x < 0.60000002384185791015625f)
                        {
                            mask.y = params_maskLight;
                        }
                        else
                        {
                            mask.z = params_maskLight;
                        }
                    }
                }
                else
                {
                    if (params_shadowMask == 4.0f)
                    {
                        pos = floor(pos * float2(1.0f, 0.5f));
                        pos.x += (pos.y * 3.0f);
                        pos.x = frac(pos.x / 6.0f);
                        if (pos.x < 0.300000011920928955078125f)
                        {
                            mask.x = params_maskLight;
                        }
                        else
                        {
                            if (pos.x < 0.60000002384185791015625f)
                            {
                                mask.y = params_maskLight;
                            }
                            else
                            {
                                mask.z = params_maskLight;
                            }
                        }
                    }
                    else
                    {
                        if (params_shadowMask == 5.0f)
                        {
                            mask = 0.0f.xxx;
                            pos.x = frac(pos.x / 2.0f);
                            if (pos.x < 0.4900000095367431640625f)
                            {
                                mask.x = 1.0f;
                                mask.z = 1.0f;
                            }
                            else
                            {
                                mask.y = 1.0f;
                            }
                            mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                        }
                        else
                        {
                            if (params_shadowMask == 6.0f)
                            {
                                mask = 0.0f.xxx;
                                pos.x = floor(ps_mod(pos.x, 3.0f));
                                if (pos.x < 0.5f)
                                {
                                    mask.x = 1.0f;
                                }
                                else
                                {
                                    if (pos.x < 1.5f)
                                    {
                                        mask.y = 1.0f;
                                    }
                                    else
                                    {
                                        mask.z = 1.0f;
                                    }
                                }
                                mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                            }
                            else
                            {
                                if (params_shadowMask == 7.0f)
                                {
                                    mask = 0.0f.xxx;
                                    pos.x = frac(pos.x / 2.0f);
                                    if (pos.x < 0.4900000095367431640625f)
                                    {
                                        mask = 0.0f.xxx;
                                    }
                                    else
                                    {
                                        mask = 1.0f.xxx;
                                    }
                                    mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                }
                                else
                                {
                                    if (params_shadowMask == 8.0f)
                                    {
                                        mask = 0.0f.xxx;
                                        pos.x = frac(pos.x / 3.0f);
                                        if (pos.x < 0.300000011920928955078125f)
                                        {
                                            mask = 0.0f.xxx;
                                        }
                                        else
                                        {
                                            if (pos.x < 0.60000002384185791015625f)
                                            {
                                                mask = 1.0f.xxx;
                                            }
                                            else
                                            {
                                                mask = 1.0f.xxx;
                                            }
                                        }
                                        mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                    }
                                    else
                                    {
                                        if (params_shadowMask == 9.0f)
                                        {
                                            mask = 0.0f.xxx;
                                            pos.x = frac(pos.x / 3.0f);
                                            if (pos.x < 0.300000011920928955078125f)
                                            {
                                                mask = 0.0f.xxx;
                                            }
                                            else
                                            {
                                                if (pos.x < 0.60000002384185791015625f)
                                                {
                                                    mask.x = 1.0f;
                                                    mask.z = 1.0f;
                                                }
                                                else
                                                {
                                                    mask.y = 1.0f;
                                                }
                                            }
                                            mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                        }
                                        else
                                        {
                                            if (params_shadowMask == 10.0f)
                                            {
                                                mask = 0.0f.xxx;
                                                pos.x = frac(pos.x * 0.25f);
                                                if (pos.x < 0.20000000298023223876953125f)
                                                {
                                                    mask = 0.0f.xxx;
                                                }
                                                else
                                                {
                                                    if (pos.x < 0.4000000059604644775390625f)
                                                    {
                                                        mask.x = 1.0f;
                                                    }
                                                    else
                                                    {
                                                        if (pos.x < 0.699999988079071044921875f)
                                                        {
                                                            mask.y = 1.0f;
                                                        }
                                                        else
                                                        {
                                                            mask.z = 1.0f;
                                                        }
                                                    }
                                                }
                                                mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                            }
                                            else
                                            {
                                                if (params_shadowMask == 11.0f)
                                                {
                                                    mask = 0.0f.xxx;
                                                    pos.x = frac(pos.x * 0.25f);
                                                    if (pos.x < 0.20000000298023223876953125f)
                                                    {
                                                        mask.x = 1.0f;
                                                    }
                                                    else
                                                    {
                                                        if (pos.x < 0.4000000059604644775390625f)
                                                        {
                                                            mask.x = 1.0f;
                                                            mask.y = 1.0f;
                                                        }
                                                        else
                                                        {
                                                            if (pos.x < 0.699999988079071044921875f)
                                                            {
                                                                mask.y = 1.0f;
                                                                mask.z = 1.0f;
                                                            }
                                                            else
                                                            {
                                                                mask.z = 1.0f;
                                                            }
                                                        }
                                                    }
                                                    mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                                }
                                                else
                                                {
                                                    if (params_shadowMask == 12.0f)
                                                    {
                                                        mask = 0.0f.xxx;
                                                        pos.x = floor(ps_mod(pos.x, 7.0f));
                                                        if (pos.x < 0.5f)
                                                        {
                                                            mask = 0.0f.xxx;
                                                        }
                                                        else
                                                        {
                                                            if (pos.x < 2.5f)
                                                            {
                                                                mask.x = 1.0f;
                                                            }
                                                            else
                                                            {
                                                                if (pos.x < 4.5f)
                                                                {
                                                                    mask.y = 1.0f;
                                                                }
                                                                else
                                                                {
                                                                    mask.z = 1.0f;
                                                                }
                                                            }
                                                        }
                                                        mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                                    }
                                                    else
                                                    {
                                                        if (params_shadowMask == 13.0f)
                                                        {
                                                            mask = 0.0f.xxx;
                                                            pos.x = floor(ps_mod(pos.x, 6.0f));
                                                            if (pos.x < 0.5f)
                                                            {
                                                                mask = 0.0f.xxx;
                                                            }
                                                            else
                                                            {
                                                                if (pos.x < 1.5f)
                                                                {
                                                                    mask.x = 1.0f;
                                                                }
                                                                else
                                                                {
                                                                    if (pos.x < 2.5f)
                                                                    {
                                                                        mask.x = 1.0f;
                                                                        mask.y = 1.0f;
                                                                    }
                                                                    else
                                                                    {
                                                                        if (pos.x < 3.5f)
                                                                        {
                                                                            mask = 1.0f.xxx;
                                                                        }
                                                                        else
                                                                        {
                                                                            if (pos.x < 4.5f)
                                                                            {
                                                                                mask.y = 1.0f;
                                                                                mask.z = 1.0f;
                                                                            }
                                                                            else
                                                                            {
                                                                                mask.z = 1.0f;
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                                        }
                                                        else
                                                        {
                                                            mask = 0.0f.xxx;
                                                            pos.x = floor(ps_mod(pos.x, 5.0f));
                                                            if (pos.x < 0.5f)
                                                            {
                                                                mask = 0.0f.xxx;
                                                            }
                                                            else
                                                            {
                                                                if (pos.x < 1.5f)
                                                                {
                                                                    mask.x = 1.0f;
                                                                }
                                                                else
                                                                {
                                                                    if (pos.x < 2.5f)
                                                                    {
                                                                        mask.x = 1.0f;
                                                                        mask.y = 1.0f;
                                                                    }
                                                                    else
                                                                    {
                                                                        if (pos.x < 3.5f)
                                                                        {
                                                                            mask.y = 1.0f;
                                                                            mask.z = 1.0f;
                                                                        }
                                                                        else
                                                                        {
                                                                            mask.z = 1.0f;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            mask = clamp(lerp(lerp(one, mask, params_mcut.xxx), lerp(one, mask, params_maskstr.xxx), mx.xxx), 0.0f.xxx, 1.0f.xxx);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (params_mask_layout > 0.5f)
    {
        mask = mask.xzy;
    }
    float maskmin = min(min(mask.x, mask.y), mask.z);
    return ((mask - maskmin.xxx) * (1.0f + ((global_maskboost - 1.0f) * mb))) + maskmin.xxx;
}

float ps_SlotMask(inout float2 pos, float m, float swidth)
{
    if ((params_slotmask + params_slotmask1) == 0.0f)
    {
        return 1.0f;
    }
    else
    {
        pos.y = floor(pos.y / global_slotms);
        float mlen = swidth * 2.0f;
        float px = floor(ps_mod(pos.x, 0.999989986419677734375f * mlen));
        float py = floor((frac(pos.y / (2.0f * params_double_slot)) * 2.0f) * params_double_slot);
        float slot_dark = lerp(1.0f - params_slotmask1, 1.0f - params_slotmask, m);
        float slot = 1.0f;
        if ((py == 0.0f) && (px < swidth))
        {
            slot = slot_dark;
        }
        else
        {
            if ((py == params_double_slot) && (px >= swidth))
            {
                slot = slot_dark;
            }
        }
        return slot;
    }
}

float3 ps_plant(float3 tar, float r)
{
    float t = max(max(tar.x, tar.y), tar.z) + 9.9999997473787516355514526367188e-06f;
    return (tar * r) / t.xxx;
}

float3 ps_gc2(float3 c, float w3)
{
    float mc = max(max(c.x, c.y), c.z);
    float gp = 1.0f / (1.0f + ((global_gamma_c2 - 1.0f) * lerp(0.375f, 1.0f, w3)));
    float mg = pow(mc, gp);
    return (c * mg) / (mc + 1.0000000133514319600180897396058e-10f).xxx;
}

float3 ps__noise(inout float3 v)
{
    if (global_addnoised < 0.0f)
    {
        v.z = -global_addnoised;
    }
    else
    {
        v.z = ps_mod(v.z, 6001.0f) / 1753.0f;
    }
    v = (frac(v) + frac(v * 10000.0f)) + frac(v * 9.9999997473787516355514526367188e-05f);
    v += float3(0.123450003564357757568359375f, 0.6789000034332275390625f, 0.3141590058803558349609375f);
    v = frac((v * dot(v, v)) * 123.45600128173828125f);
    v = frac((v * dot(v, v)) * 123.45600128173828125f);
    v = frac((v * dot(v, v)) * 123.45600128173828125f);
    v = frac((v * dot(v, v)) * 123.45600128173828125f);
    return v;
}

float ps_humbar(inout float pos)
{
    if (global_barintensity == 0.0f)
    {
        return 1.0f;
    }
    else
    {
        float _1002;
        if (global_barintensity >= 0.0f)
        {
            _1002 = pos;
        }
        else
        {
            _1002 = 1.0f - pos;
        }
        pos = _1002;
        pos = frac(pos + (ps_mod(float(global_FrameCount), global_barspeed) / (global_barspeed - 1.0f)));
        float _1028;
        if (global_barintensity < 0.0f)
        {
            _1028 = pos;
        }
        else
        {
            _1028 = 1.0f - pos;
        }
        pos = _1028;
        return (1.0f - global_barintensity) + (global_barintensity * pos);
    }
}

float ps_corner(inout float2 pos)
{
    pos = abs((pos - 0.5f.xx) * 2.0f);
    float2 aspect = float2(1.0f, global_OutputSize.x / global_OutputSize.y);
    float b = (params_bsize1 * 0.0500000007450580596923828125f) + 0.0005000000237487256526947021484375f;
    pos.y += (b * (aspect.y - 1.0f));
    float2 crn = max(params_csize.xx, ((2.0f * b) + 0.00150000001303851604461669921875f).xx);
    float2 cp = max(pos - (1.0f.xx - (crn * aspect)), 0.0f.xx) / aspect;
    float cd = sqrt(dot(cp, cp));
    pos = max(pos, (1.0f.xx - crn) + cd.xx);
    float res = lerp(1.0f, 0.0f, smoothstep(1.0f - b, 1.0f, sqrt(max(pos.x, pos.y))));
    return pow(res, global_sborder);
}

void ps_frag_main()
{
    float4 SourceSize = global_OriginalSize;
    float lum = ps_sample_lod0(LIBRA_SAMPLER2D_3, 0.5f.xx).w;
    float gamma_in = 1.0f / ps_sample_lod0(LIBRA_SAMPLER2D_2, 0.25f.xx).w;
    float intera = ps_sample_lod0(LIBRA_SAMPLER2D_2, float2(0.75f, 0.25f)).w;
    bool _1482 = intera < 0.3499999940395355224609375f;
    bool _1489;
    if (_1482)
    {
        _1489 = global_interm == 6.0f;
    }
    else
    {
        _1489 = _1482;
    }
    bool inter6 = _1489;
    bool _1495 = (intera < 0.3499999940395355224609375f) && (!inter6);
    bool _1503;
    if (!_1495)
    {
        _1503 = global_no_scanlines > 0.02500000037252902984619140625f;
    }
    else
    {
        _1503 = _1495;
    }
    bool _1510;
    if (_1503)
    {
        _1510 = params_hiscan < 0.5f;
    }
    else
    {
        _1510 = _1503;
    }
    bool interb = _1510;
    float2 texcoord = ps_vTexCoord;
    if ((params_IOS > 0.0f) && (!interb))
    {
        float2 ofactor = global_OutputSize.xy / global_OriginalSize.xy;
        float2 _1536;
        if (params_IOS < 2.5f)
        {
            _1536 = floor(ofactor);
        }
        else
        {
            _1536 = ceil(ofactor);
        }
        float2 intfactor = _1536;
        float2 diff = ofactor / intfactor;
        float scan = diff.y;
        float2 param = texcoord;
        float param_1 = scan;
        float param_2 = scan;
        float2 _1558 = ps_Overscan(param, param_1, param_2);
        texcoord = _1558;
        bool _1561 = params_IOS == 1.0f;
        bool _1568;
        if (!_1561)
        {
            _1568 = params_IOS == 3.0f;
        }
        else
        {
            _1568 = _1561;
        }
        if (_1568)
        {
            texcoord = float2(ps_vTexCoord.x, texcoord.y);
        }
    }
    float factor = (1.0f + (((1.0f - (0.5f * params_OS)) * params_BLOOM) / 100.0f)) - ((lum * params_BLOOM) / 100.0f);
    float2 param_3 = texcoord;
    float param_4 = factor;
    float param_5 = factor;
    float2 _1601 = ps_Overscan(param_3, param_4, param_5);
    texcoord = _1601;
    texcoord.y -= (global_VShift * global_OriginalSize.w);
    float2 param_6 = texcoord;
    float param_7 = (global_OriginalSize.x - global_overscanX) / global_OriginalSize.x;
    float param_8 = (global_OriginalSize.y - global_overscanY) / global_OriginalSize.y;
    float2 _1632 = ps_Overscan(param_6, param_7, param_8);
    texcoord = _1632;
    float2 pos1 = ps_vTexCoord;
    float2 param_9 = texcoord;
    float2 _1638 = ps_Warp(param_9);
    float2 pos = _1638;
    float2 param_10 = ps_vTexCoord;
    float2 _1642 = ps_Warp(param_10);
    float2 pos0 = _1642;
    float2 posb = (pos0 - 0.5f.xx) * 2.0f;
    if (params_BLOOM < 0.5f)
    {
        posb = max(abs(posb), abs((pos - 0.5f.xx) * 2.0f)) * sign(posb);
    }
    posb = (posb * 0.5f) + 0.5f.xx;
    float3 color = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1).xyz;
    float3 Bloom = ps_sample_lod0(LIBRA_SAMPLER2D_5, pos).xyz;
    float3 Glow = ps_sample_lod0(LIBRA_SAMPLER2D_4, pos).xyz;
    if ((((((abs(global_deconrr) + abs(global_deconrry)) + abs(global_deconrg)) + abs(global_deconrgy)) + abs(global_deconrb)) + abs(global_deconrby)) > 0.20000000298023223876953125f)
    {
        float3 param_11 = color;
        float3 param_12 = Bloom;
        float3 param_13 = Glow;
        float2 param_14 = pos1;
        float2 param_15 = pos;
        ps_fetch_pixel(param_11, param_12, param_13, param_14, param_15);
        color = param_11;
        Bloom = param_12;
        Glow = param_13;
    }
    float param_16 = max(max(color.x, color.y), color.z);
    float cm = ps_igc(param_16);
    float mx1 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1).w;
    float colmx = max(mx1, cm);
    float w3 = min((max((cm - 0.0005000000237487256526947021484375f) * 1.0004999637603759765625f, 0.0f) + 9.9999997473787516355514526367188e-05f) / (colmx + 0.0005000000237487256526947021484375f), 1.0f);
    if (interb)
    {
        w3 = 1.0f;
    }
    float2 dx = float2(0.001000000047497451305389404296875f, 0.0f);
    float mx0 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 - dx).w;
    float mx2 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 + dx).w;
    float mxg = max(max(mx0, mx1), max(mx2, cm));
    float mx = pow(mxg, 1.39999997615814208984375f / gamma_in);
    float cx = pow(colmx, 1.39999997615814208984375f / gamma_in);
    dx = float2(global_OriginalSize.z, 0.0f) * 0.25f;
    mx0 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 - dx).w;
    mx2 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 + dx).w;
    float mb = 1.0f - min(abs(mx0 - mx2) / (0.5f + mx1), 1.0f);
    float3 one = 1.0f.xxx;
    float3 orig1 = color;
    float3 cmask = one;
    float3 cmask1 = one;
    float3 cmask2 = one;
    float mwidth = ps__1840[int(max(params_shadowMask,0.0))];
    float mask_compensate = frac(mwidth);
    float mwidth1 = mwidth;
    if (params_shadowMask > (-0.5f))
    {
        float2 maskcoord = ps_vTexCoord * global_OutputSize.xy;
        float2 scoord = maskcoord;
        mwidth = floor(mwidth) * params_masksize;
        float swidth = mwidth;
        bool zoomed = abs(global_mask_zoom) > 0.75f;
        float mscale = 1.0f;
        float2 maskcoord0 = maskcoord;
        maskcoord.y = floor(maskcoord.y / params_masksize);
        mwidth1 = max(mwidth + global_mask_zoom, 2.0f);
        if (params_mshift > 0.25f)
        {
            float stagg_lvl = 1.0f;
            if (frac(params_mshift) > 0.25f)
            {
                stagg_lvl = 2.0f;
            }
            float next_line = float(floor(ps_mod(maskcoord.y, 2.0f * stagg_lvl)) < stagg_lvl);
            maskcoord0.x += ((next_line * 0.5f) * mwidth1);
        }
        maskcoord = maskcoord0 / params_masksize.xx;
        if (!zoomed)
        {
            float2 param_17 = floor(maskcoord);
            float param_18 = mx;
            float param_19 = mb;
            float3 _1941 = ps_Mask(param_17, param_18, param_19);
            cmask = _1941;
        }
        else
        {
            mscale = mwidth1 / mwidth;
            float mlerp = frac(maskcoord.x / mscale);
            if (global_mzoom_sh > 0.02500000037252902984619140625f)
            {
                mlerp = clamp(((1.0f + global_mzoom_sh) * mlerp) - (0.5f * global_mzoom_sh), 0.0f, 1.0f);
            }
            float mcoord = floor(maskcoord.x / mscale);
            bool _1976 = params_shadowMask == 12.0f;
            bool _1983;
            if (_1976)
            {
                _1983 = global_mask_zoom == (-2.0f);
            }
            else
            {
                _1983 = _1976;
            }
            if (_1983)
            {
                mcoord = ceil(maskcoord.x / mscale);
            }
            float2 param_20 = float2(mcoord, maskcoord.y);
            float param_21 = mx;
            float param_22 = mb;
            float3 _2000 = ps_Mask(param_20, param_21, param_22);
            float2 param_23 = float2(mcoord + 1.0f, maskcoord.y);
            float param_24 = mx;
            float param_25 = mb;
            float3 _2011 = ps_Mask(param_23, param_24, param_25);
            cmask = lerp(_2000, _2011, mlerp.xxx);
        }
        float sm_offset = 0.0f;
        bool _2019 = params_shadowMask == 0.0f;
        bool _2026;
        if (!_2019)
        {
            _2026 = params_shadowMask == 2.0f;
        }
        else
        {
            _2026 = _2019;
        }
        bool _2033;
        if (!_2026)
        {
            _2033 = params_shadowMask == 5.0f;
        }
        else
        {
            _2033 = _2026;
        }
        bool _2040;
        if (!_2033)
        {
            _2040 = params_shadowMask == 6.0f;
        }
        else
        {
            _2040 = _2033;
        }
        bool _2047;
        if (!_2040)
        {
            _2047 = params_shadowMask == 8.0f;
        }
        else
        {
            _2047 = _2040;
        }
        bool _2054;
        if (!_2047)
        {
            _2054 = params_shadowMask == 11.0f;
        }
        else
        {
            _2054 = _2047;
        }
        bool bsm_offset = _2054;
        if (zoomed)
        {
            if ((params_mask_layout < 0.5f) && bsm_offset)
            {
                sm_offset = 1.0f;
            }
            else
            {
                if (bsm_offset)
                {
                    sm_offset = -1.0f;
                }
            }
        }
        swidth = round(mwidth1);
        if (params_slotwidth > 0.5f)
        {
            swidth = params_slotwidth;
        }
        float smask = 1.0f;
        float2 param_26 = scoord + float2(sm_offset, 0.0f);
        float param_27 = mx;
        float param_28 = swidth;
        float _2089 = ps_SlotMask(param_26, param_27, param_28);
        smask = _2089;
        smask = clamp(smask + lerp(global_smask_mit, 0.0f, w3 * pow(colmx, 0.300000011920928955078125f)), 0.0f, 1.0f);
        cmask2 = cmask;
        cmask *= smask;
        cmask1 = cmask;
        if (abs(params_mask_bloom) > 0.02500000037252902984619140625f)
        {
            float maxbl = max(max(max(Bloom.x, Bloom.y), Bloom.z), mxg);
            maxbl *= max(lerp(1.0f, 2.0f - colmx, global_bloom_dist), 0.0f);
            if (params_mask_bloom > 0.02500000037252902984619140625f)
            {
                cmask = max(min(cmask + (maxbl * params_mask_bloom).xxx, 1.0f.xxx), cmask);
            }
            else
            {
                float3 param_29 = pow(Bloom, 0.3499999940395355224609375f.xxx);
                float param_30 = maxbl;
                cmask = max(lerp(cmask, (cmask * (1.0f - (0.5f * maxbl))) + ps_plant(param_29, param_30), (-params_mask_bloom).xxx), cmask);
            }
        }
        color = pow(color, (global_mask_gamma / gamma_in).xxx);
        color *= cmask;
        color = min(color, 1.0f.xxx);
        color = pow(color, (gamma_in / global_mask_gamma).xxx);
        cmask = min(cmask, 1.0f.xxx);
        cmask1 = min(cmask1, 1.0f.xxx);
    }
    float dark_compensate = lerp(max((clamp(lerp(params_mcut, params_maskstr, mx), 0.0f, 1.0f) - 1.0f) + mask_compensate, 0.0f) + 1.0f, 1.0f, mx);
    if (params_shadowMask < (-0.5f))
    {
        dark_compensate = 1.0f;
    }
    float bb = lerp(params_brightboost, params_brightboost1, mx) * dark_compensate;
    color *= bb;
    float3 Ref = ps_sample_lod0(LIBRA_SAMPLER2D_2, pos).xyz;
    float maxb = ps_sample_lod0(LIBRA_SAMPLER2D_5, pos).w;
    float vig = ps_sample_lod0(LIBRA_SAMPLER2D_6, clamp(pos, 0.0f.xx + (global_OriginalSize.zw * 0.5f), 1.0f.xx - (global_OriginalSize.zw * 0.5f))).w;
    if (params_pr_scan > 0.02500000037252902984619140625f)
    {
        float mbl = max(max(Bloom.x, Bloom.y), Bloom.z);
        float3 param_31 = orig1;
        float param_32 = mbl;
        Bloom = lerp(Bloom, lerp(Bloom, ps_plant(param_31, param_32), min(2.5f * (1.0f - w3), 1.0f).xxx), min(2.0f * params_pr_scan, 1.0f).xxx);
    }
    float3 Bloom1 = Bloom;
    float3 bcmask = lerp(one, cmask1, global_bmask1.xxx);
    float3 hcmask = lerp(one, cmask1, global_hmask1.xxx);
    if (abs(global_bloom) > 0.02500000037252902984619140625f)
    {
        if (global_bloom < (-0.00999999977648258209228515625f))
        {
            float3 param_33 = Bloom;
            float param_34 = maxb;
            Bloom1 = ps_plant(param_33, param_34);
        }
        Bloom1 = min(Bloom1 * (orig1 + color), max(((colmx.xxx + orig1) - color) * 0.5f, Bloom1 * 0.001000000047497451305389404296875f));
        Bloom1 = (Bloom1 + lerp(Bloom1, lerp(orig1 * colmx, Bloom1, 0.5f.xxx), 1.0f.xxx - color)) * 0.5f;
        Bloom1 = (bcmask * Bloom1) * max(lerp(1.0f, 2.0f - colmx, global_bloom_dist), 0.0f);
        color = pow(pow(color, (global_mask_gamma / gamma_in).xxx) + (pow(Bloom1, (global_mask_gamma / gamma_in).xxx) * abs(global_bloom)), (gamma_in / global_mask_gamma).xxx);
    }
    if (global_halation > 0.00999999977648258209228515625f)
    {
        Bloom = (Bloom + (Bloom * Bloom)) * 0.5f;
        float mbl_1 = max(max(Bloom.x, Bloom.y), Bloom.z);
        float cmxh = 0.5f * (colmx + (colmx * colmx));
        mbl_1 = lerp(lerp(cmxh, lerp(cmxh, mbl_1, mbl_1), colmx), mbl_1, mb);
        float3 param_35 = Bloom;
        float param_36 = lerp(sqrt(mbl_1 * cmxh), max(mbl_1 - (0.1500000059604644775390625f * (1.0f - colmx)), 0.4000000059604644775390625f * cmxh), pow(colmx, 0.25f));
        Bloom = ps_plant(param_35, param_36) * lerp(0.425000011920928955078125f, 1.0f, colmx);
        float3 param_37 = 0.324999988079071044921875f.xxx + (orig1 / w3.xxx);
        float param_38 = 0.5f * (1.0f + w3);
        Bloom = ((((3.0f - colmx).xxx - color) * ps_plant(param_37, param_38)) * hcmask) * Bloom;
        color = pow(pow(color, (global_mask_gamma / gamma_in).xxx) + (pow(Bloom, (global_mask_gamma / gamma_in).xxx) * global_halation), (gamma_in / global_mask_gamma).xxx);
    }
    else
    {
        if (global_halation < (-0.00999999977648258209228515625f))
        {
            float mbl_2 = max(max(Bloom.x, Bloom.y), Bloom.z);
            float3 param_39 = ((Bloom + Ref) + orig1) + ((Bloom * Bloom) * Bloom);
            float param_40 = min(mbl_2 * mbl_2, 0.75f);
            Bloom = ps_plant(param_39, param_40);
            Bloom = (hcmask * (2.0f * lerp(1.0f, w3, 0.5f * colmx))) * Bloom;
            color -= (Bloom * global_halation);
        }
    }
    color = min(color, 1.0f.xxx);
    float3 param_41 = color;
    float param_42 = w3;
    color = ps_gc2(param_41, param_42);
    if (global_smoothmask > 0.125f)
    {
        float w4 = pow(w3, 0.425000011920928955078125f + (0.300000011920928955078125f * global_smoothmask));
        w4 = max(w4 - ((0.17499999701976776123046875f * colmx) * global_smoothmask), 0.20000000298023223876953125f);
        float3 param_43 = orig1;
        float param_44 = 1.0f + ((0.17499999701976776123046875f * colmx) * global_smoothmask);
        color = lerp(min(color / w4.xxx, ps_plant(param_43, param_44)) * w4, color, w4.xxx);
    }
    if (global_m_glow < 0.5f)
    {
        Glow = lerp(Glow, color * 0.25f, colmx.xxx);
    }
    else
    {
        maxb = max(max(Glow.x, Glow.y), Glow.z);
        float3 param_45 = orig1 + (Ref * 0.001000000047497451305389404296875f);
        float param_46 = 1.0f;
        float3 orig2 = ps_plant(param_45, param_46);
        float3 param_47 = Glow;
        float param_48 = 1.0f;
        Bloom = ps_plant(param_47, param_48);
        Ref = abs(orig2 - Bloom);
        mx0 = max(max(orig2.x, orig2.y), orig2.z) - min(min(orig2.x, orig2.y), orig2.z);
        mx2 = max(max(Bloom.x, Bloom.y), Bloom.z) - min(min(Bloom.x, Bloom.y), Bloom.z);
        Bloom = lerp(min(Bloom, orig2) * maxb, lerp(lerp(Glow, Glow * max(max(Ref.x, Ref.y), Ref.z), max(mx, mx0).xxx), lerp(color, Glow, mx2.xxx), Ref * max(mx0, mx2)), min(sqrt((1.10000002384185791015625f - mx0) * (0.100000001490116119384765625f + mx2)), 1.0f).xxx);
        if (global_m_glow > 1.5f)
        {
            Glow = lerp((Glow * 0.5f) * Glow, Bloom, Bloom);
        }
        Glow = lerp(Glow * global_m_glow_low, Bloom * global_m_glow_high, pow(colmx, global_m_glow_dist / gamma_in).xxx);
    }
    if (global_m_glow < 0.5f)
    {
        if (params_glow >= 0.0f)
        {
            color += ((Glow * 0.5f) * params_glow);
        }
        else
        {
            color += ((min(cmask2 * cmask2, 1.0f.xxx) * abs(params_glow)) * Glow);
        }
    }
    else
    {
        float3 cmaskg = clamp(lerp(one, cmask1, global_m_glow_mask.xxx), 0.0f.xxx, 1.0f.xxx);
        color += ((cmaskg * abs(params_glow)) * Glow);
    }
    color = min(color, 1.0f.xxx);
    if (global_edgemask > 0.0500000007450580596923828125f)
    {
        mx0 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 - dx).w;
        mx0 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 - (dx * (1.0f - (0.75f * sqrt(mx0))))).w;
        mx2 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 + dx).w;
        mx2 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 + (dx * (1.0f - (0.75f * sqrt(mx2))))).w;
        float mx3 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 - (dx * 4.0f)).w;
        float mx4 = ps_sample_lod0(LIBRA_SAMPLER2D_7, pos1 + (dx * 4.0f)).w;
        mx4 = max(pow(abs(mx3 - mx4), 0.550000011920928955078125f - (0.4000000059604644775390625f * cx)), min(max(mx3, mx4) / min(0.100000001490116119384765625f + cx, 1.0f), 1.0f));
        mb = 1.0f - abs(pow(mx0, 1.0f - (0.64999997615814208984375f * mx2)) - pow(mx2, 1.0f - (0.64999997615814208984375f * mx0)));
        mb = (mx4 * global_edgemask) * (1.00010001659393310546875f - (mb * mb));
        float3 temp = lerp(color, orig1, mb.xxx);
        color = max(temp + lerp(lerp(temp * 1.625f, temp, cx.xxx) * (3.5f * mb), 0.0f.xxx, pow(color, 0.75f.xxx - (0.5f * colmx).xxx)), color);
    }
    color *= lerp(1.0f, lerp(0.5f * (1.0f + w3), w3, mx), params_pr_scan);
    color = min(color, max(orig1, color) * lerp(one, cmask1, global_mclip.xxx));
    color = pow(color, (1.0f / global_gamma_out).xxx);
    float rc = (0.60000002384185791015625f * sqrt(max(max(color.x, color.y), color.z))) + 0.4000000059604644775390625f;
    if (abs(global_addnoised) > 0.00999999977648258209228515625f)
    {
        float3 param_49 = float3(floor((global_OutputSize.xy * ps_vTexCoord) / global_noiseresd.xx), float(global_FrameCount));
        float3 _2992 = ps__noise(param_49);
        float3 noise0 = _2992;
        if (global_noisetype < 0.5f)
        {
            color = lerp(color, noise0, ((0.25f * abs(global_addnoised)) * rc).xxx);
        }
        else
        {
            color = min(color * lerp(1.0f, 1.5f * noise0.x, 0.5f * abs(global_addnoised)), 1.0f.xxx);
        }
    }
    colmx = max(max(orig1.x, orig1.y), orig1.z);
    color += (lerp(cmask2, color * (0.125f * (1.0f - colmx)), min(20.0f * colmx, 1.0f).xxx) * global_bmask);
    float param_50 = lerp(pos.y, pos.x, global_bardir);
    float _3060 = ps_humbar(param_50);
    float2 param_51 = posb;
    float _3068 = ps_corner(param_51);
    ps_FragColor = lerp(float4((((color * vig) * _3060) * global_post_br) * _3068, 1.0f), ps_sample_lod0(LIBRA_SAMPLER2D_8, (floor(pos1 * global_OriginalSize.xy) + 0.5f.xx) * global_OriginalSize.zw), step(pos1.x, global_oimage - 0.00025000001187436282634735107421875f).xxxx);
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
