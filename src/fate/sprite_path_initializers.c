#include "navdata.h"

#pragma pack(push, 1)
typedef struct {
    unsigned char *waypoints;
    unsigned char *sector_workspace;
    unsigned char *next_hops;
    short width;
    long ceiling_trace;
    long floor_trace;
} RouteRecord;
#pragma pack(pop)

typedef char RouteRecordSize[sizeof(RouteRecord) == 22 ? 1 : -1];

extern unsigned char board_path_sectors[];
#define BOARD_PATH_BYTES ((unsigned char *)&board_path_data)

#define WRITE_ROUTE_FIELDS(route, points, sectors, hops, matrix_width, ceiling) \
    (route)->waypoints = BOARD_PATH_BYTES + (points); \
    (route)->sector_workspace = board_path_sectors + (sectors); \
    (route)->next_hops = BOARD_PATH_BYTES + (hops); \
    (route)->width = (matrix_width); \
    (route)->ceiling_trace = (ceiling)

#define WRITE_ROUTE(route, points, sectors, hops, matrix_width, ceiling, floor) \
    WRITE_ROUTE_FIELDS(route, points, sectors, hops, matrix_width, ceiling); \
    (route)->floor_trace = (floor)

#if BOARD_INDEX < 15

enum {
    BOARD_PATH_STRIDE = 0x738,
    BOARD_SECTOR_STRIDE = 0x9c,
    ROUTE_DESCRIPTOR_OFFSET = 0x90
};

/* Each board uses the same nine route layouts with separate storage. */
#define INIT_ROUTE(slot, points, sectors, hops, matrix_width) \
    WRITE_ROUTE(&routes[slot], path_offset + (points), sector_offset + (sectors), \
                path_offset + (hops), matrix_width, -1000, 0)

#define INIT_BOARD(suffix, index) \
    void initialize_sprite_path_board##suffix(short *route_limit, \
                                               unsigned char **descriptors, \
                                               unsigned char **waypoints, \
                                               RouteRecord *routes) \
    { \
        enum { path_offset = (index) * BOARD_PATH_STRIDE }; \
        enum { sector_offset = (index) * BOARD_SECTOR_STRIDE }; \
        *route_limit = 8; \
        *descriptors = BOARD_PATH_BYTES + (path_offset + ROUTE_DESCRIPTOR_OFFSET); \
        *waypoints = BOARD_PATH_BYTES + path_offset; \
        INIT_ROUTE(0, 0x183, 0x86, 0x1db, 10); \
        INIT_ROUTE(1, 0x23f, 0x72, 0x297, 10); \
        INIT_ROUTE(2, 0x2fb, 0x66, 0x333,  6); \
        INIT_ROUTE(3, 0x357, 0x52, 0x3af, 10); \
        INIT_ROUTE(4, 0x413, 0x30, 0x4a3, 17); \
        INIT_ROUTE(5, 0x5c4, 0x26, 0x5f4,  5); \
        INIT_ROUTE(6, 0x60d, 0x1c, 0x63d,  5); \
        INIT_ROUTE(7, 0x656, 0x0e, 0x696,  7); \
        INIT_ROUTE(8, 0x6c7, 0x00, 0x707,  7); \
    }

/* Watcom can coalesce identical tails within a translation unit.
   Build each board independently to retain its original complete entry. */
#define DEFINE_BOARD(suffix, index) INIT_BOARD(suffix, index)
DEFINE_BOARD(BOARD_SUFFIX, BOARD_INDEX)

#elif BOARD_INDEX == 15

