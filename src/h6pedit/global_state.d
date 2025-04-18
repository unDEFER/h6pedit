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
import std.algorithm;

import bindbc.sdl;

import h6pedit.reference;
import h6pedit.rendered_h6p;
import h6pedit.brush;

import hexpict.h6p;
import hexpict.color;
import hexpict.colors;
import hexpict.hex2pixel;
import hexpict.hyperpixel;

// @Scales
int[] scales = [1, 2, 4, 8, 16, 32, 64, 128];

ubyte[][] dot_by_line = [ [0], 
                          [23, 1],
                          [22, 24, 2],
                          [21, 41, 25, 3],
                          [20, 40, 42, 26, 4],
                          [39, 53, 43, 27],
                          [19, 52, 54, 44, 5],
                          [38, 59, 55, 28],
                          [18, 51, 60, 45, 6],
                          [37, 58, 56, 29],
                          [17, 50, 57, 46, 7],
                          [36, 49, 47, 30],
                          [16, 35, 48, 31, 8],
                          [15, 34, 32, 9],
                          [14, 33, 10],
                          [13, 11],
                          [12] ];

ubyte[2][61] dot_to_coords = [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4],
                              [4, 6], [4, 8], [4, 10], [4, 12],
                              [3, 13], [2, 14], [1, 15] , [0, 16],
                              [0, 15], [0, 14], [0, 13], [0, 12],
                              [0, 10], [0, 8], [0, 6], [0, 4],
                              [0, 3], [0, 2], [0, 1],

                              [1, 2], [2, 3], [3, 4], [3, 5], [3, 7], [3, 9],
                              [3, 11], [3, 12], [2, 13], [1, 14], [1, 13], [1, 12],
                              [0, 11], [0, 9], [0, 7], [0, 5], [1, 4], [1, 3],

                              [2, 4], [2, 5], [3, 6], [3, 8], [3, 10], [2, 11],
                              [2, 12], [1, 11], [1, 10], [1, 8], [1, 6], [1, 5],

                              [2, 6], [2, 7], [2, 9], [2, 10], [1, 9], [1, 7],

                              [2, 8]
];

static this()
{
    foreach (y, line; dot_by_line)
    {
        foreach (x, o; line)
        {
            auto p = dot_to_coords[o];
            assert(p[0] == x && p[1] == y,
                    format("dot_by_line error %sx%s => %s => %sx%s", x, y, o, p[0], p[1]));
        }
    }
}

// @Modes
enum Mode
{
    Edit = 0,
    SimpleFormEdit,
    ExtendedFormEdit,
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
    int vertex;

    bool window_shown;
    Mode mode;
    bool lshift, lctrl;
    bool rshift;

    bool mouse_left_down;
    bool mouse_right_down;
    bool pen_down;
    bool erase_down;
    bool paste_down;
    bool rect_down;
    // @ChangeColor
    ushort change_color;
    ubyte color_gray;

    // @CurrentColor
    ushort color;
    ushort color2;

    // @ScreenSize
    SDL_Rect screen;

    // @Pictures
    RenderedH6P[] pictures;
    int pict;
    bool hide_picture;
    bool hide_reference;

    RenderedH6P picture()
    {
        return pictures[pict];
    }

    // @Selection
    RenderedH6P selection;
    // @MaskHint
    RenderedH6P mask_hint;
    // @Mask2Hint
    RenderedH6P mask2_hint;
    ubyte dotx, doty;
    // @ColorPicker
    RenderedH6P color_picker;
    // @Buffer
    RenderedH6P buffer;
    // @TilePreview
    RenderedH6P tile_preview;

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
    SDL_Texture* window_texture2;
    
    // @EditMask
    byte pressed_dir = -1;
    ubyte edited_form;
    bool form_changed;
    ubyte[] form_dots;
    Vertex last_v = Vertex(uint.max, uint.max, 100);
    Vertex first_v = Vertex(uint.max, uint.max, 100);
    Brush brush = Brush([Vector(0, 14), Vector(8, 0), Vector(0, -14), Vector(-8, 0)]);

    // @Selection
    SDL_Rect select;
    // @DrawLine
    SDL_Rect start_select;
    SDL_Rect colors_select;

    // @Palette
    ushort palette_offset;
    SDL_Texture*[12] palette_textures;

    // @Font
    SDL_Texture* font;

    // @Scales
    int scale = 2;

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
        int iw = scales[scale] * select.w;
        int ih = cast(int) round(scales[scale] * (select.h * 1.5 / sqrt(3.0) + 0.5 / sqrt(3.0)));

