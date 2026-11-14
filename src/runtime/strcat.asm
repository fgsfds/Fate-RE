; Independently reconstructed Watcom-register-ABI concatenation from pinned FATE.
; No library object or executable byte payload is embedded.
; EAX destination, EDX source; EAX returns the original destination.
; Caller supplies valid disjoint strings, enough output capacity and clear DF.
BITS 32
strcat_:
 push ecx
 push esi
 push edi
 mov edi,eax
 mov esi,edx
 push es
 push ds
 pop es
 push edi
 ; SUB r32,r/m32 form, ECX destination and source, selects the original encoding.
 db 0x2b, 0xc0 | (1 << 3) | 1
 dec ecx
 mov al,0
 repne scasb
 dec edi
.copy_pair:
 mov al,[esi]
 mov [edi],al
 cmp al,0
 je near .done
 mov al,[esi+1]
 add esi,2
 mov [edi+1],al
 add edi,2
 cmp al,0
 jne .copy_pair
.done:
 pop edi
 pop es
 mov eax,edi
 pop edi
 pop esi
 pop ecx
 ret
