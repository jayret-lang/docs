#lang scribble/manual

@(require (for-syntax syntax/parse)
          (for-syntax racket/base))

@(define cca (current-command-line-arguments))
@(define VERSION
  (if (> (vector-length cca) 0)
        (vector-ref cca 0)
        ""))

@(define-syntax (include-section/if-set stx)
  (syntax-parse stx
    [(_ envvar-stx:str file:str)
     (let* ((envvar (syntax->datum #'envvar-stx))
            (envvar (getenv envvar)))
       (if envvar
         #'(include-section file)
         #'(void)))]))

@title[#:version @VERSION]{Jayret}


@nested{This document has detailed information on the Jayret grammar and the
behavior of its expression forms and built-in libraries, along with many
examples and some longer descriptions of language design choices.

@bold{Note:} Jayret is a Java-flavored variant of Pyret. This documentation
site is a work in progress — syntax shown here currently reflects Pyret syntax.
See
@link["https://github.com/jayret-lang/jayret-lang/blob/main/docs/jayret-spec.md"
      "jayret-spec.md"]
for the current Jayret syntax reference.}

@nested{If you want to learn about (or teach!) programming and computer science
using Jayret, check out @link["https://jayret-lang.github.io/dcic" "A Data Centric Introduction to Computing"], a textbook on programming that inspired Jayret's
design. The @link["https://code.jayret.org" "Jayret playground"] lets you run
Jayret programs in your browser.}

@include-section["getting-started.scrbl"]

@include-section["language-concepts.scrbl"]

@include-section["libraries.scrbl"]

@include-section["style-guide.scrbl"]

@include-section["internal.scrbl"]

@include-section["glossary.scrbl"]
