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

import hexpict.common;
import hexpict.hex2pixel;
import hexpict.h6p;
import h6pedit.global_state;
import h6pedit.print;
import derelict.sdl2.sdl;
import std.stdio;
import std.math;
import std.algorithm;
import imaged;

// @PictureView
void update_view()
{
    picture.update(renderer);
}

// @Selection
void update_selection()
{
    if (mode == Mode.ColorPicker)
    {
        selection.image = color_picker.image;
        selection.mask = color_picker.mask;
        selection.scale = 4;
        selection.offx = colors_select.x;
        selection.offy = colors_select.y;
    }
    else
    {
        selection.image = picture.image;
        selection.mask = picture.mask;
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
        //colors_imgdata[0..$] = 127;
        color_picker.image.pixels[0..$] = 127;

        uint color = palette[color];
        ubyte pa = cast(ubyte) ((color >> 24) & 0xFF);
        ubyte pr = cast(ubyte) ((color >> 16) & 0xFF);
        ubyte pg = cast(ubyte) ((color >> 8) & 0xFF);
        ubyte pb = cast(ubyte) (color & 0xFF);

        ubyte start_gray = min(pr, pg, pb);
        
        enum div = 4;

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

                    color_picker.image.pixels[((cy-dy)*512/div + cx+dx)*4 + 0] = cast(ubyte) r;
                    color_picker.image.pixels[((cy-dy)*512/div + cx+dx)*4 + 1] = cast(ubyte) g;
                    color_picker.image.pixels[((cy-dy)*512/div + cx+dx)*4 + 2] = cast(ubyte) b;
                    color_picker.image.pixels[((cy-dy)*512/div + cx+dx)*4 + 3] = 255;
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

                    color_picker.image.pixels[((cy-dy)*512/div + cx-dx)*4 + 0] = cast(ubyte) r;
                    color_picker.image.pixels[((cy-dy)*512/div + cx-dx)*4 + 1] = cast(ubyte) g;
                    color_picker.image.pixels[((cy-dy)*512/div + cx-dx)*4 + 2] = cast(ubyte) b;
                    color_picker.image.pixels[((cy-dy)*512/div + cx-dx)*4 + 3] = 255;
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

                    color_picker.image.pixels[((cy+dy)*512/div + cx+dx)*4 + 0] = cast(ubyte) r;
                    color_picker.image.pixels[((cy+dy)*512/div + cx+dx)*4 + 1] = cast(ubyte) g;
                    color_picker.image.pixels[((cy+dy)*512/div + cx+dx)*4 + 2] = cast(ubyte) b;
                    color_picker.image.pixels[((cy+dy)*512/div + cx+dx)*4 + 3] = 255;
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

                    color_picker.image.pixels[((cy+dy)*512/div + cx-dx)*4 + 0] = cast(ubyte) r;
                    color_picker.image.pixels[((cy+dy)*512/div + cx-dx)*4 + 1] = cast(ubyte) g;
                    color_picker.image.pixels[((cy+dy)*512/div + cx-dx)*4 + 2] = cast(ubyte) b;
                    color_picker.image.pixels[((cy+dy)*512/div + cx-dx)*4 + 3] = 255;
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
        mask_hint.image.pixels[0..$] = 0;
        mask_hint.mask.pixels[0..$] = 0;

        Pixel p = picture.image[select.x, select.y];
        Pixel m = picture.mask[select.x, select.y];

        mask_hint.image.pixels[(4 + 1)*4 + 0] = cast(ubyte) p.r;
        mask_hint.image.pixels[(4 + 1)*4 + 1] = cast(ubyte) p.g;
        mask_hint.image.pixels[(4 + 1)*4 + 2] = cast(ubyte) p.b;
        mask_hint.image.pixels[(4 + 1)*4 + 3] = cast(ubyte) p.a;

        if (mode == Mode.ExtraColor || mask_i > 0)
        {
            mask_hint.mask.pixels[(4 + 1)*4 + 0] = cast(ubyte) m.r;
            mask_hint.mask.pixels[(4 + 1)*4 + 1] = cast(ubyte) m.g;
            mask_hint.mask.pixels[(4 + 1)*4 + 2] = cast(ubyte) m.b;
            mask_hint.mask.pixels[(4 + 1)*4 + 3] = cast(ubyte) m.a;
        }

        if (mode == Mode.ExtraColor)
        {
            int x = select.x;
            int y = select.y;

            // @Neighbours
            Point[6] neigh = neighbours(x, y);
            Point[6] mneigh = [Point(1, 0), Point(2, 0), Point(2, 1), Point(2, 2), Point(1, 2), Point(0, 1)];

            foreach (i, n; neigh)
            {
                if (n.x < 0 || n.y < 0 || n.x >= picture.image.width || n.y >= picture.image.height) continue;
                p = picture.image[n.x, n.y];

                int mx = mneigh[i].x;
                int my = mneigh[i].y;

                mask_hint.image.pixels[(4*my + mx)*4 + 0] = cast(ubyte) p.r;
                mask_hint.image.pixels[(4*my + mx)*4 + 1] = cast(ubyte) p.g;
                mask_hint.image.pixels[(4*my + mx)*4 + 2] = cast(ubyte) p.b;
                mask_hint.image.pixels[(4*my + mx)*4 + 3] = cast(ubyte) p.a;
            }
        }

        mask_hint.update(renderer);
    }
}

