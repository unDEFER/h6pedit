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

module h6pedit.draw;

import hexpict.hex2pixel;
import hexpict.h6p;
import hexpict.color;
import hexpict.colors;
import hexpict.hyperpixel;
import h6pedit.global_state;
import h6pedit.print;
import std.stdio;
import std.math;
import std.algorithm;
import std.format;
import bindbc.sdl;

// @PictureView
void update_view()
{
    if (picture.changed) tile_preview.changed = true;
    picture.update(renderer);
}

// @Selection
void update_selection()
{
    if (mode == Mode.ColorPicker)
    {
        selection.image = color_picker.image;
        selection.scale = 4;
        selection.offx = colors_select.x;
        selection.offy = colors_select.y;
    }
    else
    {
        selection.image = picture.image;
        selection.scale = picture.scale;
        selection.offx = select.x;
        selection.offy = select.y;
    }

    selection.update(renderer, true);
}

// @ColorPicker
void update_colors()
{
    if (mode == Mode.ColorPicker && color_picker.changed)
    {
        bool err;
        ubyte[4] pc;
        Color color = pictures[pict].image.cpalette[0][color];
        color_to_u8(&color, &SRGB_SPACE, pc, &err, ErrCorrection.ORDINARY);

        if (color_picker.image.cpalette[0].length < 16384)
        {
            color_picker.image.cpalette[0].length = 16384;
        }

        foreach (y; 0..128)
        {
            foreach (x; 0..128)
            {
                Pixel *p = color_picker.image.pixel(x, y);
                p.color = 0;
            }
        }

        ubyte pa = pc[3];
        ubyte pr = pc[0];
        ubyte pg = pc[1];
        ubyte pb = pc[2];

        ubyte start_gray = color_gray;
        
        enum div = 4;

        ushort numpixels = 0;

        int cx = 256/div;
        int cy = 256/div;
        foreach (dy; 0..(256-start_gray)/div)
        {
            ubyte ur, ug, ub;
            ubyte dr, dg, db;

            int odds = (dy+1)/2;

            ur = cast(ubyte)(start_gray + odds*div);
            ug = cast(ubyte)(start_gray + dy*div);
            ub = start_gray;

            dr = cast(ubyte)(start_gray + odds*div);
            dg = start_gray;
            db = cast(ubyte)(start_gray + dy*div);

            foreach (dx; 0..(256-start_gray)/div)
            {
                int r, g, b;
                r = ur + dx*div;
                g = ug;
                b = ub;

                if (r < 256)
                {
                    if (abs(r-pr) < div && abs(g-pg) < div && abs(b-pb) < div)
                    {
                        colors_select.x = cx+dx;
                        colors_select.y = cy-dy;
                    }

                    Color c = Color([r/255.0, g/255.0, b/255.0, 1.0], false, &SRGB_SPACE);

                    int x = cx+dx;
                    int y = cy-dy;
                    ushort ncolor = cast(ushort)(y*128 + x);
                    color_picker.image.cpalette[0][ncolor] = c;
                    Pixel *p = color_picker.image.pixel(x, y);
                    p.color = ncolor;
                }

                r = ur - dx*div;
                g = ug;
                b = ub;

                if (r < start_gray)
                {
                    g = ug + (start_gray - r);
                    b = ub + (start_gray - r);
                    r = start_gray;
                }

                if (g < 256 && b < 256)
                { 
                    if (abs(r-pr) < div && abs(g-pg) < div && abs(b-pb) < div)
                    {
                        colors_select.x = cx-dx;
                        colors_select.y = cy-dy;
                    }

                    Color c = Color([r/255.0, g/255.0, b/255.0, 1.0], false, &SRGB_SPACE);

                    int x = cx-dx;
                    int y = cy-dy;
                    ushort ncolor = cast(ushort)(y*128 + x);
                    color_picker.image.cpalette[0][ncolor] = c;
                    Pixel *p = color_picker.image.pixel(x, y);
                    p.color = ncolor;
                }

                r = dr + dx*div;
                g = dg;
                b = db;

                if (r < 256)
                {
                    if (abs(r-pr) < div && abs(g-pg) < div && abs(b-pb) < div)
                    {
                        colors_select.x = cx+dx;
                        colors_select.y = cy+dy;
                    }

                    Color c = Color([r/255.0, g/255.0, b/255.0, 1.0], false, &SRGB_SPACE);

                    int x = cx+dx;
                    int y = cy+dy;
                    ushort ncolor = cast(ushort)(y*128 + x);
                    color_picker.image.cpalette[0][ncolor] = c;
                    Pixel *p = color_picker.image.pixel(x, y);
                    p.color = ncolor;
                }

                r = dr - dx*div;
                g = dg;
                b = db;

                if (r < start_gray)
                {
                    g = dg + (start_gray - r);
                    b = db + (start_gray - r);
                    r = start_gray;
                }

                if (g < 256 && b < 256)
                { 
                    if (abs(r-pr) < div && abs(g-pg) < div && abs(b-pb) < div)
                    {
                        colors_select.x = cx-dx;
                        colors_select.y = cy-dy;
                    }

                    Color c = Color([r/255.0, g/255.0, b/255.0, 1.0], false, &SRGB_SPACE);

                    int x = cx-dx;
                    int y = cy+dy;
                    ushort ncolor = cast(ushort)(y*128 + x);
                    color_picker.image.cpalette[0][ncolor] = c;
                    Pixel *p = color_picker.image.pixel(x, y);
                    p.color = ncolor;
                }
            }
        }

        color_picker.update(renderer);
    }
}

