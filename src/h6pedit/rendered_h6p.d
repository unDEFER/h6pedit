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

module h6pedit.rendered_h6p;

import derelict.sdl2.sdl;
import imaged;

import hexpict.hex2pixel;

// @RenderedH6P
class RenderedH6P
{
    int offx, offy;
    int scale = 4;
    SDL_Rect rect;

    bool changed = true;
    SDL_Texture* texture;
    SDL_Surface* surface;
    ubyte[] rendered_data;

    Image image, mask;

    this(Image img, Image msk, int iw, int ih)
    {
        image = img;
        mask = msk;

        this(iw, ih);
    }

    this(int w, int h, int iw, int ih)
    {
        ubyte[] imgdata = new ubyte[w*h*4];
        ubyte[] maskdata = new ubyte[w*h*4];

        image = new Img!(Px.R8G8B8A8)(w, h, imgdata);
        mask = new Img!(Px.R8G8B8A8)(w, h, maskdata);

        this(iw, ih);
    }

    this(int iw, int ih)
    {
        rect.w = iw;
        rect.h = ih;

        rendered_data = new ubyte[iw*ih*4];

        uint rmask, gmask, bmask, amask;
        rmask = 0x000000ff;
        gmask = 0x0000ff00;
        bmask = 0x00ff0000;
        amask = 0xff000000;
        surface = SDL_CreateRGBSurfaceFrom(rendered_data.ptr, iw, ih, 32, iw*4,
                                             rmask, gmask, bmask, amask);
    }

    ~this()
    {
        SDL_DestroyTexture(texture);
    }

    void update(SDL_Renderer* renderer, bool inv = false)
    {
        if (changed)
        {
            if (texture) SDL_DestroyTexture(texture);
            rendered_data[0..$] = 127;

            hex2pixel(image, mask, scale, offx, offy,
                rendered_data, rect.w, rect.h, inv);

            texture = SDL_CreateTextureFromSurface(renderer, surface);

            changed = false;
        }
    }

    void draw(SDL_Renderer* renderer)
    {
        SDL_RenderCopy(renderer, texture, null, &rect);
    }
}
