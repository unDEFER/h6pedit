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

module h6pedit.global_state;

import std.stdio;
import std.string;
import std.conv;
import std.datetime;
import std.math;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import imaged;

import h6pedit.reference;
import h6pedit.rendered_h6p;

import hexpict.h6p;
import hexpict.hex2pixel;

// @Scales
int[] scales = [3, 4, 8, 10, 16, 18, 20, 24, 30, 32];

// @Modes
enum Mode
{
    Edit = 0,
    MaskStep1,
    MaskStep2,
    ExtraColor,
    ColorPicker
}

// @GlobalState
package
{
    SDL_Window* window;
    SDL_Renderer* renderer;

    bool finish = false;

    // @FPSStabilizer
    uint frame; //Frame which renders
    uint time; //Time from start of program in frames
    uint fps_frames;
    uint fps_time;

    bool window_shown;
    Mode mode;
    bool lshift;

    bool pen_down;
    // @ChangeColor
    Pixel change_color;

    // @CurrentColor
    byte color;

    // @ScreenSize
    SDL_Rect screen;

    // @Pictures
    RenderedH6P[] pictures;
    int pict;

    RenderedH6P picture()
    {
        return pictures[pict];
    }

    // @Selection
    RenderedH6P selection;
    // @MaskHint
    RenderedH6P mask_hint;
    // @ColorPicker
    RenderedH6P color_picker;

    // @Reference
    private Reference[] references;
    Reference reference()
    {
        return references[pict];
    }

    // @Save
    private string[] filenames;
    string filename()
    {
        return filenames[pict];
    }

    // @HexWindow
    SDL_Texture* window_texture;
    
    // @EditMask
    byte pressed_dir = -1;
    byte dir1, dir2;
    byte mask_of, mask_i;
    ushort[4] masks;

    // @Selection
    SDL_Rect select;
    // @DrawLine
    SDL_Rect start_select;
    SDL_Rect colors_select;

    // @Palette
    uint[12] palette = [
        0xFFFF0000,
        0xFFFF7F00,
        0xFFFFFF00,
        0xFF00FF00,
        0xFF00FF7F,
        0xFF00FFFF,
        0xFF0000FF,
        0xFF7F00FF,
        0xFFFF00FF,
        0xFF000000,
        0xFF808080,
        0xFFFFFFFF
    ];
    SDL_Texture*[12] palette_textures;

    // @Font
    SDL_Texture* font;

    // @Scales
    int scale = 1;

    /* @Modifiers
    ushort modifiers;
    @property bool ctrl() { return (modifiers & (Modifiers.Left_Ctrl | Modifiers.Right_Ctrl)) != 0; }
    @property bool shift() { return (modifiers & (Modifiers.Left_Shift | Modifiers.Right_Shift)) != 0; }
    @property bool alt() { return (modifiers & (Modifiers.Left_Alt)) != 0; }
    @property bool alt_gr() { return (modifiers & (Modifiers.Right_Alt)) != 0; }
    */

    // @Selection
    void selection_reinit()
    {
        int iw = scales[scale];
        int ih = cast(int) round(iw * 2.0 / sqrt(3.0));

        selection = new RenderedH6P(iw, ih);
    }

    // @Palette
    void palette_reinit()
    {
         SDL_Surface* surface = SDL_CreateRGBSurface(0,
                1,
                1,
                32, 0x00FF0000, 0X0000FF00, 0X000000FF, 0XFF000000);

         foreach (i, p; palette)
         {
            (cast(uint*) surface.pixels)[0] = p;
            if (palette_textures[i]) SDL_DestroyTexture(palette_textures[i]);
            palette_textures[i] = SDL_CreateTextureFromSurface(renderer, surface);
         }

        SDL_FreeSurface(surface);
    }
}

// @PictureWithReference
void open_picture(string file, string reference = null, int cRx=0, int cRy=0, int sRw=10)
{
    Image img, msk;
    read_h6p(file, img, msk);
    pictures ~= new RenderedH6P(img, msk, screen.w, screen.h);
    filenames ~= file;

    if (reference)
    {
         references ~= new Reference(reference, cRx, cRy, sRw);
    }
    else references ~= null;
}

// @PictureWithReference
void new_picture(int w, int h, string file, string reference = null, int cRx=0, int cRy=0, int sRw=10)
{
    Image img, msk;
    ubyte[] imgdata = new ubyte[w*h*4];
    ubyte[] maskdata = new ubyte[w*h*4];
    img = new Img!(Px.R8G8B8A8)(w, h, imgdata);
    msk = new Img!(Px.R8G8B8A8)(w, h, maskdata);

    pictures ~= new RenderedH6P(img, msk, screen.w, screen.h);
    filenames ~= file;

    if (reference)
    {
         references ~= new Reference(reference, cRx, cRy, sRw);
    }
    else references ~= null;
}

