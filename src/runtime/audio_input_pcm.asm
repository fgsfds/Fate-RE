; Mix PCM into signed 32-bit accumulators.
BITS 32
ORG 0x6c1b9

sample_end equ 0x16c20
mix_buffer_end equ 0x16c10

fractional_step equ 0x16c24
source_step equ 0x16c28

left_gain equ 0x16c3c
right_gain equ 0x16c40

%macro accumulate_scaled 3
    movzx eax, %1
    imul word [%2]
    db 0x03, 0xd2 ; ADD EDX, EDX, register-destination encoding.
    movsx edx, dx
    add [edi + %3], edx
%endmacro

%macro mix_pcm 4-7 0, 0, 0
.loop:
    cmp esi, [sample_end]
    jae short .return
%if %3 && %7
%if %1 = 1
    mov bh, [esi]
    mov ah, [esi + 1]
%else
    mov bx, [esi]
    mov ax, [esi + 2]
%endif
%elif %1 = 1
    mov ah, [esi]
%if %3
    mov bh, [esi + 1]
%endif
%else
    mov ax, [esi]
%if %3
    mov bx, [esi + 2]
%endif
%endif
%if %2
    xor eax, 0x8000
%if %3
    xor ebx, 0x8000
%endif
%endif
%if %6
%if %4 && !%3
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
%endif
    accumulate_scaled ax, left_gain, 0
%if %4
    accumulate_scaled bx, right_gain, 4
%endif
%else
    db 0x0f, 0xbf, 0xc0 ; MOVSX EAX, AX, explicit encoding.
    add [edi], eax
%if %4
%if %3
    movsx ebx, bx
    add [edi + 4], ebx
%else
    add [edi + 4], eax
%endif
%endif
%endif
    add edi, 4 + 4 * %4
%if %5
%if %1 = 1 && !%3
    add ecx, [fractional_step]
    adc esi, [source_step]
%else
    db 0x33, 0xed ; XOR EBP, EBP, register-destination encoding.
    add ecx, [fractional_step]
    db 0x13, 0xed ; ADC EBP, EBP, register-destination encoding.
    add esi, [source_step + ebp*4]
%endif
%else
    add esi, %1 * (1 + %3)
%endif
    cmp edi, [mix_buffer_end]
    jbe short .loop
.return:
    ret
%endmacro

mix_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0

mix_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0

mix_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0

mix_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0

mix_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1

mix_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1

mix_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1

mix_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1

mix_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0

mix_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0

mix_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0

mix_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0

mix_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1

mix_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1

mix_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1

mix_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1

resample_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 1

resample_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 1

resample_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 1

resample_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 1

resample_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 1

resample_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 1

resample_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 1

resample_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 1

resample_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 1

resample_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 1

resample_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 1

resample_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 1

resample_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 1

resample_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 1

resample_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 1

resample_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 1

mix_scaled_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 0, 1, 0

mix_scaled_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 0, 1, 0

mix_scaled_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 0, 1, 0

mix_scaled_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 0, 1, 0

mix_scaled_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 0, 1, 0

mix_scaled_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 0, 1, 0

mix_scaled_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 0, 1, 0

mix_scaled_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 0, 1, 0

mix_scaled_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 0, 1, 0

mix_scaled_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 0, 1, 0

mix_scaled_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 0, 1, 0

mix_scaled_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 0, 1, 0

mix_scaled_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 0, 1, 0

mix_scaled_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 0, 1, 0

mix_scaled_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 0, 1, 0

mix_scaled_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 0, 1, 0

resample_scaled_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 1, 1, 0

resample_scaled_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 1, 1, 0

resample_scaled_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 1, 1, 0

resample_scaled_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 1, 1, 0

resample_scaled_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 1, 1, 0

resample_scaled_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 1, 1, 0

resample_scaled_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 1, 1, 0

resample_scaled_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 1, 1, 0

resample_scaled_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 1, 1, 0

resample_scaled_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 1, 1, 0

resample_scaled_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 1, 1, 0

resample_scaled_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 1, 1, 0

resample_scaled_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 1, 1, 0

resample_scaled_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 1, 1, 0

resample_scaled_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 1, 1, 0

resample_scaled_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 1, 1, 0

mix_swapped_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 0, 0, 1

mix_swapped_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 0, 0, 1

mix_swapped_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 0, 0, 1

