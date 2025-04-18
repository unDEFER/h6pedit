module h6pedit.brush;

import hexpict.h6p;
import hexpict.hyperpixel;
import h6pedit.global_state;
import h6pedit.tick;

struct Vector
{
    short dx, dy;
}

struct Brush
{
    Vector[] form;

    void apply()
    {
        size_t i = 0;
        while (true)
        {
            Vertex v = Vertex(select.x, select.y, dot_by_line[doty][dotx]);
            paint(v);
            
            if (i >= form.length) break;

            ubyte dotx_ = cast(ubyte) (dotx + (5-dot_by_line[doty].length)/2);
            uint gx = v.x*8 + (v.y%2)*4 + (doty%2) + dotx_*2;
            uint gy = v.y*12 + doty;

            //writefln("%s gx = %s, gy = %s", v, gx, gy);

            gx += form[i].dx;
            gy += form[i].dy;

            v.y = gy/12;
            doty = gy%12;
            uint sx = gx - (v.y%2)*4 - (doty%2);
            v.x = sx/8;
            dotx_ = (sx%8)/2;
            dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);

            if (dotx >= dot_by_line[doty].length)
            {
                v.y--;
                doty += 12;
                sx = gx - (v.y%2)*4 - (doty%2);
                v.x = sx/8;
                dotx_ = (sx%8)/2;
                dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);
            }

            v.p = dot_by_line[doty][dotx];

            //writefln("New %s", v);

            select.x = v.x;
            select.y = v.y;
        }
    }
}
