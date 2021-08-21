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

include    bios.inc
include    kernel.inc

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************

         org     02000h-6        ; Header starts at 01ffah
           dw      2000h
           dw      endrom-2000h
           dw      2000h
         org     2000h          ; Program code starts at 2000
           br      start

           ; Build date
date:      db      80h+8          ; Month, 80h offset means extended info
           db      21             ; Day
           dw      2021           ; year = 2021

           ; Current build number
build:     dw      4              ; build for kernel 4

          ; Must end with 0 (null)
           db      'Copyright 2021 Gaston Williams',0

fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

start:     lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           ldn     ra                  ; get byte
           lbnz    start1              ; jump if argument given
           sep     scall               ; otherwise display usage message
           dw      o_inmsg
           db      'Usage: xsb filename',10,13,0
           sep     sret                ; and return to os
start1:    ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     ra                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     ra                  ; backup to char
           ldi     0                   ; need proper termination
           str     ra
           ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; no special flags
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    opened              ; jump if file opened
           ldi     high errmsg         ; point to error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display error message
           dw      o_msg
           lbr     o_wrmboot           ; return to Elf/OS
errmsg:    db      'file error',10,13,0
opened:    sep     scall               ; open XMODEM channel
           dw      xopenw

filelp:    ldi     high rxbuffer       ; point to buffer
           phi     rf
           ldi     low rxbuffer
           plo     rf
           ldi     0                   ; need to read 128 bytes
           phi     rc
           ldi     128
           plo     rc
clearlp:   ldi     01ah                ; clear out buffer
           str     rf
           inc     rf
           dec     rc
           glo     rc
           lbnz    clearlp
           ldi     high rxbuffer       ; point to buffer
           phi     rf
           ldi     low rxbuffer
           plo     rf
           ldi     0                   ; need to read 128 bytes
           phi     rc
           ldi     128
           plo     rc
           sep     scall               ; write buffer to file
           dw      o_read
           glo     rc                  ; see if bytes were read
           lbz     filedn              ; jump if not
           ldi     high rxbuffer       ; point to buffer
           phi     rf
           ldi     low rxbuffer
           plo     rf
           ldi     0                   ; need to send 128 bytes
           phi     rc
           ldi     128
           plo     rc
           sep     scall               ; send the block
           dw      xwrite
           lbr     filelp              ; loop back until full file sent

filedn:    sep     scall               ; close file
           dw      o_close
           sep     scall               ; close the XMODEM channel
           dw      xclosew
           lbr     o_wrmboot           ; and return to os

; *******************************************
; ***** Open XMODEM channel for writing *****
; *******************************************
xopenw:    push    rf                ; save consumed register
           mov     rf,block          ; current block number
           ldi     1                 ; starts at 1
           str     rf                ; store into block number
           inc     rf                ; point to byte count
           ldi     0                 ; set count to zero
           str     rf                ; store to byte count
           mov     rf,baud           ; place to store baud constant
           ghi     re                ; need to turn off echo
           str     rf                ; save it
           ani     0feh
           phi     re                ; put it back
xopenw1:   sep     scall             ; read a byte from the serial port
           dw      f_read
           smi     nak               ; need a nak character
           lbnz    xopenw1           ; wait until a nak is received
           pop     rf                ; recover rf
           sep     sret              ; and return to caller
; ***********************************
; ***** Write to XMODEM channel *****
; ***** RF - pointer to data    *****
; ***** RC - Count of data      *****
; ***********************************
xwrite:    push    r8                ; save consumed registers
           push    ra
           mov     ra,count          ; need address of count
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
           sep     scall             ; send current block
           dw      xsend
           ldi     0                 ; zero buffer count
           plo     r8
           mov     ra,txrx           ; reset buffer position
xwrite2:   dec     rc                ; decrement count
           glo     rc                ; see if done
           lbnz    xwrite1           ; loop back if not
           ghi     rc                ; need to check high byte
           lbnz    xwrite1           ; loop back if not
           mov     ra,count          ; need to write new count
           glo     r8                ; get the count
           str     ra                ; and save it
           pop     ra                ; pop consumed registers
           pop     r8
           sep     sret              ; and return to caller

; *******************************
; ***** Send complete block *****
; *******************************
xsend:     push    rf                 ; save consumed registers
           push    rc
xsendnak:  ldi     soh                ; need to send soh character
           phi     rc                 ; initial value for checksum
           sep     scall              ; send it
           dw      f_tty
           mov     rf,block           ; need current block number
           ldn     rf                 ; get block number
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; put it back
           ldn     r2                 ; recover block number
           sep     scall              ; and send it
           dw      f_tty
           ldn     rf                 ; get block number back
           sdi     255                ; subtract from 255
           str     r2                 ; save it
           ghi     rc                 ; get current checksum
           add                        ; add in inverted block number
           phi     rc                 ; put it back
           ldn     r2                 ; recover inverted block number
           sep     scall              ; send it
           dw      f_tty
           ldi     128                ; 128 bytes to write
           plo     rc                 ; place into counter
           mov     rf,txrx            ; point rf to data block
xsend1:    lda     rf                 ; retrieve next byte
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; save checksum
           ldn     r2                 ; recover byte
           sep     scall              ; and send it
           dw      f_tty
           dec     rc                 ; decrement byte count
           glo     rc                 ; get count
           lbnz    xsend1             ; jump if more bytes to send
           ghi     rc                 ; get checksum byte
           sep     scall              ; and send it
           dw      f_tty
xsend2:    sep     scall              ; read byte from serial port
           dw      f_read
           str     r2                 ; save it
           smi     nak                ; was it a nak
           lbz     xsendnak           ; resend block if nak
           mov     rf,block           ; point to block number
           ldn     rf                 ; get block number
           adi     1                  ; increment block number
           str     rf                 ; and put it back
           inc     rf                 ; point to buffer count
           ldi     0                  ; set buffer count
           str     rf
           pop     rc                 ; recover registers
           pop     rf
           sep     sret               ; and return
; **************************************
; ***** Close XMODEM write channel *****
; **************************************
xclosew:   push    rf                 ; save consumed registers
           push    rc
           mov     rf,count           ; get count of characters unsent
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
           sep     scall              ; send final block
           dw      xsend
xclosewd:  ldi     eot                ; need to send eot
           sep     scall              ; send it
           dw      f_tty
           sep     scall              ; read a byte
           dw      f_read
           smi     06h                ; needs to be an ACK
           lbnz    xclosewd           ; resend EOT if not ACK
           mov     rf,baud            ; need to restore baud constant
           ldn     rf                 ; get it
           phi     re                 ; put it back
           pop     rc                 ; recover consumed registers
           pop     rf
           sep     sret               ; and return


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
