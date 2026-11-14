; Diagnostics for crusher activation and per-tick updates.
BITS 32
ORG 0x145c

    db 'checkforplayersquish: invalid sector', 0
    db 'checkforplayersquish: NULL csinfo', 0
    db 'checkforspritesquish: invalid sector', 0
    db 'checkforspritequish: NULL csinfo', 0
    db 'crushsectorsound: bad cs ptr', 0
    db 'entr_crushsector: out of range', 0
    db 'crushsectors_walkintrigger: not initialized', 0
    db 'entr_crushsector: invalid sector', 0
    db 'crushsector_walkintrigger: csindx not found', 0
    db 'trg_crushsector: out of range', 0
    db 'crushsectors_walkintrigger: not initialized', 0
    db 'trg_crushsector: invalid sector', 0
    db 'crushsector_walkintrigger: csindx not found', 0
    db 'ud_crushsector: out of range', 0
    db 'updatecrushsectors: not initialized', 0
    db 'updatesectors: bad sectnum', 0
