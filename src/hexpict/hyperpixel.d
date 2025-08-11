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

module hexpict.hyperpixel;

import std.algorithm;
import std.typecons;
import std.math;
import std.stdio;
import std.conv;
import std.file;
import std.bitmanip;

import hexpict.common;
import hexpict.color;

void neighbours(int x, int y, int[][] neigh)
{
    // @H6PNeighbours
    neigh[5][0] = x - 1;
    neigh[5][1] = y;

    neigh[2][0] = x + 1;
    neigh[2][1] = y;

    neigh[0][1] = neigh[1][1] = y - 1;

    neigh[4][1] = neigh[3][1] = y + 1;

    if (y%2 == 0)
    {
        neigh[4][0] = neigh[0][0] = x - 1;

        neigh[3][0] = neigh[1][0] = x;
    }
    else
    {
        neigh[0][0] = neigh[4][0] = x;
        neigh[1][0] = neigh[3][0] = x + 1;
    }
}

struct Point
{
    float x, y;
}

// @PointsOfHexagon
Point[61] points;
int pw = 0;

BitArray*[6][19*4] hp19_4;

BitArray* get_simple_hyperpixel(ushort form, int w, ubyte rotate, bool _debug = false)
{
    if (hp19_4[form][rotate] is null)
    {
        ubyte[12] dots;
        dots[0] = cast(ubyte)((form-1)/19 + 1);
        dots[1] = cast(ubyte)((form-1)%19 + 6);
        hp19_4[form][rotate] = hyperpixel(w, dots, rotate, _debug);
    }

    return hp19_4[form][rotate];
}

/*
 * Generates mask of ingoing in areas of hyperpixel
 * of point (x, y) if width of hyperpixel is w
 * and height is h.
 * @HyperPixel @HyperMask
 */
