; Is first player sprite.
BITS 32
ORG 0x4037a

player_sprite equ 0x62f2c

is_first_player_sprite:
    cmp ax, [player_sprite]
    setz al
    and eax, strict dword 0xff
    ret
