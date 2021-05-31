################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf
CC = gcc -g

IDIR=inc
ODIR=obj
SDIR=src

CFLAGS = -Wall

_DEPS = command.h files.h labels.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJS = output.o msg.o check.o label.o main.o handle_o.o handle_oi.o handle_omi.o handle_omr.o handle_omr2.o handle_or2.o handle_or2i.o handle_or3.o handle_ori.o handle_or.o handle_om.o  
OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

_FLEX_OBJ = asm.tab.o lex.yy.o
FLEX_OBJS = $(patsubst %,$(ODIR)/%,$(_FLEX_OBJ))
_FLEX_COMPILES = asm.tab.c asm.tab.h lex.yy.c
FLEX_COMPILES = $(patsubst %,$(ODIR)/%,$(_FLEX_COMPILES))

# All Target
all: $(ODIR) asm

$(ODIR):
	mkdir -p $(ODIR)

# Tool invocations
asm: flex bison $(FLEX_OBJS) $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C Linker'
	$(CC) -o "asm" -I"inc/" $(OBJS) $(FLEX_OBJS) $(CFLAGS)
	@echo 'Finished building target: $@'
	@echo ' '
	
bison: $(SDIR)/asm.y
	bison -o obj/asm.tab.c -d $(SDIR)/asm.y
flex: $(SDIR)/asm.l
	flex -o obj/lex.yy.c $(SDIR)/asm.l
	
# Object Files

#obj/%.o: src/%.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)

obj/asm.tab.c: bison
obj/asm.tab.h: bison
obj/lex.yy.c : flex

$(ODIR)/output.o: $(SDIR)/output.c
	$(CC) -c  $(CFLAGS) -o $@ $<
$(ODIR)/msg.o: $(SDIR)/msg.c
	$(CC) -c  $(CFLAGS) -o $@ $<
$(ODIR)/check.o: $(SDIR)/check.c
	$(CC) -c  $(CFLAGS) -o $@ $<
	
$(ODIR)/main.o: $(SDIR)/main.c
	$(CC) -c -o $@ $< $(CFLAGS)
	
$(ODIR)/label.o: $(SDIR)/label.c
	$(CC) -c  $(CFLAGS) -o $@ $<
	
$(ODIR)/handle_or3.o: $(SDIR)/handle_or3.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_or2i.o: $(SDIR)/handle_or2i.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_ori.o: $(SDIR)/handle_ori.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_omr2.o: $(SDIR)/handle_omr2.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_omi.o: $(SDIR)/handle_omi.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_omr.o: $(SDIR)/handle_omr.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_oi.o: $(SDIR)/handle_oi.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_o.o: $(SDIR)/handle_o.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_or2.o: $(SDIR)/handle_or2.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_or.o: $(SDIR)/handle_or.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/handle_om.o: $(SDIR)/handle_om.c
	$(CC) -c -o $@ $< $(CFLAGS)
	
$(ODIR)/asm.tab.o: $(ODIR)/asm.tab.c
	$(CC) -c -o $@ $< $(CFLAGS)
$(ODIR)/lex.yy.o: $(ODIR)/lex.yy.c
	$(CC) -c -o $@ $< $(CFLAGS)

# Other Targets
clean:
	-$(RM) $(OBJS) $(FLEX_OBJS) $(FLEX_COMPILES) asm
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
