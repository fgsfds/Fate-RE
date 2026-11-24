#include "saveio.h"

/* One-byte transfers retain their shared size/count value in EBX. */

unsigned char *save_read_bytes_0(RuntimeStream *);
#pragma aux save_read_bytes_0 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_bytes_0(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_read, 0x7def9); /* input_forward */
    SAVE_BYTE(save_io_read, 0x7def4); /* previous_local_input */
    SAVE_BYTE(save_io_read, 0x7defa); /* input_strafe */
    SAVE_BYTE(save_io_read, 0x7def5); /* board_state_7def5 */
    SAVE_BYTE(save_io_read, 0x7defb); /* input_turn */
    SAVE_BYTE(save_io_read, 0x7def6); /* board_state_7def6 */
    return save_data_image+0x7def6+result;
}

unsigned char *save_read_bytes_1(RuntimeStream *);
#pragma aux save_read_bytes_1 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_bytes_1(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_read, 0x2891da); /* engine_2891da */
    return save_data_image+0x2891da+result;
}

unsigned char *save_read_bytes_2(RuntimeStream *);
#pragma aux save_read_bytes_2 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_bytes_2(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_read, 0x7f87d); /* loaded_level */
    SAVE_BYTE(save_io_read, 0x7f87e); /* current_board */
    SAVE_BYTE(save_io_read, 0x2040); /* destination_level */
    return save_data_image+0x2040+result;
}

unsigned char *save_read_bytes_3(RuntimeStream *);
#pragma aux save_read_bytes_3 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_bytes_3(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_read, 0x3be5); /* cursor_mode */
    return save_data_image+0x3be5+result;
}

unsigned char *save_write_bytes_0(RuntimeStream *);
#pragma aux save_write_bytes_0 parm [edi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_write_bytes_0(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_write, 0x7def9); /* input_forward */
    SAVE_BYTE(save_io_write, 0x7def4); /* previous_local_input */
    SAVE_BYTE(save_io_write, 0x7defa); /* input_strafe */
    SAVE_BYTE(save_io_write, 0x7def5); /* board_state_7def5 */
    SAVE_BYTE(save_io_write, 0x7defb); /* input_turn */
    SAVE_BYTE(save_io_write, 0x7def6); /* board_state_7def6 */
    return save_data_image+0x7def6+result;
}

unsigned char *save_write_bytes_1(RuntimeStream *);
#pragma aux save_write_bytes_1 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_write_bytes_1(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_write, 0x2891da); /* engine_2891da */
    return save_data_image+0x2891da+result;
}

unsigned char *save_write_bytes_2(RuntimeStream *);
#pragma aux save_write_bytes_2 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_write_bytes_2(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_write, 0x7f87d); /* loaded_level */
    SAVE_BYTE(save_io_write, 0x7f87e); /* current_board */
    SAVE_BYTE(save_io_write, 0x2040); /* destination_level */
    return save_data_image+0x2040+result;
}

unsigned char *save_write_bytes_3(RuntimeStream *);
#pragma aux save_write_bytes_3 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_write_bytes_3(RuntimeStream *stream)
{
    unsigned result;
    SAVE_BYTE(save_io_write, 0x3be5); /* cursor_mode */
    return save_data_image+0x3be5+result;
}