private
{
    // @SDLWindow
    void createWindow(size_t display = 0)
    {
        //writefln("MainTid=%s", thisTid);
        int displays = SDL_GetNumVideoDisplays();

        int x = SDL_WINDOWPOS_UNDEFINED;
        int y = SDL_WINDOWPOS_UNDEFINED;

        if (display > 0 && display < displays)
        {
            SDL_Rect displayBounds;
            auto r = SDL_GetDisplayBounds(cast(int) display, &displayBounds);
            if (r != 0)
            {
                writefln("Error SDL_GetDisplayBounds display %d: %s", display, SDL_GetError().fromStringz());
            }
            else
            {
                x = displayBounds.x;
                y = displayBounds.y;
            }
        }

        //The window we'll be rendering to
        window = SDL_CreateWindow(
            "h6pedit",                         // window title
            x,                                 // initial x position
            y,                                 // initial y position
            0,                                 // width, in pixels
            0,                                 // height, in pixels
            SDL_WINDOW_FULLSCREEN_DESKTOP |
            SDL_WINDOW_RESIZABLE               // flags
        );
        if( window == null )
        {
            throw new Exception(format("Error while create window: %s",
                    SDL_GetError().to!string()));
        }
    }

    // @SDLRenderer
    void createRenderer()
    {
        /* To render we need only renderer (which connected to window) and
           surfaces to draw it */
        renderer = SDL_CreateRenderer(
                window,
                -1,
                SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE
        );
        if (!renderer)
        {
            writefln("Error while create accelerated renderer: %s",
                    SDL_GetError().to!string());
            renderer = SDL_CreateRenderer(
                    window,
                    -1,
                    SDL_RENDERER_TARGETTEXTURE
            );
        }
        if (!renderer)
        {
            throw new Exception(format("Error while create renderer: %s",
                    SDL_GetError().to!string()));
        }

        SDL_RenderClear(renderer);

        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

        int r = SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        if (r < 0)
        {
            throw new Exception(
                    format("Error while set render draw blend mode: %s",
                    SDL_GetError().to!string()));
        }

        SDL_bool res = SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        if (!res)
        {
            throw new Exception(
                    format("Can't set filter mode"));
        }
    }

    // @MaskHint
    void mask_init()
    {
        int w = 4;
        int h = 3;

        int hw = 36;
        int hh = cast(int) round(hw * 2.0 / sqrt(3.0));

        int iw = w*hw;
        int ih = h*hh;

        mask_hint = new RenderedH6P(w, h, iw, ih);
        mask_hint.scale = hw;
    }

    // @ColorPicker
    void colors_init()
    {
        enum div = 4;
        int w = 512/div;
        int h = 512/div;

        int iw = w*4;
        int ih = h*7/2;

        color_picker = new RenderedH6P(w, h, iw, ih);

        colors_select.x = w/2;
        colors_select.y = h/2;
        colors_select.w = 4;
        colors_select.h = 4;
    }

    // @HexWindow
    void hexwindow_init()
    {
        SDL_Surface* image = IMG_Load("hex_window.png".ptr);

        if (image)
        {
            window_texture = SDL_CreateTextureFromSurface(renderer, image);
            SDL_FreeSurface(image);
        }
    }

    // @Font
    void createTextures()
    {
        Image image, mask;
        read_h6p("fonts/cp1251_6x10.h6p", image, mask);

        int sw = image.width*4;
        int sh = cast(int) (image.height*3.5);
        ubyte[] fontdata = new ubyte[sw*sh*4];

        hex2pixel(image, mask, 4, 0, 0,
            fontdata, sw, sh);

        uint rmask, gmask, bmask, amask;
        rmask = 0x000000ff;
        gmask = 0x0000ff00;
        bmask = 0x00ff0000;
        amask = 0xff000000;
        auto surface = SDL_CreateRGBSurfaceFrom(fontdata.ptr, sw, sh, 32, sw*4,
                                             rmask, gmask, bmask, amask);

        if (font) SDL_DestroyTexture(font);
        font = SDL_CreateTextureFromSurface(renderer, surface);
    }

    // @SDLInit
    void initSDL(size_t display = 0)
    {
        DerelictSDL2.load();

        if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) < 0 )
        {
            throw new Exception(format("Error while SDL initializing: %s",
                    SDL_GetError().to!string() ));
        }

        createWindow(display);

        createRenderer();

        SDL_GetWindowSize(window, &screen.w, &screen.h);

        createTextures();

        selection_reinit();
        palette_reinit();
        mask_init();
        colors_init();
        hexwindow_init();

        /*if( !texture )
        {
            throw new Exception(format("Error while creating surf_texture: %s",
                    SDL_GetError().to!string() ));
        }*/
    }

    // @SDLDeinit
    void deInitSDL()
    {
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
    }

    // @SDLImageInit
    void initSDLImage()
    {
        DerelictSDL2Image.load();

        auto flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
        int initted = IMG_Init(flags);
        if((initted&flags) != flags) {
            if (!(IMG_INIT_JPG & initted))
                writefln("IMG_Init: Failed to init required jpg support!");
            if (!(IMG_INIT_PNG & initted))
                writefln("IMG_Init: Failed to init required png support!");
            if (!(IMG_INIT_TIF & initted))
                writefln("IMG_Init: Failed to init required tif support!");
            throw new Exception(format("IMG_Init: %s\n",
                        IMG_GetError().to!string()));
        }
    }

    void initAllSDLLibs(size_t display = 0)
    {
        initSDLImage();
        //initSDLMixer();
        initSDL(display);
        //initSDLTTF();
    }

    void deInitAllSDLLibs()
    {
        //Mix_CloseAudio();
        //Mix_Quit();
        IMG_Quit();
        deInitSDL();
    }

    static this()
    {
        //start_cwd = getcwd();
        initAllSDLLibs();
    }

    static ~this()
    {
        deInitAllSDLLibs();
    }
}

/* @Modifiers
enum Modifiers
{
    Left_Ctrl  = 0x0001,
    Right_Ctrl = 0x0002,
    Left_Shift = 0x0004,
    Right_Shift= 0x0008,
    Left_Alt   = 0x0010,
    Right_Alt  = 0x0020,
    CapsLock   = 0x0040,
    Left_Win   = 0x0080,
    Right_Win  = 0x0100,
    Space      = 0x0200,
    Menu       = 0x0400,
    ScrollLock = 0x0800,
}
*/

