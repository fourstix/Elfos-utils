; *******************************************************************************************
; mfree - De-allocate a block of memory from the heap.
; Copyright (c) 2021 by Gaston Williams
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
                    db  21                ; Day
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
       db      'Usage: mfree hhhh, deallocate memory block at hex address <hhhh> from the heap.',13,10,0
       lbr     bye         ; return to Elf/OS     

good:  ghi     ra          ; copy argument address to rf
       phi     rf
       glo     ra
       plo     rf
       sep     scall       ; convert input to hexadecimal value
       dw      f_hexin

       ghi     rd          ; RD contains the block address
       phi     rf          ; Move address into RF to de-allocate
       glo     rd
       plo     rf          ; load block address
       
       sep     scall 
       dw      o_dealloc
           
bye:   lbr     o_wrmboot   ; return to Elf/OS       
;----------------------------------------------------------------------------------------
                    
; define end of execution block
endrom:   EQU     $
