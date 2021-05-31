
AS=../assembler/asm
RM= rm -f

SRCS= $(wildcard *.prog)
OBJS= $(SRCS:.prog=.ram)
MAPS= $(SRCS:.prog=.map)

all: $(OBJS)

maps: $(MAPS)
	
%.ram: %.prog
	$(AS) $< -o $@

%.map: %.prog
	$(AS) $< -m $@ -o $*.ram

clean:
	$(RM) $(OBJS) $(MAPS)

.PHONY: all maps