void hypermask61(bool[] hpdata, int w, int h, ubyte[] form, bool _debug = false)
{
    struct YInter
    {
        int x1, x2;
        short ydir;
        float xc, yc;
    }

    float area = 0.0f;
    foreach(i, f1; form)
    {
        ubyte f2 = form[(i+1)%$];

        Point p1 = points[f1];
        Point p2 = points[f2];

        area += p1.x*p2.y - p2.x*p1.y;
    }

    if (area == 0) return;

    int debugy = -1;
    if (_debug) debugy = 18;

    if (debugy >= 0)
    {
        foreach(i, f; form)
        {
            writefln("%s. f %s %s", i, f, points[f]);
        }
    }

    foreach(y; 0..h)
    {
        float fy = y + 0.5f;
        YInter[] yinters;

        int continued;
        foreach(i, f1; form)
        {
            ubyte f2 = form[(i+1)%$];

            Point p1 = points[f1];
            Point p2 = points[f2];

            if (fy >= p1.y && fy < p2.y || fy >= p2.y && fy < p1.y)
            {
                if (f1 < 24 && f2 < 24)
                {
                    ubyte f41 = cast(ubyte) (f1 - f1%4);
                    ubyte f42 = cast(ubyte) (f2 - f2%4);

                    if (f41 == f42 || (f41+4)%24 == f42 && f2%4 == 0 || (f42+4)%24 == f41  && f1%4 == 0)
                    {
                        if (y == debugy)
                        {
                            writefln("continued %s-%s", f1, f2);
                        }
                        continued++;
                        continue;
                    }
                }

                int x1, x2;

                if (p1.x < p2.x)
                {
                    x1 = cast(int) round(p1.x);
                    x2 = cast(int) round(p2.x);
                }
                else
                {
                    x1 = cast(int) round(p2.x);
                    x2 = cast(int) round(p1.x);
                }
                
                if (x1 >= w) x1 = w-1;
                if (x2 >= w) x2 = w-1;

                float xc = p1.x;
                float yc = (p1.y + p2.y)/2.0f;

                if (abs(p1.y - p2.y) > 0.01)
                {
                    float ux1 = p1.x;
                    float uy1 = p1.y;
                    float ux2 = p2.x;
                    float uy2 = p2.y;

                    float dx = ux2 - ux1;
                    float dy = uy2 - uy1;

                    float yy0 = y + 0.0f;
                    float yy1 = y + 1.0f;

                    float xx0 = (yy0 - uy1)*dx/dy + ux1;
                    
                    if (abs(p1.y - fy) <= 0.1)
                    {
                        if (p1.y < p2.y)
                            fy += 0.25;
                        else
                            fy -= 0.25;
                    }
                    
                    if (abs(p2.y - fy) <= 0.1)
                    {
                        if (p1.y > p2.y)
                            fy += 0.25;
                        else
                            fy -= 0.25;
                    }

                    xc = (fy - uy1)*dx/dy + ux1;

                    float xx1 = (yy1 - uy1)*dx/dy + ux1;

                    if (y == debugy)
                    {
                        writefln("xx0 = %s, xx1 = %s, p1.y = %s, p2.y = %s", xx0, xx1, p1.y, p2.y);
                    }

                    float minx, maxx;
                    if (xx0 < xx1)
                    {
                        minx = xx0;
                        maxx = xx1;
                    }
                    else
                    {
                        minx = xx1;
                        maxx = xx0;
                    }

                    int cx0 = cast(int) floor(minx);
                    int cx1 = cast(int) ceil(maxx);
                    int ix0, ix1;

                    if (cx0 < 0) cx0 = 0;
                    if (cx1 > w) cx1 = w;

                    if (y == debugy)
                    {
                        writefln("cx0 = %s, cx1 = %s", cx0, cx1);
                    }

                    if (p2.y < p1.y)
                    {
                        ix0 = cx0-1;
                        ix1 = cx0-1;

                        foreach (x; cx0..cx1)
                        {
                            float fx0 = x + 0.0f;
                            float fx1 = x + 1.0f;

                            float fy0 = (fx0 - xx0)/(xx1-xx0) + yy0;
                            float fy1 = (fx1 - xx0)/(xx1-xx0) + yy0;

                            if (y == debugy)
                            {
                                writefln(">> x = %s, fy0 = %s, fy1 = %s (<0.5 %s != %s)", x, fy0, fy1, (fy0+fy1)/2.0f < (yy0+yy1)/2.0f, p2.x > p1.x);
                            }

                            if (ix0 < cx0 && (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x)))
                                ix0 = x;

                            if (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x))
                                ix1 = x;
                        }

                        if (ix0 < cx0) ix0 = cx0;
                        if (ix1 < cx0) ix1 = cx1;

                        if (y == debugy)
                        {
                            writefln(">> x = %s-%s, ix = %s-%s", x1, x2, ix0, ix1);
                        }
                    }
                    else
                    {
                        ix0 = cx1;
                        ix1 = cx1;

                        foreach (x; cx0..cx1)
                        {
                            float fx0 = x + 0.0f;
                            float fx1 = x + 1.0f;

                            float fy0 = (fx0 - xx0)/(xx1-xx0) + yy0;
                            float fy1 = (fx1 - xx0)/(xx1-xx0) + yy0;

                            if (y == debugy)
                            {
                                writefln("<< x = %s, fy0 = %s, fy1 = %s (<0.5 %s != %s)", x, fy0, fy1, (fy0+fy1)/2.0f < (yy0+yy1)/2.0f, p2.x > p1.x);
                            }

                            if (ix0 >= cx1 && (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x)))
                                ix0 = x;

                            if (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x))
                                ix1 = x;
                        }

                        if (ix0 >= cx1) ix0 = cx0;
                        if (ix1 >= cx1) ix1 = cx1;

                        if (y == debugy)
                        {
                            writefln("<< x = %s-%s, ix = %s-%s", x1, x2, ix0, ix1);
                        }
                    }

                    if (ix0 > x1)
                    {
                        if (ix0 < x2)
                            x1 = ix0;
                        else
                            x1 = x2;
                    }
                    if (ix1 < x2)
                    {
                        if (ix1 > x1)
                            x2 = ix1;
                        else
                            x2 = x1;
                    }
                }

                yinters ~= YInter(x1, x2, cast(short) (p2.y - p1.y), xc, yc);
            }
        }

        alias myComp = (x, y) => (x.xc < y.xc || x.xc == y.xc && x.yc > y.yc);

        yinters = yinters.sort!(myComp).release();

        int xp = 0;
        short ydirp;
        foreach(yinter; yinters)
        {
            int sx = (yinter.ydir >= 0) ? yinter.x1 : xp;

            if (y == debugy)
            {
                writefln("yinter = %s, sx = %s", yinter, sx);
            }

            foreach (x; sx .. yinter.x2+1)
            {
                hpdata[y*w + x] = true;
            }

            xp = yinter.x2+1;
            ydirp = yinter.ydir;
        }

        if (y == debugy)
        {
            writefln("ydirp = %s, yinters.length = %s, area = %s, continued = %s",
                    ydirp, yinters, area, continued);
        }

        if (ydirp > 0 || yinters.length == 0 && ((area > 0) != (continued > 0 && continued%2 == 0)))
        {
            foreach (x; xp .. w)
            {
                hpdata[y*w + x] = true;
            }
        }
    }
}

