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
import h6pedit.rendered_h6p;
import h6pedit.brush;
import h6pedit.draw;
import hexpict.h6p;
import hexpict.hyperpixel;
import hexpict.common;
import hexpict.color;
import hexpict.colors;
import hexpict.get_line;

import std.datetime;
import std.algorithm;
import std.stdio;
import std.math;
import std.container: DList;
import std.bitmanip;
import bindbc.sdl;

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

// @Debug
void process_debug_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_D)
    {
        Pixel *p = picture.image.pixel(select.x, select.y);
        if (edited_form < p.forms.length)
        {
            ushort form = p.forms[edited_form].form;
            ubyte rotation = p.forms[edited_form].rotation;

            writefln("%sx%s form %s rotation %s", select.x, select.y, form, rotation);
            writefln("scale %s", scales[scale]);
            if (form > 19*4)
                writefln("form %s", picture.image.forms[form-19*4]);
        }
    }
}

// @Finish
void process_exit_key(SDL_Event event)
{
    if (lctrl && event.key.keysym.scancode == SDL_SCANCODE_Z)
    {
        finish = true;
    }
}

// @ColorPicker
void process_color_picker_key(SDL_Event event)
{
    if (!lctrl && event.key.keysym.scancode == SDL_SCANCODE_C)
    {
        if (mode == Mode.ColorPicker)
        {
            mode = Mode.Edit;
            change_color = 0;
            palette_reinit();
        }
        else
        {
            mode = Mode.ColorPicker;
            mask_hint.changed = true;
            picture.changed = true;

            bool err;
            ubyte[4] pc;
            Color color = pictures[pict].image.cpalette[0][color];
            color_to_u8(&color, &SRGB_SPACE, pc, &err, ErrCorrection.ORDINARY);

            color_gray = min(pc[0], pc[1], pc[2]);
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

                picture.scale = scales[scale];
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
        if (scale < scales.length-1) scale++;
        picture.scale = scales[scale];
        picture.changed = true;

        picture.offx = select.x - screen.w/picture.scale/4;
        picture.offy = cast(int) (select.y - screen.h/(picture.scale*7.0/8.0)/2);
        if (picture.offx < 0) picture.offx = 0;
        if (picture.offy < 0) picture.offy = 0;

        selection_reinit();
        selection.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_S)
    {
        if (scale > 0) scale--;
        picture.scale = scales[scale];
        picture.changed = true;

        selection_reinit();
        selection.changed = true;
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_UP)
    {
        picture.offy--;
        if (picture.offy < 0) picture.offy = 0;
        picture.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_DOWN)
    {
        picture.offy++;
        picture.changed = true;
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_LEFT)
    {
        picture.offx--;
        if (picture.offx < 0) picture.offx = 0;
        picture.changed = true;
    }
    if (event.key.keysym.scancode == SDL_SCANCODE_RIGHT)
    {
        picture.offx++;
        picture.changed = true;
    }
}

// @Pen
void process_down_pen_mouse(SDL_Event event)
{
    if (mouse_left_down || mouse_right_down)
    {
        int x = event.motion.x;
        int y = event.motion.y;

        int hx;
        int hy;

        int pvertex = vertex;
        int phx = select.x;
        int phy = select.y;

        vertex = picture.pixelcoord2hex(x, y, hx, hy);

        select.x = hx;
        select.y = hy;

        Pixel *p = picture.image.pixel(select.x, select.y);

        //if (lshift || change_color.channels[3] == 0.0 ||
          //      color_dist(&change_color, &p.color, ErrCorrection.ORDINARY) < 7.0)
        /+
        {
            change_color = p.color;

            bool yes = false;
            if (phx == hx && phy == hy)
            {
                form_dots ~= cast(ubyte) pvertex;
                form_dots = cast(ubyte) vertex;
                yes = true;
            }
            else
            {
                // @H6PNeighbours
                int[][] neigh = new int[][](6, 2);
                neighbours(phx, phy, neigh);

                foreach (i, n; neigh)
                {
                    if (n[0] == hx && n[1] == hy)
                    {
                        dir2 = cast(byte) vertex;
                        switch (i)
                        {
                            case 0:
                            case 3:
                                dir1 = cast(byte) (16-pvertex)%12;
                                break;
                            case 1:
                            case 4:
                                dir1 = cast(byte) (20-pvertex)%12;
                                break;
                            case 2:
                            case 5:
                                dir1 = cast(byte) (12-pvertex)%12;
                                break;
                            default:
                                assert(0, "Unreachable statement");
                        }
                        yes = true;
                    }
                }
            }

            if (yes)
            {
                int size = dir2 - dir1;
                if (size < 0) size += 12;
                bool invert = (size > 6);

                if (dir2 > 6 && dir2 - dir1 > 6)
                    dir1 += 12;

                if (dir1 > 6 && dir1 - dir2 > 6)
                    dir2 += 12;

                if (dir2 < dir1 && dir1 - dir2 != 6)
                    swap(dir1, dir2);

                size = dir2 - dir1;
                if (size < 0) size += 12;
                //writefln("%s. size %s", mask_i, size);

                if (size >= 2 && size <= 6 && (size > 2 || dir1%2 == 1))
                {
                    ubyte m = cast(ubyte) (size > 2 ? (size-3)*12 + dir1 : 48 + dir1/2);
                    // FIXME MODIFY p.form
                }

                int[][] neigh = new int[][](6, 2);
                neighbours(hx, hy, neigh);
            }

            // @CurrentColor
            /*
            uint ncolor = palette[mouse_right_down ? color2 : color];
            ubyte a = cast(ubyte) ((ncolor >> 24) & 0xFF);
            ubyte r = cast(ubyte) ((ncolor >> 16) & 0xFF);
            ubyte g = cast(ubyte) ((ncolor >> 8) & 0xFF);
            ubyte b = cast(ubyte) (ncolor & 0xFF);
            */

            //Color c = Color([r/255.0, g/255.0, b/255.0, a/255.0], false, &SRGB_SPACE);
            //p.color = c;

            picture.changed = true;
        }
        +/
    }
}

// @Pen
void process_down_pen_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_H)
    {
        pen_down = true;

        Pixel *p = picture.image.pixel(select.x, select.y);

        if (lshift || change_color == p.color)
        {
            change_color = p.color;
            // @CurrentColor
            p.color = color;

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

// @Fill
void process_fill_key(SDL_Event event)
{
    if (lctrl && event.key.keysym.scancode == SDL_SCANCODE_F)
    {
        struct Point
        {
            int x, y;
        }
        auto s = DList!Point(Point(select.x, select.y));

        // @CurrentColor
        ushort c = color;

        while (!s.empty())
        {
            DList!Point sn;
            foreach (point; s)
            {
                int[][] neigh = new int[][](6, 2);
                neighbours(point.x, point.y, neigh);
                foreach (n; neigh)
                {
                    if (n[0] < 0 || n[0] >= picture.image.width) continue;
                    if (n[1] < 0 || n[1] >= picture.image.height) continue;

                    Pixel *p2 = picture.image.pixel(n[0], n[1]);
                    if ( c != p2.color )
                    {
                        p2.color = c;
                        sn.insertBack(Point(n[0], n[1]));
                    }
                }
            }
            s = sn;
        }

        picture.changed = true;
    }
}

// @Erase
void process_down_erase_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_E)
    {
        Pixel *p = picture.image.pixel(select.x, select.y);
        p.forms.length = 0;

        picture.changed = true;

        erase_down = true;
    }
}

