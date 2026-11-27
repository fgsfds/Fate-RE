; Select video banks and step pixel addresses across 64 KiB windows.
BITS 32
ORG 0x72936

bank_shift equ 0x289248
current_bank equ 0x289249
select_bank equ 0x2891e8

select_indexed_b2_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    cli
    push edx
    mov edx, 0x1ce
    mov al, 0xb2
    out dx, al
    inc dl
    in al, dx
    and al, 0xe1
    shl ah, 1
    db 0x0a, 0xe0 ; or ah, al, register-destination encoding.
    mov al, 0xb2
    dec dl
    out dx, ax
    pop edx
    sti
.done:
    ret

select_segment_bank_3cd_shift3:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    shl ah, 1
    shl ah, 1
    shl ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    or al, 0x40
    push edx
    mov dx, 0x3cd
    out dx, al
    pop edx
.done:
    ret

select_segment_bank_3cd:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    shl ah, 1
    shl ah, 1
    shl ah, 1
    shl ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    push edx
    mov dx, 0x3cd
    out dx, al
    pop edx
.done:
    ret

select_segment_bank_3df:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    shl ah, 1
    shl ah, 1
    shl ah, 1
    shl ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    push edx
    mov dx, 0x3df
    out dx, al
    pop edx
.done:
    ret

select_sequencer_0e_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    xor ah, 2
    push edx
    mov dx, 0x3c4
    mov al, 0xe
    out dx, al
    inc dx
    in al, dx
    and al, 0xf0
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
    pop edx
.done:
    ret

select_extended_10_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    push ecx
    mov cl, byte ss:[bank_shift]
    shl al, cl
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    push edx
    mov dx, 0x3d6
    mov al, 0x10
    out dx, al
    inc dx
    in al, dx
    and al, 0xc0
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
    pop edx
    pop ecx
.done:
    ret

select_sequencer_06_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    shl al, 1
    shl al, 1
    shl al, 1
    db 0x0a, 0xe0 ; or ah, al, register-destination encoding.
    push edx
    mov dx, 0x3c4
    mov al, 6
    out dx, al
    inc dx
    in al, dx
    and al, 0x80
    or al, 0x40
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
    pop edx
.done:
    ret

select_crtc_35_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    cmp byte ss:[bank_shift], 0x10
    jne short .write_register
    shl ah, 1
    shl ah, 1
.write_register:
    mov al, 0x35
    push edx
    mov dx, 0x3d4
    out dx, al
    inc dx
    in al, dx
    and ax, 0xff0
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
    pop edx
.done:
    ret

%macro BANKED_STEP 5
    db %1.fragment_end - %1
%1:
    %2 di, strict %5 %3
    jnc short .fragment_end
    push eax
    mov al, byte ss:[current_bank]
    %4 al
    call dword [select_bank]
    pop eax
.fragment_end:
    ret
%endmacro

    db 3 ; Fragment length for the C-replaced banked callback.
    times 4 db 0 ; Reserved for step_byte_up_100 in graphics_byte_steps.c.

    db 3 ; Fragment length for the C-replaced banked callback.
    times 4 db 0 ; Reserved for step_byte_down_100 in graphics_byte_steps.c.
BANKED_STEP step_banked_up_128, sub, 128, dec, word
BANKED_STEP step_banked_down_128, add, 128, inc, word
BANKED_STEP step_banked_left, sub, 1, dec, byte
BANKED_STEP step_banked_right, add, 1, inc, byte
BANKED_STEP step_banked_up_640, sub, 640, dec, word
BANKED_STEP step_banked_down_640, add, 640, inc, word
BANKED_STEP step_banked_up_800, sub, 800, dec, word
BANKED_STEP step_banked_down_800, add, 800, inc, word
BANKED_STEP step_banked_up_1024, sub, 1024, dec, word
BANKED_STEP step_banked_down_1024, add, 1024, inc, word