Tuple!(ubyte[], "form", ubyte, "rot") normalize_form(ubyte[] form)
{
    if (form.length < 2) return tuple!("form", "rot")(form, cast(ubyte) 0);

    if (form.length > 2 && (form[0] >= 24 || form[$-1] >= 24))
    {
        writefln("Normalize form %s", form);
        ubyte[] wr_form;
        foreach (dir; form)
        {
            auto o = get_off_r(dir);

            if (o.r > 0)
                dir = cast(ubyte) (o.off + (dir-o.off)%o.r);
            wr_form ~= dir;
        }

        ptrdiff_t mindf = minIndex(wr_form);
        ubyte minv = wr_form[mindf];
        ubyte[] minds = [cast(ubyte) mindf];
        ubyte[] minds2;

        foreach (i, dir; wr_form[mindf+1..$])
        {
            if (dir == minv)
            {
                minds ~= cast(ubyte)(mindf+1+i);
            }
        }

        if (minds.length > 1)
        {
            ubyte till = cast(ubyte) ((wr_form.length + minds.length-1) / minds.length);
            //writefln("form %s, wr_form %s, minds %s", form, wr_form, minds);

            foreach (off; 1..till)
            {
                ubyte[] nexts;
                foreach (mind; minds)
                {
                    nexts ~= wr_form[(mind+off)%$];
                }

                mindf = minIndex(nexts);
                minv = nexts[mindf];
                minds2 ~= minds[mindf];

                foreach (i, dir; nexts[mindf+1..$])
                {
                    if (dir == minv)
                    {
                        minds2 ~= minds[mindf+1+i];
                    }
                }

                swap(minds, minds2);
                minds2.length = 0;

                //writefln("off %s, minds %s", off, minds);

                if (minds.length == 1)
                {
                    break;
                }
            }
        }

        form = form[minds[0]..$] ~ form[0..minds[0]];
        writefln("Till %s", form);
    }

    size_t max_i, max_j;
    ubyte[] form2;
    for(size_t i = 0; i < form.length; i++)
    {
        ubyte dir = form[i];
        if (dir < 24)
        {
            size_t i2 = form2.length;
            size_t j, j2;
            ubyte dir2;
            for(j = 1; j < form.length; j++)
            {
                dir2 = form[(i+j)%$];

                if (!(dir2 < 24 && (dir/4 == dir2/4 ||
                            dir%4 == 0 && dir2%4 == 0 && ((dir+4)%24 == dir2 || (dir2+4)%24 == dir))))
                {
                    break;
                }

                if (dir%4 == 0 || j == 1)
                {
                    form2 ~= dir;
                    j2++;
                }

                dir = dir2;
            }

            form2 ~= dir;
            j2++;

            if (j2 > max_j)
            {
                max_j = j2;
                max_i = i2;
            }

            i = i+j-1;
        }
        else
        {
            form2 ~= dir;
        }
    }

    swap(form, form2);

    if (max_j > 2)
    {
        if (max_i+max_j < form.length)
        {
            form = form[max_i+max_j-1..$] ~ form[0..max_i+1];
        }
        else
        {
            form = form[(max_i+max_j-1)%$..max_i+1];
        }
    }

    ubyte rot = get_rot(form[0]);

    foreach(ref dir; form)
    {
        auto o = get_off_r(dir);
        if (o.r == 0) continue;

        dir = cast(ubyte) (o.off + (dir-o.off + (6-rot)*o.r)%(6*o.r));
    }

    writefln("return %s", tuple!("form", "rot")(form, rot));
    return tuple!("form", "rot")(form, rot);
}

