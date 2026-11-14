; Request cd disk info.
BITS 32
ORG 0x3784f

submit_device_request equ 0x37821
cd_request_segment equ 0x173f9e

request_cd_disk_info:
    push ebx
    push edx
    mov edx, eax
    xor eax, eax
    mov ebx, ds
    mov ax, [cd_request_segment]
    mov gs, ebx
    shl eax, byte 0x4
    mov ebx, 0x4403
    mov byte [gs:eax], 0x2
    jmp short submit_device_request
