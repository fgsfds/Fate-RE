/* The selected body hands a sector word to AX and returns its row byte
 * offset in EBP. Level rows 0..25 and columns 0..31 refer to the actual table.
 * Empty auxiliaries express register handoffs without emitted instructions. */
typedef struct { short value, active; } SectorWord;
typedef char SectorWordWidth[sizeof(SectorWord) == 4 ? 1 : -1];
extern SectorWord level_sector_ids[][32];
extern int signed_column(int);
#pragma aux signed_column = "" parm [ecx] value [ecx] modify exact [];
extern int column_index(int);
#pragma aux column_index = "" parm [eax] value [eax] modify exact [];
extern void sector_word(short);
#pragma aux sector_word = "" parm [ax] modify exact [eax];

unsigned gameplay_row_word(unsigned, short);
#pragma aux gameplay_row_word parm [edx] [esi] value [ebp] modify exact [eax ecx];
unsigned gameplay_row_word(unsigned row, short column)
{
    unsigned offset = row * 128u;
    int index = signed_column(column);
    sector_word(level_sector_ids[row][column_index(index)].value);
    return offset;
}
