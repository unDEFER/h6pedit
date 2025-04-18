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
        do
        {
            Vertex v = Vertex(select.x, select.y, dot_by_line[doty][dotx]);
            paint(v);

            ubyte dotx_ = cast(ubyte) (dotx + (5-dot_by_line[doty].length)/2);
            uint gx = v.x*8 + (v.y%2 == 1 ? 4 : 0) + dotx_;
            uint gy = v.y*6 + doty;

            //doty += dy[i];
        }
        while (i < form.length);
    }
}