// @MaskHint
void draw_mask_hint()
{
    mask_hint.rect.x = (screen.w - mask_hint.rect.w)/2;
    mask_hint.rect.y = screen.h - mask_hint.rect.h;

    mask_hint.draw(renderer);

    if (mask_i < mask_of)
    {
        print_chr(cast(wchar) ('0'+(mask_of - mask_i)),
                (mask_hint.rect.x + mask_hint.rect.w/2)/4 - 3,
                cast(int) ((mask_hint.rect.y + mask_hint.rect.h/2)/3.5) - 8,
                Pixel(255, 127, 0, 255));
    }
}

// @Selection
void draw_cursor()
{
    if ((time/30)%2 == 0)
    {
        if (mode == Mode.ColorPicker)
        {
            SDL_Rect rect;
            rect.x = colors_select.x * 4 + 2*(colors_select.y%2);
            rect.y = colors_select.y * 7/2;
            rect.w = colors_select.w;
            rect.h = colors_select.h;

            SDL_RenderCopy(renderer, selection.texture, null, &rect);
        }
        else
        {
            selection.rect.x = (select.x - picture.offx) * selection.rect.w;
            if (selection.rect.w == 3)
            {
                selection.rect.y = cast(int) (2.5*(select.y - picture.offy));
            }
            else if (selection.rect.w == 4)
            {
                selection.rect.y = cast(int) (3.5*(select.y - picture.offy));
            }
            else
            {
                int hh = cast(int) round(selection.rect.h/4.0);
                selection.rect.y = (select.y - picture.offy) * (selection.rect.h - hh);
            }
            if (select.y%2 == 1) selection.rect.x += selection.rect.w/2;

            selection.draw(renderer);
        }
    }
}

// @DrawScreen
void draw_screen()
{
    update_view();
    update_selection();
    update_colors();

    SDL_SetRenderDrawColor(renderer, 127, 127, 127, 255);
    SDL_RenderClear(renderer);
    SDL_SetRenderTarget(renderer, null);

    draw_picture();

    double refScale = 1.0;
    int vx = 0;
    int vy = 0;

    if (reference)
    {
        reference.draw();
        reference.draw_cursor();
    }

    draw_palette();

    if (mode == Mode.ColorPicker)
    {
        draw_color_picker();
    }
    else if (mode != Mode.Edit)
    {
        update_mask_hint();
        draw_mask_hint();
    }

    draw_cursor();

    SDL_RenderPresent(renderer);
}
