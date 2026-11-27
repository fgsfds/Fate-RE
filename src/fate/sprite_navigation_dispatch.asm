; Original CODE-relative jump table for the board route initializers.
BITS 32
ORG 0x1d38a

navigation_dispatch:
%assign case_address 0x1d44a
%rep 25
    dd case_address - 0x10000
    %if case_address < 0x1d6a2
        %assign case_address case_address + 30
    %else
        %assign case_address case_address + 27
    %endif
%endrep
