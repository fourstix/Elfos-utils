# Elfos-utils  
A set of simple utility commands for the Elf/OS.  These commands were all assembled into Intel hex files using the 
[RcAsm 1802 Assembler](https://github.com/rileym65/RcAsm) by Mike Riley. The hex files were converted into binary files using
[hex2bin](https://sourceforge.net/projects/hex2bin/) for Windows.  

Platform  
--------
These commands were written to run on a [Pico/Elf](http://www.elf-emulation.com/picoelf.html) with the Spare Time Gizmos [STG RTC/NVR/UART expansion card](http://www.elf-emulation.com/hardware.html) and the [STG Pico/Elf EPROM v1.07](https://groups.io/g/cosmacelf/files/STG%20Elf2K/Elf2K%20and%20PicoElf%20EPROM%20v107.zip) written by Bob Armstrong. A lot of information and software for the Pico/Elf can be found on the [Elf-Emulation](http://www.elf-emulation.com/) website and in the [COSMAC ELF Group](https://groups.io/g/cosmacelf) at groups.io.

Miscellaneous Elf/OS Utility Commands
-------------------------------------
## input
**Usage:** input  
Input and display data read from Port 4

## output
**Usage:** output *hh*     
Send the hex value *hh* out to Port 4 *(where hh ranges in value from 00 to FF)*

## nop
**Usage:** nop    
No Operation, a simple program that does nothing.

## pwd
**Usage:** pwd    
Print Working Directory, write the current directory to the output.


## say
**Usage:** say *text*      
Print the string *text* to the output

## stack
**Usage:** stack    
Print the value of the Elf/OS stack pointer

STG NVR/RTC/UART and STG EPROM Utility Commands  
-----------------------------------------------

## stg  
**Usage:** stg    
Jump to the STG Pico/Elf EPROM v1.07 menu.  This command is the same as *Exec 8003*. Use *CALL 0303* to execute a Warm Boot to return to the Elf/OS from the EPROM menu.

## visualstg
**Usage:** visualstg  
Run Visual02 from the STG Pico/Elf EPROM v1.07 code. This command replaces the Elf/OS visual02 command to correctly invoke the visual02 code in the STG Pico/Elf EPROM.  (You can rename it to visual02.)

## xsb
**Usage:** xsb *filename*    
XModem Send command that uses the UART from the STG NVR/RTC/UART expansion card instead of the bit banged serial routines to send the file named *filename*.  This command is the compliment to the **xrb** [XModem receive command](https://github.com/rileym65/Elf-Elfos-xr), and can be used to send binary files from the Pico/Elf to another computer via the STG NVR/RTC/UART expansion card's UART serial interface.

## seq  
**Usage:** seq  
Set Q.  This command turns the Q bit on. (Q = 1) The Q bit is available for use when using the STG NVR/RTC/UART Expansion Card UART.

## req  
**Usage:** req  
Reset Q.  This command turns the Q bit off. (Q = 0) The Q bit is available for use when using the STG NVR/RTC/UART Expansion Card UART.

1861 Pixie Video Demo and Utility Commands
------------------------------------------
## spaceship
**Usage:** spaceship *(Press Input /EF4 to exit program.)*    
Joseph A Weisbecker's Pixie Graphic Demo program modified to 
run under Elf/OS. 

## dma_test
**Usage:** dma_test *(Press Input /EF4 to exit program.)*    
Tom Pittman's Video DMA program modified to run under Elf/OS.

## tvclock
**Usage:** tvclock *(Press Input /EF4 to exit program.)*    
Tom Pittman's TV Clock program modified to run under Elf/OS.

## voff
**Usage:** voff  
Video Off. Output Port 1 and Disable interrupts. This command 
is useful when debugging or writing pixie video programs to turn off a 1861 video display.

Library Files
-------------
The command files are grouped into three Elf/OS library files that can be unpacked with the Elf/OS lbr command using the e option to *extract* files.
* misc_utils.lbr - Library file for miscellaneous Elf/OS utilities contains the input, output, nop, pwd, say and stack commands. Extract these files with the Elf/OS command *lbr e misc_utils*
* stg_utils.lbr - Library file  for STG NVR/RTC/UART and STG EPROM utilities contains the stg, videostg,  xsb, seq and req commands. Extract these files with the Elf/OS command *lbr e stg_utils*
* video_utils.lbr - Library file for ELf/OS 1861 Pixie Video utilities contains the spaceship, dma_test, tvclock and voff commands. Extract these files with the Elf/OS command *lbr e video_utils*


Repository Contents
-------------------
* **/src/**  -- Source files for miscellaneous Elf/OS utilities.
  * input.asm - Input and display data read from Port 4
  * output.asm - Output hh - send the hex value 'hh' out to Port 4
  * nop.asm - No Operation - simple program that does nothing.
  * pwd.asm - Print Working Directory - prints the current directory
  * say.asm - Say 'text' - write the text string back to the output
  * stack.asm - print the value of the Elf/OS stack pointer
  * make_xxx.bat - Windows batch file to assemble xxx.asm and create binary
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/src/stg/**  -- Source files for STG NVR/RTC/UART and STG EPROM utilities.  
  * stg.asm - jump to the STG v1.07 EPROM menu
  * visualstg.asm - Run Visual02 from the STG v1.07 EPROM code (replaces visual02 command)
  * xsb.asm - XMODEM Send using the STG Expansion card UART
  * seq.asm - Set Q. (The Q bit is available when using the STG Expansion card UART)
  * req.asm - Reset Q. (The Q bit is available when using the STG Expansion card UART)
  * make_xxx.bat - Windows batch file to assemble xxx.asm and create binary
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/src/video/**  -- Source files for 1861 Pixie Video utilities and demo programs
  * spaceship - Joseph A Weisbecker's Pixie Graphic Demo program (Press Input /EF4 to exit)
  * dma_test -Tom Pittman's Video DMA program (Press Input /EF4 to exit)
  * tvclock - Tom Pittman's TV Clock Demo program (Press Input /EF4 to exit)
  * voff - Turn 1861 Pixie Video Off (OUT 1 and disable interrupts)  
  * make_xxx.bat - Windows batch file to assemble xxx.asm and create binary
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/bin/**  -- Binary files for miscellaneous Elf/OS utilities.  
* **/bin/stg/**  -- Binary files for STG NVR/RTC/UART EPROM utilities. 
* **/bin/video/**  -- Binary files for 1861 Pixie Video utilities and demo programs  
* **/lbr/**  -- Library files for Elf/OS utilities. (Unpack with Elf/OS lbr command)
  * misc_utils.lbr - Library file for miscellaneous Elf/OS utilities.
  * stg_utils.lbr - Library file  for STG NVR/RTC/UART and STG EPROM utilities.
  * video_utils.lbr - Library file for ELf/OS 1861 Pixie Video utilities.
  
  License Information
  -------------------
  
  This code is public domain under the MIT License, but please buy me a beer
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  This code is based on a Elf/OS code libraries written by Mike Riley and assembled with the RcAsm assembler also written by Mike Riley.
  
  Elf/OS 
  Copyright (c) 2004-2021 by Mike Riley
  
  RcAsm 1802 Assembler
  Copyright (c) 2004-2021 by Mike Riley
  
  Hex2bin
  Copyright (C) 1998-2021 by Jacques Pelletier
    
  The Pico/Elf Microcomputer Hardware
  Copyright (c) 2020-2021 by Mike Riley
   
  The STG Pico/Elf EPROM v1.07
  Copyright (c) 2004-2021 by Spare Time Gizmos.
  
  STG NVR/RTC/UART Pico/Elf Expansion Card hardware
  Copyright (c) 2020-2021 by Spare Time Gizmos.
  
  Many thanks to the original authors for making their designs and code available as open source.
   
  This code, firmware, and software is released under the [MIT License](http://opensource.org/licenses/MIT).
  
  The MIT License (MIT)
  
  Copyright (c) 2021 by Gaston Williams
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  **THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.**
