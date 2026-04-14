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

    writefln("get_line: v0 %s, v1 %s", v0, v1);

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
                    writefln("side %s cdist %s, side_eq %s", side, cdist, [sx1, sy1, sx2, sy2]);

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
                        float dist0 = hypot(sx2 - sx1, sy2 - sy1);
                        float dist1 = hypot(intersection[0] - sx1, intersection[1] - sy1);

                        float i0 = dist1/dist0;

                        float i_f = 4.0f*i0;
                        float d_f = 32.0f*i0;

                        float i_roundf = round(i_f);
                        float d_roundf = round(d_f);

                        float i_n = i_roundf/4.0f;
                        float d_n = d_roundf/32.0f;

                        float i_diff = abs(i_n - i0);
                        float d_diff = abs(d_n - i0);

                        float px, py;

                        px = sx1 + i_n * (sx2 - sx1);
                        py = sy1 + i_n * (sy2 - sy1);

                        byte op_ = (side*4 + cast(byte) i_roundf) % 24;
                        ubyte opext_;
                        if (i_diff < d_diff + 1e-5)
                        {
                            opext_ = op_;
                            writefln("get_line: opext_ = op_ = %s", op_);
                        }
                        else
                        {
                            px = sx1 + d_n * (sx2 - sx1);
                            py = sy1 + d_n * (sy2 - sy1);
                            byte d_round = cast(byte) d_roundf;
                            byte q = (d_round/8)%4;
                            byte k = d_round%8;
                            assert(k != 0);

                            opext_ = cast(byte)(61 + side*28 + 7*q + k-1);
                            writefln("get_line: opext_=%s, op_=%s, to_point24(opext_)=%s", opext_, op_, to_point24(opext_));
                            //assert(abs(to_point24(opext_) - op_) <= 1);
                        }

                        float dist = hypot(px - intersection[0], py - intersection[1]);

                        if (dist < 1e-2)
                        {
                            //"RU расстояние от пересечения до вершины гексагона
                            mindist = dist;
                            mincdist = cdist;
                            vr.p = op_;
                            vr.pext = opext_;
                            writefln("get_line: [%s, %s], intersection %s", px, py, intersection);
                            writefln("get_line: op_ %s, dist %s", op_, dist);
                        }
                    }                   
                }
            }

            return vr;
        }

        float mindist, mincdist;
        Vertex vp = choose_op(vc, mindist, mincdist);
        //writefln("vp = %s", vp);

        vxs ~= vc;

        if (vc.x == v1.x && vc.y == v1.y)
        {
            if (vc.p != v1.p)
                vxs ~= v1;
            break;
        }
        
        if (vc.p != vp.p)
            vxs ~= vp;

        // @H6PNeighbours
        neighbours(vc.x, vc.y, neigh);

        //float fxp, fyp; //DEBUG
        //to_float_coords(xc, yc, op, fxp, fyp); //DEBUG

        if (vp.pext < 24 && vp.p%4 == 0)
        {
            auto ng1 = neigh[(vp.p/4)%6];
            Vertex nv1 = Vertex(ng1[0], ng1[1], ((vp.p/4+2)%6*4)%24);

            float mindist1, mincdist1;
            Vertex vp1 = choose_op(nv1, mindist1, mincdist1);
            byte op1 = vp1.p;

            auto ng2 = neigh[(vp.p/4 + 1)%6];
            Vertex nv2 = Vertex(ng2[0], ng2[1], ((vp.p/4+3)%6*4 + 4)%24);

            float mindist2, mincdist2;
            Vertex vp2 = choose_op(nv2, mindist2, mincdist2);
            byte op2 = vp2.p;

            //writefln("nv1 %s mindist1 %s mincdist1 %s op1 %s, nv2 %s mindist2 %s mincdist2 %s op2 %s",
            //        nv1, mindist1, mincdist1, op1, nv2, mindist2, mincdist2, op2);

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
            auto n24 = neigh[(vp.p/4 + 1)%6];
            auto n = (vp.pext < 24 ? n24 : neigh[((vp.pext-61)/28 + 1)%6]);
            ubyte op24 = cast(ubyte) (((vp.p/4+3)%6*4 + 4-vp.p%4)%24);
            ubyte op = cast(ubyte) (vp.pext < 24 ? op24 : 61 + (((vp.pext-61)/28+3)%6*28 + 27-(vp.pext-61)%28)%(28*6));
            writefln("get_line: vp %s, n24=%s, n=%s, op24=%s, op=%s", vp, n24, n, op24, op);
            vc = (vp.pext < 24 ? Vertex(n24[0], n24[1], op24, op24) : Vertex(n[0], n[1], to_point24(op), op));
        }

        writefln("vc %s", vc);

        //to_float_coords(xc, yc, nc, fxc, fyc); //DEBUG
        //assert(hypot(fxc-fxp, fyc-fyp) < 1e-2); //DEBUG
    }

    return vxs;
}

