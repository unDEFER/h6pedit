module hexpict.common;
import bindbc.sdl;
import std.math;
import std.algorithm;
import std.stdio;

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

byte intersection_by_equation(float[3] eq1, float[3] eq2, ref float[2] res)
{
    float a1, b1, c1;
    float a2, b2, c2;
    a1 = eq1[0]; b1 = eq1[1]; c1 = eq1[2];
    a2 = eq2[0]; b2 = eq2[1]; c2 = eq2[2];

    float d = a1*b2-a2*b1;
    if (abs(d) < 1e-5)
    {
        float k;
        if (abs(a2) >= 1e-5)
        {
            k = a1/a2;
        }

        if (abs(b2) >= 1e-5)
        {
            if (isNaN(k))
            {
                k = b1/b2;
            }
            else if (abs(k - b1/b2) >= 1e-5)
            {
                return -1; // Параллельны
            }
        }

        if (abs(c2) >= 1e-5)
        {
            if (abs(k - c1/c2) >= 1e-5)
            {
                return -1; // Параллельны
            }
        }
        else if (abs(c1) >= 1e-5)
        {
            return -1; // Параллельны
        }

        return 0; // Совпадают
    }

    float x = (b1*c2-b2*c1)/d;
    float y = (c1*a2-c2*a1)/d;

    res[0] = x;
    res[1] = y;
    return 1; // Пересекаются
}

byte intersection(float[2] p11, float[2] p12, float[2] p21, float[2] p22, ref float[2] res)
{
    float[3] eq1;
    float[3] eq2;
    line_equation(p11, p12, eq1);
    line_equation(p21, p22, eq2);

    return intersection_by_equation(eq1, eq2, res);
}

bool between(float r, float a, float b)
{
    return b > a ? r >= a - 1e-2 && r <= b + 1e-2 : r >= b - 1e-2 && r <= a + 1e-2;
}

bool between2(float[2] r, float[2] a, float[2] b)
{
    return between(r[0], a[0], b[0]) && between(r[1], a[1], b[1]);
}

bool between(int r, int a, int b)
{
    return b > a ? r >= a && r <= b : r >= b && r <= a;
}

bool between2(int[2] r, int[2] a, int[2] b)
{
    return between(r[0], a[0], b[0]) && between(r[1], a[1], b[1]);
}

float dist2(float[2] a, float[2] b)
{
    return hypot(a[0] - b[0], a[1] - b[1]);
}

byte point_to_vector_position(float[2] point, float[2][2] vector)
{
    if ( is_same_point(point, vector[0]) ) return -1; // Начало вектора, точка A
    if ( is_same_point(point, vector[1]) ) return  1; // Конец вектора, точка B

    float[3] line_eq;
    line_equation(vector[0], vector[1], line_eq);

    float dist = signed_dist_point_to_line(point, line_eq);

    if (abs(dist) < 1e-5)
    {
        if ( between2(point, vector[0], vector[1]) ) return 0; // На векторе
        if ( between2(vector[0], point, vector[1]) ) return -2; // На линии вектора в обратном направлении
        return 2; // На линии вектора в прямом направлении
    }
    if (dist > 0) return 3;
    return -3;
}

byte[3] vectors_intersection(float[2][2] vec1, float[2][2] vec2, ref float[2] inter)
{
    byte[3] res;
    res[0] = point_to_vector_position(vec1[0], vec2);
    res[2] = point_to_vector_position(vec1[1], vec2);
    res[1] = abs(res[0]) == 1 ? res[0] : res[2];

    if (abs(res[2]) == 3)
    {
        float[3] line_eq1;
        line_equation(vec1[0], vec1[1], line_eq1);

        float[3] line_eq2;
        line_equation(vec2[0], vec2[1], line_eq2);

        byte ri = intersection_by_equation(line_eq1, line_eq2, inter);
        if (ri > 0 && !between2(vec1[0], inter, vec1[1]))
            res[1] = point_to_vector_position(inter, vec2);
    }

    return res;
}

