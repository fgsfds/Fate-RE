; Independently reconstructed ASCII case-insensitive comparison from pinned FATE.
; No library object or executable byte payload is embedded.
; EAX/EDX point to NUL-terminated byte strings; EAX returns folded byte difference.
BITS 32
stricmp_:
 push ebx
.compare:
 mov bl,[eax]
 mov bh,[edx]
 cmp bl,'A'
 jb .left_folded
 cmp bl,'Z'
 ja .left_folded
 add bl,'a'-'A'
.left_folded:
 cmp bh,'A'
 jb .right_folded
 cmp bh,'Z'
 ja .right_folded
 add bh,'a'-'A'
.right_folded:
 cmp bl,bh
 jne .difference
 test bh,bh
 jz .difference
 inc eax
 inc edx
 jmp .compare
.difference:
 xor edx,edx
 xor eax,eax
 mov dl,bl
 mov al,bh
 sub edx,eax
 mov eax,edx
 pop ebx
 ret