// @PictureView
void draw_picture()
{
    picture.draw(renderer);
}

// @Palette
void draw_palette()
{
    if (mode == Mode.Edit || mode == Mode.ColorPicker)
    {
        foreach(i, t; palette_textures)
        {
            double step = screen.w / 11.0;
            double size = step/2;
            step = (screen.w - size) / 11.0;

            SDL_Rect rect;
            rect.x = cast(int) round(i*step);
            rect.y = cast(int) round(screen.h - step);
            rect.w = cast(int) round(size);
            rect.h = cast(int) round(size);

            if (color == i)
            {
                rect.x -= cast(int) round(size*.25);
                rect.y -= cast(int) round(size*.25);
                rect.w += cast(int) round(size*.5);
                rect.h += cast(int) round(size*.5);
            }

            SDL_RenderCopy(renderer, t, null, &rect);

            if (color2 == i)
            {
                print("2", rect.x/4, cast(int) (rect.y/3.5),
                        [255, 255, 255]);
            }
        }
    }
}

// @ColorPicker
void draw_color_picker()
{
    color_picker.draw(renderer);
}

// @MaskHint
void update_mask_hint()
{
    if (mask_hint.changed)
    {
        //mask_hint.image.raster[0..$] = 0;
        mask_hint.image.cpalette[0].length = 8;
        mask_hint.image.forms.length = 7;

        Pixel *px = picture.image.pixel(select.x, select.y);
        foreach(i, dform; px.forms)
        {
            Pixel *pm = mask_hint.image.pixel(cast(uint) (i*2), 0);

            ushort form = dform.form;
            pm.forms.length = 1;
            if (form >= 19*4)
            {
                mask_hint.image.forms[i] = picture.image.forms[dform.form - 19*4];
                pm.forms[0].form = cast(ushort)(i+19*4);
            }
            else
            {
                pm.forms[0].form = form;
            }

            pm.forms[0].rotation = dform.rotation;
            pm.forms[0].extra_color = cast(ushort)(i+1);
            mask_hint.image.cpalette[0][i+1] = picture.image.cpalette[0][dform.extra_color];
        }

        foreach(i; px.forms.length..7)
        {
            Pixel *pm = mask_hint.image.pixel(cast(uint) (i*2), 0);
            pm.forms.length = 0;
        }

        mask_hint.update(renderer);
    }
}