Tuple!(ubyte, "off", ubyte, "r") get_off_r(ubyte dir)
{
    if (dir < 24)
    {
        return tuple!("off", "r")(cast(ubyte) 0, cast(ubyte) 4);
    }
    else if (dir < 42)
    {
        return tuple!("off", "r")(cast(ubyte) 24, cast(ubyte) 3);
    }
    else if (dir < 54)
    {
        return tuple!("off", "r")(cast(ubyte) 42, cast(ubyte) 2);
    }
    else if (dir < 60)
    {
        return tuple!("off", "r")(cast(ubyte) 54, cast(ubyte) 1);
    }
    else return tuple!("off", "r")(cast(ubyte) 60, cast(ubyte) 0);
}

ubyte get_rot(ubyte dir)
{
    auto o = get_off_r(dir);
    if (o.r == 0) return 0;

    return cast(ubyte) ((dir-o.off)/o.r);
}

ubyte[] form12toform(ubyte[12] form12, ubyte rotate, bool _debug = false)
{
    ubyte[] form;
    foreach (f; form12)
    {
        if (f == 0) break;
        f--;

        if (rotate > 0)
        {
            auto o = get_off_r(f);
            if (o.r != 0)
                f = cast(ubyte) (o.off + (f - o.off + o.r*rotate)%(6*o.r));
        }

        form ~= f;
    }

    if (form.length > 1 && form[0] < 24 && form[$-1] < 24)
    {
        ubyte f = form[$-1];
        ubyte f4 = f%4;
        f -= f4;

        ubyte fe = form[0];
        fe = cast(ubyte)(fe - fe%4);
        if (_debug) writefln("form %s, f=%s, fe=%s", form, f, fe);

        if (f != fe || form[$-1] < form[0])
        {
            fe = cast(ubyte)((fe + 4)%24);
            if (f4 > 0)
            {
                form ~= f;
            }

            while (f != fe)
            {
                f = (f+20)%24;
                if (f == form[0]) break;
                form ~= f;
            }
        }
    }

    if (form.length > 1 && form[0] == form[$-1])
        form = form[0..$-1];

    return form;
}

/*
 * Generates hyperpixel with width w.
 * Returns false if wasn't generated.
 * @HyperPixel
 */
