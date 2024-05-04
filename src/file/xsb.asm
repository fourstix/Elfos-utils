; -------------------------------------------------------------------
; XMODEM Send for the STG Hardware UART
; Copyright 2021 by Gaston Williams
; -------------------------------------------------------------------
; *******************************************************************
; *** This software is copyright 2005 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include ops.inc
#include bios.inc
#include  kernel.inc

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************

         org     02000h-6         ; Header starts at 01ffah
           dw      2000h
           dw      endrom-2000h
           dw      2000h
         org     2000h            ; Program code starts at 2000
           br      start

           ; Build information
           ever 
           
           ; Must end with 0 (null)
           db      'Copyright 2021 Gaston Williams',0

fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

start:     lda     ra                 ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                 ; move back to non-space character
           ghi     ra                 ; copy argument address to rf
           ldn     ra                 ; get byte
           lbnz    start1             ; jump if argument given
           CALL    o_inmsg            ; otherwise display usage message
           db      'Usage: xsb filename',10,13,0
           RETURN                     ; and return to os
           
start1:    COPY    ra, rf             ; copy argument address to rf

loop1:     lda     ra                 ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     ra                 ; backup to char
           ldi     0                  ; need proper termination
           str     ra
           LOAD    rd, fildes         ; get file descriptor
    
           ldi     0                  ; no special flags
           plo     r7
           
           CALL    o_open             ; attempt to open file      
           lbnf    opened             ; jump if file opened
           
           LOAD    rf, errmsg         ; point to error message  
           CALL    o_msg              ; display error message
           lbr     o_wrmboot          ; return to Elf/OS

errmsg:    db      'file error',10,13,0

opened:    CALL    xopenw             ; open XMODEM channel

filelp:    LOAD    rf, rxbuffer       ; point to buffer

           LOAD    rc, 128            ; need to read 128 bytes

clearlp:   ldi     01ah               ; clear out buffer
           str     rf
           inc     rf
           dec     rc
           glo     rc
           lbnz    clearlp
           
           LOAD    rf, rxbuffer       ; point to buffer

           LOAD    rc, 128            ; need to read 128 bytes
           CALL    o_read             ; write buffer to file
           glo     rc                 ; see if bytes were read
           lbz     filedn             ; jump if not

           LOAD    rf, rxbuffer       ; point to buffer
           LOAD    rc, 128            ; need to send 128 bytes
           CALL    xwrite             ; send the block
           lbr     filelp             ; loop back until full file sent

filedn:    CALL    o_close            ; close file
           CALL    xclosew            ; close the XMODEM channel
           lbr     o_wrmboot           ; and return to os

; *******************************************
; ***** Open XMODEM channel for writing *****
; *******************************************
xopenw:    push    rf                ; save consumed register
           LOAD    rf,block          ; current block number
           ldi     1                 ; starts at 1
           str     rf                ; store into block number
           inc     rf                ; point to byte count
           ldi     0                 ; set count to zero
           str     rf                ; store to byte count
           LOAD    rf,baud           ; place to store baud constant
           ghi     re                ; need to turn off echo
           str     rf                ; save it
           ani     0feh
           phi     re                ; put it back
xopenw1:   CALL    o_readkey         ; read a byte from the serial port      
           smi     nak               ; need a nak character
           lbnz    xopenw1           ; wait until a nak is received
           pop     rf                ; recover rf
           RETURN                    ; and return to caller
; ***********************************
; ***** Write to XMODEM channel *****
; ***** RF - pointer to data    *****
; ***** RC - Count of data      *****
; ***********************************
xwrite:    push    r8                ; save consumed registers
           push    ra
           LOAD    ra,count          ; need address of count
           ldn     ra                ; get count
           str     r2                ; store for add
           plo     r8                ; put into count as well
           ldi     txrx.0            ; low byte of buffer
           add                       ; add current byte count
           plo     ra                ; put into ra
           ldi     txrx.1            ; high byte of buffer
           adci    0                 ; propagate carry
           phi     ra                ; ra now has address
xwrite1:   lda     rf                ; retrieve next byte to write
           str     ra                ; store into buffer
           inc     ra
           inc     r8                ; increment buffer count
           glo     r8                ; get buffer count
           ani     080h              ; check for 128 bytes in buffer
           lbz     xwrite2           ; jump if not
           CALL    xsend             ; send current block      
           ldi     0                 ; zero buffer count
           plo     r8
           LOAD    ra,txrx           ; reset buffer position
