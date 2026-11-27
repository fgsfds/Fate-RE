/* Compiler-regression probes only. These functions never enter FATE.EXE. */
#pragma pack(1)
struct Packed { unsigned char tag; long value; };

long register_increment(long);
#pragma aux register_increment parm [eax] value [eax] modify exact [eax];
long register_increment(long value) { return value + 1; }

long signed_word(long);
#pragma aux signed_word parm [eax] value [eax] modify exact [eax];
long signed_word(long value) { return (short)value; }

unsigned long unsigned_word(unsigned long);
#pragma aux unsigned_word parm [eax] value [eax] modify exact [eax];
unsigned long unsigned_word(unsigned long value) { return (unsigned short)value; }

unsigned long low_byte(unsigned long);
#pragma aux low_byte parm [eax] value [eax] modify exact [eax];
unsigned long low_byte(unsigned long value) { return (unsigned char)value; }

long packed_value(const struct Packed *);
#pragma aux packed_value parm [eax] value [eax] modify exact [eax];
long packed_value(const struct Packed *value) { return value->value; }

long less_than_memory(long, const long *);
#pragma aux less_than_memory parm [eax] [edx] value [eax] modify exact [eax];
long less_than_memory(long value, const long *limit) { return value < *limit; }

extern long preserve_other_registers(long);
#pragma aux preserve_other_registers parm [eax] value [eax] modify exact [eax];
long keep_edx(long, long);
#pragma aux keep_edx parm [eax] [edx] value [eax] modify exact [eax];
long keep_edx(long value, long extra) { return preserve_other_registers(value) + extra; }

extern void terminal_error(void);
#pragma aux terminal_error aborts modify exact [eax];
void aborting_wrapper(long);
#pragma aux aborting_wrapper parm [eax] modify exact [eax];
void aborting_wrapper(long value) { terminal_error(); }

unsigned long rotate_idiom(unsigned long);
#pragma aux rotate_idiom parm [eax] value [eax] modify exact [eax];
unsigned long rotate_idiom(unsigned long value) { return (value << 8) | (value >> 24); }