BitArray *hyperpixel(int w, ubyte[12] form12, ubyte rotate, bool _debug = false)
{
    ubyte[] form = form12toform(form12, rotate, _debug);

    //writefln("form=%s", form);

    int h = cast(int) round(w * 2.0 / sqrt(3.0));
    int hh = cast(int) ceil(h/4.0);
    int w5 = cast(int) round(0.5*w);

    /*        0
     *    23  oo 1
     *  22  oooooo 2
     *21  oooooooooo 3
     *20oooooooooooooo 4
     *19oooooooooooooo 5
     *18oooooooooooooo 6
     *17oooooooooooooo 7
     *16  oooooooooo  8
     *1514  oooooo 10 9
     *    13  oo 11
     *        12
     */

    // @PointsOfHexagon
    if (pw != w)
    {
        hp19_4 = (BitArray*[6][19*4]).init;
        pw = w;

        points[0] = Point(w/2.0f, 0);
        points[4] = Point(w, h/4.0f);
        points[8] = Point(w, h - h/4.0f);
        points[12] = Point(w/2.0f, h);
        points[16] = Point(0, h - h/4.0f);
        points[20] = Point(0, h/4.0f);

        points[60] = Point(w/2.0f, h/2.0f);

        foreach(p; 0..6)
        {
            int p0 = p*4;

            foreach(i; 1..4)
            {
                int p1 = (27 - i*3)*i + p*(4-i);

                float xx = (points[p0].x*(4-i) + points[60].x*i)/4.0f;
                float yy = (points[p0].y*(4-i) + points[60].y*i)/4.0f;

                points[p1] = Point(xx, yy);
            }
        }
        
        foreach(z; 0..3)
        {
            int v = 4 - z;
            foreach(p; 0..6)
            {
                int o = (27 - z*3)*z;
                int p0 = o + p*v;
                int p1 = o + ((p+1)*v) % (6*v);

                foreach(i; 1..v)
                {
                    float xx = (points[p0].x*(v-i) + points[p1].x*i)/v;
                    float yy = (points[p0].y*(v-i) + points[p1].y*i)/v;

                    points[p0+i] = Point(xx, yy);
                }
            }
        }

        Point[] opoints;
        int total;

        foreach(p1; 0..61)
        {
            foreach(p2; (p1+1)..61)
            {
                float[2] p11 = [points[p1].x, points[p1].y];
                float[2] p12 = [points[p2].x, points[p2].y];

                float[2] p21 = [points[8].x, points[8].y];
                float[2] p22 = [points[4].x, points[4].y];

                float[2] ip;
                int i = line_segments_intersection([p11, p12], [p21, p22], ip);
                if (i == -1 || i == -2)
                {
                    bool found;
                    foreach (p; points ~ opoints)
                    {
                        float[2] p3 = [p.x, p.y];
                        if (is_same_point(ip, p3))
                        {
                            found = true;
                            break;
                        }
                    }

                    if (!found)
                        opoints ~= Point(ip[0], ip[1]);
                    total++;
                }
            }
        }

        alias myComp = (x, y) => x.y < y.y;
        opoints = opoints.sort!(myComp).release;

        float[] pdiff;
        foreach (i, p; opoints[0..$-1])
        {
            auto p2 = opoints[i+1];
            pdiff ~= p2.y - p.y;
            if (pdiff[$-1] > 0.1f)
                writefln("%s - %s, %s", p, p2, pdiff[$-1]);
        }

        Point[] rpoints;
        float x = w;
        float y = h/4.0f;
        float dx = 0.0f;
        float dy = h/2.0f;

        foreach(o; 0..4)
        {
            float k1 = (o == 0 ? 1.0f/28.0f : 1.0f/24.0f);
            float k2 = (o == 3 ? 1.0f/28.0f : 1.0f/24.0f);

            float x0 = x + dx * (o/4.0f + k1);
            float y0 = y + dy * (o/4.0f + k1);

            float x1 = x + dx * ((o+1)/4.0f - k2);
            float y1 = y + dy * ((o+1)/4.0f - k2);
            writefln("o=%s, y0=%s, y1=%s", o, y0, y1);

            float dx01 = x1-x0;
            float dy01 = y1-y0;

            foreach(s; 0..8)
            {
                rpoints ~= Point(x0 + dx01*s/7.0f, y0 + dy01*s/7.0f);
            }
        }

        float maxErr = 0.0f;
        foreach (p; opoints)
        {
            Point bestP;
            float minDist = h;
            foreach (r; rpoints)
            {
                float dist = hypot(r.x - p.x, r.y - p.y);
                if (dist < minDist)
                {
                    bestP = r;
                    minDist = dist;
                }
            }

            if (minDist > 0.2)
            {
                writefln("minDist = %s, p = %s, bestP = %s", minDist, p, bestP);
            }

            if (minDist > maxErr)
                maxErr = minDist;
        }

        writefln("len %s/%s, opoints = %s", opoints.length, total, opoints);
        writefln("pdiff = %s", pdiff);
        writefln("h = %s", h);

        writefln("len %s, rpoints = %s", rpoints.length, rpoints);
        writefln("maxErr = %s", maxErr);
    }

    // @HyperPixelSuccess
    bool success = (w5 == (w-w5));
    foreach (i; 1..hh)
    {
        int ww = cast(int) round(0.5*w*i/hh);
        int ww2 = cast(int) round(0.5*w*(hh-i)/hh);

        success &= (ww == (w5-ww2));
    }

    if (success)
    {
        //writefln("Generate hyperpixel 24 %sx%s (%s, %s)", w, h, 1.0*w/h, 1.0*(h-hh)/w);

        // @HyperMask
        bool[] hpdata = new bool[w*h];
        foreach (i; hh..(h-hh+2))
        {
            foreach(j; 0..w)
            {
                hpdata[(i-1)*w + j] = true;
            }
        }

        foreach (i; 1..hh)
        {
            int ww = cast(int) round(0.5*w*i/hh);

            foreach(j; 0..w5)
            {
                if (w5-j <= ww)
                {
                    hpdata[(i-1)*w + j] = true;
                    hpdata[(h-i)*w + j] = true;
                }
            }

            foreach(j; 0..(w-w5))
            {
                if (j+1 <= ww)
                {
                    hpdata[(i-1)*w + w5+j] = true;
                    hpdata[(h-i)*w + w5+j] = true;
                }
            }
        }

        if (form.length > 0)
        {
            bool[] hpdata2 = new bool[w*h];
            hypermask61(hpdata2, w, h, form, _debug);

            foreach (y; 0..h)
            {
                foreach (x; 0..w)
                {
                    hpdata[y*w + x] &= hpdata2[y*w + x];
                }
            }
        }

        if (_debug)
        {
            foreach (y; 0..h)
            {
                writef("%2d ", y);
                foreach (x; 0..w)
                {
                    write(hpdata[y*w + x] ? '+' : '.');
                }
                writeln();
            }
        }

        return new BitArray(hpdata);
    }

    return null;
}

