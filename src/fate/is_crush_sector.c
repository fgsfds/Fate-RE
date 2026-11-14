/* Identified by the original is_crushsector diagnostic and initialization caller. */
#pragma pack(push, 1)
typedef struct { char preceding[34]; unsigned short lotag; char trailing[4]; } CrushSector;
#pragma pack(pop)
extern CrushSector crush_sectors[];
extern short crush_num_sectors;
extern char crush_invalid_sector_text[];
extern void crush_report_error(const char *);

int is_crush_sector(short sector)
{
    int result;
    unsigned short tag;
    if (sector < 0 || sector >= crush_num_sectors)
        crush_report_error(crush_invalid_sector_text);
    result = 0;
    tag = crush_sectors[sector].lotag;
    if (tag >= 100 && tag <= 114) result = 1;
    return result;
}
