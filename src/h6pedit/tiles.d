module h6pedit.tiles;

import h6pedit.rendered_h6p;
import h6pedit.global_state;
import hexpict.h6p;

import std.conv;
import std.file;
import std.algorithm;

RenderedH6P[uint] tiles_pal;

void load_tiles()
{
    string dir = "tiles/";

    foreach(file; dirEntries(dir, SpanMode.depth))
    {
        string colstr = file.name.find("#");
        if (colstr.length >= 6)
        {
            uint color = colstr[1..6].to!uint(16);
            H6P *img = h6p_read(file.name);
            tiles_pal[color] = new RenderedH6P(img, 36, 42);
            tiles_pal[color].h2p(false, true);
        }
    }
}
