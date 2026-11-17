#ifndef RUNTIME_STREAM_H
#define RUNTIME_STREAM_H

typedef struct RuntimeStream RuntimeStream;

struct RuntimeStream {
    unsigned char *next;
    long buffered;
    void *buffer;
    union {
        unsigned long word;
        unsigned char bytes[4];
    } flags;
    int descriptor;
    unsigned capacity;
    unsigned char inline_buffer[2];
};

typedef struct StreamLink {
    struct StreamLink *next;
    RuntimeStream *stream;
} StreamLink;

#endif
