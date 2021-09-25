; -------------------------------------------------------------------
; Program to launch the Visual/02 debugger from the STG ROM
; Copyright 2021 by Gaston Williams
; -------------------------------------------------------------------
; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include ops.inc
#include    bios.inc
#include    kernel.inc

#define V2 0C200h
#define V2DATA 07f00h

; ************************************************************
; ***** This block generates the 6 byte Execution header *****
;
; ************************************************************
; The Execution header starts 6 bytes before the program start
        org     02000h-6            ; Header starts at 01ffah
           dw      02000h           ; Program load address
           dw      endrom-2000h     ; Program size
           dw      02000h           ; Program execution address
           
        org     02000h              ; Program code starts here
           br      start            ; Jump past build information
       
       ; Build date
date:      db      80H+9            ; Month 80H offset means extended info
           db      24               ; Day
           dw      2021             ; Year
           
       ; Current build number
build:     dw      5                ; build for kernel 4

                                    ; Must end with 0 (null)
           db      'Copyright 2021 by Gaston Williams',0

start:     LOAD    rf, 0C220h       ; need to check signature in STG ROM
           lda     rf               ; looking for 0,ADC,0
           lbnz    bad              ; if any portion is missing, error
           lda     rf
           smi     'A'
           lbnz    bad
           lda     rf
           smi     'D'
           lbnz    bad
           lda     rf
           smi     'C'
           lbnz    bad
           lda     rf
           smi     ' '
           lbnz    bad
           lda     rf
           lbz     go
bad:       CALL    o_inmsg           ; Visual/02 not present, display error
           db      'Visual/02 is not present in ROM.  Aborting.',10,13,0
           lbr     o_wrmboot
           
go:        ldn     ra                  ; see if argument provided
           lbz     V2+3                ; jump immediately to visual/02 if none
           COPY    ra, rf              ; copy argument address to rf

loop1:     lda     rf                  ; look for first less <= space
           smi     33
           bdf     loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           COPY    ra, rf              ; back to beginning of name
  
           LOAD    rd, fildes          ; get file descriptor
  
           ldi     0                   ; flags for open
           plo     r7
           
           CALL    o_open              ; attempt to open file
           bnf     opened              ; jump if file was opened
           
           LOAD    rf, errmsg          ; get error message
           CALL    o_msg               ; display it      
           lbr     o_wrmboot           ; and return to os

opened:    LOAD    rf, buffer          ; buffer to retrieve data    
           LOAD    rc, 6               ; need to read 6 byte header           
           CALL    o_read              ; read the header

           LOAD    r9, buffer          ; point to header
           lda     r9                  ; get load address
           phi     rf
           lda     r9
           plo     rf
           lda     r9                  ; get size
           phi     rc
           lda     r9
           plo     rc
           lda     r9                  ; get start address
           phi     r7
           lda     r9
           plo     r7
           ldi     V2DATA.1
           phi     r8
           ldi     6
           plo     r8 
           ghi     r7                  ; write start address to R3
           str     r8
           inc     r8
           glo     r7
           str     r8
           CALL    o_read              ; read rest of file
           CALL    o_close             ; close the file
      
           ldi     V2DATA.1
           phi     r8
           ldi     4                   ; point to R2
           plo     r8
           ghi     r2                  ; copy stack pointer
           str     r8
           inc     r8
           glo     r2
           str     r8
           ldi     3                   ; P=3
           plo     r9
           ldi     2                   ; X=2
           phi     r9
           lbr     V2+3                ; jump to Visual/02 in STG ROM

errmsg:    db      'File not found',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

buffer:    ds      10
outbuf:    dw      80

dta:       ds      512
