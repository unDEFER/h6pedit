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

module h6pedit.tick;

import h6pedit.global_state;
import hexpict.common;
import hexpict.h6p;
import hexpict.hyperpixel;

import derelict.sdl2.sdl;

import std.datetime;
import std.algorithm;
import std.stdio;
import std.math;
import imaged;

// @Tick
void make_tick()
{
}

// @GrabWindow
void process_event(SDL_Event event)
{
    if (event.type == SDL_WINDOWEVENT)
    {
        switch (event.window.event) {
            case SDL_WINDOWEVENT_SHOWN:
                window_shown = true;
                //SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1".ptr);
                //SDL_SetWindowGrab(window, SDL_TRUE);
                break;
            case SDL_WINDOWEVENT_HIDDEN:
                window_shown = false;
                break;
            default:
                break;
        }
        return;
    }
}

// @Finish
void process_exit_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_Z)
    {
        finish = true;
    }
}

// @ColorPicker
void process_color_picker_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_C)
    {
        if (mode == Mode.ColorPicker)
        {
            mode = Mode.Edit;
            change_color = Pixel.init;
            palette_reinit();
        }
        else
        {
            mode = Mode.ColorPicker;
            mask_hint.changed = true;
            picture.changed = true;
        }
    }
}

// @ChoosePicture
void process_choose_pict_keys(SDL_Event event)
{
    int[12] keys = [SDL_SCANCODE_F1, SDL_SCANCODE_F2, SDL_SCANCODE_F3, SDL_SCANCODE_F4,  SDL_SCANCODE_F5,  SDL_SCANCODE_F6,
                   SDL_SCANCODE_F7, SDL_SCANCODE_F8, SDL_SCANCODE_F9, SDL_SCANCODE_F10, SDL_SCANCODE_F11, SDL_SCANCODE_F12];

    foreach (int i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            if (i < pictures.length)
            {
                pict = i;

                if (select.x >= picture.image.width)
                    select.x = picture.image.width-1;
                if (select.y >= picture.image.height)
                    select.y = picture.image.height-1;

                picture.changed = true;
                selection.changed = true;
            }
        }
    }
}

// @PictureView
void process_change_view_keys(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_W)
    {
        scale++;
        if (scale >= scales.length) scale = cast(int) (scales.length-1);
        picture.scale = scales[scale];
        picture.changed = true;

        selection_reinit();
        selection.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_S)
    {
        scale--;
        if (scale < 0) scale = 0;
        picture.scale = scales[scale];
        picture.changed = true;

        selection_reinit();
        selection.changed = true;
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_Q)
    {
        picture.offy--;
        if (picture.offy < 0) picture.offy = 0;
        picture.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_A)
    {
        picture.offy++;
        picture.changed = true;
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_O)
    {
        picture.offx--;
        if (picture.offx < 0) picture.offx = 0;
        picture.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_P)
    {
        picture.offx++;
        picture.changed = true;
    }
}

// @Lens
void process_lens_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_L)
    {
        reference.lens = !reference.lens;
    }
}

// @Pen
void process_down_pen_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_H)
    {
        pen_down = true;

        if (lshift || change_color == Pixel.init ||
                change_color == picture.image[select.x, select.y])
        {
            change_color = picture.image[select.x, select.y];
            // @CurrentColor
            uint ncolor = palette[color];
            ubyte a = cast(ubyte) ((ncolor >> 24) & 0xFF);
            ubyte r = cast(ubyte) ((ncolor >> 16) & 0xFF);
            ubyte g = cast(ubyte) ((ncolor >> 8) & 0xFF);
            ubyte b = cast(ubyte) (ncolor & 0xFF);

            Pixel p = Pixel(r, g, b, 255);
            picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 0] = r;
            picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 1] = g;
            picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 2] = b;
            picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 3] = a;

            picture.changed = true;
        }
    }
}

// @Pen
void process_up_pen_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_H)
    {
        pen_down = false;
    }
}

// @Invert
void process_invert_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_I)
    {
        ubyte i = cast(ubyte) picture.mask[select.x, select.y].b;
        picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 2] = cast(ubyte) (i ^ 0x08);
        picture.changed = true;
        selection.changed = true;
    }
}