// @Erase
void process_up_erase_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_E)
    {
        erase_down = false;
    }
}

// @Rect
void process_down_rect_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_R)
    {
        rect_down = true;
    }
}

// @Rect
void process_up_rect_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_R)
    {
        rect_down = false;
    }
}

// @Buffer
void process_copy_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_O)
    {
        buffer = new RenderedH6P(select.w, select.h, 0, 0, picture.image.space);

        foreach (dy; 0..select.h)
        {
            foreach (dx; 0..select.w)
            {
                Pixel *p = picture.image.pixel(select.x+dx, select.y+dy);
                Pixel *bp = buffer.image.pixel(dx, dy);
                *bp = *p;
            }
        }
    }
}

// @Buffer
void process_insert_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_P)
    {
        foreach (dy; 0.. buffer.image.height)
        {
            foreach (dx; 0..buffer.image.width)
            {
                Pixel *p = buffer.image.pixel(dx, dy);
                Pixel *pp = picture.image.pixel(select.x+dx, select.y+dy);
                *pp = *p;
            }
        }

        picture.changed = true;
        selection.changed = true;

        paste_down = true;
    }
}

// @Buffer
void process_up_insert_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_P)
    {
        paste_down = false;
    }
}

void load_form_dots(bool manual = false)
{
    Pixel *p = picture.image.pixel(select.x, select.y);
    if (!manual)
    {
        if ([select.x, select.y] in edited_forms_by_coords)
        {
            edited_form = edited_forms_by_coords[[select.x, select.y]];
            writefln("%dx%d edited form %d restored", select.x, select.y, edited_form);
        }
        else
        {
            edited_form = cast(ubyte) p.forms.length;
            writefln("%dx%d edited form %d new", select.x, select.y, edited_form);
        }
    }

    form_dots.length = 0;
    if (p.forms.length > edited_form)
    {
        ushort form = p.forms[edited_form].form;
        ubyte rotate = p.forms[edited_form].rotation;

        form_dots = picture.image.get_rotated_form(form, rotate);
        writefln("Loaded %sx%s forms %s, num %s", select.x, select.y, form_dots, form);
    }

    form_changed = false;
}

