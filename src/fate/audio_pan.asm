; Independently reconstructed FATE pan arithmetic and register ABI.
; Natural adjacent entries; semantic instructions, no executable byte payload.
; NASM encoding is explicit source reconstruction, not recovered compiler source.
BITS 32
ORG 0x34e77
listener_index equ 0x3cfa
listener_x equ 0x5ad9c
listener_y equ 0x5ad5c
listener_angle equ 0x6308c
pan_table equ 0x12c40
getangle_ equ 0x4c94c

audio_pan_:
 push ebx
 push ecx
 push esi
 mov ebx,eax
 movsx eax,word [listener_index]
 mov esi,[eax*4+listener_y]
 mov ecx,eax
 sub esi,edx
 mov eax,[eax*4+listener_x]
 mov edx,esi
 sub eax,ebx
 call getangle_
 sub ax,[nosplit ecx*2+listener_angle]
 and ah,7
 cwde
 mov edx,eax
 shl edx,6
 cmp eax,1024
 jle .first_half
 cmp eax,1536
 jg .last_quadrant
 lea eax,[edx-32768]
 jmp .upper_clamp
.last_quadrant:
 mov edx,2048
 sub edx,eax
 mov eax,edx
 shl eax,6
 add eax,32768
.upper_clamp:
 cmp eax,65535
 jbe .done
 mov eax,65535
 pop esi
 pop ecx
 pop ebx
 ret
.first_half:
 cmp eax,512
 jl .first_quadrant
 mov edx,1024
 sub edx,eax
 mov eax,edx
 mov edx,32768
 shl eax,6
 sub edx,eax
 mov eax,edx
 jmp .lower_clamp
.first_quadrant:
 mov eax,32768
 sub eax,edx
.lower_clamp:
 cmp eax,32768
 jbe .done
 xor eax,eax
.done:
 pop esi
 pop ecx
 pop ebx
 ret

audio_sprite_pan_:
 push ebx
 push ecx
 push esi
 mov ebx,eax
 mov ecx,edx
 movsx edx,word [listener_index]
 mov esi,2047
 movsx eax,word [nosplit edx*2+listener_angle]
 sub esi,eax
 mov eax,edx
 mov edx,[edx*4+listener_y]
 mov eax,[eax*4+listener_x]
 sub edx,ecx
 sub eax,ebx
 call getangle_
 add eax,esi
 and eax,2047
 sar eax,6
 test eax,eax
 jl .fallback
 cmp eax,35
 jle .lookup
.fallback:
 mov eax,13
.lookup:
 mov eax,[eax*4+pan_table]
 pop esi
 pop ecx
 pop ebx
 ret