// @EditMask
void process_mask_mode_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_M)
    {
        if (mode == Mode.Edit)
        {
            mode = Mode.MaskStep1;
            mask_of = 1;
            mask_i = 0;
            mask_hint.changed = true;
        }
    }
}

// @ExtraColor
void process_edit_extra_color_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_V)
    {
        if (mode == Mode.Edit)
        {
            mode = Mode.ExtraColor;
            picture.changed = true;
            mask_hint.changed = true;
        }
    }
}

// @Cancel
void process_cancel_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_ESCAPE)
    {
        mode = Mode.Edit;
    }
}

// @Save
void process_save_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_X)
    {
        write_h6p(picture.image, picture.mask, filename);
    }
}

// @ColorPicker
void process_color_picker_navigation_keys(SDL_Event event)
{
    // @Neighbours
    Point[6] neigh = neighbours(colors_select.x, colors_select.y);
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    // @CurrentColor
    auto c = palette[color];
    ubyte r = cast(ubyte) ((c >> 16) & 0xFF);
    ubyte g = cast(ubyte) ((c >> 8) & 0xFF);
    ubyte b = cast(ubyte) (c & 0xFF);
    ubyte a = cast(ubyte) ((c >> 24) & 0xFF);

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            enum div = 4;
            if (neigh[i].x >= 0 && neigh[i].x < 512/div &&
                    neigh[i].y >= 0 && neigh[i].y < 512/div)
            {
                colors_select.x = neigh[i].x;
                colors_select.y = neigh[i].y;

                Pixel p = color_picker.image[colors_select.x, colors_select.y];

                uint ncolor = ((p.r & 0xFF) << 16) |
                    ((p.g & 0xFF) << 8) |
                    (p.b & 0xFF) |
                    ((p.a & 0xFF) << 24);

                // @CurrentColor
                palette[color] = ncolor;
                palette_reinit();
                mask_hint.changed = true;
            }
        }
    }
}

// @ColorPicker
void process_color_picker_value_keys(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_V || event.key.keysym.scancode == SDL_SCANCODE_M)
    {
        Pixel p = color_picker.image[colors_select.x, colors_select.y];

        short mc = min(p.r, p.g, p.b);

        short nc;
        if (event.key.keysym.scancode == SDL_SCANCODE_M)
        {
            nc = cast(short) (mc + 4);
            if (nc > 252) nc = 252;
        }
        else
        {
            nc = cast(short) (mc - 4);
            if (nc < 0) nc = 0;
        }

        if (p.r == mc) p.r = nc;
        if (p.g == mc) p.g = nc;
        if (p.b == mc) p.b = nc;

        uint ncolor = ((p.r & 0xFF) << 16) |
            ((p.g & 0xFF) << 8) |
            (p.b & 0xFF) |
            ((p.a & 0xFF) << 24);

        // @CurrentColor
        palette[color] = ncolor;
        palette_reinit();
        mask_hint.changed = true;
        color_picker.changed = true;
    }
}

// @Selection
void process_navigation_keys(SDL_Event event)
{
    // @Neighbours
    Point[6] neigh = neighbours(select.x, select.y);
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            select.x = neigh[i].x;
            select.y = neigh[i].y;

            if (select.x < 0) select.x = 0;
            if (select.y < 0) select.y = 0;
            if (select.x >= picture.image.width) select.x = picture.image.width-1;
            if (select.y >= picture.image.height) select.y = picture.image.height-1;

            selection.changed = true;

            if (pen_down)
            {
                // @ChangeColor
                if (lshift || change_color == Pixel.init ||
                        change_color == picture.image[select.x, select.y])
                {
                    change_color = picture.image[select.x, select.y];

                    // @CurrentColor
                    uint ncolor = palette[color];
                    ubyte a = cast(ubyte) ((ncolor >> 24) & 0xFF);
                    ubyte r = cast(ubyte) ((ncolor >> 16) & 0xFF);
                    ubyte g = cast(ubyte) ((ncolor >> 8) & 0xFF);
                    ubyte b = cast(ubyte) (ncolor & 0xFF);

                    Pixel p = Pixel(r, g, b, 255);
                    picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 0] = r;
                    picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 1] = g;
                    picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 2] = b;
                    picture.image.pixels[(picture.image.width*select.y + select.x)*4 + 3] = a;

                    picture.changed = true;
                }
            }
        }
    }
}

