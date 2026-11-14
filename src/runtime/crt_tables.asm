; Six XI records and two YI records. The final zero byte is loaded but unstored.
BITS 32
ORG 0x199b4

%macro entry 2
    db 0, %1
    dd %2 - 0x10000
%endmacro

    entry 32, 0x63415
    entry 1,  0x60322
    entry 2,  0x6463b
    entry 32, 0x6adc6
    entry 32, 0x67010
    entry 32, 0x6e6b9
    entry 1,  0x60327
    entry 32, 0x6ae3e
