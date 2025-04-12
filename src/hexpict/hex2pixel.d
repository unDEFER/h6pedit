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

module hexpict.hex2pixel;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;
import std.bitmanip;
import bindbc.sdl;

import hexpict.h6p;
import hexpict.color;
import hexpict.hyperpixel;

enum DBGX = -1;
enum DBGY = -1;

SDL_Surface *h6p_render(H6P *image, uint scale, bool inv, int offx, int offy, int ow, int oh)
{   
    // @Hex2PixelScaleDown
    uint scaledown = 1;

    if (scale == 4 || scale == 2 || scale == 1)
    {
        scaledown = 8/scale;
        scale = 8;
    }
    /*else
    {
        scaledown = 2;
        scale *= 2;
    }*/

    // @HyperMask
    uint w = scale;
    float wf = w;
    float hf = round(wf * 2.0 / sqrt(3.0));
    uint h = cast(uint) hf;

    uint iw = image.width;
    uint ih = image.height;

    uint hpw = scale;
    float hpwf = hpw;
    float hphf = round(hpwf * 2.0 / sqrt(3.0));
    uint hph = cast(uint) hphf;

    float hhf = floor(hphf/4.0);
    uint hh = cast(uint) hhf;

    uint nw = hpw*iw;
    uint nh = ih*(hph-hh)+hh+1;

    ubyte[12] form12;
    BitArray *hp = hyperpixel(hpw, form12, 0);

    ubyte[] imgbuf;

    int oow = cast(int) ceil(1.0 * ow*scaledown / hpw);
    int ooh = cast(int) ceil(1.0 * oh*scaledown / (hph-hh));

    int th = min(ih, offy+ooh-1);
    int tw = min(iw, offx+oow);

    imgbuf = new ubyte[(ow*scaledown)*(oh*scaledown) * 4];
    assert(imgbuf !is null);

    ColorSpace *rgbspace = get_rgbspace(image.space);

    for (uint y = offy; y < th; y++)
    {
        uint iy = (y-offy)*(hph-hh);

        for (uint x = offx; x < tw; x++)
        {
            bool _debug = (cast(int) x == DBGX && cast(int) y == DBGY);

            Pixel *h6p = image.pixel(x, y);
            bool err;
            ubyte[4] p;
            Color color = image.cpalette[0][h6p.color];
            if (inv) invert(&color, ErrCorrection.ORDINARY);
            color_to_u8(&color, rgbspace, p, &err, ErrCorrection.ORDINARY);

            // @H6PCoordinates
            uint ix;
            if ((inv ? y - offy : y)%2 == 0)
            {
                ix = hpw*(x-offx);
            }
            else
            {
                ix = hpw/2+hpw*(x-offx);
            }

            if (_debug)
            {
                writefln("%sx%s p=%s color=%s", x, y, p, h6p.color);
            }

            for (uint dy = 0; dy < hph; dy++)
            {
                if (iy+dy >= oh*scaledown) { break; }

                //int first_in_line = true;

                for (uint dx = 0; dx < hpw; dx++)
                {
                    if (ix+dx >= ow*scaledown) { break; }

                    size_t hpos = dx + dy*hpw;

                    if ((*hp)[hpos])
                    {
                        /*if (cast(int) ix+dx == 1193*2 && cast(int) iy+dy == 211*2)
                        {
                            writefln("%sx%s %sx%s %sx%s p %s", x, y, ix, iy, ix+dx, iy+dy, p);
                        }*/
                        size_t off = ((iy+dy)*(ow*scaledown) + (ix+dx))*4;
                        imgbuf[off..off+4] = p;
                    }
                }
            }

            //static if (false)
            foreach (s, subform; h6p.forms)
            {
                if (_debug)
                {
                    writefln("%sx%s %s. Form=%s rot=%s", x, y, s, subform.form, subform.rotation);
                }
                ubyte[4] mp;
                Color mcolor = image.cpalette[0][subform.extra_color];
                if (inv) invert(&mcolor, ErrCorrection.ORDINARY);
                color_to_u8(&mcolor, rgbspace, mp, &err, ErrCorrection.ORDINARY);

                BitArray *mhp = 
                    subform.form < 19*4 ?
                    get_simple_hyperpixel(subform.form, hpw, subform.rotation, hpw <= 16 && _debug) :
                    image.forms[subform.form - 19*4].get_hyperpixel(hpw, subform.rotation, hpw <= 16 && _debug);

                for (uint dy = 0; dy < hph; dy++)
                {
                    if (iy+dy >= oh*scaledown) { break; }

                    for (uint dx = 0; dx < hpw; dx++)
                    {
                        if (ix+dx >= ow*scaledown) { break; }

                        size_t hpos = dx + dy*hpw;

                        if ((*mhp)[hpos])
                        {
                            if (cast(int) ix+dx == 1193*2 && cast(int) iy+dy == 211*2)
                            {
                                writefln("%sx%s %sx%s %sx%s mp %s", x, y, ix, iy, ix+dx, iy+dy, mp);
                            }
                            size_t off = ((iy+dy)*(ow*scaledown) + (ix+dx))*4;
                            imgbuf[off..off+4] = mp;
                        }
                    }
                }
            }


        }
    }

    // @Hex2PixelScaleDown
    if (scaledown > 1)
    {
        ubyte[] imgbuf2 = new ubyte[ow*oh * 4];
        assert(imgbuf2 !is null);

        for (uint y = 0; y < oh; y++)
        {
            for (uint x = 0; x < ow; x++)
            {
                ushort[4] p = [0, 0, 0, 0];

                for (uint dy = 0; dy < scaledown; dy++)
                {
                    for (uint dx = 0; dx < scaledown; dx++)
                    {
                        ubyte[4] pp;
                        uint xx = x*scaledown+dx;
                        uint yy = y*scaledown+dy;
                        size_t off = (yy*(ow*scaledown) + xx)*4;
                        pp = imgbuf[off..off+4];

                        p[0] += pp[0];
                        p[1] += pp[1];
                        p[2] += pp[2];
                        p[3] += pp[3];
                    }
                }

                ushort ss = cast(ushort) (scaledown*scaledown);
                p[0] = cast(ushort) ((p[0]+ss/2)/ss);
                p[1] = cast(ushort) ((p[1]+ss/2)/ss);
                p[2] = cast(ushort) ((p[2]+ss/2)/ss);
                p[3] = cast(ushort) ((p[3]+ss/2)/ss);

                ubyte[4] pp = [cast(ubyte) p[0], cast(ubyte) p[1], cast(ubyte) p[2], cast(ubyte) p[3]];
                uint off = (y*ow + x)*4;
                imgbuf2[off..off+4] = pp;
            }
        }

        imgbuf = imgbuf2;
    }

    uint rmask, gmask, bmask, amask;
    rmask = 0x000000ff;
    gmask = 0x0000ff00;
    bmask = 0x00ff0000;
    amask = 0xff000000;
    return SDL_CreateRGBSurfaceFrom(imgbuf.ptr, ow, oh,
            32, ow * 4, rmask, gmask, bmask, amask);
}