// @EditMask
void process_mask_mode_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_M)
    {
        if (mode == Mode.Edit)
        {
            mode = Mode.SimpleFormEdit;
            form_dots.length = 0;
            Pixel *p = picture.image.pixel(select.x, select.y);
            edited_form = cast(ubyte) p.forms.length;
            load_form_dots();
            mask_hint.changed = true;
        }
        else if (mode == Mode.SimpleFormEdit)
        {
            first_v.p = 100;
            last_v.p = 100;
            edited_forms_by_coords.clear();
            mode = Mode.ExtendedFormEdit;
            mask2_hint.changed = true;
        }
        else if (mode == Mode.ExtendedFormEdit)
        {
            mode = Mode.SimpleFormEdit;
            mask_hint.changed = true;
        }
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_C)
    {
        if (mode == Mode.ExtendedFormEdit)
        {
            form_dots.length = 0;
        }
    }
}

// @Cancel
void process_cancel_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_ESCAPE)
    {
        mode = Mode.Edit;
        form_dots.length = 0;
    }
}

// @Save
void process_save_key(SDL_Event event)
{
    if (lctrl && event.key.keysym.scancode == SDL_SCANCODE_X)
    {
        h6p_write(picture.image, filename);
    }
}

// @Space
void process_space_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_SPACE)
    {
        if (reference)
        {
            hide_picture = !hide_picture;
            if (hide_reference && hide_picture)
                hide_reference = false;
        }
    }
}

// @Tab
void process_tab_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_TAB)
    {
        if (reference)
        {
            hide_reference = !hide_reference;
            if (hide_reference && hide_picture)
                hide_picture = false;
        }
    }
}

// @ColorPicker
void process_color_picker_navigation_keys(SDL_Event event)
{
    // @H6PNeighbours
    int[][] neigh = new int[][](6, 2);
    neighbours(colors_select.x, colors_select.y, neigh);
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            enum div = 4;
            if (neigh[i][0] >= 0 && neigh[i][0] < 512/div &&
                    neigh[i][1] >= 0 && neigh[i][1] < 512/div)
            {
                colors_select.x = neigh[i][0];
                colors_select.y = neigh[i][1];

                Pixel *p = color_picker.image.pixel(colors_select.x, colors_select.y);

                // @CurrentColor
                picture.image.cpalette[0][color] = color_picker.image.cpalette[0][p.color];

                Color *cc = &picture.image.cpalette[0][color];
                color_convert(cc, picture.image.space, ErrCorrection.ORDINARY);
                foreach(ic, ch; cc.channels)
                {
                    ushort ch16 = cast(ushort) round(min(ch * 65535.0f, 65535.0f));
                    ubyte[2] be16_ch = nativeToBigEndian(ch16);
                    picture.image.palette[0][color*8 + ic*2..color*8 + ic*2 + 2] = be16_ch;
                }

                palette_reinit();
                mask_hint.changed = true;
                picture.changed = true;
            }
        }
    }
}

// @ColorPicker
void process_color_picker_value_keys(SDL_Event event)
{
    if (!lctrl && (event.key.keysym.scancode == SDL_SCANCODE_V || event.key.keysym.scancode == SDL_SCANCODE_M))
    {
        Pixel *p = color_picker.image.pixel(colors_select.x, colors_select.y);

        ubyte[4] col;
        bool err;
        color_to_u8(&color_picker.image.cpalette[0][p.color], &SRGB_SPACE, col, &err, ErrCorrection.ORDINARY);

        short mc = color_gray;

        short nc;
        if (event.key.keysym.scancode == SDL_SCANCODE_M)
        {
            nc = cast(short) (mc + 7);
            if (nc > 255) nc = 255;
        }
        else
        {
            nc = cast(short) (mc - 7);
            if (nc < 0) nc = 0;
        }

        color_gray = cast(byte) nc;

        palette_reinit();

        p = color_picker.image.pixel(colors_select.x, colors_select.y);
        mask_hint.changed = true;
        color_picker.changed = true;
    }
}

// @Selection
void process_navigation_keys(SDL_Event event)
{
    // @H6PNeighbours
    int[][] neigh = new int[][](6, 2);
    if (rect_down)
    {
        neighbours(select.x + select.w - 1, select.y + select.h - 1, neigh);
    }
    else
    {
        neighbours(select.x, select.y, neigh);
    }
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            if (rect_down)
            {
                select.w = neigh[i][0] - select.x + 1;
                select.h = neigh[i][1] - select.y + 1;
                if (select.h % 2 == 0) select.w++;
                if (select.w < 1) select.w = 1;
                if (select.h < 1) select.h = 1;
            }
            else
            {
                select.x = neigh[i][0];
                select.y = neigh[i][1];

                if (select.x < 0) select.x = 0;
                if (select.y < 0) select.y = 0;
                if (select.x >= picture.image.width) select.x = picture.image.width-1;
                if (select.y >= picture.image.height) select.y = picture.image.height-1;
            }

            selection.changed = true;
            if (rect_down)
            {
                selection_reinit();
            }

            Pixel *p = picture.image.pixel(select.x, select.y);

            if (pen_down && !rect_down)
            {
                // @ChangeColor
                if (lshift || change_color == p.color)
                {
                    change_color = p.color;
                    p.color = color;

                    picture.changed = true;
                }
            }

            if (erase_down && !rect_down)
            {
                p.forms.length = 0;
                picture.changed = true;
            }

            if (paste_down)
            {
                foreach (dy; 0.. buffer.image.height)
                {
                    foreach (dx; 0..buffer.image.width)
                    {
                        Pixel *pix = buffer.image.pixel(dx, dy);
                        Pixel *ip = picture.image.pixel(select.x+dx, select.y+dy);
                        *ip = *pix;
                    }
                }

                picture.changed = true;
                selection.changed = true;
            }
        }
    }
}

