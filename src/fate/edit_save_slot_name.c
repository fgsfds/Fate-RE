#include "menurec.h"

extern char save_slot_name_format[], save_name_key_ascii[];
extern MenuRecord *save_slot_menu_rows[];
extern long editing_save_slot;
extern unsigned char editing_save_slot_name;
extern char *strcpy(char *destination, const char *source);
extern void *memset(void *destination, int value, unsigned length);
extern int sprintf(char *destination, const char *format, ...);
extern void trim_and_uppercase(char *text);
extern void presentation_reset(void);
extern int presentation_input(void);
extern void draw_menu_frame(unsigned selection, long count, short background, const char *title,
                            MenuRecord **rows);
extern int toupper(int character);

/* The original ABI keeps two twenty-byte name buffers and the background on the stack. */
extern void copy_original_slot_name(int background, const char *title);
#pragma aux copy_original_slot_name = \
    "push ebx" "push ecx" "push esi" "push edi" "push ebp" "sub esp,40" "push eax" "mov ebp,edx" \
    "mov eax,[editing_save_slot]" "mov eax,[eax*4+save_slot_menu_rows]" "mov edx,[eax+3]" \
    "lea eax,[esp+18h]" "call strcpy" parm [eax] [edx] modify exact [eax edx];
extern void initialize_edited_name(void);
#pragma aux initialize_edited_name = \
    "lea edx,[esp+18h]" "lea eax,[esp+4]" "call strcpy" "lea eax,[esp+4]" "mov ebx,17" \
    "call trim_and_uppercase" "xor edx,edx" "lea eax,[esp+4]" "call memset" modify exact [eax ebx edx];
extern void start_editing_slot_name(void);
#pragma aux start_editing_slot_name = \
    "lea eax,[esp+4]" "push eax" "mov eax,[editing_save_slot]" "mov eax,[eax*4+save_slot_menu_rows]" \
    "push offset save_slot_name_format" "mov edx,[eax+3]" "push edx" "call sprintf" \
    "add esp,12" "lea edi,[esp+4]" "xor esi,esi" "call presentation_reset" modify exact [eax edx esi edi];

extern unsigned editor_read_key(void);
#pragma aux editor_read_key = \
    "mov ah,1" "push offset save_slot_menu_rows" "movsx ebx,word ptr [esp+4]" "mov edx,10" \
    "mov ecx,ebp" "mov [editing_save_slot_name],ah" "mov eax,[editing_save_slot]" \
    "call draw_menu_frame" "xor dl,dl" "mov [editing_save_slot_name],dl" \
    "call presentation_input" "mov edx,eax" value [eax] modify exact [eax ebx ecx edx];
extern void prepare_edit_slot_offset(void);
#pragma aux prepare_edit_slot_offset = "mov ebx,[editing_save_slot]" "shl ebx,2" modify exact [ebx];
extern void restore_original_slot_name(void);
#pragma aux restore_original_slot_name = \
    "mov eax,[ebx+save_slot_menu_rows]" "lea edx,[esp+18h]" "mov eax,[eax+3]" \
    "call strcpy" modify exact [eax edx];

extern int current_name_length(void);
#pragma aux current_name_length = value [esi] modify exact [];
extern char *edit_name_buffer(void);
#pragma aux edit_name_buffer = value [edi] modify exact [];
#pragma aux shorten_slot_name = "dec esi" modify exact [esi];

extern void reuse_original_if_empty(void);
#pragma aux reuse_original_if_empty = \
    "lea eax,[esp+18h]" "push eax" "mov eax,[ebx+save_slot_menu_rows]" \
    "push offset save_slot_name_format" "mov ebx,[eax+3]" "push ebx" "call sprintf" \
    "add esp,12" modify exact [eax ebx];

extern unsigned char current_name_character(void);
#pragma aux current_name_character = "mov bl,[edx+save_name_key_ascii]" value [bl] modify exact [ebx];
extern void append_uppercase_character(unsigned char);
#pragma aux append_uppercase_character = \
    "xor eax,eax" "mov al,bl" "call toupper" "mov edx,eax" "mov eax,esi" "inc esi" \
    "mov [edi+eax],dl" parm [bl] modify exact [eax edx esi];
extern void clamp_name_length(void);
#pragma aux clamp_name_length = "mov esi,16" modify exact [esi];

extern void refresh_edited_slot_name(void);
#pragma aux refresh_edited_slot_name = \
    "lea eax,[esp+4]" "push eax" "mov eax,[editing_save_slot]" "mov eax,[eax*4+save_slot_menu_rows]" \
    "push offset save_slot_name_format" "mov ecx,[eax+3]" "push ecx" \
    "call sprintf" "add esp,12" modify exact [eax ecx];
extern void finish_slot_name_frame(void);
#pragma aux finish_slot_name_frame = "add esp,44" "pop ebp" "pop edi" \
    "pop esi" "pop ecx" "pop ebx" modify exact [];
extern int return_slot_name_result(int);
#pragma aux return_slot_name_result = parm [eax] value [eax] modify exact [];

extern int edit_save_slot_name(int, const char *);
#pragma aux edit_save_slot_name parm [eax] [edx] modify exact [eax ebx ecx edx esi edi];

int edit_save_slot_name(int background, const char *title)
{
    char *buffer;
    int length;
    unsigned key;
    unsigned char character;
    int accepted;

    copy_original_slot_name(background, title);
    initialize_edited_name();
    start_editing_slot_name();
draw:
    key = editor_read_key();
    if (!key)
        goto draw;
    prepare_edit_slot_offset();
    if (key < 0xe)
        goto early_key;
    if (key <= 0xe)
        goto backspace;
    if (key == 0x1c)
        goto enter;
    goto type_character;
early_key:
    if (key != 1)
        goto type_character;
    restore_original_slot_name();
    accepted = return_slot_name_result(0);
    goto done;
backspace:
    if (current_name_length() <= 0)
        goto refresh;
    /* Use the same buffer and length for both terminators before shortening the name. */
    buffer = edit_name_buffer();
    length = current_name_length();
    buffer[length] = 0;
    buffer[length - 1] = 0;
    shorten_slot_name();
    goto refresh;
enter:
    if (!edit_name_buffer()[0])
        reuse_original_if_empty();
    accepted = return_slot_name_result(1);
    goto done;
type_character:
    character = current_name_character();
    if (!character)
        goto refresh;
    append_uppercase_character(character);
    if (current_name_length() >= 17)
        clamp_name_length();
    edit_name_buffer()[current_name_length()] = 0;
refresh:
    refresh_edited_slot_name();
    goto draw;
done:
    finish_slot_name_frame();
    return accepted;
}
