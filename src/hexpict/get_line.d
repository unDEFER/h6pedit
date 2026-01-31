module hexpict.get_line;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;
import std.bitmanip;
import bindbc.sdl;

import hexpict.h6p;
import hexpict.common;
import hexpict.hyperpixel;

Vertex[] get_line(Vertex v0, Vertex v1, out float max_err)
{
    Vertex[] vxs;
    int[][] neigh = new int[][](6, 2);

    float fx0, fy0;
    float fx1, fy1;

    to_float_coords(v0, fx0, fy0);
    to_float_coords(v1, fx1, fy1);

    float[3] eq;
    line_equation([fx0, fy0], [fx1, fy1], eq);

    //writefln("v0 %s", v0);

    max_err = 0.0f;
    Vertex vc = v0;

    while (true)
    {
        Vertex choose_op(Vertex vc, out float mindist, out float mincdist)
        {
            byte op;

            mincdist = 1e10f;

            Vertex v = vc;
            Vertex vr = vc;
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
                    //"RU расстояние от пересечения со стороной гексагона до конечной точки
                    mincdist = cdist;
                    //writefln("side %s cdist %s, side_eq %s", side, cdist, [sx1, sy1, sx2, sy2]);

                    mindist = 1e10f;

                    static if (0)
                    {
                        foreach (byte p; 0..5)
                        {
                            v.p = (side*4 + p) % 24;
                            float px, py;
                            to_float_coords(v, px, py);

                            float dist = hypot(px - intersection[0], py - intersection[1]);
                            if (dist < mindist)
                            {
                                //"RU расстояние от пересечения до вершины гексагона
                                mindist = dist;
                                op = v.p;
                                //writefln("op %s, dist %s", op, dist);
                            }
                        }
                    }
                    else
                    {
                        v.p = (side*4 + 0) % 24;
                        float px0, py0;
                        to_float_coords(v, px0, py0);

                        v.p = (side*4 + 4) % 24;
                        float px1, py1;
                        to_float_coords(v, px1, py1);

                        float dist0 = hypot(px1 - px0, py1 - py0);
                        float dist1 = hypot(intersection[0] - px0, intersection[1] - py0);

                        float i0 = dist1/dist0;

                        float i_f = 4.0f*i0;
                        float d_f = 33.0f*i0;

                        float i_roundf = round(i_f);
                        float d_roundf = round(d_f);

                        float i_n = i_roundf/4.0f;
                        float d_n = d_roundf/33.0f;

                        float i_diff = abs(i_n - i0);
                        float d_diff = abs(d_n - i0);

                        float px, py;

                        px = px0 + i_n * (px1 - px0);
                        py = py0 + i_n * (py1 - py0);

                        byte op_ = (side*4 + cast(byte) i_roundf) % 24;
                        ubyte opext_;
                        if (i_diff < d_diff + 1e-5)
                        {
                            opext_ = op_;
                        }
                        else
                        {
                            px = px0 + d_n * (px1 - px0);
                            py = py0 + d_n * (py1 - py0);

                            opext_ = cast(byte)(60 + side*32 + cast(byte) d_roundf);
                        }

                        float dist = hypot(px - intersection[0], py - intersection[1]);
                        if (dist < mindist)
                        {
                            //"RU расстояние от пересечения до вершины гексагона
                            mindist = dist;
                            vr.p = op_;
                            vr.pext = opext_;
                            //writefln("op %s, dist %s", op, dist);
                        }
                    }                   
                }
            }

            return vr;
        }

        float mindist, mincdist;
        Vertex vp = choose_op(vc, mindist, mincdist);
        byte op = vp.p;
        if (mindist > max_err) max_err = mindist;
        //writefln("op = %s", op);

        byte pp1 = vc.p;
        byte pp2 = op;

        if (pp1 > pp2 && pp1 - pp2 < 12 || pp2 - pp1 > 12)
        {
            swap(pp1, pp2);
        }

        vxs ~= vc;

        if (vc.x == v1.x && vc.y == v1.y)
        {
            if (vc.p != v1.p)
                vxs ~= v1;
            break;
        }
        
        if (vc.p != op)
            vxs ~= vp;

        // @H6PNeighbours
        neighbours(vc.x, vc.y, neigh);

        //float fxp, fyp; //DEBUG
        //to_float_coords(xc, yc, op, fxp, fyp); //DEBUG

        if (op%4 == 0)
        {
            auto ng1 = neigh[(op/4)%6];
            Vertex nv1 = Vertex(ng1[0], ng1[1], ((op/4+2)%6*4)%24);

            float mindist1, mincdist1;
            Vertex vp1 = choose_op(nv1, mindist1, mincdist1);
            byte op1 = vp1.p;

            auto ng2 = neigh[(op/4 + 1)%6];
            Vertex nv2 = Vertex(ng2[0], ng2[1], ((op/4+3)%6*4 + 4)%24);

            float mindist2, mincdist2;
            Vertex vp2 = choose_op(nv2, mindist2, mincdist2);
            byte op2 = vp2.p;

            //writefln("nv1 %s mindist1 %s mincdist1 %s op1 %s, nv2 %s mindist2 %s mincdist2 %s op2 %s",
            //        nv1, mindist1, mincdist1, op1, nv2, mindist2, mincdist2, op2);

            if (nv1.x == v1.x && nv1.y == v1.y)
            {
                vc = nv1;
                if (mindist1 > max_err) max_err = mindist1;
            }
            else if (nv2.x == v1.x && nv2.y == v1.y)
            {
                vc = nv2;
                if (mindist2 > max_err) max_err = mindist2;
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
                    if (mindist1 > max_err) max_err = mindist1;
                }
                else
                {
                    vc = nv2;
                    if (mindist2 > max_err) max_err = mindist2;
                }
            }
            else if (mincdist1 < mincdist2)
            {
                vc = nv1;
                if (mindist1 > max_err) max_err = mindist1;
            }
            else
            {
                vc = nv2;
                if (mindist2 > max_err) max_err = mindist2;
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

