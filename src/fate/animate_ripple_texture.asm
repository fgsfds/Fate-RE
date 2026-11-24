; Advance the ripple effect in a 128-by-128 texture.
BITS 32
ORG 0x2eb57
section .text align=1

radial_sample_count equ 0x5ae5c
radial_x_offsets equ 0x5aedc
radial_y_offsets equ 0x5eedc
random_value equ 0x602d0
ripple_radius equ 0x62fcc
frame_state_630fc equ 0x630fc
ripple_buffer equ 0x6331c
frame_state_6331d equ 0x6331d
frame_state_6339d equ 0x6339d
frame_state_633a1 equ 0x633a1
frame_state_675a0 equ 0x675a0
frame_state_67623 equ 0x67623
ripple_origin_y equ 0x6773c
ripple_origin_x equ 0x677bc
ripple_count equ 0x770e0
ripple_frame equ 0x770f4

animate_ripple_texture:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
; C computes and clamps the creation count in EAX.
; C establishes the tile register and the creation step.
section .control align=1 vstart=0x2eb80 follows=.text
    jmp short .branch_2ebc5

.branch_2eb82:
; C copies the X draw, reads the slot, masks it, and stores the coordinate.
; Its EBP countdown handoffs surround the selected X instructions.
; C stores the Y draw, radius and updated count.
section .after_spawn_slot align=1 vstart=0x2ebca follows=.control

.branch_2ebc5 equ 0x2ebc5
    jnl short .branch_2eb82
section .radial_jump align=1 vstart=0x2ebd5 follows=.after_spawn_slot
    jmp near .branch_2ecb2

.branch_2ebda:
; C supplies the slot handoff, radial setup and Y-origin handoff.
section .after_radial_setup align=1 vstart=0x2ec1a follows=.radial_jump
    jmp short .branch_2ec5f

.branch_2ec1c equ 0x2ec1c
; C supplies sample coordinate selection and byte addition.
; C clamps the updated pixel to the original floor.
section .after_pixel_floor align=1 vstart=0x2ec61 follows=.after_radial_setup

.branch_2ec5e equ 0x2ec5e

.branch_2ec5f equ 0x2ec5f
    jnl short .branch_2ec1c
; C advances the radius and removes expired rings.

.branch_2ecaf equ 0x2ecaf

.branch_2ecb2 equ 0x2ecb2
; C establishes the masked-row destination and tile input.
; C resets the row counter at each pass ingress.
section .mask_row_counter align=1 vstart=0x2ecc6 follows=.after_pixel_floor
    jmp short .branch_2ece9

.branch_2ecc8 equ 0x2ecc8
; C copies and masks one 128-byte row, returning the next row in EAX.
; C advances the shared EBP row counter.
section .after_mask_row align=1 vstart=0x2ecef follows=.mask_row_counter

.branch_2ece9 equ 0x2ece9
    jl short .branch_2ecc8
; C supplies the counter initialization and top/bottom border loop.
section .after_border_columns align=1 vstart=0x2ed1b follows=.after_mask_row
    jmp short .branch_2ed4c

.branch_2ed1d equ 0x2ed1d
; C head, counter increment and tail share the caller's row state.
section .vertical_row_guard align=1 vstart=0x2ed52 follows=.after_border_columns
.branch_2ed4c equ 0x2ed4c
    jl short .branch_2ed1d
; C supplies all four corner reads, masks and stores.
; C also supplies the output tile pointer and row reset.
section .after_corners align=1 vstart=0x2ed85 follows=.vertical_row_guard
    jmp near .branch_2ee92

.branch_2ed8a equ 0x2ed8a
; C computes the output row and shared end-pointer slot.
section .output_row_jump align=1 vstart=0x2eda9 follows=.after_corners
    jmp near .branch_2ee87

.branch_2edae:
; C supplies all stencil pointers, four sums and packed-lane handoffs.
; C stores the packed word and advances both pointers.
; C supplies both signed loop guards, the row increment and frame advance.
.branch_2ee87 equ 0x2ee87
.branch_2ee92 equ 0x2ee92
section .output_epilogue align=1 vstart=0x2eea7 follows=.output_row_jump
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
