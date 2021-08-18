; *******************************************************************************************
; MemoryHog - Allocate a block of memory on the heap for testing low memory conditions.
;
; Copyright (c) 2021 by Gaston Williams
;
; *******************************************************************************************
include bios.inc
include kernel.inc
                                                 
; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
                        ORG     02000h-6  ; Header starts at 01ffah
                    dw  02000h            ; Program load address
                    dw  endrom-2000h      ; Program size
                    dw  02000h            ; Program execution address

                        ORG     02000h    ; code starts here
                    br  start             ; Jump past build info to code

; Build information
binfo:              db  80H+8             ; Month, 80H offset means extended info
                    db  18                ; Day
                    dw  2021              ; Year

                    ; Current build number
build:              dw  4

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start: lda     ra          ; move past any spaces
       smi     ' '
       lbz     start
       dec     ra          ; move back to non-space character
       ldn     ra          ; check for nonzero byte
       lbnz    good        ; jump if non-zero
       sep     scall       ; otherwise display usage
       dw      o_inmsg
       db      'Usage: MemoryHog size, allocate memory block of <size> in the heap.',13,10,0
       lbr     o_wrmboot   ; return to Elf/OS     

good:  ghi     ra          ; copy argument address to rf
       phi     rf
       glo     ra
       plo     rf
       sep     scall       ; convert input to integer value
       dw      f_atoi

start: ghi     rd          ; RD contains the block size in bytes
       phi     rc          ; Move size into RC for allocate
       glo     rd
       plo     rc          ; load block size
           
       ldi     00H         ; no alignment 

       phi     r7
       ldi     04H         ; permanent allocation
       plo     r7
       sep     scall       ; allocate a block of memory
       dw      o_alloc
       bnf     okay        ; DF = 1 means allocation failed
       
       sep     scall       ; display test message
       dw      o_inmsg
       db      'Allocation failed.',13,10,0
okay:  lbr     o_wrmboot   ; return to Elf/OS       
;----------------------------------------------------------------------------------------
                    
; define end of execution block
endrom:   EQU     $