// @EditMask
void process_mask_editor_keys(SDL_Event event, ref bool dirs_ready)
{
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            if (pressed_dir == -1)
            {
                pressed_dir = cast(byte) i;
            }
            else
            {
                if (i == 5 && pressed_dir == 0)
                    pressed_dir += 6;
                if (i == 0 && pressed_dir == 5)
                    pressed_dir -= 6;

                if (mode == Mode.MaskStep1)
                {
                    dir1 = (i+pressed_dir + 11)%12;
                    mode = Mode.MaskStep2;
                    mask_hint.changed = true;
                }
                else
                {
                    dir2 = (i+pressed_dir + 11)%12;
                    dirs_ready = true;
                }

                pressed_dir = -1;
            }
        }
    }
}

// @EditMask
void process_mask_editor_up_keys(SDL_Event event, ref bool dirs_ready)
{
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            if (pressed_dir == i)
            {
                pressed_dir = -1;

                if (mode == Mode.MaskStep1)
                {
                    dir1 = (i*2 + 11)%12;
                    mode = Mode.MaskStep2;
                }
                else
                {
                    dir2 = (i*2 + 11)%12;
                    dirs_ready = true;
                }
            }
        }
    }
}

// @ExtraColor
void process_mask_color_chooser_keys(SDL_Event event)
{
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 2] = cast(ubyte) i;
            writefln("b=%s", picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 2]);
            mode = Mode.Edit;
            picture.changed = true;
            selection.changed = true;
        }
    }
}

// @TakeColor
void process_take_color_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_T)
    {
        Pixel p = picture.image[select.x, select.y];

        uint ncolor = ((p.r & 0xFF) << 16) |
            ((p.g & 0xFF) << 8) |
            (p.b & 0xFF) |
            ((p.a & 0xFF) << 24);

        // @CurrentColor
        palette[color] = ncolor;
        palette_reinit();
        change_color = Pixel.init;
        color_picker.changed = true;
    }
}

// @Palette
void process_choose_color_keys(SDL_Event event)
{
    int[12] pkeys = [SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4, SDL_SCANCODE_5, SDL_SCANCODE_6,
        SDL_SCANCODE_7, SDL_SCANCODE_8, SDL_SCANCODE_9, SDL_SCANCODE_0, SDL_SCANCODE_MINUS, SDL_SCANCODE_EQUALS];

    foreach (i, k; pkeys)
    {
        if (event.key.keysym.scancode == k)
        {
            color = cast(byte) i;
            color_picker.changed = true;
        }
    }
}

// @EditMask
void process_choose_number_of_areas_keys(SDL_Event event)
{
    int[4] pkeys = [SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4];

    foreach (i, k; pkeys)
    {
        if (event.key.keysym.scancode == k)
        {
            mask_of = cast(ubyte) (i+1);
        }
    }
}

