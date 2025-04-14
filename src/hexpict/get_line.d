module hexpict.get_line;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;
import std.bitmanip;
import bindbc.sdl;

import hexpict.h6p;
import hexpict.color;
import hexpict.colors;
import hexpict.hyperpixel;

Vertex[] get_line(Vertex v0, Vertex v1)
{
    Vertex[] vxs;
    int[][] neigh = new int[][](6, 2);

    float fx0, fy0;
    float fx1, fy1;

    to_float_coords(v0, fx0, fy0);
    to_float_coords(v1, fx1, fy1);

    float[3] eq;
    line_equation([fx0, fy0], [fx1, fy1], eq);

    writefln("v0 %s", v0);

    Vertex vc = v0;

    while (true)
    {
        byte choose_op(Vertex vc, out float mindist, out float mincdist)
        {
            byte op;

            mincdist = 1e10f;

            Vertex v = vc;
            foreach (byte side; 0..6)
            {
                //if (vc.p >= side*4 && (vc.p < (side+1)*4 || vc.p == ((side+1)*4)%24)) continue;

                v.p = cast(byte) (side*4);
                float sx1, sy1;
                to_float_coords(v, sx1, sy1);
                //writefln("side = %s, v = %s, sx1 = %s, sy1 = %s", side, v, sx1, sy1);

                v.p = ((side+1)*4)%24;
                float sx2, sy2;
                to_float_coords(v, sx2, sy2);
                //writefln("side = %s, v = %s, sx2 = %s, sy2 = %s", side, v, sx2, sy2);

                float[3] side_eq;
                line_equation([sx1, sy1], [sx2, sy2], side_eq);
                
                float[2] intersection;
                intersection_by_equation(eq, side_eq, intersection);

                bool between(float r, float a, float b)
                {
                    return b > a ? r >= a - 1e-1 && r <= b + 1e-1 : r >= b - 1e-1 && r <= a + 1e-1;
                }

                float dx = intersection[0] - fx1;
                float dy = intersection[1] - fy1;
                float cdist = hypot(dx, dy);
                //writefln("intersection %s, cdist = %s", intersection, cdist);
                //writefln("between1 %s, between2 %s", between(intersection[0], sx1, sx2), between(intersection[1], sy1, sy2));

                if (between(intersection[0], sx1, sx2) && between(intersection[1], sy1, sy2) && cdist < mincdist)
                {
                    mincdist = cdist;
                    writefln("side %s cdist %s, side_eq %s", side, cdist, [sx1, sy1, sx2, sy2]);

                    mindist = 1e10f;

                    foreach (byte p; 0..5)
                    {
                        v.p = (side*4 + p) % 24;
                        float px, py;
                        to_float_coords(v, px, py);

                        float dist = hypot(px - intersection[0], py - intersection[1]);
                        if (dist < mindist)
                        {
                            mindist = dist;
                            op = v.p;
                            //writefln("op %s, dist %s", op, dist);
                        }
                    }
                }
            }

            return op;
        }

        float mindist, mincdist;
        byte op = choose_op(vc, mindist, mincdist);
        //writefln("op = %s", op);

        byte pp1 = vc.p;
        byte pp2 = op;

        if (pp1 > pp2 && pp1 - pp2 < 12 || pp2 - pp1 > 12)
        {
            swap(pp1, pp2);
        }

        vxs ~= vc;
        if (vc.p != op)
            vxs ~= Vertex(vc.x, vc.y, op);

        if (vc.x == v1.x && vc.y == v1.y)
        {
            if (vc.p != v1.p)
                vxs ~= v1;
            break;
        }

        // @H6PNeighbours
        neighbours(vc.x, vc.y, neigh);

        //float fxp, fyp; //DEBUG
        //to_float_coords(xc, yc, op, fxp, fyp); //DEBUG

        if (op%4 == 0)
        {
            auto ng1 = neigh[(op/4)%6];
            Vertex nv1 = Vertex(ng1[0], ng1[1], ((op/4+2)%6*4)%24);

            float mindist1, mincdist1;
            byte op1 = choose_op(nv1, mindist1, mincdist1);

            auto ng2 = neigh[(op/4 + 1)%6];
            Vertex nv2 = Vertex(ng2[0], ng2[1], ((op/4+3)%6*4 + 4)%24);

            float mindist2, mincdist2;
            byte op2 = choose_op(nv2, mindist2, mincdist2);

            writefln("nv1 %s mindist1 %s mincdist1 %s op1 %s, nv2 %s mindist2 %s mincdist2 %s op2 %s",
                    nv1, mindist1, mincdist1, op1, nv2, mindist2, mincdist2, op2);

            if (nv1.x == v1.x && nv1.y == v1.y)
            {
                vc = nv1;
            }
            else if (nv2.x == v1.x && nv2.y == v1.y)
            {
                vc = nv2;
            }
            else if (abs(mindist1 - mindist2) < 1e-1 && abs(mincdist1 - mincdist2) < 1e-1)
            {
                float fx, fy;
                to_float_coords(Vertex(nv1.x, nv1.y, 24), fx, fy);

                float dist = signed_dist_point_to_line([fx, fy], eq);

                //writefln("signed dist for %s %s", Vertex(nv1.x, nv1.y, 24), dist);

                if (dist > 0.0f)
                {
                    vc = nv1;
                }
                else
                {
                    vc = nv2;
                }
            }
            else if (mincdist1 < mincdist2)
            {
                vc = nv1;
            }
            else
            {
                vc = nv2;
            }
        }
        else
        {
            auto n = neigh[(op/4 + 1)%6];
            vc = Vertex(n[0], n[1], ((op/4+3)%6*4 + 4-op%4)%24);
        }

        //writefln("vc %s", vc);

        //to_float_coords(xc, yc, nc, fxc, fyc); //DEBUG
        //assert(hypot(fxc-fxp, fyc-fyp) < 1e-2); //DEBUG
    }

    return vxs;
}

