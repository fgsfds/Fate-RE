BITS 32
ORG 0x6025a

comspec equ 0x1bfc
default_shell equ 0x1c0c
cmd_name equ 0x1c18
command_name equ 0x1c1c
getenv equ 0x63fb5
select_shell_switch equ 0x6400f
spawnlp equ 0x64385

system_:
    push ebx
    push ecx
    push edx
    push ebp
    mov ebp, esp
    sub esp, 8
    mov edx, eax
    mov eax, comspec
    call getenv
    mov ecx, eax
    mov ebx, eax
    test edx, edx
    jne short .prepare_command
    mov eax, 1
    jmp short .restore

.prepare_command:
    xor ah, ah
    mov [ebp - 4], ah
    test ecx, ecx
    jne short .select_switch
    mov ebx, default_shell

.select_switch:
    push byte 0
    push edx
    xor edx, edx
    lea eax, [ebp - 8]
    mov dl, [ebp - 4]
    call select_shell_switch
    mov dl, [ebp - 4]
    push eax
    test dl, dl
    je short .use_command_name
    mov eax, cmd_name
    jmp short .spawn

.use_command_name:
    mov eax, command_name

.spawn:
    push eax
    push ebx
    push byte 0
    call spawnlp
    add esp, 0x18

.restore:
    mov esp, ebp
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
