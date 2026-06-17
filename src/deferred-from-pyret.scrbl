#lang scribble/base

@(require (only-in scribble/manual link))

@title[#:style '(toc)]{Deferred from Jayret}

@section{Overview}

Jayret is a Java-flavored surface syntax for Jayret. A small set of Jayret
features do not yet have a Jayret surface syntax in
@tt{jayret-v0.1.0}; this page collects them in one place so they can be
restored when surface syntax is designed.

For each item the upstream Jayret reference is linked.

@section{Deferred features}

@subsection{Reactors}

Reactor programs (interactive simulations driven by event handlers) live
entirely in the Jayret runtime and are reachable at runtime, but no Jayret
syntax has been chosen yet.

Upstream: @link["https://jayret-lang.github.io/docs/latest/reactors.html"
                "Jayret docs: reactors"].

@subsection{Tuples}

Jayret tuples — written @tt{@"{"a; b; c@"}"} — and the corresponding
tuple-pattern bindings (@tt{@"{"x; y@"}" = ...}) are not in
@tt{jayret-v0.1.0}. Use a record (@tt{@"{"x: ..., y: ...@"}"}) as a workaround.

Upstream: @link["https://jayret-lang.github.io/docs/latest/Tuples.html"
                "Jayret docs: tuples"].

@subsection{External tables (@tt{load-table})}

The literal @tt{table @"{" ... @"}"} form and the column DSL
(@tt{sieve} / @tt{order} / @tt{extend} / @tt{select} / @tt{extract}) are
all supported in Jayret. Only the external loader form
(@tt{load-table:} for CSV and Google Sheets) is deferred.

Upstream: @link["https://jayret-lang.github.io/docs/latest/tables.html"
                "Jayret docs: tables, Loading Tables section"].

@subsection{Shared methods on @tt{data} variants (@tt{sharing:})}

Jayret's @tt{sharing:} block — methods shared across every variant of a
@tt{data} — has no Jayret syntax yet. As a workaround, hoist the methods
out as free functions that pattern-match (@tt{switch}) on the variant.

Upstream: @link["https://jayret-lang.github.io/docs/latest/data-types.html"
                "Jayret docs: data types, Shared Methods section"].

@subsection{Refinement type annotations}

Jayret's predicate-annotation form (@tt{Number%(is-positive)}) is not
yet in Jayret. Validate inputs with dynamic checks inside the function
body instead.

Upstream: @link["https://jayret-lang.github.io/docs/latest/Type_Annotations.html"
                "Jayret docs: type annotations"].

@subsection{Fine-grained @tt{provide} and @tt{provide-types}}

Top-level definitions in a Jayret module are implicitly
@tt{provide *}. The fine-grained @tt{provide} form (subsetting,
renaming, type-only exports) is deferred.

Upstream: @link["https://jayret-lang.github.io/docs/latest/Modules.html"
                "Jayret docs: modules"].

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

The Jayret runtime supports @tt{use context starter2024} /
@tt{essentials2024} / etc. Jayret does not yet expose a surface form.
The default context is whichever the surrounding @link["https://code.jayret.org"
"code.jayret.org"] configuration sets.

Upstream: @link["https://jayret-lang.github.io/docs/latest/use.html"
                "Jayret docs: use"].
