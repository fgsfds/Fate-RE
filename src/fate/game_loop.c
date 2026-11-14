/* Frame-loop orchestration at loaded0x3b496; subsystem roles remain provisional. */
#pragma pack(push, 1)
typedef struct {
    short wallptr, wallnum;
    char remainder[36];
} LoopSector;
typedef struct {
    long x, y;
    short point2, nextwall, nextsector;
    char remainder[18];
} LoopWall;
#pragma pack(pop)
extern char loop_running, loop_exit;
extern short loop_candidate, loop_request_a, loop_request_b, loop_candidate_b;
extern short loop_toggle_a, loop_toggle_b, loop_skip_neighbors, loop_sector, loop_scale;
extern long loop_last_tick, loop_queue_read, loop_queue_write, loop_updates, main_state_b;
extern volatile long totalclock;
extern LoopSector sector[];
extern LoopWall wall[];
extern void loop_poll(void), loop_process(void), loop_special(void);
extern void loop_mark(long, short), loop_render(void), loop_timing(long, long), loop_finish(void);

void game_loop(void)
{
    long i;
    short start, end;
    LoopWall *cursor;
    loop_running = 1;
    while (!loop_exit) {
        loop_candidate = -1;
        loop_request_a = 0;
        loop_request_b = 0;
        loop_candidate_b = 0;
        if (loop_toggle_a) {
            if (!loop_toggle_b) loop_toggle_b = 1;
            else { loop_toggle_a = 0; loop_toggle_b = 0; }
        }
        while (totalclock - loop_last_tick < 2) ;
        loop_last_tick = totalclock;
        loop_poll();
        loop_updates = 0;
        while (loop_queue_read != loop_queue_write) {
            loop_updates++;
            loop_process();
        }
        if ((long)loop_request_b == 3) loop_special();
        if (!loop_skip_neighbors) {
            loop_mark(0, loop_sector);
            start = sector[loop_sector].wallptr;
            end = start + sector[loop_sector].wallnum;
            for (i = start, cursor = &wall[i]; i < end; i++, cursor++)
                if (cursor->nextsector >= 0) loop_mark(0, cursor->nextsector);
        }
        loop_render();
        loop_timing((long)loop_scale, (totalclock-main_state_b)*21845);
        loop_finish();
    }
    loop_running = 0;
}