void scalelist()
{
    // @HyperPixel @HyperPixelSuccess
    writefln("Available hyperpixel sizes:");
    write("4");
    foreach (w; 5..100)
    {
        int h = cast(int) round(w * 2.0 / sqrt(3.0));
        int hh = cast(int) ceil(h/4.0);
        int w5 = cast(int) round(0.5*w);

        bool success = (w5 == (w-w5));
        foreach (i; 1..hh)
        {
            int ww = cast(int) round(0.5*w*i/hh);
            int ww2 = cast(int) round(0.5*w*(hh-i)/hh);

            success &= (ww == (w5-ww2));
        }

        if (success)
        {
            writef(", %s", w);
        }
    }
    
    writeln();
}

// @PointsOfHexagon
private Point[61] fpoints;

private
{
    immutable float fw = 1.0f;
    immutable float fh = fw * 2.0f / sqrt(3.0f);
    immutable float fvh = fh/4.0f;
}

static this()
{
    /*        0
     *    23  oo 1
     *  22  oooooo 2
     *21  oooooooooo 3
     *20oooooooooooooo 4
     *19oooooooooooooo 5
     *18oooooooooooooo 6
     *17oooooooooooooo 7
     *16  oooooooooo  8
     *1514  oooooo 10 9
     *    13  oo 11
     *        12
     */

    fpoints[0] = Point(fw/2, 0);
    fpoints[4] = Point(fw, fh/4);
    fpoints[8] = Point(fw, fh - fh/4);
    fpoints[12] = Point(fw/2, fh);
    fpoints[16] = Point(0, fh - fh/4);
    fpoints[20] = Point(0, fh/4);

    fpoints[60] = Point(fw/2.0f, fh/2.0f);

    foreach(p; 0..6)
    {
        int p0 = p*4;

        foreach(i; 1..4)
        {
            int p1 = (27 - i*3)*i + p*(4-i);

            float xx = (fpoints[p0].x*(4-i) + fpoints[60].x*i)/4.0f;
            float yy = (fpoints[p0].y*(4-i) + fpoints[60].y*i)/4.0f;

            fpoints[p1] = Point(xx, yy);
        }
    }

    foreach(z; 0..3)
    {
        int v = 4 - z;
        foreach(p; 0..6)
        {
            int o = (27 - z*3)*z;
            int p0 = o + p*v;
            int p1 = o + ((p+1)*v) % (6*v);

            foreach(i; 1..v)
            {
                float xx = (fpoints[p0].x*(v-i) + fpoints[p1].x*i)/v;
                float yy = (fpoints[p0].y*(v-i) + fpoints[p1].y*i)/v;

                fpoints[p0+i] = Point(xx, yy);
            }
        }
    }
}

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

struct Vertex
{
    uint x, y;
    byte p;