mix_swapped_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 0, 0, 1

mix_swapped_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 0, 0, 1

mix_swapped_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 0, 0, 1

mix_swapped_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 0, 0, 1

mix_swapped_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 0, 0, 1

mix_swapped_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 0, 0, 1

mix_swapped_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 0, 0, 1

mix_swapped_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 0, 0, 1

mix_swapped_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 0, 0, 1

mix_swapped_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 0, 0, 1

mix_swapped_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 0, 0, 1

mix_swapped_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 0, 0, 1

mix_swapped_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 0, 0, 1

resample_swapped_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 1, 0, 1

resample_swapped_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 1, 0, 1

resample_swapped_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 1, 0, 1

resample_swapped_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 1, 0, 1

resample_swapped_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 1, 0, 1

resample_swapped_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 1, 0, 1

resample_swapped_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 1, 0, 1

resample_swapped_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 1, 0, 1

resample_swapped_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 1, 0, 1

resample_swapped_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 1, 0, 1

resample_swapped_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 1, 0, 1

resample_swapped_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 1, 0, 1

resample_swapped_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 1, 0, 1

resample_swapped_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 1, 0, 1

resample_swapped_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 1, 0, 1

resample_swapped_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 1, 0, 1

mix_scaled_swapped_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 0, 1, 1

mix_scaled_swapped_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 0, 1, 1

mix_scaled_swapped_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 0, 1, 1

mix_scaled_swapped_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 0, 1, 1

mix_scaled_swapped_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 0, 1, 1

mix_scaled_swapped_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 0, 1, 1

mix_scaled_swapped_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 0, 1, 1

mix_scaled_swapped_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 0, 1, 1

mix_scaled_swapped_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 0, 1, 1

mix_scaled_swapped_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 0, 1, 1

mix_scaled_swapped_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 0, 1, 1

mix_scaled_swapped_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 0, 1, 1

mix_scaled_swapped_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 0, 1, 1

mix_scaled_swapped_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 0, 1, 1

mix_scaled_swapped_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 0, 1, 1

mix_scaled_swapped_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 0, 1, 1

resample_scaled_swapped_mono_to_mono_signed_8:
    mix_pcm 1, 0, 0, 0, 1, 1, 1

resample_scaled_swapped_mono_to_mono_unsigned_8:
    mix_pcm 1, 1, 0, 0, 1, 1, 1

resample_scaled_swapped_mono_to_mono_signed_16:
    mix_pcm 2, 0, 0, 0, 1, 1, 1

resample_scaled_swapped_mono_to_mono_unsigned_16:
    mix_pcm 2, 1, 0, 0, 1, 1, 1

resample_scaled_swapped_mono_to_stereo_signed_8:
    mix_pcm 1, 0, 0, 1, 1, 1, 1

resample_scaled_swapped_mono_to_stereo_unsigned_8:
    mix_pcm 1, 1, 0, 1, 1, 1, 1

resample_scaled_swapped_mono_to_stereo_signed_16:
    mix_pcm 2, 0, 0, 1, 1, 1, 1

resample_scaled_swapped_mono_to_stereo_unsigned_16:
    mix_pcm 2, 1, 0, 1, 1, 1, 1

resample_scaled_swapped_stereo_to_mono_signed_8:
    mix_pcm 1, 0, 1, 0, 1, 1, 1

resample_scaled_swapped_stereo_to_mono_unsigned_8:
    mix_pcm 1, 1, 1, 0, 1, 1, 1

resample_scaled_swapped_stereo_to_mono_signed_16:
    mix_pcm 2, 0, 1, 0, 1, 1, 1

resample_scaled_swapped_stereo_to_mono_unsigned_16:
    mix_pcm 2, 1, 1, 0, 1, 1, 1

resample_scaled_swapped_stereo_to_stereo_signed_8:
    mix_pcm 1, 0, 1, 1, 1, 1, 1

resample_scaled_swapped_stereo_to_stereo_unsigned_8:
    mix_pcm 1, 1, 1, 1, 1, 1, 1

resample_scaled_swapped_stereo_to_stereo_signed_16:
    mix_pcm 2, 0, 1, 1, 1, 1, 1

resample_scaled_swapped_stereo_to_stereo_unsigned_16:
    mix_pcm 2, 1, 1, 1, 1, 1, 1
