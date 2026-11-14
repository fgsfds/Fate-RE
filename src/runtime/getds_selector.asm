; __GETDS reads this selector through CS after _cstart_ initializes it.
BITS 32
ORG 0x601dd

runtime_data_selector:
    dw 0
    db 0 ; Align the following callback to 0x601e0.
