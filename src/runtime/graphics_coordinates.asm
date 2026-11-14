; Graphics world-to-pixel transforms and their inverse.
BITS 32
ORG 0x7326a

double_to_float equ 0x73cca
float_subtract equ 0x73d16
float_add equ 0x73d20
float_multiply equ 0x73dcd
float_divide equ 0x73e44
float_to_i32 equ 0x73ec4
i32_to_float equ 0x73f73
float_to_double equ 0x73f84
graphics_available equ 0x6ffe6

viewport_origin_first equ 0x16c6c
viewport_origin_second equ 0x16c6e
world_bounds equ 0x16cd5
reverse_second_axis equ 0x16ce5
world_first_min equ 0x16ce7
world_second_min equ 0x16ceb
world_first_max equ 0x16cef
world_second_max equ 0x16cf3
first_extent equ 0x2891fc
second_extent equ 0x2891fe
pixel_first_min equ 0x289216
pixel_first_max equ 0x289218
pixel_second_min equ 0x28921a
pixel_second_max equ 0x28921c
second_pixel_scale equ 0x2892e0
first_pixel_scale equ 0x2892e4
second_extent_scale equ 0x2892e8
first_extent_scale equ 0x2892ec

map_first_coordinate:
    call double_to_float
    mov edx, dword [world_first_min]
    call float_subtract
    mov edx, dword [first_pixel_scale]
    call float_multiply
    call float_to_i32
    movsx edx, word [pixel_first_min]
    cwde
    add eax, edx
    ret

map_second_coordinate:
    cmp word [reverse_second_axis], 0
    je short .forward
    call double_to_float
    mov edx, eax
    mov eax, dword [world_second_max]
    jmp short .scale
.forward:
    call double_to_float
    mov edx, dword [world_second_max]
.scale:
    call float_subtract
    mov edx, dword [second_pixel_scale]
    call float_multiply
    call float_to_i32
    add ax, word [pixel_second_min]
    ret

map_first_extent:
    push ebx
    push ecx
    mov ecx, eax
    movsx eax, word [first_extent]
    call i32_to_float
    mov ebx, eax
    mov eax, ecx
    call double_to_float
    mov edx, eax
    mov eax, ebx
    call float_multiply
    mov edx, dword [first_extent_scale]
.finish:
    call float_multiply
    call float_to_i32
    pop ecx
    pop ebx
    ret

map_second_extent:
    push ebx
    push ecx
    mov ecx, eax
    movsx eax, word [second_extent]
    call i32_to_float
    mov ebx, eax
    mov eax, ecx
    call double_to_float
    mov edx, eax
    mov eax, ebx
    call float_multiply
    mov edx, dword [second_extent_scale]
    jmp short map_first_extent.finish

unmap_coordinate_pair:
    push ebx
    push ecx
    push edi
    push es
    enter 0x10, 0
    mov ebx, esi
    mov ecx, eax
    mov edi, edx
    call graphics_available
    test ax, ax
    je near .disabled
    movsx eax, word [viewport_origin_first]
    movsx edx, cx
    movsx esi, word [pixel_first_min]
    add eax, edx
    sub eax, esi
    call i32_to_float
    mov edx, dword [world_first_min]
    mov ecx, eax
    mov eax, dword [world_first_max]
    call float_subtract
    mov edx, ecx
    call float_multiply
    mov ecx, eax
    movsx eax, word [pixel_first_max]
    sub eax, esi
    call i32_to_float
    mov edx, eax
    mov eax, ecx
    call float_divide
    mov edx, eax
    mov eax, dword [world_first_min]
    call float_add
    call float_to_double
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    movsx eax, word [viewport_origin_second]
    movsx edx, di
    movsx ecx, word [pixel_second_min]
    add eax, edx
    sub eax, ecx
    call i32_to_float
    mov edx, eax
    movsx eax, word [pixel_second_max]
    sub eax, ecx
    call i32_to_float
    mov ecx, eax
    mov eax, edx
    mov edx, ecx
    call float_divide
    mov ecx, eax
    cmp word [reverse_second_axis], 0
    je short .forward_second_axis
    mov eax, dword [world_second_max]
    mov edx, dword [world_second_min]
    call float_subtract
    mov edx, eax
    mov eax, ecx
    call float_multiply
    mov edx, eax
    mov eax, dword [world_second_max]
    call float_subtract