byte[3] vector_in_polygon_position(float[2][2] vec, float[2][] polygon, ref float[2] inter, ref size_t side)
{
    float dist = float.max;
    byte[3] res = [-4, -3, -3];
    int intersections, seg_intersections;
    size_t imax = polygon.length;
    for (size_t i; i < imax; i++)
    {
        float[2] p1 = polygon[i];
        float[2] p2 = polygon[(i+1)%$];
        float[2][2] vec2 = [p1, p2];

        float[2] vinter;
        byte[3] r = vectors_intersection(vec, vec2, vinter);
        if ( abs(r[0]) == 3 )
        {
            bool is_inter;
            if (r[1] == 0) is_inter = true;
            else if (r[1] == -1)
            {
                float[2] p0 = polygon[(i+$-1)%$];
                float[2][2] vec1 = [p0, p1];
                byte r2 = point_to_vector_position(vec[0], vec1);
                if (r2 == r[0]) is_inter = true;
                if (abs(r2) == 3 && i == 0) imax--;
            }
            else if (r[1] == 1)
            {
                float[2] p3 = polygon[(i+2)%$];
                float[2][2] vec3 = [p2, p3];
                byte r2 = point_to_vector_position(vec[0], vec3);
                if (r2 == r[0]) is_inter = true;
                if (abs(r2) == 3) i++;
            }

            if (is_inter)
            {
                intersections++;
                if (abs(r[2]) == 3 && r[0] != r[2]) seg_intersections++;

                float d = dist2(vec[0], vinter);
                if (d < dist)
                {
                    dist = d;
                    inter = vinter;
                    side = i;
                    res[1] = r[1];
                }
            }
            else if (abs(r[1]) == 1 && abs(res[1]) > abs(r[1]))
                res[1] = r[1];
            writefln("vec=%s, vec2=%s, vinter=%s, r=%s, is_inter=%s, res=%s", vec, vec2, vinter, r, is_inter, res);
        }
        else if (abs(r[0]) <= 1)
        {
            dist = 0;
            inter = vec[0];
            side = i;
            if (abs(r[0]) == 0 && abs(r[2]) == 3) intersections++;
            if (abs(r[0]) < abs(res[0]))
                res[0] = r[0];
            if (abs(r[2]) <= 2 && abs(r[2]) < abs(res[2]))
                res[2] = r[2];
            writefln("!vec=%s, vec2=%s, vinter=%s, r=%s, res=%s", vec, vec2, vinter, r, res);
        }
        else if (abs(r[0]) == 2 && abs(r[2]) == 2 && r[0] != r[2])
        {
            if (r[0] == -2)
            {
                float d = dist2(vec[0], vec2[0]);
                if (d < dist)
                {
                    dist = d;
                    inter = vec2[0];
                    side = i;
                }
            }
            else
            {
                float d = dist2(vec[0], vec2[1]);
                if (d < dist)
                {
                    dist = d;
                    inter = vec2[1];
                    side = i;
                }
            }

            res = [r[0], 0, r[2]];
            writefln("Ivec=%s, vec2=%s, vinter=%s, r=%s, res=%s", vec, vec2, vinter, r, res);
        }

        if (abs(r[2]) <= 1)
        {
            float d = dist2(vec[0], vec[1]);
            if (d < dist)
            {
                dist = d;
                inter = vec[1];
                side = i;
            }

            if (abs(r[2]) <= abs(res[2]) && abs(r[0]) <= 2 && abs(r[0]) <= abs(res[0]))
            {
                res[0] = r[0];
                res[2] = r[2];
            }
            else
            {
                if (abs(r[2]) < abs(res[2]))
                    res[2] = r[2];
                if (abs(r[0]) <= 2 && abs(r[0]) < abs(res[0]))
                    res[0] = r[0];
            }
            writefln("@vec=%s, vec2=%s, vinter=%s, r=%s, res=%s", vec, vec2, vinter, r, res);
        }

        if (abs(r[0]) <= 1 && abs(r[2]) <= 1)
            res[1] = 0;
    }

    if (res[0] == -4)
        res[0] = (intersections%2 == 0) ? -3 : 3;
    if (res[2] == -3)
        res[2] = (seg_intersections%2 == intersections%2) ? -3 : 3;
    if (abs(res[0]) <= 1 && abs(res[2]) <= 1 && abs(res[1]) == 3)
        res[1] = (intersections%2 == 0) ? -3 : 3;
    if (res[1] == -3 && (abs(res[0]) <= 1 && res[2] == 3 || abs(res[2]) <= 1 && res[0] == 3))
        res[1] = 3;
    if (res[1] == -3)
        writefln("intersections=%s, seg_intersections=%s, inter=%s", intersections, seg_intersections, inter);
    return res;
}

