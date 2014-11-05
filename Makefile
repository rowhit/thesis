SHELL := /bin/bash  # This is pretty important. Default is /bin/sh

metadata=meta.yaml

latex_build=build/latex
html_build=build/html
rendered=build/rendered

.PHONY: render all html pdf tex clean docx serve pages

all: html pdf

source_md := $(wildcard chapters/*.md)
source_nb := $(wildcard chapters/*.ipynb)

render: $(source_md)
	notedown --render $(source_md) --output ${rendered}/$(basename $(notdir $(source_md))).md

html: render
	cd ${html_build} && jekyll build && cd -

# build _site and push diff to gh-pages branch
# using a temporary git repo to rebase the changes onto
pages: html
	root_dir=$$(git rev-parse --show-toplevel) && \
	tmp_dir=$$(mktemp -d) && \
	cd $${tmp_dir} && git init && \
	git remote add origin $${root_dir} && \
	git pull origin gh-pages && \
	git rm -rf --cached * && \
	rsync -av $${root_dir}/${html_build}/_site/ . && \
	git add -A && git commit -m "update gh-pages" && \
	git push origin master:gh-pages && \
	cd $${root_dir}

# remember each line in the recipe is executed in a *new* shell,
# so if we want to pass variables around we have to make a long
# single line command.
pdf: render
	abbreviations=$$(pandoc abbreviations.md --to latex); \
	prelims="$$(pandoc $(metadata) \
				--template ${latex_build}/prelims.tex \
				--variable=abbreviations:"$$abbreviations" \
				--to latex)"; \
	postlims="$$(pandoc $(metadata) --template ${latex_build}/postlims.tex --to latex)"; \
	pandoc $(metadata) ${rendered}/* -o thesis.pdf \
		--template ${latex_build}/Thesis.tex \
		--chapter \
		--variable=prelims:"$$prelims" \
		--variable=postlims:"$$postlims" \
        --filter ${latex_build}/filters.py

tex: render
	abbreviations=$$(pandoc abbreviations.md --to latex); \
	prelims="$$(pandoc $(metadata) \
				--template ${latex_build}/prelims.tex \
				--variable=abbreviations:"$$abbreviations" \
				--to latex)"; \
	postlims="$$(pandoc $(metadata) --template ${latex_build}/postlims.tex --to latex)"; \
	pandoc $(metadata) ${rendered}/* -o thesis.tex \
		--template ${latex_build}/Thesis.tex \
		--chapter \
		--variable=prelims:"$$prelims" \
		--variable=postlims:"$$postlims" \
        --filter ${latex_build}/filters.py

docx:
	pandoc $(metadata) test.md -o test.docx

clean:
	rm ${rendered}/*

serve:
	cd ${html_build} && jekyll serve --detach --watch && cd -