// @EditMask24
void process_mask_editor_keys24(SDL_Event event)
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

                form_dots ~= (2*(i+pressed_dir) + 22)%24;
                form_changed = true;
                mask_hint.changed = true;

                pressed_dir = -1;
            }
        }
    }

    int[4] keys2 = [SDL_SCANCODE_I, SDL_SCANCODE_M, SDL_SCANCODE_V, SDL_SCANCODE_T];
    byte[4] knum = [2, 3, 5, 6];
    if (pressed_dir != -1)
    {
        foreach (i, k; keys2)
        {
            if (event.key.keysym.scancode == k)
            {
                byte kn = knum[i];
                byte d = (kn > pressed_dir ? 1 : -1);
                if (kn == 6 && pressed_dir < 2) d = -1;

                form_dots ~= cast(ubyte)((4*pressed_dir + d + 22)%24);
                form_changed = true;
                mask_hint.changed = true;

                pressed_dir = -1;
            }
        }
    }
}

void process_mask2_editor_keys(SDL_Event event)
{
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];
    byte[6] dx = [0, 1, 1, 0, 0, 0];
    byte[6] dy = [-2, -1, 1, 2, 1, -1];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            ubyte d;
            uint scalew = scales[scale];
            d = dot_by_line[doty][dotx];

            do
            {
                ubyte dotx_ = cast(ubyte) (dotx + (5-dot_by_line[doty].length)/2);
                doty += dy[i];

                bool mir;
                if (doty >= dot_by_line.length)
                    mir = true;
                else
                {
                    dotx_ += dx[i];
                    if ( abs(dy[i]) == 1 && doty % 2 == 1 )
                    {
                        dotx_--;
                    }

                    dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);

                    if (dotx >= dot_by_line[doty].length)
                        mir = true;
                }

                if (mir)
                {
                    ubyte side = d/4;
                    ubyte nons = d%4;
                    if (nons == 0 && (i == side || (i+1)%6 == side))
                    {
                        side = (side + 5)%6;
                        nons = 4;
                    }

                    ubyte nn = (side+1)%6;
                    side = (side + 3)%6;
                    nons = cast(ubyte)(4 - nons);

                    if (nons == 4)
                    {
                        side = (side + 1)%6;
                        nons = 0;
                    }

                    d = cast(ubyte) (side*4 + nons);
                    dotx = dot_to_coords[d][0];
                    doty = dot_to_coords[d][1];

                    // @H6PNeighbours
                    int[][] neigh = new int[][](6, 2);
                    neighbours(select.x, select.y, neigh);
                    if (neigh[nn][0] >= 0 && neigh[nn][0] < picture.image.width &&
                        neigh[nn][1] >= 0 && neigh[nn][1] < picture.image.height)
                    {
                        select.x = neigh[nn][0];
                        select.y = neigh[nn][1];

                        Pixel *p = picture.image.pixel(select.x, select.y);

                        if ([select.x, select.y] in edited_forms_by_coords)
                        {
                            edited_form = edited_forms_by_coords[[select.x, select.y]];
                            writefln("%dx%d edited form %d restored", select.x, select.y, edited_form);
                        }
                        else
                        {
                            edited_form = cast(ubyte) p.forms.length;
                            writefln("%dx%d edited form %d new", select.x, select.y, edited_form);
                        }
                    }

                    dotx_ = cast(ubyte) (dotx + (5-dot_by_line[doty].length)/2);
                    doty += dy[i];
                    dotx_ += dx[i];
                    if ( abs(dy[i]) == 1 && doty % 2 == 1 )
                    {
                        dotx_--;
                    }
                    dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);

                    mode = Mode.ExtendedFormEdit;
                    mask2_hint.changed = true;
                    load_form_dots();
                }
                else
                {
                    d = dot_by_line[doty][dotx];
                }
            }
            while ( !(d<24 && (d%2 == 0 || scalew >= 32) || scalew >= 64) );
        }
    }

    bool loop;
    Vertex ov = Vertex(select.x, select.y, dot_by_line[doty][dotx]);
    
    if (event.key.keysym.scancode == SDL_SCANCODE_K)
    {
        writefln("START PAINT BRUSH");
        first_v.p = 100;
        last_v.p = 100;
        edited_forms_by_coords.clear();

        Pixel *p = picture.image.pixel(select.x, select.y);
        edited_form = cast(ubyte) p.forms.length;
        form_dots.length = 0;

        float merr = apply_brush(brush, true) < 0.01;
        if ( merr < 0.01 )
        {
            apply_brush(brush);
        }

        join_forms();

        writefln("%sx%s MERR = %s", select.x, select.y, merr);
        writefln("END PAINT BRUSH");
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_L)
    {
        if (first_v.p <= 60 && (select.x != first_v.x || select.y != first_v.y))
        {
            change_form24();

            select.x = first_v.x;
            select.y = first_v.y;
            dotx = dot_to_coords[first_v.p][0];
            doty = dot_to_coords[first_v.p][1];
            loop = true;

            load_form_dots();
        }
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_H || loop)
    {
        Vertex v = Vertex(select.x, select.y, dot_by_line[doty][dotx]);
        paint(v);
    }

    if (loop && !lshift && (select.x != ov.x || select.y != ov.y))
    {
        change_form24();

        select.x = ov.x;
        select.y = ov.y;
        dotx = dot_to_coords[ov.p][0];
        doty = dot_to_coords[ov.p][1];

        load_form_dots();
    }

    mask2_hint.changed = true;
}

