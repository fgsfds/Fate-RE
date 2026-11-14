; Prepare DOS executable and batch-file launches.
BITS 32
ORG 0x64087

check_stack equ 0x67018
set_errno equ 0x6468e
set_runtime_error equ 0x646b1
build_child_environment equ 0x67603
strlen equ 0x60381
malloc equ 0x6126d
stackavail equ 0x67006
free equ 0x6170a
split_path equ 0x678a2
make_path equ 0x6793e
stricmp equ 0x62d95
probe_executable equ 0x64035
prepare_spawn equ 0x64054
get_errno_address equ 0x67a09
measure_argument_block equ 0x6773b
select_shell_switch equ 0x6400f
getenv equ 0x63fb5
spawn_with_arguments equ 0x67a15
spawn_with_path_search equ 0x67a33
save_spawn_state equ 0x17408
restore_spawn_state equ 0x1740c
dos_major_version equ 0x144a3
current_directory_prefix equ 0x1c24
batch_extension equ 0x1c27
com_extension equ 0x1c2c
exe_extension equ 0x1c31
comspec_name equ 0x1c36
cmd_name equ 0x1c3e
command_name equ 0x1c42

spawnve_:
    push strict dword 0xe4
    call check_stack
    push esi
    push edi
    push es
    enter 0xb0, 0
    push eax
    sub ebp, strict dword 0x82
    mov esi, edx
    mov dword [ebp + 0x6e], ebx
    mov edx, ecx
    mov byte [ebp + 0x7e], 0
    cmp eax, 2
    jb short build_environment
    mov eax, 9
    call set_errno

return_failure:
    mov eax, 0xffffffff
    jmp near restore_registers

build_environment:
    push 0
    lea eax, [ebp + 0x52]
    push eax
    lea eax, [ebp + 0x56]
    lea ecx, [ebp + 0x5a]
    push eax
    mov eax, ebx
    lea ebx, [ebp + 0x5e]
    call build_child_environment
    mov dword [ebp + 0x76], eax
    cmp eax, -1
    je near restore_registers
    mov eax, esi
    call strlen
    lea edx, [eax + 0x9a]
    mov eax, edx
    call malloc
    mov ebx, eax
    mov dword [ebp + 0x66], eax
    test eax, eax
    jne short use_path_heap_alloc
    lea ebx, [edx + 3]
    and bl, 0xfc
    call stackavail
    cmp ebx, eax
    jae short fail_path_stack_alloc
    mov eax, ebx
    sub esp, eax
    mov eax, esp
    jmp short check_path_stack_alloc

fail_path_stack_alloc:
    xor eax, eax

check_path_stack_alloc:
    mov dword [ebp + 0x7a], eax
    test eax, eax
    jne short split_executable_path
    mov eax, dword [ebp + 0x5e]
    call free
    jmp short return_failure

use_path_heap_alloc:
    mov dword [ebp + 0x7a], eax

split_executable_path:
    lea eax, [ebp + 0x42]
    lea ebx, [ebp + 0x46]
    lea ecx, [ebp + 0x4a]
    push eax
    lea eax, [ebp + 0x3e]
    sub edx, strict dword 0x93
    push eax
    add edx, dword [ebp + 0x7a]
    mov eax, esi
    call split_path
    lea eax, [ebp - 0x2e]
    call dword [save_spawn_state]
    mov eax, dword [ebp + 0x52]
    call malloc
    mov edx, eax
    mov dword [ebp + 0x62], eax
    test eax, eax
    jne short use_argument_heap_alloc
    mov eax, dword [ebp + 0x52]
    add eax, 3
    and al, 0xfc
    mov edx, eax
    call stackavail
    cmp edx, eax
    jae short fail_argument_stack_alloc
    mov eax, dword [ebp + 0x52]
    add eax, 3
    and al, 0xfc
    sub esp, eax
    mov eax, esp
    jmp short check_argument_stack_alloc

fail_argument_stack_alloc:
    xor eax, eax

check_argument_stack_alloc:
    mov dword [ebp + 0x72], eax
    test eax, eax
    jne short check_relative_path
    mov eax, 2
    call set_errno
    mov eax, 0xa
    mov dword [ebp + 0x76], 0xffffffff
    call set_runtime_error
    jmp near release_allocations

use_argument_heap_alloc:
    mov dword [ebp + 0x72], eax

check_relative_path:
    cmp byte [dos_major_version], 3
    jb short rebuild_path
    mov eax, dword [ebp + 0x46]
    cmp byte [eax], 0
    jne short rebuild_path
    mov eax, dword [ebp + 0x4a]
    cmp byte [eax], 0
    jne short rebuild_path
    mov dword [ebp + 0x4a], current_directory_prefix

