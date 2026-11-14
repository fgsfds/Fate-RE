; DATA-relative key name pointers indexed by PC scan code.
BITS 32
ORG 0x13154

blank_key_name equ 0xd84
%assign key_name blank_key_name
%macro key_names_of_size 2
    %rep %2
        dd key_name
        %assign key_name key_name + %1
    %endrep
%endmacro

    key_names_of_size 1, 1
    key_names_of_size 4, 1
    key_names_of_size 2, 12
    key_names_of_size 6, 1
    key_names_of_size 4, 1
    key_names_of_size 2, 12
    key_names_of_size 6, 2
    key_names_of_size 2, 12
    key_names_of_size 6, 1
    key_names_of_size 2, 11
    key_names_of_size 6, 5
    key_names_of_size 3, 9
    key_names_of_size 4, 1
    key_names_of_size 6, 15
    times 3 dd blank_key_name
    key_names_of_size 4, 1
    key_names_of_size 4, 1
    times 67 dd blank_key_name
    key_names_of_size 6, 1
    key_names_of_size 6, 1
    times 23 dd blank_key_name
    key_names_of_size 6, 1
    times 1 dd blank_key_name
    key_names_of_size 6, 1
    key_names_of_size 6, 1
    times 14 dd blank_key_name
    key_names_of_size 5, 1
    key_names_of_size 6, 1
    key_names_of_size 6, 1
    times 1 dd blank_key_name
    key_names_of_size 6, 1
    times 1 dd blank_key_name
    key_names_of_size 6, 1
    times 1 dd blank_key_name
    key_names_of_size 4, 1
    key_names_of_size 6, 1
    key_names_of_size 6, 1
    key_names_of_size 4, 1
    key_names_of_size 4, 1
    times 44 dd blank_key_name
