module hexpict.tiles;

import hexpict.h6p;

import std.conv;
import std.file;
import std.algorithm;

H6P[uint] tiles_pal;

void load_tiles()
{
    string dir = "tiles/";

    foreach(file; dirEntries(dir, SpanMode.depth))
    {
        string colstr = file.name.find("#");
        if (colstr.length >= 6)
        {
            uint color = colstr[1..6].to!uint(16);
            H6P* h6p = h6p_read(file.name);
            tiles_pal[color] = *h6p;
        }
    }
}

/*
SDL_Surface *tile_h6p(H6P *img)
{
    uint w = img.width;
    uint h = img.height;

    uint iw = 9*w;
    uint ih = 9*h+3;

    ubyte[] imgdata = new ubyte[iw*ih*4];

    foreach (y; 0..h)
    {
        foreach (x; 0..w)
        {
            uint tilen = RGB2color(img[x, y]);
            auto tile = tilen in tiles_pal;
            if (tile)
            {
                foreach(ty; 0..12)
                {
                    int dx, dw, mm;
                    mm = 1;

                    switch (ty)
                    {
                        case 0:
                            dx = 4;
                            dw = 2;
                            break;

                        case 1:
                            dx = 2;
                            dw = 5;
                            break;

                        case 2:
                            dx = 1;
                            dw = 8;
                            break;

                        case 3:
                        case 5:
                        case 7:
                            dx = 0;
                            dw = 9;
                            mm = 0;
                            break;

                        case 4:
                        case 6:
                        case 8:
                            dx = 0;
                            dw = 10;
                            break;

                        case 9:
                            dx = 0;
                            dw = 9;
                            break;

                        case 10:
                            dx = 2;
                            dw = 6;
                            break;

                        case 11:
                            dx = 3;
                            dw = 3;
                            break;

                        default:
                            assert(0, "Unreachable statement");
                    }

                    imgdata[(iw*(y*9+ty) + x*9 + (y%2 ? 4 + (ty%2) : 0) + dx + mm)*4 .. (iw*(y*9+ty) + x*9 + (y%2 ? 4 + (ty%2) : 0) + dx + dw)*4] =
                        tile.image.pixels[(tile.image.width*ty + dx + mm)*4 .. (tile.image.width*ty + dx + dw)*4];
                }
            }
        }
    }

    uint rmask, gmask, bmask, amask;
    rmask = 0x000000ff;
    gmask = 0x0000ff00;
    bmask = 0x00ff0000;
    amask = 0xff000000;
    return SDL_CreateRGBSurfaceFrom(imgdata.ptr, iw, ih,
            32, iw * 4, rmask, gmask, bmask, amask);
}
*/