rebuild_path:
    push dword [ebp + 0x42]
    mov eax, dword [ebp + 0x7a]
    mov edx, dword [ebp + 0x46]
    mov ebx, dword [ebp + 0x4a]
    mov ecx, dword [ebp + 0x3e]
    call make_path
    mov eax, 1
    call set_errno
    mov eax, dword [ebp + 0x42]
    cmp byte [eax], 0
    je short resolve_missing_extension
    mov edx, batch_extension
    call stricmp
    test eax, eax
    jne short spawn_explicit_executable
    mov eax, dword [ebp + 0x7a]
    mov dword [ebp + 0x76], 0xffffffff
    call probe_executable
    test eax, eax
    jne near run_batch_via_shell
    jmp near release_allocations

spawn_explicit_executable:
    mov edx, dword [ebp + 0x7a]
    xor eax, eax
    mov ebx, dword [ebp + 0x72]
    call set_errno
    push dword [ebp + 0x6e]
    mov eax, dword [ebp - 0x32]
    mov ecx, dword [ebp + 0x5e]
    call prepare_spawn
    jmp near save_result

resolve_missing_extension:
    mov eax, dword [ebp + 0x7a]
    mov edx, dword [ebp + 0x7a]
    call strlen
    add edx, eax
    mov dword [ebp + 0x6a], edx
    cmp byte [ebp + 0x7e], 0
    je short try_com
    mov eax, 1
    call set_errno
    jmp short check_com_result

try_com:
    mov ebx, dword [ebp + 0x72]
    push ds
    pop es
    mov edi, edx
    mov esi, com_extension
    xor eax, eax
    mov edx, dword [ebp + 0x7a]
    movsd
    movsb
    call set_errno
    push dword [ebp + 0x6e]
    mov eax, dword [ebp - 0x32]
    mov ecx, dword [ebp + 0x5e]
    call prepare_spawn
    mov dword [ebp + 0x76], eax

check_com_result:
    call get_errno_address
    cmp dword [eax], 1
    jne near release_allocations
    mov edi, dword [ebp + 0x6a]
    mov edx, dword [ebp + 0x7a]
    xor eax, eax
    mov ebx, dword [ebp + 0x72]
    call set_errno
    push ds
    pop es
    mov esi, exe_extension
    push dword [ebp + 0x6e]
    movsd
    movsb
    mov eax, dword [ebp - 0x32]
    mov ecx, dword [ebp + 0x5e]
    call prepare_spawn
    mov dword [ebp + 0x76], eax
    call get_errno_address
    cmp dword [eax], 1
    jne near release_allocations
    mov edi, dword [ebp + 0x6a]
    xor eax, eax
    mov esi, batch_extension
    call set_errno
    mov eax, dword [ebp + 0x7a]
    movsd
    movsb
    call probe_executable
    test eax, eax
    je short release_allocations

run_batch_via_shell:
    mov eax, dword [ebp + 0x5e]
    mov edx, dword [ebp + 0x6e]
    mov ebx, dword [ebp + 0x72]
    mov ecx, 1
    call free
    mov eax, dword [ebp + 0x7a]
    mov dword [ebp + 0x5e], 0
    call measure_argument_block
    push 0
    push dword [ebp + 0x72]
    movzx edx, byte [ebp + 0x7e]
    push dword [ebp + 0x7a]
    lea eax, [ebp + 0x4e]
    call select_shell_switch
    push eax
    cmp byte [ebp + 0x7e], 0
    je short select_command_name
    mov eax, cmd_name
    jmp short lookup_shell

select_command_name:
    mov eax, command_name

lookup_shell:
    push eax
    mov eax, comspec_name
    call getenv
    push eax
    push dword [ebp - 0x32]
    call spawn_with_arguments
    add esp, 0x1c

save_result:
    mov dword [ebp + 0x76], eax

release_allocations:
    mov eax, dword [ebp + 0x62]
    call free
    mov eax, dword [ebp + 0x66]
    call free
    mov eax, dword [ebp + 0x5e]
    call free
    lea eax, [ebp - 0x2e]
    call dword [restore_spawn_state]
    mov eax, dword [ebp + 0x76]

restore_registers:
    lea esp, [dword ebp + 0x82]
    pop ebp
    pop es
    pop edi
    pop esi
    ret

spawnlp_:
    push ebx
    push edx
    mov eax, dword [esp + 0xc]
    mov edx, dword [esp + 0x10]
    lea ebx, [esp + 0x14]
    call spawn_with_path_search
    pop edx
    pop ebx
    ret
