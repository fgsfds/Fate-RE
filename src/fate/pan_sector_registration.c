extern short pan_sector_count, pan_sectors[];
extern char error_buffer[];
extern const char pan_overflow[];
extern int format_game_error(char *, const char *, ...);
#pragma aux format_game_error "sprintf_" parm caller [] modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

void register_pan_sector(short sector_num)
{
    long count = ++pan_sector_count;
    if (count > 63) {
        format_game_error(error_buffer, pan_overflow);
        report_game_error(error_buffer);
    }
    pan_sectors[pan_sector_count] = sector_num;
}
