@echo off
rem gcc makemif.c -o makemif.exe
nasm -fbin bios.asm -o bios.bin
makemif > bios.mif
d:\\altera\\13.0sp1\\quartus\\bin64\\quartus_map --read_settings_files=off --write_settings_files=off 186 -c 186
d:\\altera\\13.0sp1\\quartus\\bin64\\quartus_fit --read_settings_files=off --write_settings_files=off 186 -c 186
d:\\altera\\13.0sp1\\quartus\\bin64\\quartus_asm --read_settings_files=off --write_settings_files=off 186 -c 186