module h6pedit.brush;

import hexpict.h6p;
import hexpict.hyperpixel;

struct Vector
{
    short dx, dy;
}

struct Brush
{
    Vector[] form;
}

import std.math;
import std.algorithm.mutation;
import h6pedit.global_state;
import h6pedit.tick;
import h6pedit.rendered_h6p;

void brush_preview_init(Brush b)
{
    int left, right;
    int top, bottom;
    int x, y;

    for (size_t i = 0; i < b.form.length; i++)
    {
        x += b.form[i].dx;
        y += b.form[i].dy;

        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
    }

    int gw = right - left;
    int gh = bottom - top + 4;

    int w = gw / 8 + 1;
    int h = gh / 12 + 1;

    int hw = 8;
    int hh = cast(int) round(hw * 2.0 / sqrt(3.0));
    int hhh = cast(int) floor(hh/4.0);

    int iw = w*hw;
    int ih = h*(hh-hhh) + hhh;

    brush_preview = new RenderedH6P(w, h, iw, ih);

    swap(pictures[pict], brush_preview);

    uint[2] gc = [-left, -top + 4];
    uint[2][] gvertices;
    gvertices ~= gc;

    Vertex[] vs = Vertex.from_global(gvertices);

    select.x = vs[0].x;
    select.y = vs[0].y;

    dotx = dot_to_coords[vs[0].p][0];
    doty = dot_to_coords[vs[0].p][1];

    first_v.p = 100;
    last_v.p = 100;
    edited_forms_by_coords.clear();

    Pixel *p = picture.image.pixel(select.x, select.y);
    edited_form = cast(ubyte) p.forms.length;
    form_dots.length = 0;

    apply_brush(brush);
    join_forms();

    swap(pictures[pict], brush_preview);
}

