; *******************************************************************************************
; mfree - De-allocate a block of memory from the heap.
; Copyright (c) 2021 by Gaston Williams
; *******************************************************************************************

#include ops.inc
#include bios.inc
#include kernel.inc
                                                 
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
binfo:              db  80H+9             ; Month, 80H offset means extended info
                    db  22                ; Day
                    dw  2021              ; Year

                    ; Current build number
build:              dw  5

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
       CALL    o_inmsg     ; otherwise display usage      
       db      'Usage: mfree hhhh, deallocate memory block at hex address <hhhh> from the heap.',13,10,0
       lbr     bye         ; return to Elf/OS     

good:  COPY    ra, rf      ; copy argument address to rf
       CALL    f_hexin     ; convert input to hexadecimal value

       COPY    rd, rf      ; RD contains the block address
                           ; Move address into RF to de-allocate block
       
       CALL    o_dealloc   ; de-allocate block
           
bye:   lbr     o_wrmboot   ; return to Elf/OS       
;----------------------------------------------------------------------------------------
                    
; define end of execution block
endrom:   EQU     $
