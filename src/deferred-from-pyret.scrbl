#lang scribble/base

@(require (only-in scribble/manual link))

@title[#:style '(toc) #:tag "Deferred_from_Pyret"]{Deferred from Pyret}

@section{Overview}

Jayret is a Java-flavored surface syntax for Pyret. A small set of Pyret
features do not yet have a Jayret surface syntax in
@tt{jayret-v0.1.0}; this page collects them in one place so they can be
restored when surface syntax is designed.

For each item the upstream Pyret reference is linked.

@section{Deferred features}

@subsection{Reactors}

Reactor programs (interactive simulations driven by event handlers) live
entirely in the Pyret runtime and are reachable at runtime, but no Jayret
syntax has been chosen yet.

Upstream: @link["https://www.pyret.org/docs/latest/reactors.html"
                "Pyret docs: reactors"].

@subsection{Tuples}

Pyret tuples — written @tt{@"{"a; b; c@"}"} — and the corresponding
tuple-pattern bindings (@tt{@"{"x; y@"}" = ...}) are not in
@tt{jayret-v0.1.0}. Use a record (@tt{@"{"x: ..., y: ...@"}"}) as a workaround.

Upstream: @link["https://www.pyret.org/docs/latest/Tuples.html"
                "Pyret docs: tuples"].

@subsection{Shared methods on @tt{data} variants (@tt{sharing:})}

Pyret's @tt{sharing:} block — methods shared across every variant of a
@tt{data} — has no Jayret syntax yet. As a workaround, hoist the methods
out as free functions that pattern-match (@tt{switch}) on the variant.

Upstream: @link["https://www.pyret.org/docs/latest/data-types.html"
                "Pyret docs: data types, Shared Methods section"].

@subsection{Refinement type annotations}

Pyret's predicate-annotation form (@tt{Number%(is-positive)}) is not
yet in Jayret. Validate inputs with dynamic checks inside the function
body instead.

Upstream: @link["https://www.pyret.org/docs/latest/Type_Annotations.html"
                "Pyret docs: type annotations"].

@subsection{Fine-grained @tt{provide} and @tt{provide-types}}

Top-level definitions in a Jayret module are implicitly
@tt{provide *}. The fine-grained @tt{provide} form (subsetting,
renaming, type-only exports) is deferred.

Upstream: @link["https://www.pyret.org/docs/latest/Modules.html"
                "Pyret docs: modules"].

@subsection{Mid-loop @tt{return}}

@tt{return} inside a @tt{for} body or other deeply-nested,
non-@tt{if} position is not yet supported. The translator emits a
helpful error directing the reader to restructure with @tt{if}/@tt{else}
or recursion.

(No upstream equivalent — this is a Jayret-only construct.)

@subsection{@tt{while} loops}

@tt{while} requires mutable state. Recognized syntactically but not
yet executable; use recursion or @tt{for}/comprehensions.

(No upstream equivalent — this is a Jayret-only construct.)

@subsection{@tt{use context}}

The Pyret runtime supports @tt{use context starter2024} /
@tt{essentials2024} / etc. Jayret does not yet expose a surface form.
The default context is whichever the surrounding @link["https://jayret-lang.github.io/code"
"jayret-lang.github.io/code"] configuration sets.

Upstream: @link["https://www.pyret.org/docs/latest/use.html"
                "Pyret docs: use"].
