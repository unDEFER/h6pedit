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

module h6pedit.reference;

import h6pedit.global_state;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.string;
import std.math;
import std.algorithm;

// @Reference
class Reference
{
    private:
        SDL_Texture* texture;
        int centerRx;
        int centerRy;
        int sizeRw;
        double sizeRh;
        int sizeRz;
        double scale = 1.0;
        int vx = 0;
        int vy = 0;

        int rw, rh;

    public:
        bool lens = true;

        this(string file, int cRx, int cRy, int sRw)
        {
            auto image = IMG_Load(file.toStringz());

            if (image)
            {
                texture = SDL_CreateTextureFromSurface(renderer, image);
                SDL_FreeSurface(image);
            }

            SDL_QueryTexture(texture, null, null, &rw, &rh);

            centerRx = cRx;
            centerRy = cRy;
            sizeRw = sRw;

            sizeRh = 7.0/8.0 * sizeRw;
            sizeRz = cast(int) round(7.0/8.0 * sizeRw * 4.0/3.0);

            scale = min(0.5*screen.w/rw, 1.0*screen.h/rh);
        }

        void draw()
        {
            SDL_Rect src_rect, dst_rect;

            src_rect.x = vx;
            src_rect.y = vy;
            src_rect.w = rw-vx;
            src_rect.h = rh-vy;

            dst_rect.x = screen.w/2;
            dst_rect.y = 0;
            dst_rect.w = cast(int) round((rw-vx)*scale);
            dst_rect.h = cast(int) round((rh-vy)*scale);

            SDL_RenderCopy(renderer, texture, &src_rect, &dst_rect);
        }

        // @Lens
        void draw_cursor()
        {
            int centerPx = centerRx/sizeRw;
            int centerPy = cast(int)(centerRy/sizeRh);

            SDL_Rect src_rect, dst_rect;

            if (lens)
            {
                src_rect.x = cast(int) round((select.x - centerPx + 0.5*(select.y%2) - 0.5*(centerPy%2))*sizeRw + centerRx);
                src_rect.y = cast(int) round((select.y - centerPy - 0.5*(centerPy%2))*sizeRh + centerRy);
                src_rect.w = sizeRw;
                src_rect.h = sizeRz;

                dst_rect.w = 52;
                dst_rect.h = 60;
                dst_rect.x = cast(int) round(screen.w/2 + (src_rect.x - vx)*scale - dst_rect.w/2);
                dst_rect.y = cast(int) round((src_rect.y - vy)*scale - dst_rect.h/2);

                SDL_RenderCopy(renderer, texture, &src_rect, &dst_rect);
                SDL_RenderCopy(renderer, window_texture, null, &dst_rect);
            }
            else
            {
                src_rect.x = cast(int) round((select.x - centerPx + 0.5*(select.y%2) - 0.5*(centerPy%2))*sizeRw + centerRx);
                src_rect.y = cast(int) round((select.y - centerPy - 0.5*(centerPy%2))*sizeRh + centerRy);

                dst_rect.w = cast(int) round(sizeRw*scale);
                dst_rect.h = cast(int) round(sizeRz*scale);
                dst_rect.x = cast(int) round(screen.w/2 + (src_rect.x - vx)*scale);
                dst_rect.y = cast(int) round((src_rect.y - vy)*scale);

                SDL_RenderCopy(renderer, window_texture, null, &dst_rect);
            }
        }
}