float paint(Vertex v, bool preview = false)
{
    float max_err = 0.0f;

    if (last_v.p <= 60 && (v.x != last_v.x || v.y != last_v.y))
    {
        change_form24();

        if (!preview) writefln("Return to last_v %sx%s %s", last_v.x, last_v.y, last_v.p);
        select.x = last_v.x;
        select.y = last_v.y;
        dotx = dot_to_coords[last_v.p][0];
        doty = dot_to_coords[last_v.p][1];
        if (!preview) writefln("D1 dotx = %s, doty = %s", dotx, doty);

        load_form_dots();

        Vertex[] line = get_line(last_v, v, max_err);
        if (preview) return max_err;

        foreach(v2; line[1..$-1])
        {
            if (select.x != v2.x || select.y != v2.y)
            {
                change_form24();

                select.x = v2.x;
                select.y = v2.y;
                dotx = dot_to_coords[v2.p][0];
                doty = dot_to_coords[v2.p][1];
                writefln("D2 dotx = %s, doty = %s", dotx, doty);

                load_form_dots();

                if (form_dots.length > 0 && form_dots[$-1] < 24 && v2.p < 24)
                {
                    ubyte fe = v2.p;
                    ubyte f = form_dots[$-1];
                    if (lshift)
                        f = (f+1)%24;
                    else
                        f = (f+23)%24;

                    while (f != fe)
                    {
                        if (f%4 == 0)
                        {
                            form_dots ~= f;
                            writefln("ADD f %s", f);
                            form_changed = true;
                        }
                        if (lshift)
                            f = (f+1)%24;
                        else
                            f = (f+23)%24;
                    }
                }
            }

            form_dots ~= v2.p;
            form_changed = true;
            writefln("%sx%s Add2 %s", v2.x, v2.y, v2.p);
        }

        if (select.x != v.x || select.y != v.y)
        {
            change_form24();

            select.x = v.x;
            select.y = v.y;
            writefln("D3 dotx = %s, doty = %s", dotx, doty);

            load_form_dots();

            if (form_dots.length > 0 && form_dots[$-1] < 24 && v.p < 24)
            {
                ubyte fe = v.p;
                ubyte f = form_dots[$-1];
                if (lshift)
                    f = (f+1)%24;
                else
                    f = (f+23)%24;

                while (f != fe)
                {
                    if (f%4 == 0)
                    {
                        form_dots ~= f;
                        form_changed = true;
                    }
                    if (lshift)
                        f = (f+1)%24;
                    else
                        f = (f+23)%24;
                }
            }
        }
        else
        {
            dotx = dot_to_coords[v.p][0];
            doty = dot_to_coords[v.p][1];
            writefln("D4 dotx = %s, doty = %s", dotx, doty);
        }
    }

    if (form_dots.length == 0 || form_dots[0] != v.p)
    {
        writefln("%sx%s Add %s (First %s)", v.x, v.y, v.p, form_dots.length == 0 ? 100 : form_dots[0]);
        form_dots ~= v.p;
        form_changed = true;
    }
    last_v = v;

    if (first_v.p == 100)
        first_v = v;

    return max_err;
}

