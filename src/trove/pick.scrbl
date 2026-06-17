#lang scribble/base
@(require "../../scribble-api.rkt" "../abbrevs.rkt")

@(define s-pick-args (list `("elt" ("type" "normal") ("contract" ,(a-id "a"))) `("rest" ("type" "normal") ("contract" ,(a-id "b")))))

@(append-gen-docs
'(module
  "pick"
  (path "src/arr/base/pick.arr")
  (data-spec
    (name "Pick")
    (type-vars (a16 b17))
    (variants ("pick-none" "pick-some"))
    (shared ()))
  
  (singleton-spec (name "pick-none") (with-members ()))
  (fun-spec
    (name "is-pick-none")
    (arity 1)
    (params [list: ])
    (args ("val"))
    (return (a-id "Boolean" (xref "<global>" "Boolean")))
    (contract (a-arrow "Any" (a-id "Boolean" (xref "<global>" "Boolean"))))
    (doc "Checks whether the provided argument is in fact a pick-none"))
  (constr-spec
    (name "pick-some")
    (members
      (("elt" (type normal) (contract "a"))
      ("rest" (type normal) (contract "b"))))
    (with-members ()))
  (fun-spec
    (name "is-pick-some")
    (arity 1)
    (params [list: ])
    (args ("val"))
    (return (a-id "Boolean" (xref "<global>" "Boolean")))
    (contract (a-arrow "Any" (a-id "Boolean" (xref "<global>" "Boolean"))))
    (doc "Checks whether the provided argument is in fact a pick-some"))))

@docmodule["pick"]{
  @; Ignored type testers
  @section{The Pick Datatype}

  @data-spec2["Pick" (list "a" "b") (list
    @singleton-spec2["Pick" "pick-none"]
    @constructor-spec["Pick" "pick-some" s-pick-args]
  )]

  @nested[#:style 'inset]{
  @singleton-doc["Pick" "pick-none" (P-of "a" "b")]
  @constructor-doc["Pick" "pick-some" s-pick-args (P-of "a" "b")]

  @function["is-pick-none" #:alt-docstrings ""]
  @function["is-pick-some" #:alt-docstrings ""]
  }
  
The primary use of @pyret{pick} is as a way of obtaining values from sets.
See the documentation of @pyret-method["Set" #f "pick" "sets"].

However, nothing precludes other datatypes from also implementing the
@pyret{Pick} interface. For instance, here's a simple queue definition that
provides a @pyret{pick} method:
@pyret-block{import pick as P
data Queue {
    Queue(List<Object> elts); /* TODO: with: methods */
}}
We can then write a function that uses that method to traverse the queue:
@pyret-block{int sum-queue(Queue q) {
    return switch (q.pick()) {
        case Pick-none: yield 0;
        case Pick-some(e, r): yield e + sum-queue(r);
    }
}}
with the expected behavior:
@examples{@"@"Check void test() {
    q = queue([1, 2, 3]);
    assertEquals(sum-queue(q), 6);
}}
  }
