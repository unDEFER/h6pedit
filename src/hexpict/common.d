module hexpict.common;
import bindbc.sdl;

void SdlGetPixel(SDL_Surface *image, int x, int y, out ubyte r, out ubyte g, out ubyte b, out ubyte a)
{
    uint pixel_value;
    ubyte *pixel = cast(ubyte*) (image.pixels + y * image.pitch + x * image.format.BytesPerPixel);
    switch(image.format.BytesPerPixel) {
        case 1:
            pixel_value = *cast(ubyte *)pixel;
            break;
        case 2:
            pixel_value = *cast(ushort *)pixel;
            break;
        case 3:
            pixel_value = *cast(uint *)pixel & (~image.format.Amask);
            break;
        case 4:
            pixel_value = *cast(uint *)pixel;
            break;
        default:
            assert(0);
    }
    SDL_GetRGBA(pixel_value,image.format,&r,&g,&b,&a);
}
