SVGS= $(wildcard *.svg)
IMGS= $(SVGS:.svg=.pdf)


all: $(IMGS)

%.pdf: %.svg
	inkscape -z -T -A $@ $<

clean:
	rm -f *.pdf
