# Elfos-utils
Simple utitlity commands for the ElfOs

Repository Contents
-------------------
* **/src/**  -- Source files for miscellaneous Elf/OS utilities.
  * clear.asm - clear the output
  * input.asm - Input and display data read from Port 4
  * output.asm - Output hh - send the hex value 'hh' out to Port 4
  * nop.asm - No Operation - simple program that does nothing.
  * pwd.asm - Print Working Directory - prints the current directory
  * say.asm - Say 'text' - write the text string back to the output
  * stack.asm - print the value of the Elf/OS stack pointer
  * make_xxx.bat - Windows batch file to assemble xxx.asm and create binary
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/src/stg/**  -- Source files for STG NVR/RTC/UART and STG ROM utilities.  
  * stg.asm - jump to the STG v1.07 Rom menu
  * visualstg.asm - Run Visual02 from the STG v1.07 Rom code (replaces visual02 command)
  * xsb.asm - XMODEM Send using the STG UART
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
* **/bin/stg/**  -- Binary files for STG NVR/RTC/UART ROM utilities. 
* **/bin/video/**  -- Binary files for 1861 Pixie Video utilities and demo programs  
* **/lbr/**  -- Library files for Elf/OS utilities. (Unpack with Elf/OS lbr command)
  * misc_utils.lbr - Library file for miscellaneous Elf/OS utilities.
  * misc_utils.lbr - Library file  for STG NVR/RTC/UART and STG ROM utilities.
  * video_utils.lbr - Library file for ELf/OS 1861 Pixie Video utilities.
