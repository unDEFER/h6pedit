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

module h6pedit.main_loop;

import h6pedit.global_state;
import h6pedit.tick;
import h6pedit.draw;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;

void main_loop()
{
    /* How many frames was skipped */
    uint skipframe;
    /* How long rendering was last frame */
    uint last_draw_time;
    uint[] times;
    uint prev_time;

    /* Sum of time which was taken by rendering */
    uint drawtime;
    /* Minumum time between 2 frames */
    uint min_frame_time = 2;
    /* Maximum skip frames running */
    uint max_skip_frames = 10;
    enum lock_fps = 60;

    /* Start time used in below scope(exit) to calculate avarage
       rendering time*/
    uint starttime=SDL_GetTicks();
    scope(exit)
    {
        uint endtime = SDL_GetTicks();
        writefln("FPS= %f, average draw time: %f ms",
            (cast(float)frame)*1000/(endtime-starttime),
            (cast(float)drawtime)/frame);
    }

    // @FPSStabilizer
    /* The main Idea of rendering process:
       Splitting the actions which must be done on frame on 2:
       1. Process events and make tick
       2. Draw Frame
       "Draw frame" maybe skipped to catch up real time,
       But "Make tick" can't be skipped
     */
    while(!finish)
    {
        uint time_before_frame=SDL_GetTicks();

        /* Process incoming events. */

        process_events();

        make_tick();
        stdout.flush();

        uint now=SDL_GetTicks();

        /* Draw the screen. */
        /* Don't skip frame when:
            1. Too much frame skipped
            2. The virtual time (time) too big (more than real time)
            3. Estimation time of the next frame less than minimum frame time  */
        if ( skipframe>=max_skip_frames || (time+250.0)>now ||
                (now+last_draw_time)<(time_before_frame+min_frame_time) )
        {
            uint time_before_draw=SDL_GetTicks();

            if (window_shown)
                draw_screen();

            last_draw_time=SDL_GetTicks()-time_before_draw;
            drawtime+=last_draw_time;

            frame++;
            skipframe=0;
        }
        else skipframe++;

        now=SDL_GetTicks();

        /* Calculate FPS */
        fps_frames++;
        fps_time += now - prev_time;
        times ~= now - prev_time;
        if (fps_frames > 100)
        {
            fps_time -= times[0];
            fps_frames--;
            times = times[1..$];
        }
        prev_time = now;

        /* Virtual time more real time? */
        if (time * 1000/lock_fps > now)
            SDL_Delay(time * 1000/lock_fps - now);
        else /* If time of frame too small */
            if ( (now - time_before_frame) < min_frame_time )
                SDL_Delay( min_frame_time - (now - time_before_frame) );

        /* Time in frames */
        time++;
    }
}

