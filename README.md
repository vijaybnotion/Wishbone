
Setup

The following Instruction apply if you are intending to build the toolchain for the LT16x32 and associated SoC, and want to create a synthesized bitfile of said SoC.

It is assumed that:
* you run linux
* have make installed
* have gcc, flex and bison installed
* have inkscape installed
* have all required latex packages installed (install texlive-latex-extra metapackage for ubuntu/Debian)
** packages for openSUSE: texlive-latex,texlive-multirow,texlive-lineno
* pygmetize for minted source code, (python-pygments package in ubuntu/Debian/openSuse)

1. Making of...
1.1 the assembler

Change into the 'assembler' directory and run the Makefile with
$ make all

The LT16x32 assembler should then be present as 'asm' binary executeable.
To integrate this executeable, create a symbolic link in a user directory which exists in your $PATH or directly link to it.

1.2 the documentation

Change into the 'documentation' directory and run the Makefile with
$ make all

A file named 'soc.pdf' should then pop up and be placed in the documentation directory.
It contains information about the the LT16x32 core and assembler.