float apply_brush(in Brush b, bool preview = false)
{
    Vertex[] vertices;

    float max_err = 0.0f;

    Vertex v = Vertex(select.x, select.y, dot_by_line[doty][dotx]);
    Vertex sv = v;
    vertices ~= v;
    writefln("dotx = %s, doty = %s", dotx, doty);

    for (size_t i = 0; i < b.form.length-1; i++)
    {
        uint[2] gc = v.to_global();
        uint[2][] gvertices;
        gvertices ~= gc;

        gc[0] += b.form[i].dx;
        gc[1] += b.form[i].dy;

        gvertices ~= gc;

        gc[0] += b.form[(i+1)%$].dx;
        gc[1] += b.form[(i+1)%$].dy;

        gvertices ~= gc;

        Vertex[] vs = Vertex.from_global(gvertices);
        vertices ~= vs[0];

        v = vs[0];
    }

    ptrdiff_t off;

    for(off = 0; off < vertices.length; off++)
    {
        v = vertices[off];
        size_t pi = (off - 1 + vertices.length)%vertices.length;
        Vertex pv = vertices[pi];

        writefln("Off %s, v = %s, pv = %s", off, v, pv);
        if (pv.x != v.x || pv.y != v.y)
        {
            break;
        }
    }

    writefln("Offset is %s, vertices.length = %s", off, vertices.length);

    for(size_t i = 0; i <= vertices.length; i++)
    {
        change_form24();

        v = vertices[(off + i)%$];

        select.x = v.x;
        select.y = v.y;

        dotx = dot_to_coords[v.p][0];
        doty = dot_to_coords[v.p][1];

        load_form_dots();

        float merr = paint(v, preview);
        if (merr > max_err) max_err = merr;
    }

    change_form24();

    select.x = sv.x;
    select.y = sv.y;

    dotx = dot_to_coords[sv.p][0];
    doty = dot_to_coords[sv.p][1];

    load_form_dots();

    return max_err;
}

void join_forms()
{
    foreach (pt, f; edited_forms_by_coords)
    {
        Pixel *p = picture.image.pixel(pt[0], pt[1]);

        auto color = p.forms[f].extra_color;
        foreach (e, form; p.forms)
        {
            if (e != f && form.extra_color == color)
            {
                writefln("Join forms %s and %s in point %s", e, f, pt);

                ushort form1 = p.forms[f].form;
                ubyte rotate1 = p.forms[f].rotation;
                ubyte[] dots1 = picture.image.get_rotated_form(form1, rotate1);

                ushort form2 = p.forms[e].form;
                ubyte rotate2 = p.forms[e].rotation;
                ubyte[] dots2 = picture.image.get_rotated_form(form2, rotate2);

                writefln("dots %s and %s", dots1, dots2);

                size_t[2] ii = [0, 0];
                ubyte dotsnum = 0;
                size_t dot = 0;
                size_t ioff = 0;
                bool iok;

                ubyte[] new_dots;
                bool bad;

                for(size_t i11 = 0; dotsnum != 0 || i11 < ioff + dots1.length; i11++)
                {
                    ubyte d11 = dots1[i11%$];
                    ubyte d12 = dots1[(i11+1)%$];

                    int[2] f11 = Vertex(1, 1, d11).to_flat();
                    int[2] f12 = Vertex(1, 1, d12).to_flat();

                    int[2] intersection;
                    size_t iint;
                    int num_intersections;
                    int num_bias_intersections;

                    for(size_t i21 = 0; i21 < dots2.length; i21++)
                    {
                        ubyte d21 = dots2[i21%$];
                        ubyte d22 = dots2[(i21+1)%$];

                        int[2] f21 = Vertex(1, 1, d21).to_flat();
                        int[2] f22 = Vertex(1, 1, d22).to_flat();

                        int[2] inter;
                        byte r = line_segments_intersection([f11, f12], [f21, f22], inter);

                        if (r == 1)
                        {
                            if ( num_intersections == 0 || between2(inter, f11, intersection) )
                            {
                                iint = i21;
                                intersection[0..2] = inter[0..2];
                            }

                            num_intersections++;
                            num_bias_intersections++;
                        }
                        else if (r == -1)
                        {
                            num_bias_intersections++;
                        }
                    }

                    writefln("S %s-%s, num_intersections %s, num_bias_intersections %s", d11, d12, num_intersections, num_bias_intersections);

                    if (num_bias_intersections%2 == 0)
                    {
                        iok = true;
                        new_dots ~= d11;
                    }
                    else if (!iok)
                        ioff++;

                    if (num_intersections > 0)
                    {
                        iok = true;
                        Vertex[] iv = Vertex.from_flat([intersection]);
                        if (iv.length > 0)
                        {
                            Vertex nv;
                            bool found;
                            foreach (v; iv)
                            {
                                if (v.x == 1 && v.y == 1)
                                {
                                    nv = v;
                                    writefln("Intersection %s-%s & %s is %s", d11, d12, dots2, v);
                                    found = true;
                                    break;
                                }
                            }
                            assert(found, "Vertex(1, 1) not found in intersection result");

                            new_dots ~= nv.p;
                        }
                        else
                            writefln("Intersection %s-%s & %s is %s [NO POINT IN THE GRID]", d11, d12, dots2, intersection);

                        //assert(ii[dotsnum] != (i11+1)%dots1.length, "Oops!");
                        ii[dotsnum] = i11+1;
                        i11 = iint;
                        dotsnum = (dotsnum+1)%2;
                        swap(dots1, dots2);
                        writefln("SWAP ii %s, dotsnum %s", ii, dotsnum);
                    }
                }

                writefln("new_dots %s", new_dots);
                form_dots = new_dots;
                edited_form = cast(ubyte) e;
                p.forms = p.forms[0..f] ~ p.forms[f+1..$];

                change_form24();

                break;
            }
        }
    }
}

