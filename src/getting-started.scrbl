#lang scribble/base

@(require (only-in scribble/manual link))

@title[#:style '(toc)]{Getting Started and Running Jayret}

The most direct way to Jayret is to visit @url["https://code.jayret.org"], which
runs Jayret entirely within your browser.

There are a few other ways to run Jayret via the command-line and via Visual
Studio Code, and all of these are summarized in @secref["platforms"].

If you're interested in a textbook, you can try out
@link["https://jayret-lang.github.io/dcic" "A Data-Centric Introduction to Computing"],
which gives a structured introduction to programming in Jayret.

@(table-of-contents)

@include-section["platforms/platforms.scrbl"]
@include-section["tour.scrbl"]
