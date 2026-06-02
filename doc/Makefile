# Build the Bookmark++ Info manual.
#
# Targets:
#   make           - build bookmark-plusplus.info
#   make html      - also build bookmark-plusplus.html
#   make pdf       - also build bookmark-plusplus.pdf (requires texi2pdf)
#   make clean     - remove generated files

MAKEINFO ?= makeinfo
TEXI2PDF ?= texi2pdf

INFO  = bookmark-plusplus.info
HTML  = bookmark-plusplus.html
PDF   = bookmark-plusplus.pdf
TEXI  = bookmark-plusplus.texi

.PHONY: all html pdf clean

all: $(INFO)

$(INFO): $(TEXI)
	$(MAKEINFO) $(TEXI) -o $@

html: $(HTML)

$(HTML): $(TEXI)
	$(MAKEINFO) --html --no-split $(TEXI) -o $@

pdf: $(PDF)

$(PDF): $(TEXI)
	$(TEXI2PDF) --clean $(TEXI) -o $@

clean:
	rm -f $(INFO) $(HTML) $(PDF) *.aux *.cp *.fn *.fns *.ky *.log \
	      *.pg *.toc *.tp *.vr *.vrs