void initialize_sprite_path_board_16(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 14;
    *descriptors = BOARD_PATH_BYTES + 0x6d38;
    *waypoints = BOARD_PATH_BYTES + 0x6c48;
    WRITE_ROUTE(&routes[ 0], 0x6fdb, 0x9ac, 0x7003,  4,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0x7013, 0x996, 0x7073, 11,  -2000, 0);
    WRITE_ROUTE(&routes[ 2], 0x70ec, 0x984, 0x713c,  9,  -8000, 0);
    WRITE_ROUTE(&routes[ 3], 0x718d, 0x97a, 0x71bd,  5,  -3000, 0);
    WRITE_ROUTE(&routes[ 4], 0x71d6, 0x96c, 0x7216,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0x7247, 0x95e, 0x7287,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0x72b8, 0x958, 0x72d8,  3,  -3000, 0);
    WRITE_ROUTE(&routes[ 7], 0x72e1, 0x952, 0x7301,  3,  -3000, 0);
    WRITE_ROUTE(&routes[ 8], 0x730a, 0x942, 0x7352,  8,  -2000, 0);
    WRITE_ROUTE(&routes[ 9], 0x7392, 0x93e, 0x73aa,  2,  -1000, 0);
    WRITE_ROUTE(&routes[10], 0x73ae, 0x93a, 0x73c6,  2,  -1000, 0);
    WRITE_ROUTE(&routes[11], 0x73ca, 0x936, 0x73e2,  2,  -1000, 0);
    WRITE_ROUTE(&routes[12], 0x73e6, 0x930, 0x7406,  3,  -1000, 0);
    WRITE_ROUTE(&routes[13], 0x740f, 0x928, 0x7437,  4, -10000, 0);
    WRITE_ROUTE(&routes[14], 0x7447, 0x924, 0x745f,  2,  -1000, 0);
}

#elif BOARD_INDEX == 16

void initialize_sprite_path_board_17(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 8;
    *descriptors = BOARD_PATH_BYTES + 0x74f4;
    *waypoints = BOARD_PATH_BYTES + 0x7464;
    WRITE_ROUTE(&routes[ 0], 0x75e7, 0xa3a, 0x763f, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0x76a3, 0xa26, 0x76fb, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 2], 0x775f, 0xa1a, 0x7797,  6,  -1000, 0);
    WRITE_ROUTE(&routes[ 3], 0x77bb, 0xa06, 0x7813, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 4], 0x7877, 0x9e4, 0x7907, 17,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0x7a28, 0x9da, 0x7a58,  5,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0x7a71, 0x9d0, 0x7aa1,  5,  -1000, 0);
    WRITE_ROUTE(&routes[ 7], 0x7aba, 0x9c2, 0x7afa,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 8], 0x7b2b, 0x9b4, 0x7b6b,  7,  -1000, 0);
}

#elif BOARD_INDEX == 17

void initialize_sprite_path_board_18(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 23;
    *descriptors = BOARD_PATH_BYTES + 0x7d1c;
    *waypoints = BOARD_PATH_BYTES + 0x7b9c;
    WRITE_ROUTE(&routes[ 0], 0x83dc, 0xbc8, 0x843c, 11,  -3000, 0);
    WRITE_ROUTE(&routes[ 1], 0x84b5, 0xbb6, 0x8505,  9, -15000, 0);
    WRITE_ROUTE(&routes[ 2], 0x8556, 0xba6, 0x859e,  8,  -2000, 0);
    WRITE_ROUTE(&routes[ 3], 0x85de, 0xb94, 0x862e,  9,  -2000, 0);
    WRITE_ROUTE(&routes[ 4], 0x867f, 0xb8c, 0x86a7,  4,  -2000, 0);
    WRITE_ROUTE(&routes[ 5], 0x86b7, 0xb82, 0x86e7,  5,  -3000, 0);
    WRITE_ROUTE(&routes[ 6], 0x8700, 0xb78, 0x8730,  5,  -3000, 0);
    WRITE_ROUTE(&routes[ 7], 0x8749, 0xb56, 0x87d9, 17,  -3000, 0);
    WRITE_ROUTE(&routes[ 8], 0x88fa, 0xb4c, 0x892a,  5,  -4000, 0);
    WRITE_ROUTE(&routes[ 9], 0x8943, 0xb38, 0x899b, 10,  -3000, 0);
    WRITE_ROUTE(&routes[10], 0x89ff, 0xb2a, 0x8a3f,  7,  -3000, 0);
    WRITE_ROUTE(&routes[11], 0x8a70, 0xb1c, 0x8ab0,  7,  -3000, 0);
    WRITE_ROUTE(&routes[12], 0x8ae1, 0xafa, 0x8b71, 17,  -4000, 0);
    WRITE_ROUTE(&routes[13], 0x8c92, 0xae8, 0x8ce2,  9,  -4000, 0);
    WRITE_ROUTE(&routes[14], 0x8d33, 0xade, 0x8d63,  5,  -2000, 0);
    WRITE_ROUTE(&routes[15], 0x8d7c, 0xace, 0x8dc4,  8,  -3000, 0);
    WRITE_ROUTE(&routes[16], 0x8e04, 0xac2, 0x8e3c,  6,  -3000, 0);
    WRITE_ROUTE(&routes[17], 0x8e60, 0xab6, 0x8e98,  6,  -3000, 0);
    WRITE_ROUTE(&routes[18], 0x8ebc, 0xaa8, 0x8efc,  7,  -4000, 0);
    WRITE_ROUTE(&routes[19], 0x8f2d, 0xa9a, 0x8f6d,  7,  -4000, 0);
    WRITE_ROUTE(&routes[20], 0x8f9e, 0xa8c, 0x8fde,  7,  -3000, 0);
    WRITE_ROUTE(&routes[21], 0x900f, 0xa7a, 0x905f,  9,  -3000, 0);
    WRITE_ROUTE(&routes[22], 0x90b0, 0xa68, 0x9100,  9,  -3000, 0);
    WRITE_ROUTE(&routes[23], 0x9151, 0xa50, 0x91b9, 12,  -4000, 0);
}

