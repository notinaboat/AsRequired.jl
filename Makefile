PACKAGE := $(shell basename $(CURDIR))
export JULIA_PROJECT = $(CURDIR)

JL := julia

all: README.html

README.md: src/*
	julia --project -e "using $(PACKAGE); $(PACKAGE).readme_docs_generate()"

README.html: README.md
	@pandoc $< \
		--from markdown+multiline_tables \
  		--to json \
	| pandoc \
		--from json \
  		--to html5+smart \
		--standalone \
		--variable fontsize=10pt \
		--variable mainfont=sans-serif \
		--output=$@

#	| $(JL) -e "using $(PACKAGE); $(PACKAGE).pandoc_filter()" \

.PHONY: test
test:
	$(JL) test/runtests.jl

.PHONY: jl
jl:
	$(JL)