    uint[2] to_global()
    {
        ubyte dotx = dot_to_coords[p][0];
        ubyte doty = dot_to_coords[p][1];

        ubyte dotx_ = cast(ubyte) (dotx + (5-dot_by_line[doty].length)/2);
        uint gx = x*8 + (y%2)*4 + (doty%2) + dotx_*2;
        uint gy = y*12 + doty;

        //writefln("HyperCoordsToGlobal: %s => gx = %s, gy = %s", this, gx, gy);

        return [gx, gy];
    }

    static int[2] to_flat(uint[2] gc)
    {
        int[2] pc;
        
        uint gx = gc[0];
        uint gy = gc[1];

        pc[0] = gx*2 + gy%2;
        pc[1] = gy;
        return pc;
    }

    int[2] to_flat()
    {
        auto gc = to_global();
        return to_flat(gc);
    }

    static int[3] flat_to_global(int[2] fc)
    {
        int[3] gc;

        int fx = fc[0];
        int fy = fc[1];

        gc[0] = fx/2;
        gc[1] = fy;
        gc[2] = (fx%2 + fy%2)%2;
        return gc;
    }

    static Vertex[] from_flat(int[2][] fc)
    {
        uint[2][] gc;
        foreach (fp; fc)
        {
            auto gp = flat_to_global(fp);
            if (gp[2] != 0)
                return [];
            gc ~= [gp[0], gp[1]];
        }

        return from_global(gc);
    }

    static Vertex[] from_global(uint[2][] gc)
    {
        Vertex[] vs;

        uint gx = gc[$/2][0];
        uint gy = gc[$/2][1];

        Vertex v;

        v.y = gy/12;
        ubyte doty = gy%12;
        uint sx = gx - (v.y%2)*4 - (doty%2);
        v.x = sx/8;
        ubyte dotx_ = (sx%8)/2;
        ubyte dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);

        if (dotx >= dot_by_line[doty].length)
        {
            v.y--;
            doty += 12;
            sx = gx - (v.y%2)*4 - (doty%2);
            v.x = sx/8;
            dotx_ = (sx%8)/2;
            dotx = cast(ubyte) (dotx_ - (5-dot_by_line[doty].length)/2);
        }

        v.p = dot_by_line[doty][dotx];
        int vy_even = (v.y%2 == 0 ? 1 : 0);