xwrite2:   dec     rc                ; decrement count
           glo     rc                ; see if done
           lbnz    xwrite1           ; loop back if not
           ghi     rc                ; need to check high byte
           lbnz    xwrite1           ; loop back if not
           LOAD    ra,count          ; need to write new count
           glo     r8                ; get the count
           str     ra                ; and save it
           pop     ra                ; pop consumed registers
           pop     r8
           RETURN                    ; and return to caller

; *******************************
; ***** Send complete block *****
; *******************************
xsend:     push    rf                 ; save consumed registers
           push    rc
xsendnak:  ldi     soh                ; need to send soh character
           phi     rc                 ; initial value for checksum
           CALL    o_type             ; send it
           LOAD    rf,block           ; need current block number
           ldn     rf                 ; get block number
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; put it back
           ldn     r2                 ; recover block number
           CALL    o_type             ; and send it
           ldn     rf                 ; get block number back
           sdi     255                ; subtract from 255
           str     r2                 ; save it
           ghi     rc                 ; get current checksum
           add                        ; add in inverted block number
           phi     rc                 ; put it back
           ldn     r2                 ; recover inverted block number
           CALL    o_type             ; send it
           ldi     128                ; 128 bytes to write
           plo     rc                 ; place into counter
           LOAD    rf,txrx            ; point rf to data block
xsend1:    lda     rf                 ; retrieve next byte
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; save checksum
           ldn     r2                 ; recover byte
           CALL    o_type             ; and send it
           dec     rc                 ; decrement byte count
           glo     rc                 ; get count
           lbnz    xsend1             ; jump if more bytes to send
           ghi     rc                 ; get checksum byte
           CALL    o_type             ; and send it
xsend2:    CALL    o_readkey          ; read byte from serial port
           str     r2                 ; save it
           smi     nak                ; was it a nak
           lbz     xsendnak           ; resend block if nak
           LOAD    rf,block           ; point to block number
           ldn     rf                 ; get block number
           adi     1                  ; increment block number
           str     rf                 ; and put it back
           inc     rf                 ; point to buffer count
           ldi     0                  ; set buffer count
           str     rf
           pop     rc                 ; recover registers
           pop     rf
           RETURN                     ; and return
; **************************************
; ***** Close XMODEM write channel *****
; **************************************
xclosew:   push    rf                 ; save consumed registers
           push    rc
           LOAD    rf,count           ; get count of characters unsent
           ldn     rf                 ; retrieve count
           lbz     xclosewd           ; jump if no untransmitted characters
           plo     rc                 ; put into count
           str     r2                 ; save for add
           ldi     txrx.0             ; low byte of buffer
           add                        ; add characters in buffer
           plo     rf                 ; put into rf
           ldi     txrx.1             ; high byte of transmit buffer
           adci    0                  ; propagate carry
           phi     rf                 ; rf now has position to write at
xclosew1:  ldi     csub               ; character to put into buffer
           str     rf                 ; store into transmit buffer
           inc     rf                 ; point to next position
           inc     rc                 ; increment byte count
           glo     rc                 ; get count
           ani     080h               ; need 128 bytes
           lbz     xclosew1           ; loop if not enough
           CALL    xsend              ; send final block
xclosewd:  ldi     eot                ; need to send eot
           CALL    o_type             ; send it
           CALL    o_readkey          ; read a byte
           smi     06h                ; needs to be an ACK
           lbnz    xclosewd           ; resend EOT if not ACK
           LOAD    rf,baud            ; need to restore baud constant
           ldn     rf                 ; get it
           phi     re                 ; put it back
           pop     rc                 ; recover consumed registers
           pop     rf
           RETURN                     ; and return

           ;------ define end of execution block
endrom:    equ     $
dta:       ds      512

base:      equ      $                 ; XMODEM data segment
baud:      equ     base+0
init:      equ     base+1
block:     equ     base+2            ; current block
count:     equ     base+3            ; byte send/receive count
xdone:     equ     base+4
h1:        equ     base+5
h2:        equ     base+6
h3:        equ     base+7
txrx:      equ     base+8            ; buffer for tx/rx
temp1:     equ     base+150
temp2:     equ     base+152
buffer:    equ     base+154          ; address for input buffer
ack:       equ     06h
nak:       equ     15h
soh:       equ     01h
etx:       equ     03h
eot:       equ     04h
can:       equ     18h
csub:      equ     1ah
rxbuffer:  equ     base+200h
