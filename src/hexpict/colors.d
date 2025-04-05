/*
 * This is detail documentated program.
 * The idea of detail documentation is that always easy to explain
 * what does function do, but to understand how it does it necessary
 * to know many details. "The devil is in the details."
 * So in the code we are writing description of functions
 * and make references to details like @Detail_Name.
 * All details explained in the "details" directory.
 * We can reference to any detail several times.
 * We don't translate comments in the code, but we can
 * want to translate details to several languages.
 */
module hexpict.colors;

import hexpict.color;

// Standard illuminants according https://en.wikipedia.org/wiki/Standard_illuminant
XyType A_WHITE_COLOR = XyType(0.44757, 0.40745);
XyType B_WHITE_COLOR = XyType(0.34842, 0.35161);
XyType C_WHITE_COLOR = XyType(0.31006, 0.31616);
XyType D50_WHITE_COLOR = XyType(0.34567, 0.35850);
XyType D55_WHITE_COLOR = XyType(0.33242, 0.34743);
XyType D65_WHITE_COLOR = XyType(0.31271, 0.32902);
XyType D75_WHITE_COLOR = XyType(0.29902, 0.31485);
XyType D93_WHITE_COLOR = XyType(0.28315, 0.29711);
XyType E_WHITE_COLOR = XyType(0.33333, 0.33333);
XyType F1_WHITE_COLOR = XyType(0.31310, 0.33727);
XyType F2_WHITE_COLOR = XyType(0.37208, 0.37529);
XyType F3_WHITE_COLOR = XyType(0.40910, 0.39430);
XyType F4_WHITE_COLOR = XyType(0.44018, 0.40329);
XyType F5_WHITE_COLOR = XyType(0.31379, 0.34531);
XyType F6_WHITE_COLOR = XyType(0.37790, 0.38835);
XyType F7_WHITE_COLOR = XyType(0.31292, 0.32933);
XyType F8_WHITE_COLOR = XyType(0.34588, 0.35875);
XyType F9_WHITE_COLOR = XyType(0.37417, 0.37281);
XyType F10_WHITE_COLOR = XyType(0.34609, 0.35986);
XyType F11_WHITE_COLOR = XyType(0.38052, 0.37713);
XyType F12_WHITE_COLOR = XyType(0.43695, 0.40441);
XyType LED_B1_WHITE_COLOR = XyType(0.4560, 0.4078);
XyType LED_B2_WHITE_COLOR = XyType(0.4357, 0.4012);
XyType LED_B3_WHITE_COLOR = XyType(0.3756, 0.3723);
XyType LED_B4_WHITE_COLOR = XyType(0.3422, 0.3502);
XyType LED_B5_WHITE_COLOR = XyType(0.3118, 0.3236);
XyType LED_BH1_WHITE_COLOR = XyType(0.4474, 0.4066);
XyType LED_RGB1_WHITE_COLOR = XyType(0.4557, 0.4211);
XyType LED_V1_WHITE_COLOR = XyType(0.4560, 0.4548);
XyType LED_V2_WHITE_COLOR = XyType(0.3781, 0.3775);

// RGB Base colors according http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
ColorSpace ADOBE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2100, 0.7100), XyType(0.1500, 0.0600)), null, null);

ColorSpace APPLE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6250, 0.3400), XyType(0.2800, 0.5950), XyType(0.1550, 0.0700)), null, null);

ColorSpace BEST_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7347, 0.2653), XyType(0.2150, 0.7750), XyType(0.1300, 0.0350)), null, null);

ColorSpace BETA_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6888, 0.3112), XyType(0.1986, 0.7551), XyType(0.1265, 0.0352)), null, null);

ColorSpace BRUCE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2800, 0.6500), XyType(0.1500, 0.0600)), null, null);

ColorSpace CIE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.33333, 0.33333), XyType(0.7350, 0.2650), XyType(0.2740, 0.7170), XyType(0.1670, 0.0090)), null, null);

ColorSpace COLORMATCH_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6300, 0.3400), XyType(0.2950, 0.6050), XyType(0.1500, 0.0750)), null, null);

ColorSpace DON_RGB_4_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6960, 0.3000), XyType(0.2150, 0.7650), XyType(0.1300, 0.0350)), null, null);

ColorSpace ECI_RGB_V2_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.L, CompandingType.NONE,
    CompandingType.L, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6700, 0.3300), XyType(0.2100, 0.7100), XyType(0.1400, 0.0800)), null, null);

ColorSpace EKTA_SPACE_PS5_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6950, 0.3050), XyType(0.2600, 0.7000), XyType(0.1100, 0.0050)), null, null);

ColorSpace NTSC_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31006, 0.31616), XyType(0.6700, 0.3300), XyType(0.2100, 0.7100), XyType(0.1400, 0.0800)), null, null);

ColorSpace PAL_SECAM_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2900, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace PROPHOTO_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7347, 0.2653), XyType(0.1596, 0.8404), XyType(0.0366, 0.0001)), null, null);

ColorSpace SMPTE_C_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6300, 0.3400), XyType(0.3100, 0.5950), XyType(0.1550, 0.0700)), null, null);

ColorSpace SRGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace WIDE_GAMUT_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7350, 0.2650), XyType(0.1150, 0.8260), XyType(0.1570, 0.0180)), null, null);

// Rec. 2020
ColorSpace REC2020_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.7080, 0.2920), XyType(0.1700, 0.7970), XyType(0.1310, 0.0460)), null, null);

// https://en.wikipedia.org/wiki/DCI-P3
XyType K6000_WHITE_COLOR = XyType(0.32168, 0.33767);
XyType K6300_WHITE_COLOR = XyType(0.314, 0.351);

ColorSpace DCI_P3_DISPLAY_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

ColorSpace DCI_P3_THEATER_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.314, 0.351), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

ColorSpace DCI_P3_ACES_CINEMA_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.32168, 0.33767), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

ColorSpace DCI_P3_PLUS_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.314, 0.351), XyType(0.740, 0.270), XyType(0.220, 0.780), XyType(0.090, -0.090)), null, null);

ColorSpace DCI_P3_CINEMA_GAMUT_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.740, 0.270), XyType(0.170, 1.140), XyType(0.080, -0.100)), null, null);

ColorSpace RMB_SPACE = ColorSpace(ColorType.RMB,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace XYZ_SPACE = ColorSpace(ColorType.XYZ,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace XYY_SPACE = ColorSpace(ColorType.XYY,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace YUV_SPACE = ColorSpace(ColorType.YUV,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace LAB_SPACE = ColorSpace(ColorType.LAB,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace LMS_SPACE = ColorSpace(ColorType.LMS,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace ICTCP_SPACE = ColorSpace(ColorType.ICTCP,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

ColorSpace ITP_SPACE = ColorSpace(ColorType.ITP,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);
