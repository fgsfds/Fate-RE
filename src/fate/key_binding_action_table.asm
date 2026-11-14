; Action IDs and pointers to their 14-byte menu captions.
BITS 32
ORG 0x13554

action_names equ 0xef5
%assign action 0
%rep 25
    dd action, action_names + 14 * action
    %assign action action + 1
%endrep
