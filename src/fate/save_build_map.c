/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
typedef struct { unsigned char bytes[40]; } MapSector;
typedef struct { unsigned char bytes[32]; } MapWall;
typedef struct { unsigned char bytes[44]; } MapSprite;

enum { MAP_OPEN_FLAGS = 0x261, MAP_WRITE_MODE = 0x80 };
#define MAX_STATUS 1024
extern long map_version;
extern short numsectors, numwalls, headspritestat[], nextspritestat[];
extern MapSector sector[];
extern MapWall wall[];
extern MapSprite sprite[];
extern int open(const char *, int, ...);
#pragma aux open parm caller [] modify exact [eax ebx ecx edx];
extern int write(int, const void *, unsigned);
#pragma aux write parm [eax] [edx] [ebx] modify exact [eax ebx];
extern int close(int);
#pragma aux close parm [eax] modify exact [eax];

/* Retain the shared wallscan return frame and its two scratch slots. */
extern void begin_map_save(const long *, const long *, const long *);
#pragma aux begin_map_save = "push esi" "push edi" "push ebp" "sub esp,8" \
    "mov ebp,edx" "mov [esp],ebx" "mov edi,ecx" parm [edx] [ebx] [ecx] modify exact [edi];
extern int keep_file_descriptor(int);
#pragma aux keep_file_descriptor = "movsx ecx,ax" "mov esi,eax" parm [eax] value [ecx] modify exact [ecx esi];
extern int descriptor_in_ecx(void);
#pragma aux descriptor_in_ecx = value [ecx] modify exact [];
extern short descriptor_in_si(void);
#pragma aux descriptor_in_si = value [si] modify exact [];
extern const long *map_origin_x(void);
#pragma aux map_origin_x = value [ebp] modify exact [];
/* The size arguments keep EBX loaded before each stack-relative source. */
extern const long *map_origin_y(unsigned);
#pragma aux map_origin_y = "mov edx,[esp]" parm [ebx] value [edx] modify exact [edx];
extern const long *map_origin_z(void);
#pragma aux map_origin_z = value [edi] modify exact [];
extern const short *map_angle(unsigned);
#pragma aux map_angle = "mov edx,[esp+18h]" parm [ebx] value [edx] modify exact [edx];
extern const short *map_start_sector(unsigned);
#pragma aux map_start_sector = "mov edx,[esp+1ch]" parm [ebx] value [edx] modify exact [edx];
extern void reset_sprite_count(void);
#pragma aux reset_sprite_count = "xor edx,edx" "xor edi,edi" "mov [esp+4],edx" modify exact [edx edi];
extern void reset_saved_status(void);
#pragma aux reset_saved_status = "xor edi,edi" modify exact [edi];
/* Watcom keeps the 16-bit status cursor in DI across file writes. */
extern short saved_status_in_di(short);
#pragma aux saved_status_in_di = "" parm [di] value [di] modify exact [];
extern short current_saved_status(void);
#pragma aux current_saved_status = value [di] modify exact [];
extern int saved_status_in_eax(int);
#pragma aux saved_status_in_eax = "" parm [eax] value [eax] modify exact [];
extern int current_counted_sprite(int);
#pragma aux current_counted_sprite = parm [eax] value [eax] modify exact [];
extern short next_counted_sprite(int);
#pragma aux next_counted_sprite = "mov ebx,[esp+4]" "inc ebx" "mov ax,nextspritestat[eax*2]" "mov [esp+4],ebx" \
    parm [eax] value [ax] modify exact [eax ebx];
extern short sprite_in_ax(short);
#pragma aux sprite_in_ax = parm [ax] value [ax] modify exact [];
extern int sprite_in_ecx(int);
#pragma aux sprite_in_ecx = parm [ecx] value [ecx] modify exact [];
extern const void *sprite_count_field(unsigned);
#pragma aux sprite_count_field = "lea edx,[esp+4]" parm [ebx] value [edx] modify exact [edx];

extern void release_map_save_frame(void);
#pragma aux release_map_save_frame = "add esp,8" modify exact [];
extern int finish_save_map(int);
#pragma aux finish_save_map aborts parm [eax] modify exact [eax];
extern int map_result_in_eax(int);
#pragma aux map_result_in_eax = parm [eax] value [eax] modify exact [];

extern int save_map_failure(int);
#pragma aux save_map_failure = "mov eax,ecx" parm [ecx] value [eax] modify exact [eax];

extern int save_build_map(const char *, const long *, const long *, const long *, const short *, const short *);
#pragma aux save_build_map parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx esi edi];

int save_build_map(const char *name, const long *x, const long *y, const long *z,
                   const short *angle, const short *start_sector)
{
    int fd, result, index, status;
    short item;

    begin_map_save(x, y, z);
    fd = keep_file_descriptor(open(name, MAP_OPEN_FLAGS, MAP_WRITE_MODE));
    if (fd != -1)
        goto header;
    result = save_map_failure(fd);
    goto done;
header:

    write(descriptor_in_ecx(), &map_version, sizeof map_version);
    write(descriptor_in_ecx(), map_origin_x(), sizeof *x);
    write(descriptor_in_ecx(), map_origin_y(4), sizeof *y);
    write(descriptor_in_ecx(), map_origin_z(), sizeof *z);
    write(descriptor_in_ecx(), map_angle(2), sizeof *angle);
    write(descriptor_in_ecx(), map_start_sector(2), sizeof *start_sector);
    write(descriptor_in_ecx(), &numsectors, sizeof numsectors);
    write(descriptor_in_ecx(), sector, (unsigned)numsectors * sizeof *sector);
    write(descriptor_in_ecx(), &numwalls, sizeof numwalls);
    write(descriptor_in_ecx(), wall, (unsigned)numwalls * sizeof *wall);

    /* Count and write sprites in the engine's status-list order. */
    reset_sprite_count();
    goto count_status;
count_head:
    item = sprite_in_ax(headspritestat[status]);
count_sprite:
    index = current_counted_sprite(item);
    if (index == -1)
        goto count_next;
    item = next_counted_sprite(index);
    goto count_sprite;
count_next:
    saved_status_in_di(current_saved_status() + 1);
count_status:
    status = saved_status_in_eax(current_saved_status());
    if (status < MAX_STATUS)
        goto count_head;
    write(descriptor_in_si(), sprite_count_field(2), 2);

    reset_saved_status();
    goto save_status;
save_head:
    item = sprite_in_ax(headspritestat[status]);
save_sprite:
    index = sprite_in_ecx(item);
    if (index == -1)
        goto save_next;
    write(descriptor_in_si(), &sprite[index], sizeof *sprite);
    item = sprite_in_ax(nextspritestat[index]);
    goto save_sprite;
save_next:
    saved_status_in_di(current_saved_status() + 1);
save_status:
    status = saved_status_in_eax(current_saved_status());
    if (status < MAX_STATUS)
        goto save_head;
    close(descriptor_in_si());
    result = map_result_in_eax(0);
done:
    release_map_save_frame();
    return finish_save_map(result);
}