#elif BOARD_INDEX == 18

void initialize_sprite_path_board_19(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 14;
    *descriptors = BOARD_PATH_BYTES + 0x933c;
    *waypoints = BOARD_PATH_BYTES + 0x924c;
    WRITE_ROUTE(&routes[ 0], 0x95df, 0xc7e, 0x9607,  4,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0x9617, 0xc60, 0x9697, 15,  -3000, 0);
    WRITE_ROUTE(&routes[ 2], 0x9778, 0xc4e, 0x97c8,  9,  -8000, 0);
    WRITE_ROUTE(&routes[ 3], 0x9819, 0xc36, 0x9881, 12,  -4000, 0);
    WRITE_ROUTE(&routes[ 4], 0x9911, 0xc28, 0x9951,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0x9982, 0xc1a, 0x99c2,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0x99f3, 0xc14, 0x9a13,  3,  -3000, 0);
    WRITE_ROUTE(&routes[ 7], 0x9a1c, 0xc0e, 0x9a3c,  3,  -3000, 0);
    WRITE_ROUTE(&routes[ 8], 0x9a45, 0xbfe, 0x9a8d,  8,  -2000, 0);
    WRITE_ROUTE(&routes[ 9], 0x9acd, 0xbfa, 0x9ae5,  2,  -1000, 0);
    WRITE_ROUTE(&routes[10], 0x9ae9, 0xbf6, 0x9b01,  2,  -1000, 0);
    WRITE_ROUTE(&routes[11], 0x9b05, 0xbf2, 0x9b1d,  2,  -1000, 0);
    WRITE_ROUTE(&routes[12], 0x9b21, 0xbec, 0x9b41,  3,  -1000, 0);
    WRITE_ROUTE(&routes[13], 0x9b4a, 0xbe4, 0x9b72,  4, -10000, 0);
    WRITE_ROUTE(&routes[14], 0x9b82, 0xbe0, 0x9b9a,  2,  -1000, 0);
}

#elif BOARD_INDEX == 19

void initialize_sprite_path_board_20(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 8;
    *descriptors = BOARD_PATH_BYTES + 0x9c30;
    *waypoints = BOARD_PATH_BYTES + 0x9ba0;
    WRITE_ROUTE(&routes[ 0], 0x9d23, 0xcf8, 0x9d7b, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0x9ddf, 0xcf2, 0x9dff,  3,  -1000, 0);
    WRITE_ROUTE(&routes[ 2], 0x9e08, 0xce4, 0x9e48,  7,  -2000, 0);
    WRITE_ROUTE(&routes[ 3], 0x9e79, 0xcd4, 0x9ec1,  8,  -1000, 0);
    WRITE_ROUTE(&routes[ 4], 0x9f01, 0xcc0, 0x9f59, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0x9fbd, 0xcb8, 0x9fe5,  4,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0x9ff5, 0xcaa, 0xa035,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 7], 0xa066, 0xc92, 0xa0ce, 12,  -1000, 0);
    WRITE_ROUTE(&routes[ 8], 0xa15e, 0xc88, 0xa18e,  5,  -1000, 0);
}

#elif BOARD_INDEX == 20

