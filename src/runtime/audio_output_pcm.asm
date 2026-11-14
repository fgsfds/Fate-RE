; Write the low 16-bit accumulator directly as mono or interleaved PCM.
BITS 32
ORG 0x6e0fd

%macro output_pcm 2-3 0
.loop:
    mov eax, [esi]
    add esi, 4
%if %3
    cmp eax, 32767
    jg short .clip_high
    cmp eax, -32768
    jl short .clip_low
.store:
%endif
%if %2
    xor eax, 0x8000
%endif
%if %1 = 1
    mov [edi], ah
%else
    mov [edi], ax
%endif
    add edi, %1
    dec ecx
    jne short .loop
    ret
%if %3
.clip_high:
    mov eax, 32767
    jmp short .store
.clip_low:
    mov eax, -32768
    jmp short .store
%endif
%endmacro

output_signed_8:
    output_pcm 1, 0

output_signed_16:
    output_pcm 2, 0

output_unsigned_8:
    output_pcm 1, 1

output_unsigned_16:
    output_pcm 2, 1

%macro output_stereo_pcm 3-4 0
.loop:
    mov eax, [esi]
    mov ebx, [esi + 4]
    add esi, 8
%if %4
    cmp eax, 32767
    jg short .clip_left_high
    cmp eax, -32768
    jl short .clip_left_low
.check_right:
    cmp ebx, 32767
    jg short .clip_right_high
    cmp ebx, -32768
    jl short .clip_right_low
.store:
%endif
%if %2
    xor eax, 0x8000
    xor ebx, 0x8000
%endif
%if %1 = 1
%if %3
    db 0x8a, 0xc7 ; MOV AL, BH, register-destination encoding.
    mov [edi], ax
%else
    db 0x8a, 0xdc ; MOV BL, AH, register-destination encoding.
    mov [edi], bx
%endif
%elif %3
    mov [edi], bx
    mov [edi + 2], ax
%else
    mov [edi], ax
    mov [edi + 2], bx
%endif
    add edi, %1 * 2
    dec ecx
    jne short .loop
    ret
%if %4
.clip_left_high:
    mov eax, 32767
    jmp short .check_right
.clip_left_low:
    mov eax, -32768
    jmp short .check_right
.clip_right_high:
    mov ebx, 32767
    jmp short .store
.clip_right_low:
    mov ebx, -32768
    jmp short .store
%endif
%endmacro

output_stereo_signed_8:
    output_stereo_pcm 1, 0, 0

output_stereo_signed_16:
    output_stereo_pcm 2, 0, 0

output_stereo_unsigned_8:
    output_stereo_pcm 1, 1, 0

output_stereo_unsigned_16:
    output_stereo_pcm 2, 1, 0

output_swapped_mono_signed_8:
    output_pcm 1, 0

output_swapped_mono_signed_16:
    output_pcm 2, 0

output_swapped_mono_unsigned_8:
    output_pcm 1, 1

output_swapped_mono_unsigned_16:
    output_pcm 2, 1

output_swapped_stereo_signed_8:
    output_stereo_pcm 1, 0, 1

output_swapped_stereo_signed_16:
    output_stereo_pcm 2, 0, 1

output_swapped_stereo_unsigned_8:
    output_stereo_pcm 1, 1, 1

output_swapped_stereo_unsigned_16:
    output_stereo_pcm 2, 1, 1

output_clipped_mono_signed_8:
    output_pcm 1, 0, 1

output_clipped_mono_signed_16:
    output_pcm 2, 0, 1

output_clipped_mono_unsigned_8:
    output_pcm 1, 1, 1

output_clipped_mono_unsigned_16:
    output_pcm 2, 1, 1

output_clipped_stereo_signed_8:
    output_stereo_pcm 1, 0, 0, 1

output_clipped_stereo_signed_16:
    output_stereo_pcm 2, 0, 0, 1

output_clipped_stereo_unsigned_8:
    output_stereo_pcm 1, 1, 0, 1

output_clipped_stereo_unsigned_16:
    output_stereo_pcm 2, 1, 0, 1

output_clipped_swapped_mono_signed_8:
    output_pcm 1, 0, 1

output_clipped_swapped_mono_signed_16:
    output_pcm 2, 0, 1

output_clipped_swapped_mono_unsigned_8:
    output_pcm 1, 1, 1

output_clipped_swapped_mono_unsigned_16:
    output_pcm 2, 1, 1

output_clipped_swapped_stereo_signed_8:
    output_stereo_pcm 1, 0, 1, 1

output_clipped_swapped_stereo_signed_16:
    output_stereo_pcm 2, 0, 1, 1

output_clipped_swapped_stereo_unsigned_8:
    output_stereo_pcm 1, 1, 1, 1

output_clipped_swapped_stereo_unsigned_16:
    output_stereo_pcm 2, 1, 1, 1
