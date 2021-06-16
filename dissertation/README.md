# Dissertation

This folder contains all the LaTeX files required for my dissertation.
It also includes a directory of example programs which are included in the appendix.

## Build

```sh
latexmk \
    -synctex=1 \
    -interaction=nonstopmode \
    -file-line-error \
    -pdf \
    -outdir=_build/ \
    -auxdir=_build/ \
    dissertation.tex
```

This creates the file `dissertation.pdf` in `_build/`.