void initialize_sprite_path_board_21(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 15;
    *descriptors = BOARD_PATH_BYTES + 0xa2a8;
    *waypoints = BOARD_PATH_BYTES + 0xa1a8;
    WRITE_ROUTE(&routes[ 0], 0xa5a8, 0xe40, 0xa678, 25,  -4000, 0);
    WRITE_ROUTE(&routes[ 1], 0xa8e9, 0xe2a, 0xa949, 11,  -5000, 0);
    WRITE_ROUTE(&routes[ 2], 0xa9c2, 0xe22, 0xa9ea,  4,  -3000, 0);
    WRITE_ROUTE(&routes[ 3], 0xa9fa, 0xe10, 0xaa4a,  9,  -2000, 0);
    WRITE_ROUTE(&routes[ 4], 0xaa9b, 0xe02, 0xaadb,  7,  -3000, 0);
    WRITE_ROUTE(&routes[ 5], 0xab0c, 0xdf6, 0xab44,  6,  -6000, 0);
    WRITE_ROUTE(&routes[ 6], 0xab68, 0xde8, 0xaba8,  7,  -6000, 0);
    WRITE_ROUTE(&routes[ 7], 0xabd9, 0xdd2, 0xac39, 11,  -5000, 0);
    WRITE_ROUTE(&routes[ 8], 0xacb2, 0xdcc, 0xacd2,  3,  -5000, 0);
    WRITE_ROUTE(&routes[ 9], 0xacdb, 0xdc6, 0xacfb,  3,  -5000, 0);
    WRITE_ROUTE(&routes[10], 0xad04, 0xd9e, 0xadac, 20,  -5000, 0);
    WRITE_ROUTE(&routes[11], 0xaf3c, 0xd86, 0xafa4, 12, -15000, 0);
    WRITE_ROUTE(&routes[12], 0xb034, 0xd60, 0xb0d4, 19,  -6000, 0);
    WRITE_ROUTE(&routes[13], 0xb23d, 0xd54, 0xb275,  6,  -6000, 0);
    WRITE_ROUTE(&routes[14], 0xb299, 0xd3e, 0xb2f9, 11,  -2000, 0);
    WRITE_ROUTE(&routes[15], 0xb372, 0xd0c, 0xb442, 25,  -6000, 0);
}

#elif BOARD_INDEX == 21

void initialize_sprite_path_board_22(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 10;
    *descriptors = BOARD_PATH_BYTES + 0xb764;
    *waypoints = BOARD_PATH_BYTES + 0xb6b4;
    WRITE_ROUTE(&routes[ 0], 0xb8cf, 0xf1c, 0xb8e7,  2,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0xb8eb, 0xf06, 0xb94b, 11,  -1000, 0);
    WRITE_ROUTE(&routes[ 2], 0xb9c4, 0xf00, 0xb9e4,  3,  -1000, 0);
    WRITE_ROUTE(&routes[ 3], 0xb9ed, 0xed0, 0xbab5, 24,  -1000, 0);
    WRITE_ROUTE(&routes[ 4], 0xbcf5, 0xec4, 0xbd2d,  6,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0xbd51, 0xeba, 0xbd81,  5,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0xbd9a, 0xea4, 0xbdfa, 11,  -1000, 0);
    WRITE_ROUTE(&routes[ 7], 0xbe73, 0xe90, 0xbecb, 10,  -5000, 0);
    WRITE_ROUTE(&routes[ 8], 0xbf2f, 0xe8c, 0xbf47,  2,      0, 1000);
    WRITE_ROUTE(&routes[ 9], 0xbf4b, 0xe88, 0xbf63,  2,  -1000, 0);
    WRITE_ROUTE(&routes[10], 0xbf67, 0xe74, 0xbfbf, 10,  -1000, 0);
}

#elif BOARD_INDEX == 22

void initialize_sprite_path_board_23(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 8;
    *descriptors = BOARD_PATH_BYTES + 0xc0b4;
    *waypoints = BOARD_PATH_BYTES + 0xc024;
    WRITE_ROUTE(&routes[ 0], 0xc1a7, 0xf7e, 0xc1bf,  2,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0xc1c3, 0xf54, 0xc273, 21,  -1000, 0);
    WRITE_ROUTE(&routes[ 2], 0xc42c, 0xf4a, 0xc45c,  5,  -3000, 0);
    WRITE_ROUTE(&routes[ 3], 0xc475, 0xf46, 0xc48d,  2,  -1000, 0);
    WRITE_ROUTE(&routes[ 4], 0xc491, 0xf42, 0xc4a9,  2,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0xc4ad, 0xf3e, 0xc4c5,  2,  -3000, 0);
    WRITE_ROUTE(&routes[ 6], 0xc4c9, 0xf2a, 0xc521, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 7], 0xc585, 0xf26, 0xc59d,  2,  -3000, 0);
    WRITE_ROUTE(&routes[ 8], 0xc5a1, 0xf20, 0xc5c1,  3,  -3000, 0);
}

