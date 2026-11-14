; Adapter and monitor classes indexed by the detected BIOS display code.
BITS 32

adapter_class_table:
    dw -1, 1, 2, 5, 5, 5, 0, 6, 6, 0, 4, 4, 4, 3, 3, 3, 7, 7
monitor_class_table:
    dw -1, 1, 2, 3, 2, 1, 0, 5, 6, 0, 2, 5, 6, 1, 1, 1, 5, 6
video_memory_table:
    dw 0, 16, 16, 64, 256, -1, 256, 256
