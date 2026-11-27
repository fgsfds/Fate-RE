/* The wrappers preserve ECX. Each external alias resolves to
 * the same truncation helper, keeping the six original call sites. */
extern void select_float_mode(unsigned char);
#pragma aux select_float_mode = "" parm [cl] modify exact [ecx];
#define FLOAT_CONVERSION(name, mode, callee) \
    long name(unsigned long bits) \
    { \
        long result; \
        select_float_mode(mode); \
        result = callee(bits); \
        return result; \
    }

long float_to_i32(unsigned long);
#pragma aux float_to_i32 parm [eax] modify exact [eax];
long float_to_u32(unsigned long);
#pragma aux float_to_u32 parm [eax] modify exact [eax];
long float_to_i16(unsigned long);
#pragma aux float_to_i16 parm [eax] modify exact [eax];
long float_to_u16(unsigned long);
#pragma aux float_to_u16 parm [eax] modify exact [eax];
long float_to_i8(unsigned long);
#pragma aux float_to_i8 parm [eax] modify exact [eax];
long float_to_u8(unsigned long);
#pragma aux float_to_u8 parm [eax] modify exact [eax];

extern long truncate_for_i32(unsigned long);
#pragma aux truncate_for_i32 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_i32, 0x9e, truncate_for_i32)
extern long truncate_for_u32(unsigned long);
#pragma aux truncate_for_u32 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_u32, 0x9f, truncate_for_u32)
extern long truncate_for_i16(unsigned long);
#pragma aux truncate_for_i16 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_i16, 0x8e, truncate_for_i16)
extern long truncate_for_u16(unsigned long);
#pragma aux truncate_for_u16 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_u16, 0x8f, truncate_for_u16)
extern long truncate_for_i8(unsigned long);
#pragma aux truncate_for_i8 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_i8, 0x86, truncate_for_i8)
extern long truncate_for_u8(unsigned long);
#pragma aux truncate_for_u8 parm [eax] modify exact [eax ecx];
FLOAT_CONVERSION(float_to_u8, 0x87, truncate_for_u8)
