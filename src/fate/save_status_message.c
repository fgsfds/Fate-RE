typedef struct { char bytes[13]; } LoadedMessage;
typedef struct { char bytes[12]; } SavedMessage;
typedef char SaveMessageSizes[sizeof(LoadedMessage)==13 && sizeof(SavedMessage)==12 ? 1 : -1];
/* Character views of the status buffer and constant messages in LE DATA.
 * Assignment copies the complete fixed object, including bytes after NUL.
 * The flat Watcom string ABI supplies equal DS/ES and a clear direction flag. */
extern LoadedMessage save_loaded_status;
extern const LoadedMessage save_loaded_message;
extern SavedMessage save_saved_status;
extern const SavedMessage save_saved_message;
extern unsigned save_message_length(const char *);
#pragma aux save_message_length "strlen_" parm [eax] value [eax] modify exact [eax];

unsigned save_copy_loaded_message(void);
#pragma aux save_copy_loaded_message parm [] value [ebx] modify exact [eax ebx esi edi];
unsigned save_copy_loaded_message(void)
{
    save_loaded_status=save_loaded_message;
    return save_message_length(save_loaded_status.bytes);
}

unsigned save_copy_saved_message(void);
#pragma aux save_copy_saved_message parm [] value [ebx] modify exact [eax ebx esi edi];
unsigned save_copy_saved_message(void)
{
    save_saved_status=save_saved_message;
    return save_message_length(save_saved_status.bytes);
}