struct HPoint
{
    ubyte x, y;
}

private HPoint[61] hpoints;

static this()
{
    hpoints[0] = HPoint(6, 0);
    hpoints[4] = HPoint(12, 4);
    hpoints[8] = HPoint(12, 12);
    hpoints[12] = HPoint(6, 16);
    hpoints[16] = HPoint(0, 12);
    hpoints[20] = HPoint(0, 4);

    hpoints[60] = HPoint(6, 8);

    foreach(p; 0..6)
    {
        int p0 = p*4;

        foreach(i; 1..4)
        {
            int p1 = (27 - i*3)*i + p*(4-i);

            ubyte xx = cast(ubyte)((hpoints[p0].x*(4-i) + hpoints[60].x*i)/4);
            ubyte yy = cast(ubyte)((hpoints[p0].y*(4-i) + hpoints[60].y*i)/4);

            hpoints[p1] = HPoint(xx, yy);
        }
    }

    foreach(z; 0..3)
    {
        int v = 4 - z;
        foreach(p; 0..6)
        {
            int o = (27 - z*3)*z;
            int p0 = o + p*v;
            int p1 = o + ((p+1)*v) % (6*v);

            foreach(i; 1..v)
            {
                ubyte yy = cast(ubyte)((hpoints[p0].y*(v-i) + hpoints[p1].y*i)/v);
                ubyte xx = cast(ubyte)((hpoints[p0].x*(v-i) + hpoints[p1].x*i)/v + (yy == 4 || yy == 12 ? 1 : 0));

                hpoints[p0+i] = HPoint(xx, yy);
            }
        }
    }
}

// @Mask2Hint
void update_mask2_hint()
{
    if (mask2_hint.changed)
    {
        mask2_hint.image.cpalette[0].length = 4;
        mask2_hint.image.forms.length = 7;

        mask2_hint.image.cpalette[0][1] = Color([0.0f, 0.0f, 1.0f, 1.0f], false, &SRGB_SPACE);
        mask2_hint.image.cpalette[0][2] = Color([1.0f, 1.0f, 0.0f, 1.0f], false, &SRGB_SPACE);
        mask2_hint.image.cpalette[0][3] = Color([0.5f, 0.5f, 0.5f, 1.0f], false, &SRGB_SPACE);

        uint scalew = scales[scale];
        foreach(i, p; hpoints)
        {
            Pixel *px = mask2_hint.image.pixel(p.x, p.y);
            px.color = i<24 && (i%2 == 0 || scalew >= 32) || scalew >= 64 ? 1 : 0;
        }

        foreach(d; form_dots)
        {
            HPoint *hp = &hpoints[d];
            Pixel *px = mask2_hint.image.pixel(hp.x, hp.y);
            px.color = 3;
        }

        HPoint *hp = &hpoints[ dot_by_line[doty][dotx] ];
        Pixel *px = mask2_hint.image.pixel(hp.x, hp.y);
        px.color = 2;

        mask2_hint.update(renderer);
    }
}

// @MaskHint
void draw_mask_hint()
{
    mask_hint.rect.x = (screen.w - mask_hint.rect.w)/2;
    mask_hint.rect.y = screen.h - mask_hint.rect.h;

    mask_hint.draw(renderer);

    /*if (mask_i < 2)
    {
        print_chr(cast(wchar) ('0'+(mask_of - mask_i)),
                (mask_hint.rect.x + mask_hint.rect.w/2)/4 - 3,
                cast(int) ((mask_hint.rect.y + mask_hint.rect.h/2)/3.5) - 8,
                [255, 127, 0]);
    }*/
}