#elif BOARD_INDEX == 23

void initialize_sprite_path_board_24(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    *route_limit = 8;
    *descriptors = BOARD_PATH_BYTES + 0xc65c;
    *waypoints = BOARD_PATH_BYTES + 0xc5cc;
    WRITE_ROUTE(&routes[ 0], 0xc74f, 0x100a, 0xc7a7, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 1], 0xc80b, 0xff6, 0xc863, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 2], 0xc8c7, 0xfea, 0xc8ff,  6,  -1000, 0);
    WRITE_ROUTE(&routes[ 3], 0xc923, 0xfd6, 0xc97b, 10,  -1000, 0);
    WRITE_ROUTE(&routes[ 4], 0xc9df, 0xfb4, 0xca6f, 17,  -1000, 0);
    WRITE_ROUTE(&routes[ 5], 0xcb90, 0xfaa, 0xcbc0,  5,  -1000, 0);
    WRITE_ROUTE(&routes[ 6], 0xcbd9, 0xfa0, 0xcc09,  5,  -1000, 0);
    WRITE_ROUTE(&routes[ 7], 0xcc22, 0xf92, 0xcc62,  7,  -1000, 0);
    WRITE_ROUTE(&routes[ 8], 0xcc93, 0xf84, 0xccd3,  7,  -1000, 0);
}

#elif BOARD_INDEX == 24

extern RouteRecord *next_path_record(RouteRecord *);
#pragma aux next_path_record = parm [eax] value [eax] modify exact [];
extern RouteRecord *final_path_record(RouteRecord *);
#pragma aux final_path_record = parm [ecx] value [ecx] modify exact [];

void initialize_sprite_path_board_25(short *route_limit,
                                     unsigned char **descriptors,
                                     unsigned char **waypoints,
                                     RouteRecord *routes)
{
    RouteRecord *record;
    *route_limit = 10;
    *descriptors = BOARD_PATH_BYTES + 0xcdb4;
    *waypoints = BOARD_PATH_BYTES + 0xcd04;
    WRITE_ROUTE_FIELDS(routes, 0xcf1f, 0x10c2, 0xcfe7, 24, -500);
    record = next_path_record(&routes[1]);
    routes[0].floor_trace = 0;
    WRITE_ROUTE(record, 0xd227, 0x10ba, 0xd24f, 4, -7000, 0);
    record = next_path_record(&routes[2]);
    WRITE_ROUTE(record, 0xd25f, 0x10ac, 0xd29f, 7, -500, 0);
    record = next_path_record(&routes[3]);
    WRITE_ROUTE(record, 0xd2d0, 0x10a4, 0xd2f8, 4, -500, 0);
    record = next_path_record(&routes[4]);
    WRITE_ROUTE(record, 0xd308, 0x1070, 0xd3e0, 26, -500, 0);
    record = next_path_record(&routes[5]);
    WRITE_ROUTE(record, 0xd684, 0x106c, 0xd69c, 2, -7000, 0);
    record = next_path_record(&routes[6]);
    WRITE_ROUTE(record, 0xd6a0, 0x1062, 0xd6d0, 5, -7000, 0);
    record = next_path_record(&routes[7]);
    WRITE_ROUTE(record, 0xd6e9, 0x102e, 0xd7c1, 26, -500, 0);
    record = next_path_record(&routes[8]);
    WRITE_ROUTE(record, 0xda65, 0x102a, 0xda7d, 2, -7000, 0);
    record = next_path_record(&routes[9]);
    WRITE_ROUTE_FIELDS(record, 0xda81, 0x1024, 0xdaa1, 3, -7000);
    routes = final_path_record(&routes[10]);
    record->floor_trace = 0;
    WRITE_ROUTE(routes, 0xdaaa, 0x1020, 0xdac2, 2, -316584, 0);
}

#endif
