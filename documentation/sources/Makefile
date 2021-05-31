SVGS= $(wildcard figures/*.svg)
IMGS= $(SVGS:.svg=.pdf)

PDFDIR=obj
SRCS= $(wildcard *.tex)
#SRCS+= refs3.bib
PDFFLAGS= -interaction=nonstopmode -shell-escape -halt-on-error -synctex=1 -output-directory=$(PDFDIR)/

docu=soc
TARGET=$(addsuffix .pdf,$(docu))

all: target images

target: $(TARGET) $(IMGS)

images: $(IMGS)

figures/%.pdf: figures/%.svg
	inkscape -z -T -A $@ $<

%.pdf: %.tex $(SRCS) $(IMGS)
	mkdir -p $(PDFDIR)
	pdflatex  $(PDFFLAGS) -jobname=$(notdir $(basename $@)) $<
	pdflatex  $(PDFFLAGS) -jobname=$(notdir $(basename $@)) $<
	cp -p -f $(PDFDIR)/$@ $@

## Other Targets
clean:
	rm -fr $(PDFDIR) $(IMGS) $(TARGET)

.PHONY: all target images clean
