; Read digital audio settings from hmiset.cfg.
BITS 32
ORG 0x3488d

audio_config_filename equ 0x6d4
audio_config_open_error equ 0x6df
digital_section equ 0x6fa
device_id_key equ 0x702
device_port_key equ 0x70b
device_dma_key equ 0x716
device_irq_key equ 0x720
report_error equ 0x26a03
open_configuration equ 0x35732
close_configuration equ 0x35824
find_configuration_section equ 0x35882
read_configuration_integer equ 0x35d9c
frame_state_171548 equ 0x171548
frame_state_17154c equ 0x17154c
frame_state_171550 equ 0x171550
frame_state_1715f0 equ 0x1715f0

read_audio_configuration:
    push ebx
    push ecx
    push edx
    sub esp, strict dword 0xac
    push strict dword audio_config_filename
    lea eax, [esp + 0x4]
    push eax
    call open_configuration
    add esp, 0x8
    test eax, eax
    jnz short .branch_348bd
    mov eax, audio_config_open_error
    call report_error

.branch_348b6:
    xor eax, eax
    jmp near .branch_3494c

.branch_348bd:
    push strict dword digital_section
    lea eax, [esp + 0x4]
    push eax
    call find_configuration_section
    add esp, 0x8
    test eax, eax
    jnz short .branch_348e0
    mov eax, esp
    push eax
    call close_configuration
    add esp, 0x4
    jmp short .branch_348b6

.branch_348e0:
    push strict dword frame_state_1715f0
    push strict dword device_id_key
    lea eax, [esp + 0x8]
    push eax
    call read_configuration_integer
    add esp, 0xc
    push strict dword frame_state_171548
    push strict dword device_port_key
    lea eax, [esp + 0x8]
    push eax
    call read_configuration_integer
    add esp, 0xc
    push strict dword frame_state_171550
    push strict dword device_dma_key
    lea eax, [esp + 0x8]
    push eax
    call read_configuration_integer
    add esp, 0xc
    push strict dword frame_state_17154c
    push strict dword device_irq_key
    lea eax, [esp + 0x8]
    push eax
    call read_configuration_integer
    add esp, 0xc
    mov eax, esp
    push eax
    call close_configuration
    mov eax, 0x1
    add esp, 0x4

.branch_3494c:
    add esp, strict dword 0xac
    pop edx
    pop ecx
    pop ebx
    ret