// @EditMask24
void process_mask_editor_up_keys24(SDL_Event event)
{
    int[6] keys = [SDL_SCANCODE_Y, SDL_SCANCODE_U, SDL_SCANCODE_J, SDL_SCANCODE_N, SDL_SCANCODE_B, SDL_SCANCODE_G];

    foreach (i, k; keys)
    {
        if (event.key.keysym.scancode == k)
        {
            if (pressed_dir == i)
            {
                pressed_dir = -1;

                form_dots ~= (i*4 + 22)%24;
                form_changed = true;
            }
        }
    }
}

// @TakeColor
void process_take_color_key(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_T)
    {
        Pixel *p = picture.image.pixel(select.x, select.y);

        color = p.color;
        palette_reinit();
        change_color = 0;
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
            if (lshift)
            {
                color2 = cast(ushort) (palette_offset + i);
            }
            else
            {
                color = cast(ushort) (palette_offset + i);
            }
            color_picker.changed = true;

            if (picture.image.cpalette[0].length < max(color, color2)+1)
            {
                Color nc = Color([0.0f, 0.0f, 0.0f, 0.0f], false, picture.image.space);
                size_t from = picture.image.cpalette[0].length;
                picture.image.cpalette[0].length = max(color, color2)+1;
                picture.image.palette[0].length = picture.image.cpalette[0].length*8;

                foreach (ref col; picture.image.cpalette[0][from..$])
                {
                    col = nc;
                }
            }
        }
    }

    if (event.key.keysym.scancode == SDL_SCANCODE_GRAVE)
    {
        palette_offset += 12;
        if (palette_offset > picture.image.cpalette[0].length)
        {
            palette_offset = 0;
        }

        palette_reinit();
    }
}

// @EditMask24
void process_choose_edited_form(SDL_Event event)
{
    int[7] pkeys = [SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4,
                    SDL_SCANCODE_5, SDL_SCANCODE_6, SDL_SCANCODE_7];

    foreach (i, k; pkeys)
    {
        if (event.key.keysym.scancode == k)
        {
            edited_form = cast(ubyte) i;
            writefln("edited_form = %s", edited_form);
            load_form_dots(true);
        }
    }
}

