; Start the sequence encoded in a sprite's lotag.
BITS 32
ORG 0x11fdd
sprite equ 0x2040a0
rows equ 0x6807c
active equ 0x7dee0
list equ 0x67a3c
floor_z equ 0x27c3a8
tile_height equ 0x1f4020
random equ 0x602d0
sound equ 0x34f79
format_error equ 0x601f3
report_error equ 0x26a03
spawn equ 0x11073
move_sprite equ 0x339b9
append equ 0x134c2

%define sequence esp+28
%define debris esp+32
%define sign_x esp+24
%define sign_y esp+20
%define spawned esp+16

start_sequence_:
 push ebx
 push ecx
 push edx
 push esi
 push edi
 push ebp
 sub esp,32
 push eax
 cwde
 imul eax,eax,44
 movsx eax,word [eax+sprite+38]
 and eax,0xff00
 sar eax,8
 mov [sequence],eax
 test ax,ax
 je near .done
 mov eax,1
 jmp .test_active
.scan:
 movsx edx,ax
 mov ebx,[esp]
 cmp bx,[nosplit edx*2+list]
 je near .done
 inc eax
.test_active:
 cmp ax,[active]
 jle .scan

 ; Select one of eight sound slots when sound is enabled.
 movsx edx,word [sequence]
 mov eax,edx
 shl eax,4
 sub eax,edx
 mov edx,eax
 shl edx,3
 cmp word [edx+rows+104],0
 je .enqueue
 call random
 and eax,7
 mov cx,[edx+eax*2+rows+104]
 movsx eax,word [esp]
 imul eax,eax,44
 mov ebx,[eax+sprite+4]
 mov edx,[eax+sprite]
 movsx eax,cx
 mov ecx,2
 call sound
.enqueue:
 mov si,[active]
 inc esi
 movsx eax,si
 mov [active],si
 cmp eax,511
 jle .store
 push dword 0x1b0
 push dword 0x67e3c
 call format_error
 add esp,8
 mov eax,0x67e3c
 call report_error
.store:
 movsx eax,word [active]
 mov edx,[esp]
 mov [nosplit eax*2+list],dx
 movsx edx,word [sequence]
 mov eax,edx
 shl eax,4
 sub eax,edx
 mov dx,[nosplit eax*8+rows]
 test dx,dx
 jle near .debris_begin
 movsx eax,word [esp]
 imul eax,eax,44
 mov [eax+sprite+14],dx
 movsx edx,dx
 cmp edx,807
 je .special_tile
 cmp edx,803
 je .special_tile
 cmp edx,827
 je .special_tile
 cmp edx,910
 je .special_tile
 cmp edx,771
 je .special_tile
 cmp edx,866
 je .special_tile
 mov dx,[eax+sprite+12]
 xor dh,dh
 and dl,0x80
 movsx edx,dx
 test edx,edx
 je near .debris_begin
 and byte [eax+sprite+12],0x7f
 movsx ebx,word [eax+sprite+24]
 jmp .place_at_floor
.special_tile:
 movsx eax,word [esp]
 imul eax,eax,44
 mov byte [eax+sprite+16],0xc0
 movsx edx,word [eax+sprite+30]
 cmp edx,1
 jne .check_extra
 mov dl,[eax+sprite+20]
 add dl,dl
 mov [eax+sprite+20],dl
 mov dl,[eax+sprite+21]
 add dl,dl
 mov [eax+sprite+21],dl
.check_extra:
 movsx eax,word [esp]
 imul eax,eax,44
 mov dx,[eax+sprite+42]
 xor dl,dl
 and dh,0x20
 movsx edx,dx
 test edx,edx
 je .debris_begin
 mov dh,[eax+sprite+12]
 and dh,0x7f
 movsx ebx,word [eax+sprite+24]
 mov [eax+sprite+12],dh
.place_at_floor:
 mov edx,ebx
 shl edx,2
 add edx,ebx
 mov edx,[nosplit edx*8+floor_z]
 mov [eax+sprite+8],edx

