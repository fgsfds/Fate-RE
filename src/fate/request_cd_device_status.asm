; Request cd device status.
BITS 32
ORG 0x37805

send_cd_driver_request equ 0x377a7
cd_request_segment equ 0x173f9e

request_cd_device_status:
    push ebx
    push edx
    mov edx, eax
    xor eax, eax
    mov ebx, ds
    mov ax, [cd_request_segment]
    mov gs, ebx
    shl eax, byte 0x4
    mov ebx, 0x4403
    mov byte [gs:eax], 0x0
    movsx eax, dx
    mov edx, 0x1
    call send_cd_driver_request
    pop edx
    pop ebx
    ret
