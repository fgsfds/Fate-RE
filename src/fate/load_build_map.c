/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
typedef struct { unsigned char bytes[40]; } MapSector;
typedef struct { unsigned char bytes[32]; } MapWall;
typedef struct {
    unsigned char prefix[24];
    short sector, status;
    unsigned char suffix[16];
} MapSprite;
extern long map_version;
extern short numsectors, numwalls;
extern MapSector sector[];
extern MapWall wall[];
extern MapSprite sprite[];
extern unsigned char show_2d_sectors[128], show_2d_walls[1024], sprite_visibility[512];

extern int read_mode_in_edx(int);
#pragma aux read_mode_in_edx = parm [edx] value [edx] modify exact [];
extern void z_stays_in_ecx(long *);
#pragma aux z_stays_in_ecx = "" parm [ecx] modify exact [];
extern int kopen4load(const char *, int);
#pragma aux kopen4load parm [eax] [edx] modify exact [eax ebx ecx edx];
extern int kread(int, void *, unsigned);
#pragma aux kread parm [eax] [edx] [ebx] modify exact [eax ebx];
extern void kclose(int);
#pragma aux kclose parm [eax] modify exact [eax];
extern void initspritelists(void);
#pragma aux initspritelists modify exact [eax];
extern int insertsprite(int, int);
#pragma aux insertsprite parm [eax] [edx] modify exact [eax];
extern void updatesector(long, long, short *);
#pragma aux updatesector parm [eax] [edx] [ebx] modify exact [eax];

/* Supply bitmap addresses and dword counts from C for the original fills. */
extern void clear_sector_map_bits(void *, unsigned, unsigned);
#pragma aux clear_sector_map_bits = "rep stosd" parm [edi] [ecx] [eax] modify exact [eax ecx edi];
extern void clear_sprite_map_bits(void *, unsigned);
#pragma aux clear_sprite_map_bits = "mov ebx,4" "rep stosd" parm [edi] [ecx] modify exact [ebx ecx edi];
extern void clear_wall_map_bits(void *, unsigned);
#pragma aux clear_wall_map_bits = "mov edx,[esp]" "rep stosd" parm [edi] [ecx] modify exact [eax edx ecx edi];
extern void release_load_map(void);
#pragma aux release_load_map = "add esp,16" modify exact [];
extern int finish_load_map(int);
#pragma aux finish_load_map aborts parm [eax] modify exact [eax];
extern int load_result_in_eax(int);
#pragma aux load_result_in_eax = parm [eax] value [eax] modify exact [];
extern int header_read_width(void);
#pragma aux header_read_width = value [ebx] modify exact [];
extern long *read_origin_x(void);
#pragma aux read_origin_x = value [edx] modify exact [];
extern int load_build_map(const char *, long *, long *, long *, short *, short *);
#pragma aux load_build_map parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

int load_build_map(const char *name, long *x, long *y, long *z, short *angle, short *start_sector)
{
    int result, raw_fd;
    short fd;
    struct {
        long *saved_z;
        int saved_fd;
        short sprite_count;
        short pad;
    } frame;
    short index;

    frame.saved_z = z;
    z_stays_in_ecx(z);
    raw_fd = kopen4load(name, read_mode_in_edx(0));
    fd = (short)raw_fd;
    frame.saved_fd = raw_fd;
    if (fd == -1) {
        map_version = 7;
        result = load_result_in_eax(fd);
        goto done;
    }
    kread(fd, &map_version, sizeof map_version);
    if (map_version != 7) {
        result = load_result_in_eax(-1);
        goto done;
    }

    initspritelists();
    clear_sector_map_bits(show_2d_sectors, sizeof show_2d_sectors / sizeof(unsigned long), 0);
    clear_sprite_map_bits(sprite_visibility, sizeof sprite_visibility / sizeof(unsigned long));
    clear_wall_map_bits(show_2d_walls, sizeof show_2d_walls / sizeof(unsigned long));
    kread(fd, read_origin_x(), header_read_width());
    kread(fd, y, sizeof *y);
    kread(fd, frame.saved_z, sizeof *z);
    kread(fd, angle, sizeof *angle);
    kread(fd, start_sector, sizeof *start_sector);
    kread(fd, &numsectors, sizeof numsectors);
    kread(fd, sector, (unsigned)numsectors * sizeof *sector);
    kread(fd, &numwalls, sizeof numwalls);
    kread(fd, wall, (unsigned)numwalls * sizeof *wall);
    kread(fd, (void *)&frame.sprite_count, sizeof frame.sprite_count);
    kread(fd, sprite, (unsigned)frame.sprite_count * sizeof *sprite);
    for (index = 0; index < frame.sprite_count; ++index)
        insertsprite(sprite[index].sector, sprite[index].status);
    updatesector(*x, *y, start_sector);
    kclose((short)frame.saved_fd);
    result = load_result_in_eax(0);
done:
    release_load_map();
    return finish_load_map(result);
}