// @Mask2Hint
void draw_mask2_hint()
{
    uint scalew = scales[scale];
    uint scaledown = 1;

    if (scalew == 4 || scalew == 2 || scalew == 1)
    {
        scaledown = 8/scalew;
        scalew = 8;
    }
    else
    {
        scaledown = 2;
        scalew *= 2;
    }

    int h = cast(int) round(scalew * 2.0 / sqrt(3.0));
    int hh = cast(int) floor(h/4.0);

    mask2_hint.rect.x = (select.x - picture.offx) * scales[scale];
    mask2_hint.rect.y = (select.y - picture.offy) * (h - hh) / scaledown;
    mask2_hint.rect.w = scalew / scaledown;
    mask2_hint.rect.h = h / scaledown;

    if (select.y%2 == 1) mask2_hint.rect.x += scales[scale]/2;

    mask2_hint.draw(renderer);
}

// @Selection
void draw_cursor()
{
    if ((time/30)%2 == 0)
    {
        if (mode == Mode.ColorPicker)
        {
            SDL_Rect rect;
            rect.x = colors_select.x * 8 + 2*(colors_select.y%2);
            rect.y = colors_select.y * 7;
            rect.w = colors_select.w;
            rect.h = colors_select.h;

            SDL_RenderCopy(renderer, selection.texture, null, &rect);
        }
        else
        {
            uint scalew = scales[scale];
            uint scaledown = 1;

            if (scalew == 4 || scalew == 2 || scalew == 1)
            {
                scaledown = 8/scalew;
                scalew = 8;
            }
            else
            {
                scaledown = 2;
                scalew *= 2;
            }

            int h = cast(int) round(scalew * 2.0 / sqrt(3.0));
            int hh = cast(int) floor(h/4.0);
            
            selection.rect.x = (select.x - picture.offx) * scales[scale];
            selection.rect.y = (select.y - picture.offy) * (h - hh) / scaledown;

            if (select.y%2 == 1) selection.rect.x += scales[scale]/2;

            selection.draw(renderer);
        }
    }
}

// @DrawCoords
void draw_coords()
{
    print(format("%sx%s", select.x, select.y),
            0, cast(int) ((screen.h - 30)/3.5),
            [255, 255, 255]);

    print(format("%s", vertex),
            90, cast(int) ((screen.h - 30)/3.5),
            [255, 255, 255]);
}

// @DrawScreen
void draw_screen()
{
    update_view();
    update_selection();
    update_colors();

    SDL_SetRenderDrawColor(renderer, 160, 120, 80, 255);
    SDL_RenderClear(renderer);
    SDL_SetRenderTarget(renderer, null);

    double refScale = 1.0;
    int vx = 0;
    int vy = 0;

    if (reference)
    {
        reference.draw();
        reference.draw_cursor();
    }

    if (!hide_picture)
        draw_picture();

    draw_palette();

    if (mode == Mode.ColorPicker)
    {
        draw_color_picker();
    }
    else if (mode == Mode.SimpleFormEdit)
    {
        update_mask_hint();
        draw_mask_hint();
    }
    else if (mode == Mode.ExtendedFormEdit)
    {
        update_mask2_hint();
        draw_mask2_hint();
    }

    if (picture.image.width == 10 && picture.image.height == 12)
    {
        if (tile_preview.changed)
        {
            foreach(ty; 0..4)
            {
                foreach(tx; 0..4)
                {
                    foreach(y; 0..12)
                    {
                        if (ty % 2 && tx == 3) continue;
                        int dx, dw, mm;
                        mm = 1;

                        switch (y)
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

                        for (int dd = mm; dd < dw; dd++)
                        {
                            Pixel *p = picture.image.pixel(dx + dd, y);
                            Pixel *pt = tile_preview.image.pixel(tx*9 + (ty%2 ? 4 + (y%2) : 0) + dx + dd, ty*9+y);
                            *pt = *p;
                        }
                    }
                }
            }
        }

        tile_preview.update(renderer);
        tile_preview.draw(renderer);
    }

    draw_coords();
    if (mode != Mode.ExtendedFormEdit) draw_cursor();

    SDL_RenderPresent(renderer);
}