// @EditMask24
void process_invert_form(SDL_Event event)
{
    if (event.key.keysym.scancode == SDL_SCANCODE_I)
    {
        form_dots.reverse();
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
            /*
            uint ncolor = palette[color];
            ubyte a = cast(ubyte) ((ncolor >> 24) & 0xFF);
            ubyte r = cast(ubyte) ((ncolor >> 16) & 0xFF);
            ubyte g = cast(ubyte) ((ncolor >> 8) & 0xFF);
            ubyte b = cast(ubyte) (ncolor & 0xFF);
            */

            double x, y;

            double angle = atan2(dy*sqrt(3.0)/2.0, dx) * 180.0 / PI;
            //writefln("angle = %s", angle);
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
                    //writefln("%sx%s", x, y);

                    int iy = cast(int) round(y);
                    int ix = cast(int) round(x);
                    double px = x;
                    if (iy % 2 == 1)
                    {
                        px -= 0.5;
                        ix = cast(int) round(px);
                    }

                    /*
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
                    */
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

                    /*
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
                    */
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

// @EditMask24
void change_form24()
{
    if (!form_changed) return;

    Pixel *p = picture.image.pixel(select.x, select.y);

    ubyte[] dform = form_dots.dup();
    //writefln("dform = %s", dform);
    ubyte rotate = 0;
    /*auto r = normalize_form(dform);
    dform = r.form;
    rotate = r.rot;*/

    if (dform.length == 2 && dform[0] < 24 && dform[1] < 24)
    {
        rotate = dform[0]/4;
        dform[0] %= 4;
        dform[1] = cast(ubyte) ((dform[1] + 24 - rotate*4)%24);

        if (dform[1] >= 5)
        {
            if (p.forms.length < edited_form + 1) p.forms.length = edited_form + 1;
            if (p.forms[edited_form].form >= 19*4)
            {
                ushort form = p.forms[edited_form].form;
                picture.image.forms[form - 19*4].used--;
            }
            p.forms[edited_form].extra_color = color;
            p.forms[edited_form].form = cast(ushort) (1 + dform[0]*19 + (dform[1] - 5));
            p.forms[edited_form].rotation = rotate;
            writefln("dform = %s, form = %s, rotate = %s", dform, p.forms[edited_form].form, rotate);

            picture.changed = true;
            selection.changed = true;
        }
    }
    else if (dform.length <= 12)
    {
        ubyte[12] f12;
        foreach(i, f; dform)
        {
            f12[i] = cast(ubyte)(f+1);
        }

        if (p.forms.length < edited_form + 1)
        {
            p.forms.length = edited_form + 1;
            ushort form = p.forms[edited_form].form = picture.image.get_form_num(f12);
            picture.image.forms[form - 19*4].used++;
        }
        else
        {
            ushort form = p.forms[edited_form].form;
            if (form < 19*4)
            {
                form = p.forms[edited_form].form = picture.image.get_form_num(f12);
                picture.image.forms[form - 19*4].used++;
            }
            else if (picture.image.forms[form - 19*4].used == 1)
            {
                picture.image.formsmap.remove(picture.image.forms[form - 19*4].dots);
                if (f12 !in picture.image.formsmap)
                {
                    picture.image.formsmap[f12] = cast(ushort)(form - 19*4);
                    picture.image.forms[form - 19*4].dots = f12;
                    picture.image.forms[form - 19*4].hp = (BitArray*[6]).init;
                }
                else
                {
                    picture.image.forms[form - 19*4].used--;
                    form = p.forms[edited_form].form = picture.image.get_form_num(f12);
                    picture.image.forms[form - 19*4].used++;
                }
            }
            else
            {
                picture.image.forms[form - 19*4].used--;
                form = p.forms[edited_form].form = picture.image.get_form_num(f12);
                picture.image.forms[form - 19*4].used++;
            }
        }

        p.forms[edited_form].extra_color = color;
        p.forms[edited_form].rotation = rotate;
        writefln("%sx%s dform = %s, form = %s, rotate = %s, used = %s", select.x, select.y, dform, p.forms[edited_form].form, rotate, picture.image.forms[p.forms[edited_form].form - 19*4].used);

        picture.changed = true;
        selection.changed = true;
    }

    edited_forms_by_coords[[select.x, select.y]] = edited_form;
    writefln("Save %dx%d edited form %d", select.x, select.y, edited_form);

    mask_hint.changed = true;
    form_changed = false;
}

void make_screenshot() {
    SDL_Surface *screenshot;
    screenshot = SDL_CreateRGBSurface(SDL_SWSURFACE,
            screen.w,
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
        if (event.type == SDL_KEYDOWN)
        {
            /* @GrabWindow
            if (event.key.keysym.scancode == SDL_SCANCODE_TAB &&
                    (modifiers & Modifiers.Left_Alt))
            {
                SDL_SetWindowGrab(window, SDL_FALSE);
            } */

            process_debug_key(event);
            process_exit_key(event);
            process_cancel_key(event);
            process_save_key(event);
            process_space_key(event);
            process_tab_key(event);

            process_choose_pict_keys(event);

            process_change_view_keys(event);

            process_copy_key(event);
            process_insert_key(event);
            process_mask_mode_key(event);

            final switch(mode)
            {
                case Mode.Edit:
                    process_color_picker_key(event);
                    process_take_color_key(event);
                    process_fill_key(event);

                    process_navigation_keys(event);
                    process_choose_color_keys(event);
                    process_down_pen_key(event);
                    process_down_erase_key(event);
                    process_down_rect_key(event);
                    break;
                case Mode.SimpleFormEdit:
                    process_mask_editor_keys24(event);
                    process_choose_edited_form(event);
                    break;
                case Mode.ExtendedFormEdit:
                    process_mask2_editor_keys(event);
                    process_choose_edited_form(event);
                    process_invert_form(event);
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

            if (event.key.keysym.scancode == SDL_SCANCODE_RSHIFT)
            {
                rshift = true;
            }

            if (event.key.keysym.scancode == SDL_SCANCODE_LCTRL)
            {
                lctrl = true;
            }
        }
        else if (event.type == SDL_KEYUP)
        {
            process_up_pen_key(event);
            process_up_erase_key(event);
            process_up_rect_key(event);
            process_up_insert_key(event);

            if (mode == Mode.SimpleFormEdit)
            {
                process_mask_editor_up_keys24(event);
            }

            //process_draw_line(event);

            if (event.key.keysym.scancode == SDL_SCANCODE_LSHIFT)
            {
                lshift = false;
            }

            if (event.key.keysym.scancode == SDL_SCANCODE_RSHIFT)
            {
                rshift = false;
            }

            if (event.key.keysym.scancode == SDL_SCANCODE_LCTRL)
            {
                lctrl = false;
            }
        }
        /+else if (event.type == SDL_MOUSEMOTION)
        {
            process_down_pen_mouse(event);
        }
        else if (event.type == SDL_MOUSEBUTTONDOWN)
        {
            if (event.button.button == SDL_BUTTON_LEFT)
            {
                mouse_left_down = true;
                process_down_pen_mouse(event);
            }
            else if (event.button.button == SDL_BUTTON_RIGHT)
            {
                mouse_right_down = true;
                process_down_pen_mouse(event);
            }
        }
        else if (event.type == SDL_MOUSEBUTTONUP)
        {
            if (event.button.button == SDL_BUTTON_LEFT)
            {
                mouse_left_down = false;
            }
            else if (event.button.button == SDL_BUTTON_RIGHT)
            {
                mouse_right_down = false;
            }
        }+/

        if (form_dots.length > 0)
        {
            change_form24();
        }

        process_event(event);

        prev_event = event;
    }
}