unittest
{
    float[2][] polygon = [[7.0f, 0.0f], [5.0f, 2.0f], [5.0f, 6.0f], [7.0f, 8.0f], [9.0f, 6.0f], [9.0f, 2.0f]];
    float[2][2] vec = [[0.0f, 4.0f], [2.0f, 4.0f]];
    float[2] inter;
    size_t side;
    byte[3] res = vector_in_polygon_position(vec, polygon, inter, side);
    byte[3] expected = [-3, 0, -3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[0.0f, 4.0f], [0.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, -3, -3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[4.0f, 4.5f], [6.0f, 7.5f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, 1, -3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[4.0f, 4.0f], [6.0f, 4.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, 0, 3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[4.0f, 4.0f], [5.0f, 4.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, -3, 0];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[4.0f, 4.0f], [5.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, 1, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 3.0f], [5.0f, 4.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [0, 0, 0];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);
    
    vec = [[5.0f, 3.0f], [5.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [0, 0, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);
    
    vec = [[5.0f, 3.0f], [5.0f, 7.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [0, -1, 2];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 2.0f], [5.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-1, 0, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 1.0f], [5.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-2, 1, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 1.0f], [5.0f, 7.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-2, 0, 2];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 7.0f], [5.0f, 1.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [2, 0, -2];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 1.0f], [5.0f, 4.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-2, 1, 0];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 2.0f], [5.0f, 6.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-1, 0, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 6.0f], [5.0f, 2.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [1, 0, -1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 2.0f], [9.0f, 2.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [1, 3, 1];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 2.0f], [7.0f, 2.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [1, 3, 3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[4.0f, 2.0f], [6.0f, 2.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [-3, 1, 3];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);

    vec = [[5.0f, 4.0f], [9.0f, 4.0f]];
    res = vector_in_polygon_position(vec, polygon, inter, side);
    expected = [0, -3, 0];
    writefln("res=%s, expected=%s", res, expected);
    assert(res == expected);
}

float[2][] join_polygons(float[2][] polygon1, float[2][] polygon2)
{
    writefln("join_polygons: %s & %s", polygon1, polygon2);
    float[2][] jp;

    for (size_t i=0; ; i++)
    {
        float[2] p1 = polygon1[i%$];
        float[2] p2 = polygon1[(i+1)%$];

        if (jp.length > 0 && p1 == jp[0]) break;

        float[2][2] vec = [p1, p2];
        float[2] inter;
        size_t side;
        byte[3] r = vector_in_polygon_position(vec, polygon2, inter, side);

        writefln("J+:+ jp.$=%s vec=%s, polygon=%s, inter=%s, side=%s, r=%s", jp.length, vec, polygon2, inter, side, r);
        if (r[0] == 3)
        {
            assert(jp.length == 0);
            if (i >= polygon1.length-1)
            {
                writefln("J: SWITCH ON END");
                i = -1;
                swap(polygon1, polygon2);
            }
            continue;
        }
        
        if (r[0] >= 0 && r[0] <= 2 && r[2] <= 0 && r[2] >= -2)
        {
            writefln("J: 0 SWITCH");
            i = side;
            swap(polygon1, polygon2);
            if (r[0] == 2 && r[1] == 0)
            {
                jp ~= p1;
                jp ~= inter;
            }
            continue;
        }

        if ( jp.length == 0 || point_to_vector_position(p1, [jp[$-1], p2]) != 0 )
            jp ~= p1;

        if (r[0] == -3 && r[1] != -3)
        {
            writefln("J: SWITCH");
            jp ~= inter;
            i = side;
            swap(polygon1, polygon2);
        }
        
        assert(jp.length <= 2*(polygon1.length + polygon2.length));
    }
    
    return jp;
}

unittest
{
    float[2][] polygon1 = [[0.0f, 3.0f], [5.0f, 3.0f], [5.0f, 2.0f], [0.0f, 2.0f]];
    float[2][] polygon2 = [[2.0f, 0.0f], [2.0f, 5.0f], [3.0f, 5.0f], [3.0f, 0.0f]];
    float[2][] joined = join_polygons(polygon1, polygon2);
    float[2][] expected = [[0.0f, 3.0f], [2.0f, 3.0f], [2.0f, 5.0f], [3.0f, 5.0f], [3.0f, 3.0f], [5.0f, 3.0f], [5.0f, 2.0f], [3.0f, 2.0f], [3.0f, 0.0f], [2.0f, 0.0f], [2.0f, 2.0f], [0.0f, 2.0f]];
    writefln("  joined=%s", joined);
    writefln("expected=%s", expected);
    assert(joined == expected);

    polygon1 = [[0.0f, 0.0f], [0.0f, 2.0f], [4.0f, 2.0f], [4.0f, 0.0f]];
    polygon2 = [[0.0f, 2.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 2.0f]];
    joined = join_polygons(polygon1, polygon2);
    expected = [[0.0f, 0.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 0.0f]];
    writefln("  joined=%s", joined);
    writefln("expected=%s", expected);
    assert(joined == expected);

    polygon1 = [[0.0f, 0.0f], [0.0f, 2.0f], [4.0f, 2.0f], [4.0f, 0.0f]];
    polygon2 = [[0.0f, 0.0f], [0.0f, 2.0f], [4.0f, 2.0f], [4.0f, 0.0f]];
    joined = join_polygons(polygon1, polygon2);
    expected = [[0.0f, 0.0f], [0.0f, 2.0f], [4.0f, 2.0f], [4.0f, 0.0f]];
    writefln("  joined=%s", joined);
    writefln("expected=%s", expected);
    assert(joined == expected);

    polygon1 = [[0.0f, 0.0f], [0.0f, 2.0f], [4.0f, 2.0f], [4.0f, 0.0f]];
    polygon2 = [[0.0f, 0.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 0.0f]];
    joined = join_polygons(polygon1, polygon2);
    expected = [[0.0f, 0.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 0.0f]];
    writefln("  joined=%s", joined);
    writefln("expected=%s", expected);
    assert(joined == expected);

    polygon1 = [[1.0f, 1.0f], [1.0f, 3.0f], [3.0f, 3.0f], [3.0f, 1.0f]];
    polygon2 = [[0.0f, 0.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 0.0f]];
    joined = join_polygons(polygon1, polygon2);
    expected = [[0.0f, 0.0f], [0.0f, 4.0f], [4.0f, 4.0f], [4.0f, 0.0f]];
    writefln("  joined=%s", joined);
    writefln("expected=%s", expected);
    assert(joined == expected);
}

byte line_segments_intersection(float[2][2] seg1, float[2][2] seg2, ref float[2] res)
{
    float[3] line_eq1;
    line_equation(seg1[0], seg1[1], line_eq1);

    float[3] line_eq2;
    line_equation(seg2[0], seg2[1], line_eq2);

    byte ri = intersection_by_equation(line_eq1, line_eq2, res);
    if ( ri == -1 )
    {
        return -4; // Лежат на параллельных прямых
    }
    else if ( ri == 0 )
    {
        if ( between2(seg2[0], seg1[0], seg1[1]) )
        {
            res = seg2[0];
            if ( between2(seg1[0], seg2[0], seg2[1]) && is_same_point(seg1[0], seg2[0]) )
            {
                if ( is_same_point(seg1[1], seg2[1]) )
                    return 5; // Отрезки совпадают
                else
                    return 6; // Лежат на одной прямой и касаются друг друга одной вершиной
            }
            else if ( between2(seg1[1], seg2[0], seg2[1]) && is_same_point(seg1[1], seg2[0]) )
            {
                if ( is_same_point(seg1[0], seg2[1]) )
                    return 5; // Отрезки совпадают
                else
                    return 6; // Лежат на одной прямой и касаются друг друга одной вершиной
            }

            return 2; // Лежат на одной прямой и пересекаются
        }
        else if ( between2(seg2[1], seg1[0], seg1[1]) )
        {
            res = seg2[1];
            if ( between2(seg1[0], seg2[0], seg2[1]) && is_same_point(seg1[0], seg2[1]) )
            {
                if ( is_same_point(seg1[1], seg2[0]) )
                    return 5; // Отрезки совпадают
                else
                    return 6; // Лежат на одной прямой и касаются друг друга одной вершиной
            }
            else if ( between2(seg1[1], seg2[0], seg2[1]) && is_same_point(seg1[1], seg2[1]) )
            {
                if ( is_same_point(seg1[0], seg2[0]) )
                    return 5; // Отрезки совпадают
                else
                    return 6; // Лежат на одной прямой и касаются друг друга одной вершиной
            }

            return 3; // Лежат на одной прямой и пересекаются
        }
        else if ( between2(seg1[0], seg2[0], seg2[1]) )
        {
            res = seg1[0];
            return 4; // Лежат на одной прямой и пересекаются
        }
        else return 0; // Лежат на одной прямой, но не пересекаются
    }

    bool i1 = between2(res, seg1[0], seg1[1]);
    bool i2 = between2(res, seg2[0], seg2[1]);

    if ( i1 && i2 )
    {
        return 1; // Пересекаются
    }

    if ( i1 ) return -3; // Не пересекаюся, хотя лежат на пересекающихся прямых
    else if ( !i2 ) return -4; // Не пересекаюся, хотя лежат на пересекающихся прямых

    if ( between2(seg1[1], seg1[0], res) )
        return -1; // Не пересекаюся, хотя луч AB пересекается

    return -2; // Не пересекаюся, хотя луч BA пересекается
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

bool is_same_point(float[2] a, float[2] b, float delta = 1e-5)
{
    return abs(a[0] - b[0]) < delta && abs(a[1] - b[1]) < delta;
}
