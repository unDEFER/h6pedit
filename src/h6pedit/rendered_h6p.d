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

module h6pedit.rendered_h6p;

import bindbc.sdl;

import hexpict.hex2pixel;
import hexpict.h6p;
import hexpict.color;
import hexpict.colors;

import std.math;

// @RenderedH6P
class RenderedH6P
{
    int offx, offy;
    int scale = 4;
    SDL_Rect rect;

    bool changed = true;
    SDL_Texture* texture;
    SDL_Surface* surface;

    H6P *image;

    this(H6P *img, int iw, int ih)
    {
        image = img;

        this(iw, ih);
    }

    this(int w, int h, int iw, int ih, ColorSpace *space)
    {
        ubyte[] imgdata = new ubyte[w*h*4];

        image = h6p_create(space, w, h);

        this(iw, ih);
    }

    this(int w, int h, int iw, int ih)
    {
        ubyte[] imgdata = new ubyte[w*h*4];

        ColorSpace *ITP = new ColorSpace;
        *ITP = ITP_SPACE;
        Bounds bb = new double[][](2,3);
        get_itp_bounds(&RMB_SPACE, bb);
        ITP.bounds = bb;
        image = h6p_create(ITP, w, h);

        this(iw, ih);
    }

    this(int iw, int ih)
    {
        if (iw == 0 || ih == 0) return;
        rect.w = iw;
        rect.h = ih;
    }

    ~this()
    {
        SDL_DestroyTexture(texture);
    }

    void h2p(bool inv = false, bool t = false)
    {
        bool tile_mode;
        if (scale == 36 || t) tile_mode = true;
        //hex2pixel(image, mask, scale, offx, offy,
        //        rendered_data, rect.w, rect.h, inv, tile_mode);

        surface = h6p_render(image, scale, inv,
                offx, offy, rect.w, rect.h);
        assert(surface !is null);
    }

    int pixelcoord2hex(int x, int y, out int hx, out int hy)
    {
        int w = scale;

        int h = cast(int) round(w * 2.0 / sqrt(3.0));
        int hh = cast(int) round(h/4.0);

        hx = x / w;
        hy = y / (h-hh);

        int x0 = x - hx*w;
        int y0 = y - hy*(h-hh);
            
        hx += offx;
        hy += offy;

        if (hy%2 == 1)
        {
            x0 += w/2;
            if (x0 >= w)
            {
                x0 -= w;
                hx++;
            }
            hx--;
        }

        struct Point
        {
            int x, y;
        }

        // @PointsOfHexagon
        Point[12] points;

        points[0] = Point(w/2, 0);
        points[2] = Point(w, cast(int) round(h/4.0));
        points[4] = Point(w, h - cast(int) round(h/4.0));
        points[6] = Point(w/2, h);
        points[8] = Point(0, h - cast(int) round(h/4.0));
        points[10] = Point(0, cast(int) round(h/4.0));

        {
            int p, p1;
            if (y0 < points[2].y)
            {
                if (x0 < points[0].x)
                {
                    p = 10;
                    p1 = 0;
                }
                else
                {
                    p = 0;
                    p1 = 2;
                }
            }
            else if (y0 > points[4].y)
            {
                if (x0 < points[6].x)
                {
                    p = 6;
                    p1 = 8;
                }
                else
                {
                    p = 4;
                    p1 = 6;
                }
            }
            else
            {
                goto skip;
            }

            bool bit;

            int dx = points[p1].x - points[p].x;
            int dy = points[p1].y - points[p].y;

            double k = 1.0*dy/dx;

            int dx1 = x0 - points[p].x;
            int dy1 = y0 - points[p].y;
            if (sgn(dx1) != sgn(dx))
            {
                bit = (k > 0 ? dy1 == 0 && dx1 == 0 : sgn(dy1) == sgn(dy));
            }
            else
            {
                double k1 = 1.0*dy1/dx1;
                bit = k1 <= k;
            }

            if (bit)
            {
                if (y0 < points[2].y)
                {
                    hy--;
                    if (x0 < points[0].x)
                    {
                        if (hy%2 == 1) hx--;
                    }
                    else
                    {
                        if (hy%2 == 0) hx++;
                    }
                }
                else if (y0 > points[4].y)
                {
                    hy++;
                    if (x0 < points[6].x)
                    {
                        if (hy%2 == 0) hx--;
                    }
                    else
                    {
                        if (hy%2 == 1) hx++;
                    }
                }
            }
        }

skip:
        foreach(p; 0..6)
        {
            int p0 = p*2;
            int p1 = ((p+1)*2) % 12;

            int xx = (points[p0].x + points[p1].x)/2;
            int yy = (points[p0].y + points[p1].y)/2;

            points[1+p*2] = Point(xx, yy);
        }

        hx -= offx;
        hy -= offy;

        x0 = x - hx*w;
        y0 = y - hy*(h-hh);

        hx += offx;
        hy += offy;

        if (hy%2 == 1)
        {
            x0 += w/2;
            if (x0 >= w)
            {
                x0 -= w;
            }
        }

        int r = 0;
        float dist = float.max;

        foreach(p; 0..12)
        {
            int dx = points[p].x - x0;
            int dy = points[p].y - y0;

            float d = hypot(dx*1.0, dy*1.0);
            if (d < dist)
            {
                r = p;
                dist = d;
            }
        }

        if (hx >= image.width)
            hx = image.width-1;
        if (hy >= image.height)
            hy = image.height-1;

        return r;
    }

    void update(SDL_Renderer* renderer, bool inv = false)
    {
        if (changed)
        {
            if (texture) SDL_DestroyTexture(texture);

            h2p(inv);

            texture = SDL_CreateTextureFromSurface(renderer, surface);

            changed = false;
        }
    }

    void draw(SDL_Renderer* renderer)
    {
        SDL_RenderCopy(renderer, texture, null, &rect);
    }
}
