; Read and update digital audio sample controls and identifiers.
BITS 32
ORG 0x62480

driver_slots equ 0x1663c

set_sample_field_2c:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x1c
    mov dword [ebp - 0x1c], eax
    mov dword [ebp - 0x18], edx
    mov dword [ebp - 0x14], ebx
    mov eax, dword [ebp - 0x1c]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x18], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x2c]
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0x14]
    mov edx, dword [ebp - 8]
    mov dword [edx + 0x2c], eax
    jmp short .return_previous_value

.record_inactive_error:
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.return_previous_value:
    mov eax, dword [ebp - 0xc]
    mov dword [ebp - 0x10], eax

.return_status:
    mov eax, dword [ebp - 0x10]
    leave
    pop edi
    pop esi
    pop ecx
    ret

get_sample_field_2c:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x2c]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

get_sample_field_58:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x58]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

get_sample_field_30:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x30]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

set_sample_field_44:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x1c
    mov dword [ebp - 0x1c], eax
    mov dword [ebp - 0x18], edx
    mov dword [ebp - 0x14], ebx
    mov eax, dword [ebp - 0x1c]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x18], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x44]
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0x14]
    mov edx, dword [ebp - 8]
    mov dword [edx + 0x44], eax
    mov eax, dword [ebp - 0xc]
    mov dword [ebp - 0x10], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0x10], 0xa

.return_status:
    mov eax, dword [ebp - 0x10]
    leave
    pop edi
    pop esi
    pop ecx
    ret

get_sample_field_44:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x44]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

set_sample_field_34:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x1c
    mov dword [ebp - 0x1c], eax
    mov dword [ebp - 0x18], edx
    mov dword [ebp - 0x14], ebx
    mov eax, dword [ebp - 0x1c]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x18], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0x10], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x34]
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0x14]
    mov edx, dword [ebp - 8]
    mov dword [edx + 0x34], eax
    mov eax, dword [ebp - 0xc]
    mov dword [ebp - 0x10], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0x10], 0xa

.return_status:
    mov eax, dword [ebp - 0x10]
    leave
    pop edi
    pop esi
    pop ecx
    ret

get_sample_field_34:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x34]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

get_sample_field_48:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    je short .record_inactive_error
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x48]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.record_inactive_error:
    mov dword [ebp - 0xc], 0xa

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

get_sample_identifier:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .read_sample_identifier
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.read_sample_identifier:
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0x1c]
    mov dword [ebp - 0xc], eax

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

find_sample_by_identifier:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .start_sample_scan
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.start_sample_scan:
    mov dword [ebp - 8], 0

.check_sample_index:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 4]
    cmp eax, dword [edx + 0x14]
    jb short .compare_identifier
    jmp short .identifier_not_found

.advance_sample_index:
    inc dword [ebp - 8]
    jmp short .check_sample_index

.compare_identifier:
    imul edx, dword [ebp - 8], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov eax, dword [eax + 0x1c]
    cmp eax, dword [ebp - 0x10]
    jne short .continue_sample_scan
    imul edx, dword [ebp - 8], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov eax, dword [eax + 0x28]
    mov dword [ebp - 0xc], eax
    jmp short .return_status

.continue_sample_scan:
    jmp short .advance_sample_index

.identifier_not_found:
    mov dword [ebp - 0xc], 0xffffffff

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

read_driver_field_54:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0xc
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0xc]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .read_driver_value
    mov dword [ebp - 8], 0xa
    jmp short .return_status

.read_driver_value:
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x54]
    mov dword [ebp - 8], eax

.return_status:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

sample_is_inactive:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x18
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .resolve_sample
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.resolve_sample:
    imul edx, dword [ebp - 0x10], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .check_sample_active
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.check_sample_active:
    mov eax, dword [ebp - 8]
    test byte [eax + 0x21], 0x80
    jne short .record_active_result
    mov dword [ebp - 0x18], 1
    jmp short .save_activity_result

.record_active_result:
    mov dword [ebp - 0x18], 0

.save_activity_result:
    mov eax, dword [ebp - 0x18]
    mov dword [ebp - 0xc], eax

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

audio_noop_62a82:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
