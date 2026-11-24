#ifndef SAVE_IO_H
#define SAVE_IO_H
typedef struct RuntimeStream RuntimeStream;
/* Character representation of the complete original LE DATA object.
 * The verifier binds this external to DATA offset zero, extent 0x28a300.
 * No typed subobject or integer-to-pointer arithmetic is used. */
extern unsigned char save_data_image[0x28a300];
extern unsigned save_io_read(void *, unsigned, unsigned, RuntimeStream *);
#pragma aux save_io_read "fread_" parm [eax] [edx] [ebx] [ecx] value [eax] modify exact [eax ebx ecx edx];
extern unsigned save_io_write(const void *, unsigned, unsigned, RuntimeStream *);
#pragma aux save_io_write "fwrite_" parm [eax] [edx] [ebx] [ecx] value [eax] modify exact [eax ebx ecx edx];
/* Empty identities conservatively clobber later argument registers to
 * preserve the original count/size/buffer/stream preparation order. */
extern unsigned save_io_count(unsigned);
#pragma aux save_io_count = "" parm [ebx] value [ebx] modify exact [eax edx ecx];
extern unsigned save_io_size(unsigned);
#pragma aux save_io_size = "" parm [edx] value [edx] modify exact [eax ecx];
extern unsigned char *save_io_buffer(unsigned char *);
#pragma aux save_io_buffer = "" parm [eax] value [eax] modify exact [ecx];
#define SAVE_FIELD(transfer, offset, bytes) do { \
    typedef char SaveFieldFits[((offset)<=sizeof(save_data_image) && \
        (bytes)>0 && (bytes)<=sizeof(save_data_image)-(offset))?1:-1]; \
    unsigned count=save_io_count(1); \
    unsigned size=save_io_size(bytes); \
    unsigned char *buffer=save_io_buffer(save_data_image+(offset)); \
    result=transfer(buffer,size,count,stream); \
} while(0)
extern RuntimeStream *save_byte_stream(RuntimeStream *);
#pragma aux save_byte_stream = "" parm [ecx] value [ecx] modify exact [edx];
extern unsigned save_byte_size(unsigned);
#pragma aux save_byte_size = "" parm [edx] value [edx] modify exact [];
#define SAVE_BYTE(transfer, offset) do { \
    typedef char SaveByteFits[((offset)<sizeof(save_data_image))?1:-1]; \
    unsigned count=save_io_count(1); \
    unsigned char *buffer=save_io_buffer(save_data_image+(offset)); \
    RuntimeStream *input=save_byte_stream(stream); \
    unsigned size=save_byte_size(count); \
    result=transfer(buffer,size,count,input); \
} while(0)
#endif