        selection = new RenderedH6P(iw, ih);
    }

    // @Palette
    void palette_reinit()
    {
        H6P *image = picture.image;
        SDL_Surface* surface = SDL_CreateRGBSurface(0,
                1,
                1,
                32, 0x00FF0000, 0X0000FF00, 0X000000FF, 0XFF000000);

        foreach (i; 0..12)
        {
            uint ncolor;
            auto pi = palette_offset + i;
            if (pi < image.cpalette[0].length)
            {
                auto p = image.cpalette[0][pi];
                bool err;
                ubyte[4] pc;
                Color color = p;
                color_to_u8(&color, &SRGB_SPACE, pc, &err, ErrCorrection.ORDINARY);
                ncolor = ( (pc[0]) << 16 |
                                (pc[1]) << 8 |
                                (pc[2]) |
                                (pc[3]) << 24 );
            }

            (cast(uint*) surface.pixels)[0] = ncolor;
            if (palette_textures[i]) SDL_DestroyTexture(palette_textures[i]);
            palette_textures[i] = SDL_CreateTextureFromSurface(renderer, surface);
        }

        SDL_FreeSurface(surface);
    }
}

// @PictureWithReference
void open_picture(string file, string reference = null, int cRx=0, int cRy=0, int sRw=10)
{
    H6P *img = h6p_read(file);
    pictures ~= new RenderedH6P(img, screen.w, screen.h);
    filenames ~= file;

    if (reference)
    {
         references ~= new Reference(reference, cRx, cRy, sRw);
    }
    else references ~= null;

    palette_reinit();
}

// @PictureWithReference
void new_picture(int w, int h, string file, string reference = null, int cRx=0, int cRy=0, int sRw=10)
{
    ubyte[] imgdata = new ubyte[w*h*6];
    ColorSpace *ITP = new ColorSpace;
    *ITP = ITP_SPACE;
    Bounds bb = new double[][](2,3);
    get_itp_bounds(&RMB_SPACE, bb);
    ITP.bounds = bb;
    H6P *img = h6p_create(ITP, w, h);

    pictures ~= new RenderedH6P(img, screen.w, screen.h);
    filenames ~= file;

    if (reference)
    {
         references ~= new Reference(reference, cRx, cRy, sRw);
    }
    else references ~= null;

    palette_reinit();
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
        int w = 13;
        int h = 1;

        int hw = 36;
        int hh = cast(int) round(hw * 2.0 / sqrt(3.0));

        int iw = w*hw;
        int ih = h*hh;

        mask_hint = new RenderedH6P(w, h, iw, ih);
        mask_hint.scale = hw;
    }

    // @MaskHint2
    void mask2_init()
    {
        int w = 13;
        int h = 17;

        int hw = 8;
        int hh = cast(int) round(hw * 2.0 / sqrt(3.0));
        int hhh = cast(int) floor(hh/4.0);

        int iw = w*hw;
        int ih = h*(hh-hhh) + hhh;

        mask2_hint = new RenderedH6P(w, h, iw, ih);
        mask2_hint.scale = hw;
    }

    // @TilePreview
    void tile_preview_init()
    {
        int w = 37;
        int h = 39;

        int iw = w*4;
        int ih = cast(int) round(h*3.5);

        tile_preview = new RenderedH6P(w, h, iw, ih);
        tile_preview.rect.x = screen.w - iw;
    }

    // @ColorPicker
    void colors_init()
    {
        enum div = 4;
        int w = 512/div;
        int h = 512/div;

        int iw = w*8;
        int ih = h*7;

        color_picker = new RenderedH6P(w, h, iw, ih);
        color_picker.scale = 8;

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

        SDL_Surface* image2 = IMG_Load("hex_window2.png".ptr);

        if (image2)
        {
            window_texture2 = SDL_CreateTextureFromSurface(renderer, image2);
            SDL_FreeSurface(image2);
        }
    }

    // @Font
    void createTextures()
    {
        /*H6P *image = h6p_read("fonts/cp1251_6x10.h6p");

        auto surface = h6p_render(image, 4, 0, 0, 0, image.width*4, cast(int)(image.height*4* 1.5 / sqrt(3.0)));

        if (font) SDL_DestroyTexture(font);
        font = SDL_CreateTextureFromSurface(renderer, surface);*/
    }

    // @SDLInit
    void initSDL(size_t display = 0)
    {
        if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) < 0 )
        {
            throw new Exception(format("Error while SDL initializing: %s",
                    SDL_GetError().to!string() ));
        }

        createWindow(display);

        createRenderer();

        SDL_GetWindowSize(window, &screen.w, &screen.h);

        select.w = 1;
        select.h = 1;

        createTextures();

        selection_reinit();
        mask_init();
        mask2_init();
        colors_init();
        hexwindow_init();
        tile_preview_init();

        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

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
        rmb_init();
        change_color = 0;
        calc_rgb_matrices(&SRGB_SPACE);
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