.store_second_axis:
    call float_to_double
    mov dword [ebp - 8], eax
    mov dword [ebp - 4], edx
    jmp short .copy_result
.forward_second_axis:
    mov eax, dword [world_second_min]
    mov edx, dword [world_second_max]
    call float_subtract
    mov edx, eax
    mov eax, ecx
    call float_multiply
    mov edx, dword [world_second_max]
    call float_add
    jmp short .store_second_axis
.disabled:
    mov dword [ebp - 0x10], 0
    mov dword [ebp - 0xc], 0
    mov dword [ebp - 8], 0
    mov dword [ebp - 4], 0
.copy_result:
    lea esi, [ebp - 0x10]
    push ds
    pop es
    mov edi, ebx
    movsd
    movsd
    movsd
    movsd
    mov eax, ebx
    leave
    pop es
    pop edi
    pop ecx
    pop ebx
    ret

map_coordinate_pair:
    push esi
    enter 4, 0
    mov esi, eax
    call graphics_available
    test ax, ax
    je short .disabled
    mov eax, esi
    call map_first_coordinate
    sub ax, word [viewport_origin_first]
    mov edx, ecx
    mov word [ebp - 4], ax
    mov eax, ebx
    call map_second_coordinate
    sub ax, word [viewport_origin_second]
    jmp short .pack_result
.disabled:
    mov word [ebp - 4], ax
.pack_result:
    mov word [ebp - 2], ax
    mov eax, dword [ebp - 4]
    leave
    pop esi
    ret

map_pair_stack:
    push ebx
    push ecx
    push edx
    push ebp
    mov ebp, esp
    mov eax, dword [ebp + 0x14]
    mov edx, dword [ebp + 0x18]
    mov ebx, dword [ebp + 0x1c]
    mov ecx, dword [ebp + 0x20]
    call map_coordinate_pair
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret 0x10

map_pair_from_pointer:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, dword [eax + 8]
    mov ecx, dword [eax + 0xc]
    mov ebx, dword [eax]
    mov edx, dword [eax + 4]
    mov eax, ebx
    mov ebx, esi
    call map_coordinate_pair
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

copy_world_bounds:
    push edi
    push es
    enter 0x10, 0
    mov eax, esi
    lea edi, [ebp - 0x10]
    push ds
    pop es
    mov esi, world_bounds
    movsd
    movsd
    movsd
    movsd
    lea esi, [ebp - 0x10]
    mov edi, eax
    movsd
    movsd
    movsd
    movsd
    leave
    pop es
    pop edi
    ret

recalculate_coordinate_scales:
    push ebx
    push edx
    mov eax, dword [world_first_max]
    mov edx, dword [world_first_min]
    call float_subtract
    movsx edx, word [pixel_first_max]
    mov ebx, eax
    movsx eax, word [pixel_first_min]
    sub edx, eax
    mov eax, edx
    mov edx, ebx
    call i32_to_float
    call float_divide
    mov dword [first_pixel_scale], eax
    mov edx, ebx
    mov eax, 0x3f800000
    call float_divide
    mov dword [first_extent_scale], eax
    cmp word [reverse_second_axis], 0
    je short .forward_second_axis
    mov eax, dword [world_second_max]
    mov edx, dword [world_second_min]
    jmp short .second_axis_difference
.forward_second_axis:
    mov eax, dword [world_second_min]
    mov edx, dword [world_second_max]
.second_axis_difference:
    call float_subtract
    mov ebx, eax
    movsx edx, word [pixel_second_max]
    movsx eax, word [pixel_second_min]
    sub edx, eax
    mov eax, edx
    mov edx, ebx
    call i32_to_float
    call float_divide
    mov dword [second_pixel_scale], eax
    mov edx, ebx
    mov eax, 0x3f800000
    call float_divide
    mov dword [second_extent_scale], eax
    pop edx
    pop ebx
    ret
