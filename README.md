# Elfos-utils  
A set of simple utility commands for the Elf/OS.  These commands were all assembled into 1802 binary files using the 
[Asm/02 1802 Assembler](https://github.com/rileym65/Asm-02) by Mike Riley.

Platform  
--------
These commands were written to run on a [Pico/Elf](http://www.elf-emulation.com/picoelf.html) with the Spare Time Gizmos [STG RTC/NVR/UART expansion card](http://www.elf-emulation.com/hardware.html) and the [STG Pico/Elf EPROM v1.12](https://groups.io/g/cosmacelf/files/STG%20Elf2K/Elf2K%20and%20PicoElf%20EPROM%20v112%20BIOS%201.0.9.zip) written by Bob Armstrong. A lot of information and software for the Pico/Elf can be found on the [Elf-Emulation](http://www.elf-emulation.com/) website and in the [COSMAC ELF Group](https://groups.io/g/cosmacelf) at groups.io.

Elf/OS File Utility Commands
-------------------------------------

## cmd
**Usage:** cmd [-e] [*filename*, default = start.cmd]    
Run commands from the file *filename*, or the file start.cmd if not specified. Each
line of the file contains a separate command. The option -e will echo the commands before they are executed.
 
**Note:** 
To use *cmd* as the ELf/OS init program, copy this file as an executable file named *init* in the /bin directory. Elf/OS will then execute the commands contained in the start.cmd file in the root / directory when the Elf/OS boots. *Press and hold Input /EF4 to skip the execution of start.cmd and auto-baud during boot-up.* 

**Note:**
The cmd program occupies memory from $5000 to $6000.  Programs up to 12K in size that load at $2000 can be run from a command file.  If a program allocates memory so that the heap goes below $6000, the command interpreter will exit with an 'Out of Memory' error. 

## flags
**Usage:** flags *filename*    
Show the Elf/OS flags associated with the file. Display 'd' for a directory file, 'x' for an executable file, 'h' for a hidden file and 'w' for write-protected file.  If a flag is not set, then a dot '.' is displayed. The string '. . . .' means no flags are set for the file.

## header
**Usage:** header *filename*    
Show the executable header information for a file. Display the program load address, program size and the program execution address.

## malloc
**Usage:** malloc [-f *hh*] *size*    
Allocate a block of memory of *size* bytes on the heap. The -f option will fill the memory with the *hh* hex byte value. *Useful for testing low memory conditions.*

## mfree
**Usage:** mfree *hhhh*    
Free a block of memory allocated at the hex address *hhhh* on the heap.

## scpy
**Usage:** scpy [-y] *source* *dest*    
Safely copy the file from *source* to the destination file *dest*.  The scpy command does not over-write directories and will prompt before over-writing an existing destination file.  The -y option will 
over-write an existing file without the prompt. *Copy or rename to 'copy' to replace default Elf/OS command in the /bin directory.*

## xtrim
**Usage:** xtrim *filename*, where *filename* is an executable file.  
Trim the executable file *filename* to the runtime size in its header, and save with the .tr extension.  *Useful to remove padding bytes added by an XMODEM transfer* 

Elf/OS I/O Utility Commands
-------------------------------------

## clr
**Usage:** clr    
Clear the screen. Clears both ANSI and non-ANSI displays. *Copy or rename to 'cls' to replace default Elf/OS command in the /bin directory.*

## input
**Usage:** input  
Input and display data read from Port 4

## output
**Usage:** output *hh*     
Send the hex value *hh* out to Port 4 *(where hh ranges in value from 00 to FF)*

## nop
**Usage:** nop    
No Operation, a simple program that does nothing. *Can be copied or renamed to 'rem' in the /bin directory and used for comments in command files*

## pwd
**Usage:** pwd    
Print Working Directory, write the current directory to the output.

## say
**Usage:** say *text*      
Print the string *text* to the output. *Useful for printing text output in command files*

## stack
**Usage:** stack    
Print the value of the Elf/OS stack pointer.

STG NVR/RTC/UART and STG EPROM Utility Commands  
-----------------------------------------------

## seq  
**Usage:** seq  
Set Q.  This command turns the Q bit on. (Q = 1) The Q bit is available for use when using the STG NVR/RTC/UART Expansion Card UART.

## req  
**Usage:** req  
Reset Q.  This command turns the Q bit off. (Q = 0) The Q bit is available for use when using the STG NVR/RTC/UART Expansion Card UART.

## stg
**Usage:** stg    
Jump to the STG Pico/Elf EPROM v1.12 menu.  This command is the same as *Exec 8003*. Use *CALL 0303* to execute a Warm Boot to return to the Elf/OS from the EPROM menu.

## visualstg
**Usage:** visualstg  
Run Visual02 from the STG Pico/Elf EPROM v1.12 code. This command replaces the Elf/OS visual02 command to correctly invoke the visual02 code in the STG Pico/Elf EPROM.  *Rename or copy to visual02 in the /bin directory to replace the original command.*

## xsb
**Usage:** xsb *filename*    
XModem Send command that uses the UART from the STG NVR/RTC/UART expansion card instead of the bit banged serial routines to send the file named *filename*.  This command is the compliment to the **xrb** [XModem receive command](https://github.com/rileym65/Elf-Elfos-xr), and can be used to send binary files from the Pico/Elf to another computer via the STG NVR/RTC/UART expansion card's UART serial interface.

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
* file_utils.lbr - Library file for Elf/OS file utilities containing the cmd, flags, header, malloc, mfree and xtrim commands. Extract these files with the Elf/OS command *lbr e file_utils*
* io_utils.lbr - Library file for Elf/OS I/O utilities containing the clr, input, nop, output, pwd, say, and stack commands. Extract these files with the Elf/OS command *lbr e io_utils*
* stg_utils.lbr - Library file for STG NVR/RTC/UART and STG EPROM utilities contains the stg, videostg,  xsb, seq and req commands. Extract these files with the Elf/OS command *lbr e stg_utils*
* video_utils.lbr - Library file for ELf/OS 1861 Pixie Video utilities contains the spaceship, dma_test, tvclock and voff commands. Extract these files with the Elf/OS command *lbr e video_utils*


Repository Contents
-------------------
* **/src/**  -- Common source files for assembling Elf/OS utilities.
  * asm.bat - Windows batch file to assemble source file with Asm/02 to create binary file. Use the command *asm xxx.asm* to assemble the xxx.asm file.
  * ops.inc - Opcode definitions for Asm/02.
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/src/file/**  -- Source files for Elf/OS file utilities.
  * cmd.asm - Run commands from a file.
  * flags.asm - Show Elf/OS flags associated with a file.
  * header.asm - Show the executable header information for a file.
  * malloc.asm - Allocate block of memory on the heap.
  * mfree.asm - Free a block of memory on the heap.
  * scpy.asm - Safely copy a file.
  * xtrim.asm - Trim an executable file to its runtime size.
* **/src/io/**  -- Source files for Elf/OS I/O utilities.  
  * cls.asm - Clear the screen
  * input.asm - Input and display data read from Port 4
  * nop.asm - No Operation - simple program that does nothing.
  * output.asm - Output hh - send the hex value 'hh' out to Port 4
  * pwd.asm - Print Working Directory - prints the current directory
  * say.asm - Say 'text' - write the text string back to the output
  * stack.asm - Print the value of the Elf/OS stack pointer
* **/src/stg/**  -- Source files for STG NVR/RTC/UART and STG EPROM utilities.  
  * seq.asm - Set Q. (The Q bit is available when using the STG Expansion card UART)
  * req.asm - Reset Q. (The Q bit is available when using the STG Expansion card UART)
  * stg.asm - jump to the STG v1.12 EPROM menu
  * visualstg.asm - Run Visual02 from the STG v1.12 EPROM code (replaces visual02 command)
  * xsb.asm - XMODEM Send using the STG Expansion card UART
* **/src/video/**  -- Source files for 1861 Pixie Video utilities and demo programs
  * spaceship - Joseph A Weisbecker's Pixie Graphic Demo program (Press Input /EF4 to exit)
  * dma_test -Tom Pittman's Video DMA program (Press Input /EF4 to exit)
  * tvclock - Tom Pittman's TV Clock Demo program (Press Input /EF4 to exit)
  * voff - Turn 1861 Pixie Video Off (OUT 1 and disable interrupts)  
* **/bin/file/**  -- Binary files for Elf/OS file utilities.
* **/bin/io/**  -- Binary files for Elf/OS I/O utilities.  
* **/bin/stg/**  -- Binary files for STG NVR/RTC/UART EPROM utilities. 
* **/bin/video/**  -- Binary files for 1861 Pixie Video utilities and demo programs  
* **/lbr/**  -- Library files for Elf/OS utilities. (Unpack with Elf/OS lbr command)
  * file_utils.lbr - Library file for Elf/OS file utilities.
  * io_utils.lbr - Library file for Elf/OS I/O utilities.
  * stg_utils.lbr - Library file  for STG NVR/RTC/UART and STG EPROM utilities.
  * video_utils.lbr - Library file for ELf/OS 1861 Pixie Video utilities.
  
  License Information
  -------------------
  
  This code is public domain under the MIT License, but please buy me a beverage
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  This code is based on a Elf/OS code libraries written by Mike Riley and assembled with the RcAsm assembler also written by Mike Riley.
  
  Elf/OS 
  Copyright (c) 2004-2021 by Mike Riley
  
  Asm/02 1802 Assembler
  Copyright (c) 2004-2021 by Mike Riley
  
  Elf/OS Init Program 
  Copyright (c) 2021 by David Madole
    
  The Pico/Elf Microcomputer Hardware
  Copyright (c) 2020-2021 by Mike Riley
   
  The STG Pico/Elf EPROM v1.12
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
