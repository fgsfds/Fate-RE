; Request cd device control.
BITS 32
ORG 0x37831

submit_device_request equ 0x37821
cd_request_segment equ 0x173f9e

request_cd_device_control:
    push ebx
    push edx
    mov edx, eax
    xor eax, eax
    mov ebx, ds
    mov ax, [cd_request_segment]
    mov gs, ebx
    shl eax, byte 0x4
    mov ebx, 0x4403
    mov byte [gs:eax], 0x5
    jmp short submit_device_request