// @DrawLine
void process_draw_line(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_LSHIFT)
    {
        lshift = false;

        if (start_select != select)
        {
            double x1 = start_select.x;
            double y1 = start_select.y;
            if (y1 % 2 == 1) x1 += 0.5;

            double x2 = select.x;
            double y2 = select.y;
            if (y2 % 2 == 1) x2 += 0.5;

            double dx = x2-x1;
            double dy = y2-y1;

            // @CurrentColor
            uint ncolor = palette[color];
            ubyte a = cast(ubyte) ((ncolor >> 24) & 0xFF);
            ubyte r = cast(ubyte) ((ncolor >> 16) & 0xFF);
            ubyte g = cast(ubyte) ((ncolor >> 8) & 0xFF);
            ubyte b = cast(ubyte) (ncolor & 0xFF);

            double x, y;

            double angle = atan2(dy*sqrt(3.0)/2.0, dx) * 180.0 / PI;
            writefln("angle = %s", angle);
            bool swapped;
            if (angle > 45 && angle < 135 || angle < -45 && angle > -135)
            {
                if (dy < 0)
                {
                    dy = -dy;
                    swap(y1, y2);
                    dx = -dx;
                    swap(x1, x2);
                    swap(select, start_select);
                    swapped = true;
                }

                for (y = y1; y <= y2; y += 0.5)
                {
                    x = x1 + (y-y1)*dx/dy;
                    writefln("%sx%s", x, y);

                    int iy = cast(int) round(y);
                    int ix = cast(int) round(x);
                    double px = x;
                    if (iy % 2 == 1)
                    {
                        px -= 0.5;
                        ix = cast(int) round(px);
                    }

                    double fpx = px - trunc(px);
                    if ((abs(angle - 90.0) < 1.0 || abs(angle + 90.0) < 1.0) && fpx > 0.4 && fpx < 0.6)
                    {
                        picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 0] = 37;
                        picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 1] = 0;
                        picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 2] = 1;
                        picture.mask.pixels[(picture.image.width*iy + ix)*4 + 0] = 43;
                        picture.mask.pixels[(picture.image.width*iy + ix)*4 + 1] = 0;
                        picture.mask.pixels[(picture.image.width*iy + ix)*4 + 2] = 0;
                    }
                    else
                    {
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 0] = r;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 1] = g;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 2] = b;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 3] = a;

                        if (abs(angle - 60.0) < 1.0 || abs(angle + 120.0) < 1.0)
                        {
                            if (iy != start_select.y)
                            {
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 0] = 13;
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 2] = 2;
                            }
                            if (iy != select.y)
                            {
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 0] = 19;
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 2] = 5;
                            }
                        }

                        if (abs(angle - 120.0) < 1.0 || abs(angle + 60.0) < 1.0)
                        {
                            if (iy != select.y)
                            {
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 0] = 15;
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*iy + ix-1)*4 + 2] = 2;
                            }
                            if (iy != start_select.y)
                            {
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 0] = 21;
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*iy + ix+1)*4 + 2] = 5;
                            }
                        }
                    }
                }
            }
            else
            {
                if (dx < 0)
                {
                    dy = -dy;
                    swap(y1, y2);
                    dx = -dx;
                    swap(x1, x2);
                    swap(select, start_select);
                    swapped = true;
                }

                for (x = x1; x <= x2; x += 0.5)
                {
                    y = y1 + (x-x1)*dy/dx;
                    writefln("%sx%s", x, y);

                    int iy = cast(int) round(y);
                    int ix = cast(int) round(x);
                    double px = x;
                    if (iy % 2 == 1)
                    {
                        px -= 0.5;
                        ix = cast(int) round(px);
                    }

                    double fpx = px - trunc(px);
                    {
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 0] = r;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 1] = g;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 2] = b;
                        picture.image.pixels[(picture.image.width*iy + ix)*4 + 3] = a;

                        if (abs(angle - 0.0) < 1.0 || abs(angle - 180.0) < 1.0 || abs(angle + 180.0) < 1.0)
                        {
                            if (ix != start_select.x)
                            {
                                if (iy % 2 == 0) ix--;
                                picture.mask.pixels[(picture.image.width*(iy-1) + ix)*4 + 0] = 17;
                                picture.mask.pixels[(picture.image.width*(iy-1) + ix)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*(iy-1) + ix)*4 + 2] = 3;
                                picture.mask.pixels[(picture.image.width*(iy+1) + ix)*4 + 0] = 23;
                                picture.mask.pixels[(picture.image.width*(iy+1) + ix)*4 + 1] = 0;
                                picture.mask.pixels[(picture.image.width*(iy+1) + ix)*4 + 2] = 0;
                            }
                        }
                    }
                }
            }

            if (swapped)
            {
                swap(select, start_select);
            }

            picture.changed = true;
        }
    }
}

