/* Keep the two DOS status entry points adjacent with separate returns. */
extern unsigned status_return(unsigned);
#pragma aux status_return = "" parm [eax] value [eax] modify exact [];
int set_dos_errno(unsigned);
#pragma aux set_dos_errno modify exact [eax];
int translate_exec_result(unsigned status, int failed);
#pragma aux translate_exec_result modify exact [eax];
int dosret0(unsigned status, int failed);
#pragma aux dosret0 modify exact [eax];
int dosret0(unsigned status, int failed)
{
    if (failed)
        return translate_exec_result(status, failed);
    return 0;
}
int translate_exec_result(unsigned status, int failed)
{
    if (failed)
        return set_dos_errno(status);
    return status_return(status);
}
extern unsigned char dos_major_version;
#pragma pack(push, 1)
typedef struct { long value; } ErrorTableEntry;
#pragma pack(pop)
extern const unsigned char dos_error_table_window[];
extern void set_runtime_error(unsigned);
#pragma aux set_runtime_error modify exact [eax];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];
/* Keep the full DOS status in EDX across the runtime error call. */
extern void keep_status_in_edx(unsigned);
extern unsigned retained_status(void);
#pragma aux retained_status = value [edx] modify exact [];
#pragma aux keep_status_in_edx = parm [edx] modify exact [];
extern unsigned char status_low_byte(void);
#pragma aux status_low_byte = value [al] modify exact [];
extern unsigned char index_in_bl(unsigned char);
#pragma aux index_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned zero_in_eax(unsigned);
#pragma aux zero_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned zero_in_edx(unsigned);
#pragma aux zero_in_edx = parm [edx] value [edx] modify exact [];
int set_dos_errno(unsigned);
#pragma aux set_dos_errno modify exact [eax];
int set_dos_errno(unsigned status)
{
    union { unsigned value; unsigned char bytes[4]; } clean, entry;
    unsigned char index;
    int error;
    keep_status_in_edx(status);
    index = index_in_bl(status_low_byte());
    clean.value = zero_in_eax(0);
    clean.bytes[0] = (unsigned char)retained_status();
    set_runtime_error(clean.value);
    if (retained_status() >= 0x100)
        goto explicit_errno;
    if (dos_major_version < 3)
        goto clamp;
    if ((unsigned char)retained_status() == 0x50) {
        index = index_in_bl(0xe);
        goto clamp;
    }
    if ((unsigned char)retained_status() >= 0x22) {
        index = index_in_bl(0x13);
        goto clamp;
    }
    if ((unsigned char)retained_status() >= 0x20)
        index = index_in_bl(5);
clamp:
    if (index > 0x13)
        index = index_in_bl(0x13);
    entry.value = zero_in_edx(0);
    entry.bytes[0] = index;
    /* The original table load reads the selected signed byte as the high byte. */
    error = ((const ErrorTableEntry *)(dos_error_table_window + zero_in_edx(entry.value)))->value >> 24;
    goto publish;
explicit_errno:
    error = (retained_status() >> 8) & 0xff;
publish:
    set_errno(error);
    return -1;
}
