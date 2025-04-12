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

module hexpict.hexogrid;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;
import std.bitmanip;
import bindbc.sdl;

import hexpict.h6p;
import hexpict.color;
import hexpict.colors;
import hexpict.hyperpixel;
import hexpict.common;

enum DBGX = -1;
enum DBGY = -1;

SDL_Surface *hexogrid(SDL_Surface *image, uint scale, float scaleupx, int offx, int offy, int ow, int oh, int selx, int sely)
{   
    int iw = image.w;
    int ih = image.h;

    uint hpw = scale;
    float hpwf = hpw;
    float hphf = round(hpwf * 2.0f / sqrt(3.0f));
    uint hph = cast(uint) hphf;

    float hhf = floor(hphf/4.0f);
    uint hh = cast(uint) hhf;

    float h16 = round(16.0f * 2.0f / sqrt(3.0f));
    float hh16 = floor(h16/4.0f);
    float scaleupy = scaleupx;

    int nw = cast(int) ceil(iw * scaleupx / hpw);
    int nh = cast(int) ceil(ih * scaleupy / (hph-hh));
    writefln("scaleupx %s, scaleupy %s, nh %s", scaleupx, scaleupy, ih * scaleupy / (hph-hh));

    // @HyperMaskFile
    ubyte[12] form12;
    BitArray *hp = hyperpixel(hpw, form12, 0);

    ubyte[] imgbuf;

    int oow = cast(int) ceil(ow * 1.0f / hpw);
    int ooh = cast(int) ceil(oh * 1.0f / (hph-hh));

    int th = min(nh, offy+ooh-1);
    int tw = min(nw, offx+oow);

    imgbuf = new ubyte[ow*oh*4];
    assert(imgbuf !is null);

    ColorSpace *space = new ColorSpace;
    assert(space !is null);
    *space = cast(ColorSpace) SRGB_SPACE;

    space.type = ColorType.RGB;
    space.companding = CompandingType.GAMMA_2_2;
    space.alpha_companding = CompandingType.NONE;

    calc_rgb_matrices(space);

    ColorSpace *rgbspace = get_rgbspace(space);

    for (int y = offy; y < th; y++)
    {
        int iy = (y-offy)*(hph-hh);
        int siy = y*(hph-hh);

        for (int x = offx; x < tw; x++)
        {
            int ix;
            int six;

            if (y%2 == 0)
            {
                ix = (x-offx)*hpw;
                six = x*hpw;
            }
            else
            {
                ix = hpw/2 + (x-offx)*hpw;
                six = hpw/2 + x*hpw;
            }

            bool sel = (x == selx && y == sely);
            bool seldark;

            if (sel)
            {
                int total, numdark;
                for (int dy = 0; dy < hph; dy++)
                {
                    if (iy+dy >= oh) { break; }

                    for (int dx = 0; dx < hpw; dx++)
                    {
                        if (ix+dx >= ow) { break; }

                        // @HyperMask
                        if ((*hp)[dx + dy*hpw])
                        {
                            int x0 = ix + dx;
                            int y0 = iy + dy;

                            int sx0 = cast(int) round((six + dx)/scaleupx);
                            int sy0 = cast(int) round((siy + dy)/scaleupy);

                            assert(sx0 >= 0 && sy0 >=0);

                            // @Pixel2HexScaleUp
                            if (sx0 < iw && sy0 < ih)
                            {
                                ubyte r, g, b, a;
                                SdlGetPixel(image, sx0, sy0, r, g, b, a);
                                
                                total++;
                                if (max(r, g, b) < 205)
                                {
                                    numdark++;
                                }
                            }
                        }
                    }
                }

                seldark = (numdark > total/2);
            }

            // @Pixel2HexAverage
            for (int dy = 0; dy < hph; dy++)
            {
                if (iy+dy >= oh) { break; }

                for (int dx = 0; dx < hpw; dx++)
                {
                    if (ix+dx >= ow) { break; }

                    bool bdr = (dx == 0 || dx == hpw-1);

                    if (!bdr)
                    {
                        int dx0 = dx-1;
                        int dx2 = dx+1;

                        bool prev = (*hp)[dx0 + dy*hpw];
                        bool curr = (*hp)[dx + dy*hpw];
                        bool next = (*hp)[dx2 + dy*hpw];

                        bdr = curr && (!prev || !next);
                    }

                    if (!bdr && dy > 0 && dy < hph-1)
                    {
                        int dy0 = dy-1;
                        int dy2 = dy+1;

                        bool prev = (*hp)[dx + dy0*hpw];
                        bool curr = (*hp)[dx + dy*hpw];
                        bool next = (*hp)[dx + dy2*hpw];

                        bdr = curr && (!prev || !next);
                    }

                    // @HyperMask
                    if ((*hp)[dx + dy*hpw])
                    {
                        int x0 = ix + dx;
                        int y0 = iy + dy;

                        int sx0 = cast(int) round((six + dx)/scaleupx);
                        int sy0 = cast(int) round((siy + dy)/scaleupy);

                        assert(sx0 >= 0 && sy0 >=0);

                        // @Pixel2HexScaleUp
                        if (sx0 < iw && sy0 < ih)
                        {
                            ubyte r, g, b, a;
                            SdlGetPixel(image, sx0, sy0, r, g, b, a);

                            if (bdr)
                            {
                                if (dx < hpw/2)
                                {
                                    r = cast(ubyte) (r < 205 ? r + 50 : 255);
                                    g = cast(ubyte) (g < 205 ? g + 50 : 255);
                                    b = cast(ubyte) (b < 205 ? b + 50 : 255);
                                }
                                else
                                {
                                    r = cast(ubyte) (r > 50 ? r - 50 : 0);
                                    g = cast(ubyte) (g > 50 ? g - 50 : 0);
                                    b = cast(ubyte) (b > 50 ? b - 50 : 0);
                                }
                            }
                            else if (sel)
                            {
                                if (seldark)
                                {
                                    r = cast(ubyte) (r < 205 ? r + 50 : 255);
                                    g = cast(ubyte) (g < 205 ? g + 50 : 255);
                                    b = cast(ubyte) (b < 205 ? b + 50 : 255);
                                }
                                else
                                {
                                    r = cast(ubyte) (r > 50 ? r - 50 : 0);
                                    g = cast(ubyte) (g > 50 ? g - 50 : 0);
                                    b = cast(ubyte) (b > 50 ? b - 50 : 0);
                                }
                            }

                            ubyte[4] p = [r, g, b, a];

                            if (x0 == DBGX && y0 == DBGY)
                            {
                                writefln("x0 %s y0 %s p %s, x %s y %s, dx %s dy %d", x0, y0, p, x, y, dx, dy);
                            }

                            uint off = (y0*ow + x0)*4;
                            imgbuf[off..off+4] = p;
                        }
                    }
                }
            }
        }
    }

    uint rmask, gmask, bmask, amask;
    rmask = 0x000000ff;
    gmask = 0x0000ff00;
    bmask = 0x00ff0000;
    amask = 0xff000000;
    return SDL_CreateRGBSurfaceFrom(imgbuf.ptr, ow, oh,
            32, ow * 4, rmask, gmask, bmask, amask);
}