// @EditMask
void change_form()
{
    if (dir2 > 6 && dir2 - dir1 > 6)
        dir1 += 12;

    if (dir1 > 6 && dir1 - dir2 > 6)
        dir2 += 12;

    if (dir2 < dir1 && dir1 - dir2 != 6)
        swap(dir1, dir2);

    int size = dir2 - dir1;
    if (size < 0) size += 12;
    writefln("%s. size %s", mask_i, size);

    if (size >= 2 && size <= 6)
    {
        ushort m = cast(ushort) (size > 2 ? (size-3)*12 + dir1 : 48 + dir1/2);

        masks[mask_i] = m;
        mask_i++;

        ushort g;
        if (mask_i == 1 && m < 48)
        {
            g = cast(ushort) (m + 1);
        }
        else
        {
            ulong form;
            foreach (i, n; masks[0..mask_i])
            {
                writefln("%s %s", i, n);
                form |= (1UL << n);
            }

            // @H6PMask
            foreach (ushort i, f; forms)
            {
                if (f == form)
                    g = i;
            }
        }
        writefln("form %s", g);

        picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 1] = (g >> 8) & 0x03;
        picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 0] = g & 0xFF;
        picture.changed = true;

        if (mask_i < mask_of)
        {
            mode = Mode.MaskStep1;
        }
        else
        {
            mode = Mode.Edit;
        }
    }
    else
    {
        picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 1] = 0;
        picture.mask.pixels[(picture.image.width*select.y + select.x)*4 + 0] = 0;
        picture.changed = true;
        mode = Mode.Edit;
    }

    mask_hint.changed = true;
}

void make_screenshot() {
    SDL_Surface *screenshot;
    screenshot = SDL_CreateRGBSurface(SDL_SWSURFACE,
            screen.w+32*6,
            screen.h,
            32, 0x00FF0000, 0X0000FF00, 0X000000FF, 0XFF000000);
    SDL_RenderReadPixels(renderer, null, SDL_PIXELFORMAT_ARGB8888,
            screenshot.pixels, screenshot.pitch);
    SDL_SaveBMP(screenshot, "screenshot.bmp");
    SDL_FreeSurface(screenshot);
}

// @SDLEvents
void process_events()
{
    /* Our SDL event placeholder. */
    SDL_Event event;
    SDL_Event prev_event;

    /* Grab all the events off the queue. */
    while( SDL_PollEvent( &event ) )
    {
        bool dirs_ready;

        if (event.type == SDL_KEYDOWN)
        {
            /* @GrabWindow
            if (event.key.keysym.scancode == SDL_SCANCODE_TAB &&
                    (modifiers & Modifiers.Left_Alt))
            {
                SDL_SetWindowGrab(window, SDL_FALSE);
            } */

            process_exit_key(event);
            process_cancel_key(event);
            process_save_key(event);

            process_choose_pict_keys(event);

            process_change_view_keys(event);

            process_invert_key(event);
            process_mask_mode_key(event);
            process_edit_extra_color_key(event);

            process_lens_key(event);

            process_color_picker_key(event);
            process_take_color_key(event);

            final switch(mode)
            {
                case Mode.Edit:
                    process_navigation_keys(event);
                    process_choose_color_keys(event);
                    process_down_pen_key(event);
                    break;
                case Mode.MaskStep1:
                case Mode.MaskStep2:
                    process_mask_editor_keys(event, dirs_ready);
                    process_choose_number_of_areas_keys(event);
                    break;
                case Mode.ExtraColor:
                    process_mask_color_chooser_keys(event);
                    break;
                case Mode.ColorPicker:
                    process_color_picker_navigation_keys(event);
                    process_color_picker_value_keys(event);
                    break;
            }

            if (event.key.keysym.scancode == SDL_SCANCODE_PRINTSCREEN)
            {
                make_screenshot();
            }

            // @DrawLine
            if (event.key.keysym.scancode == SDL_SCANCODE_LSHIFT)
            {
                lshift = true;
                start_select = select;
            }
        }
        else if (event.type == SDL_KEYUP)
        {
            process_up_pen_key(event);

            if (mode == Mode.MaskStep1 || mode == Mode.MaskStep2)
            {
                process_mask_editor_up_keys(event, dirs_ready);
            }

            process_draw_line(event);
        }

        if (dirs_ready)
        {
            change_form();
        }

        process_event(event);

        prev_event = event;
    }
}

