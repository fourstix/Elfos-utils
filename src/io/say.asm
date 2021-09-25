; *******************************************************************************************
; Say - Write input string to console
; Copyright (c) 2021 by Gaston Williams
; *******************************************************************************************

#include  ops.inc
#include  bios.inc
#include  kernel.inc

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
                  org    02000h-6       ; Header starts at 01ffah
                    dw  02000h          ; Program load address
                    dw  endrom-2000h    ; Program size
                    dw  02000h          ; Program execution address

                  org     02000h        ; Program code starts here
                    br  start           ; Jump past build info to code

; Build information
binfo:              db  80H+9           ; Month, 80H offset means extended info
                    db  23              ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  5

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:              lda   ra                ; move past any spaces
                    smi   ' '
                    bz    start
                    dec   ra                ; move back to non-space character
                    ldn   ra                ; check for nonzero byte
                    bnz   good              ; jump if non-zero
                    LOAD  rf, usage         ; display usage message
                    CALL  o_msg             ; otherwise display
                    RETURN                  ; return to Elf/OS
                              
good:               COPY  ra, rf            ; copy RA to RF
                    CALL  o_msg             ; display text message
                    RETURN                  ; return to Elf/OS
                        
usage:              db   'Usage: say text',10,13,0 
                        
                        
;----------------------------------------------------------------------------------------
; define end of execution block
endrom: EQU     $

; buffers are in HiMem
