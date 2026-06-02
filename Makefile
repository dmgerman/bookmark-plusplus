# Top-level Makefile for bookmark-plusplus.
#
# Targets:
#   make test          - run the test suite (ERT, batch mode)
#   make compile       - byte-compile the source files
#   make clean         - remove .elc files
#   make -C doc        - build the user manual (info / html / pdf)

EMACS ?= emacs

CORE_FILES = bookmark+-mac.el bookmark+-lit.el bookmark+-bmu.el \
             bookmark+-1.el bookmark+-key.el bookmark+-preview.el \
             bookmark+.el

.PHONY: test compile clean

test:
	$(EMACS) -Q --batch -L . -L test \
	    -l bookmark+-mac.el \
	    -l ert \
	    -l test/run-tests.el \
	    -f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -Q --batch -L . -l bookmark+-mac.el \
	    -f batch-byte-compile $(CORE_FILES)

clean:
	rm -f *.elc
