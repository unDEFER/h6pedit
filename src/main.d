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

// @Story

module main;

import std.stdio;
import std.path;
import std.array;
import std.conv;
import std.file;

import hexpict.color;
import h6pedit.tiles;
import h6pedit.global_state;
import h6pedit.main_loop;

/*
 * Prints usage info. We are using it in main() function
 * when see errors in passed to the program arguments.
 */
private void usage()
{
    writeln("Usage: h6pedit <file1> [<file2> ...]");
    writeln("   where <file> is [options] <filename.h6p>");
    writeln("   Options:");
    writeln("   -n, --new <Width>x<Height> -- new h6p file with specified size");
    writeln("   -r, --ref <Picture>        -- reference image");
    writeln("   -c, --center <X>x<Y>       -- center point on reference image");
    writeln("   -p, --point <Width>        -- point size on reference image");
}

/*
 * Main function gets arguments of command line.
 * See description of arguments in the usage() above.
 */
int main(string[] args)
{
    if (args.length < 2)
    {
        usage();
        return 1;
    }

    string h6pname, refname;
    int nw, nh;
    int cx, cy;
    int pw = 10;
    nw = nh = -1;
    bool options;

    load_tiles();

    for (int i = 1; i < args.length; i++)
    {
        switch (args[i])
        {
            case "-n":
            case "--new":
                i++;
                if (i >= args.length)
                {
                    writefln("No arguments after -n|--new");
                    usage();
                    return 1;
                }
                string newsize = args[i];
                auto ss = newsize.split("x");
                if (ss.length != 2)
                {
                    writefln("Argument after -n|--new must have format <number>x<number>, but specified `%s`", newsize);
                    usage();
                    return 1;
                }

                nw = ss[0].to!int;
                nh = ss[1].to!int;

                options = true;
                break;

            case "-r":
            case "--ref":
                i++;
                if (i >= args.length)
                {
                    writefln("No arguments after -r|--ref");
                    usage();
                    return 1;
                }
                refname = args[i];

                options = true;
                break;

            case "-c":
            case "--center":
                i++;
                if (i >= args.length)
                {
                    writefln("No arguments after -c|--center");
                    usage();
                    return 1;
                }
                string center = args[i];
                auto cc = center.split("x");
                if (cc.length != 2)
                {
                    writefln("Argument after -c|--center must have format <number>x<number>, but specified `%s`", center);
                    usage();
                    return 1;
                }

                cx = cc[0].to!int;
                cy = cc[1].to!int;

                options = true;
                break;

            case "-p":
            case "--point":
                i++;
                if (i >= args.length)
                {
                    writefln("No arguments after -p|--point");
                    usage();
                    return 1;
                }
                pw = args[i].to!int;

                options = true;
                break;

            default:
                h6pname = args[i];

                if (nw > 0 && nh > 0)
                {
                    if ( exists(h6pname) )
                    {
                        writefln("File `%s` already exists", h6pname);
                        return 1;
                    }

                    new_picture(nw, nh, h6pname, refname, cx, cy, pw);
                }
                else
                {
                    open_picture(h6pname, refname, cx, cy, pw);
                }

                refname = null;
                h6pname = null;
                nw = nh = -1;
                cx = cy = 0;
                pw = 10;
                options = false;

                break;
        }
    }

    if (options)
    {
        writefln("Options without argument-filename", h6pname);
        usage();
        return 1;
    }

    import hexpict.get_line;
    import hexpict.hyperpixel;
    writefln("%s", get_line(Vertex(1,1,60), Vertex(10,10,60)));

    h6pedit.main_loop.main_loop();
    return 0;
}