.debris_begin:
 mov dword [debris],4
 jmp near .test_debris
.spawn_debris:
 movsx ebx,word [sequence]
 mov eax,ebx
 shl eax,4
 add edx,edx
 sub eax,ebx
 mov si,[edx+eax*8+rows]
 test si,si
 je near .done
 call random
 test al,1
 jne .negative_x
 mov dword [sign_x],1
 jmp .roll_y
.negative_x:
 mov dword [sign_x],-1
.roll_y:
 call random
 test al,1
 jne .negative_y
 mov dword [sign_y],1
 jmp .position
.negative_y:
 mov dword [sign_y],-1
.position:
 movsx edx,word [esp]
 imul edx,edx,44
 mov eax,[edx+sprite]
 mov cx,[edx+sprite+24]
 mov [esp+4],eax
 mov eax,[edx+sprite+4]
 movsx ebx,cx
 mov [esp+8],eax
 mov eax,[edx+sprite+8]
 lea edx,[esp+4]
 mov [esp+12],eax
 movsx eax,si
 call spawn
 movsx ebx,word [sequence]
 mov edx,eax
 mov [spawned],eax
 mov eax,ebx
 shl eax,4
 movsx esi,word [debris]
 sub eax,ebx
 add esi,esi
 shl eax,3
 add esi,eax
 mov di,[esi+rows+4]
 test di,di
 jne .moving
 movsx eax,dx
 imul eax,eax,44
 mov dx,[eax+sprite+12]
 xor dh,dh
 and dl,0x80
 movsx edx,dx
 test edx,edx
 je .uncentered
 movsx edx,word [eax+sprite+14]
 xor ebx,ebx
 movsx edx,word [nosplit edx*2+tile_height]
 mov bl,[eax+sprite+21]
 imul ebx,edx
 add ebx,ebx
 jmp .debris_floor
.uncentered:
 xor ebx,ebx
.debris_floor:
 movsx edx,cx
 mov eax,edx
 shl eax,2
 add eax,edx
 mov edx,[nosplit eax*8+floor_z]
 movsx eax,word [spawned]
 imul eax,eax,44
 sub edx,ebx
 mov [eax+sprite+8],edx
 jmp near .next_debris
.moving:
 movsx ebx,word [sign_x]
 mov cx,[esi+rows+2]
 call random
 and eax,32767
 imul eax,ebx
 movsx ebx,cx
 imul eax,ebx
 shl eax,6
 movsx ebp,word [sign_y]
 mov [esp+4],eax
 call random
 and eax,32767
 imul eax,ebp
 imul ebx,eax
 shl ebx,6
 mov [esp+8],ebx
 xor ebx,ebx
 xor ecx,ecx
 push ebx
 movsx ebp,dx
 push dword 1024
 mov edx,[esp+12]
 mov eax,ebp
 push dword 1024
 mov [esp+24],ebx
 mov ebx,[esp+20]
 call move_sprite
 imul edx,ebp,44
 call random
 mov ecx,[sign_x]
 xor ah,ah
 imul eax,ecx
 imul eax,edi
 mov ebx,[sign_y]
 mov [edx+sprite+32],ax
 call random
 xor ah,ah
 imul eax,ebx
 imul eax,edi
 mov [edx+sprite+34],ax
 call random
 and ah,1
 imul eax,eax,-1
 imul edi,eax
 movsx eax,word [esi+rows+6]
 mov [edx+sprite+36],di
 cmp eax,1
 jne .append
 mov ax,[edx+sprite+42]
 or ah,0x80
 mov [edx+sprite+42],ax
.append:
 movsx eax,word [spawned]
 call append
.next_debris:
 add dword [debris],4
.test_debris:
 movsx edx,word [debris]
 cmp edx,51
 jle near .spawn_debris
.done:
 add esp,36
 pop ebp
 pop edi
 pop esi
 pop edx
 pop ecx
 pop ebx
 ret