        if (dotx == 0 || dotx == dot_by_line[doty].length - 1)
        {
            if (doty == 0)
            {
                //0
                if (gc.length == 3)
                {
                    int[2] pc0 = to_flat(gc[0]);
                    int[2] pc1 = to_flat(gc[1]);
                    int[2] pc2 = to_flat(gc[2]);

                    pc0[] -= pc1[];
                    pc2[] -= pc1[];

                    float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                    float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);

                    float dir = dir1;

                    if (abs(dir1 - PI/2.0f) < 1e-5 || abs(dir1 + PI/4.0f) < 1e-5 ||
                            abs(dir1 + PI*3.0f/4.0f) < 1e-5)
                    {
                        dir = dir2;
                    }

                    if ( dir < PI/2.0f + 1e-5 && dir > -PI/4.0f - 1e-5 )
                    {
                        vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                    }
                    else if ( dir < -PI/4.0f && dir > -PI*3.0f/4.0f - 1e-5 )
                    {
                        vs ~= v;
                    }
                    else
                    {
                        vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][4]);
                    }
                }
                else
                {
                    vs ~= v;
                    vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][4]);
                    vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                }
            }
            if (doty == 4)
            {
                if (dotx == 0)
                {
                    //1
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);

                        float dir = dir1;

                        if (abs(dir1 + PI/2.0f) < 1e-5 || abs(dir1 - PI/4.0f) < 1e-5 ||
                                abs(dir1 - PI*3.0f/4.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir > -PI/2.0f - 1e-5 && dir < PI/4.0f + 1e-5 )
                        {
                            vs ~= v;
                        }
                        else if ( dir > PI/4.0f && dir < PI*3.0f/4.0f + 1e-5 )
                        {
                            vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][0]);
                        }
                        else
                        {
                            vs ~= Vertex(v.x - 1, v.y, dot_by_line[12][4]);
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x - 1, v.y, dot_by_line[12][4]);
                        vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][0]);
                    }
                }
                else
                {
                    //2
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);

                        float dir = dir1;

                        if (abs(dir1 + PI/2.0f) < 1e-5 || abs(dir1 - PI/4.0f) < 1e-5 ||
                                abs(dir1 - PI*3.0f/4.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir > -PI/2.0f - 1e-5 && dir < PI/4.0f + 1e-5 )
                        {
                            vs ~= Vertex(v.x + 1, v.y, dot_by_line[12][4]);
                        }
                        else if ( dir > PI/4.0f && dir < PI*3.0f/4.0f + 1e-5 )
                        {
                            vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                        }
                        else
                        {
                            vs ~= v;
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x + 1, v.y, dot_by_line[12][4]);
                        vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                    }
                }
            }
            else if (doty < 4)
            {
                if (dotx == 0)
                {
                    //3
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);

                        float dir = dir1;

                        if (abs(dir1 - PI/4.0f) < 1e-5 || abs(dir1 + PI*3.0f/4.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir < PI/4.0f + 1e-5 && dir > -PI*3.0f/4.0f - 1e-5 )
                        {
                            vs ~= v;
                        }
                        else
                        {
                            vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][0]);
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x - vy_even, v.y-1, dot_by_line[12][0]);
                    }
                }
                else
                {
                    //4
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);

                        float dir = dir1;

                        if (abs(dir1 - PI*3.0f/4.0f) < 1e-5 || abs(dir1 + PI/4.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir < PI*3.0f/4.0f + 1e-5 && dir > -PI/4.0f - 1e-5 )
                        {
                            vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                        }
                        else
                        {
                            vs ~= v;
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x - vy_even + 1, v.y-1, dot_by_line[12][0]);
                    }
                }
            }
            else
            {
                if (dotx == 0)
                {
                    //5
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);
                        writefln("5. dir1=%s, dir2=%s", dir1*180.0f/PI, dir2*180.0f/PI);

                        float dir = dir1;

                        if (abs(dir1 - PI/2.0f) < 1e-5 || abs(dir1 + PI/2.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir < PI/2.0f + 1e-5 && dir > -PI/2.0f - 1e-5 )
                        {
                            vs ~= v;
                        }
                        else
                        {
                            vs ~= Vertex(v.x-1, v.y, dot_by_line[doty][dot_by_line[doty].length-1 - dotx]);
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x-1, v.y, dot_by_line[doty][dot_by_line[doty].length-1 - dotx]);
                    }
                }
                else
                {
                    //6
                    if (gc.length == 3)
                    {
                        int[2] pc0 = to_flat(gc[0]);
                        int[2] pc1 = to_flat(gc[1]);
                        int[2] pc2 = to_flat(gc[2]);

                        pc0[] -= pc1[];
                        pc2[] -= pc1[];

                        float dir1 = atan2(-1.0f*pc0[1], 1.0f*pc0[0]);
                        float dir2 = atan2(-1.0f*pc2[1], 1.0f*pc2[0]);
                        writefln("6. dir1=%s, dir2=%s", dir1*180.0f/PI, dir2*180.0f/PI);

                        float dir = dir1;

                        if (abs(dir1 - PI/2.0f) < 1e-5 || abs(dir1 + PI/2.0f) < 1e-5)
                        {
                            dir = dir2;
                        }

                        if ( dir < PI/2.0f + 1e-5 && dir > -PI/2.0f - 1e-5 )
                        {
                            vs ~= Vertex(v.x+1, v.y, dot_by_line[doty][dot_by_line[doty].length-1 - dotx]);
                        }
                        else
                        {
                            vs ~= v;
                        }
                    }
                    else
                    {
                        vs ~= v;
                        vs ~= Vertex(v.x+1, v.y, dot_by_line[doty][dot_by_line[doty].length-1 - dotx]);
                    }
                }
            }
        }
        else
        {
            vs ~= v;
        }

        //writefln("GlobalCoordsToHyper: gx = %s, gy = %s => %s", gx, gy, vs);

        return vs;
    }
}

void to_float_coords(Vertex v, out float fx, out float fy)
{
    fx = (v.x + (v.y%2 == 1 ? 0.5f : 0.0f))*fw + fpoints[v.p].x;
    fy = v.y*(fh-fvh) + fpoints[v.p].y;
}

