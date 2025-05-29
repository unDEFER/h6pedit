module hexpict.common;
import bindbc.sdl;
import std.math;

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

void line_equation(float[2] p1, float[2] p2, ref float[3] res)
{
    float x1, y1;
    float x2, y2;
    x1 = p1[0]; y1 = p1[1];
    x2 = p2[0]; y2 = p2[1];

    float a = y2-y1;
    float b = -(x2-x1);
    float c = y1*(x2-x1) - x1*(y2-y1);

    res[0] = a; res[1] = b; res[2] = c;
}

float dist_point_to_line(float[2] p, float[3] eq)
{
    return abs(eq[0]*p[0] + eq[1]*p[1] + eq[2])/hypot(eq[0], eq[1]);
}

float signed_dist_point_to_line(float[2] p, float[3] eq)
{
    return (eq[0]*p[0] + eq[1]*p[1] + eq[2])/hypot(eq[0], eq[1]);
}

bool intersection_by_equation(float[3] eq1, float[3] eq2, ref float[2] res)
{
    float a1, b1, c1;
    float a2, b2, c2;
    a1 = eq1[0]; b1 = eq1[1]; c1 = eq1[2];
    a2 = eq2[0]; b2 = eq2[1]; c2 = eq2[2];

    float d = a1*b2-a2*b1;
    if (d < 1e-2) return false;

    float x = (b1*c2-b2*c1)/d;
    float y = (c1*a2-c2*a1)/d;

    res[0] = x;
    res[1] = y;
    return true;
}

bool intersection(float[2] p11, float[2] p12, float[2] p21, float[2] p22, ref float[2] res)
{
    float[3] eq1;
    float[3] eq2;
    line_equation(p11, p12, eq1);
    line_equation(p21, p22, eq2);

    return intersection_by_equation(eq1, eq2, res);
}

byte line_segments_intersection(float[2][2] seg1, float[2][2] seg2, ref float[2] res)
{
    float[3] line_eq1;
    line_equation(seg1[0], seg1[1], line_eq1);

    float[3] line_eq2;
    line_equation(seg2[0], seg2[1], line_eq2);

    bool between(float r, float a, float b)
    {
        return b > a ? r >= a - 1e-2 && r <= b + 1e-2 : r >= b - 1e-2 && r <= a + 1e-2;
    }

    bool between2(float[2] r, float[2] a, float[2] b)
    {
        return between(r[0], a[0], b[0]) && between(r[1], a[1], b[1]);
    }

    if ( !intersection_by_equation(line_eq1, line_eq2, res) )
    {
        if ( between2(seg2[0], seg1[0], seg1[1]) )
        {
            res = seg2[0];
            return 2;
        }
        else if ( between2(seg2[1], seg1[0], seg1[1]) )
        {
            res = seg2[1];
            return 3;
        }
        else return 0;
    }

    if ( between2(res, seg1[0], seg1[1]) &&
            between2(res, seg2[0], seg2[1]) )
    {
        return 1;
    }

    return -1;
}

byte line_segments_intersection(int[2][2] seg1, int[2][2] seg2, ref int[2] res)
{
    float[2][2] fseg1;
    float[2][2] fseg2;
    float[2] fres;

    foreach (j; 0..2)
    {
        foreach (i; 0..2)
        {
            fseg1[j][i] = seg1[j][i];
            fseg2[j][i] = seg2[j][i];
        }
    }

    byte r = line_segments_intersection(fseg1, fseg2, fres);
    if (r != 0)
    {
        res[0] = cast(int) round(fres[0]);
        res[1] = cast(int) round(fres[1]);
    }

    return r;
}
