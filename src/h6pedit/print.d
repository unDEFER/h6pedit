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

module h6pedit.print;

import h6pedit.global_state;
import derelict.sdl2.sdl;
import std.stdio;
import std.algorithm;
import imaged;

// @Font
void print_chr(wchar chr, int x, int y, Pixel color = Pixel(255, 255, 255, 255))
{
    uint code = cast(uint) chr;

    assert(code >= 32);
    if (code > 127)
    {
        string cp1251 = "        Ё       "~
                        "        ё       "~
                        "АБВГДЕЖЗИЙКЛМНОП"~
                        "РСТУФХЦЧШЩЪЫЬЭЮЯ"~
                        "абвгдежзийклмноп"~
                        "рстуфхцчшщъыьэюя";
        auto c = countUntil(cp1251, chr);

        assert(c >= 0);
        code = cast(uint) (128 + c);
    }

    ubyte symbol = cast(ubyte) (code - 32);
    ubyte col = symbol%16;
    ubyte row = symbol/16;

    SDL_Rect srcrect, dstrect;

    srcrect.w = 24;
    srcrect.h = 35;

    srcrect.x = col * srcrect.w;
    srcrect.y = row * srcrect.h;

    dstrect.x = x*4;
    dstrect.y = cast(int) (y*3.5);

    dstrect.w = srcrect.w;
    dstrect.h = srcrect.h;

    SDL_SetTextureColorMod(font, cast(ubyte) color.r, cast(ubyte) color.g, cast(ubyte) color.b);
    //writefln("%s from %s at %s", chr, srcrect, dstrect);
    SDL_RenderCopy(renderer, font, &srcrect, &dstrect);
}

void print(string text, int x, int y, Pixel color = Pixel(255, 255, 255, 255))
{
    foreach(wchar chr; text)
    {
        print_chr(chr, x, y, color);
        x += 6;
    }
}
