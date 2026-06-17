#lang scribble/base
@(require "../../scribble-api.rkt" "../abbrevs.rkt")

@(define a-of-a '(a-app (a-id "Array" (xref "arrays" "Array")) "a"))

@(define (a-method name #:args args #:return ret #:contract contract)
  (method-doc "Array" "array" name #:alt-docstrings "" #:args args #:return ret #:contract contract))
@(define (a-ref name)
  (pyret-method "Array" "array" name "arrays"))

@(append-gen-docs
  '(module "arrays"
    (path "src/js/base/runtime-anf.js")
    (fun-spec
      (name "array")
      (arity 1))
    (data-spec
      (name "Array")
      (type-vars (a-id "a"))
      (variants ("array"))
      (shared (
        (method-spec (name "get-now"))
        (method-spec (name "set-now"))
        (method-spec (name "filter"))
        (method-spec (name "map"))
        (method-spec (name "fold"))
        (method-spec (name "concat"))
        (method-spec (name "duplicate"))
        (method-spec (name "sort-nums"))
        (method-spec (name "sort-by"))
        (method-spec (name "length"))
        (method-spec (name "to-list-now"))
        )))
    (fun-spec
      (name "build-array")
      (arity 2)
      (params [list: leaf("a")])
      (args ("f" "len"))
      (return "Any")
      (contract
        (a-arrow
          (a-arrow (a-id "Number" (xref "<global>" "Number")) "a")
          (a-id "Number" (xref "<global>" "Number"))
          "Any")))
    (fun-spec
      (name "array-from-list")
      (arity 1)
      (params [list: ])
      (args ("l"))
      (return "Any")
      (contract (a-arrow "Any" "Any")))
    (fun-spec
      (name "array-of")
      (arity 2)
      (args ("value" "count"))
      (doc ""))
    (fun-spec
      (name "array-get-now")
      (arity 2)
      (args ("array" "index"))
      (doc ""))
    (fun-spec
      (name "array-set-now")
      (arity 3)
      (args ("array" "index" "new-value"))
      (doc ""))
    (fun-spec
      (name "array-length")
      (arity 1)
      (args ("array"))
      (doc ""))
    (fun-spec
      (name "array-to-list-now")
      (arity 1)
      (args ("array"))
      (doc ""))
    (fun-spec
      (name "array-filter")
      (arity 2)
      (args ("f" "array"))
      (doc ""))
    (fun-spec
      (name "array-map")
      (arity 2)
      (args ("f" "array"))
      (doc ""))
    (fun-spec
      (name "array-fold")
      (arity 4)
      (args ("f" "init" "array" "start-index"))
      (doc ""))
    (fun-spec
      (name "array-concat")
      (arity 2)
      (args ("array1" "array2"))
      (doc ""))
    (fun-spec
      (name "array-duplicate")
      (arity 1)
      (args ("array"))
      (doc ""))
    (fun-spec
      (name "array-sort-nums")
      (arity 2)
      (args ("array" "asc"))
      (doc ""))
    (fun-spec
      (name "array-sort-by")
      (arity 3)
      (args ("array" "key" "asc"))
      (doc ""))
))


@docmodule["arrays" #:noimport #t]{

@section{The Array Type}

@type-spec["Array" (list)]{

A @pyret{array} is a mutable, fixed-length collection indexed
by non-negative intgers. Accessing and mutating a @pyret{array} takes
constant time in the size of the array.

By default, Pyret users should use this library. If, however, you need
a higher-performant but potentially less ergonomic array library, look at
@seclink{raw-arrays} instead, which is primarily reserved for internal
use and for building other libraries. However, do not use that library
unless you really cannot get what you need out of this one.

Because arrays are @emph{mutable}, equality is not straightforward.
Learn more at @seclink["equality"].

}

@section{Using Arrays in Programs}

Some of the names provided for arrays inevitably overlap with those
provided for other data. Therefore, using the @pyret{include}
form is likely to cause name-clashes. It is wiser to import arrays using a prefix name and
use the names below through that prefix.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = A.array-of("a", 3);
    assertEqualsRoughly(a, [A.array: "a", "a", "a"]);
    assertEquals(A.array-length(a), 3);
}}

@section{Constructing Arrays}

@collection-doc["array" #:contract `(a-arrow ("value" "a") ,(A-of "a"))]

Constructs an @pyret-id{Array} with the given elements.

Note that
@pyret-id{Array}s are mutable, so comparisons using
@secref["eq-fun-equal-always"]
will only
return @pyret{true} on @pyret-id{Array}s when they are also
@secref["eq-fun-identical"], regardless of their contents.
Usually, the most appropriate comparison is
@secref["eq-fun-equal-now"].
Tests should correspondingly use 
@pyret-id["is=~" "testing"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: 1, 2, 3];
    assertEquals(a, a);
    assertEqualsStrict(a, a);
    assertNotEquals([A.array: 1, 2, 3], a);
    assertNotEquals([A.array: 1, 2, 3], [A.array: 1, 2, 3]);
    /* TODO(pyret2jayret): check-op is-not== */ [A.array: 1, 2, 3] is-not== a;
    assertEqualsRoughly([A.array: 1, 2, 3], a);
    assertEqualsRoughly([A.array: 1, 2, 3], [A.array: 1, 2, 3]);
}}

@function["array-of"
  #:contract (a-arrow "a" N (A-of "a"))
  #:args (list (list "value" #f) (list "count" #f))
  #:return (A-of "a")
]

Constructs an @pyret{Array} of length @tt{count}, where every element is the value
given as @pyret{value}.

Note that @pyret{value} is not @emph{copied}, so,
the elements of @pyret{Array}s created with @pyret-id{array-of} will always be
@secref["eq-fun-identical"].

To create an array of arrays where each sub-array is independent of the other, use
@pyret-id{build-array}.

Similar to @pyret-id["raw-array-of" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    arr = A.array-of(true, 2);
    assertEqualsRoughly(arr, [A.array: true, true]);
    assertNotEquals(arr, [A.array: true, true]);
    /* TODO(pyret2jayret): check-op is<=> */ A.array-get-now(arr, 0) is<=> A.array-get-now(arr, 1);
    A.array-set-now(arr, 1, false);
    assertEqualsRoughly(arr, [A.array: true, false]);
    arr-of-arrs = A.array-of(arr, 3);
    assertEqualsRoughly(arr-of-arrs, [A.array: [A.array: true, false], [A.array: true, false], [A.array: true, false]]);
    A.array-set-now(arr, 0, false);
    assertEqualsRoughly(arr-of-arrs, [A.array: [A.array: false, false], [A.array: false, false], [A.array: false, false]]);
}}

@function["build-array"
  #:contract (a-arrow (a-arrow N "a") N (A-of "a"))
  #:args (list (list "f" #f) (list "size" #f))
  #:return (A-of "a")
]

Constructs an array of length @pyret{size}, and fills it with the result of
calling the function @pyret{f} with each index from @pyret{0} to @pyret{size - 1}.

Similar to @pyret-id["build-list" "lists"] and @pyret-id["raw-array-build" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    Object sq(x) {
        return x * x;
    }
    assertEqualsRoughly(A.build-array(sq, 4), [A.array: sq(0), sq(1), sq(2), sq(3)]);
}
@"@"Check void test() {
    Array<Object> build(int n) {
        return A.array-of("_", 3);
    }
    a = A.build-array(build, 3);
    assertEqualsRoughly(a, [A.array: [A.array: "_", "_", "_"], [A.array: "_", "_", "_"], [A.array: "_", "_", "_"]]);
    a.get-now(0).set-now(0, "X");
    a.get-now(1).set-now(1, "O");
    assertEqualsRoughly(a, [A.array: [A.array: "X", "_", "_"], [A.array: "_", "O", "_"], [A.array: "_", "_", "_"]]);
}}

@function["array-from-list"
  #:contract (a-arrow (L-of "a") (A-of "a"))
  #:args (list (list "l" #f))
  #:return (A-of "a")]

Converts a @pyret-id["List" "lists"] to an @pyret-id{Array} containing the same elements in the same order.

Similar to @pyret-id["raw-array-from-list" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
import lists as L
@"@"Check void test() {
    assertEqualsRoughly(A.array-from-list([L.list: 1, 2, 3]), [A.array: 1, 2, 3]);
}}

@section{Array Methods}

@a-method["get-now"
  #:contract (a-arrow (A-of "a") N "a")
  #:args (list (list "self" #f) (list "index" #f))
  #:return "a"
]

Returns the value at the given @tt{index}.  

This method has a
@pyret{-now} suffix because its answer can change from one call to the next if,
for example, @a-ref["set-now"] is used.

Using an index too large, negative, or not a whole number raises an error.

Similar to @pyret-id["get" "lists"] and @pyret-id["raw-array-get" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "a", "b", "c"];
    assertEquals(a.get-now(0), "a");
    assertEquals(a.get-now(1), "b");
    assertRaises(() -> { a.get-now(4) }, "index");
    assertRaises(() -> { a.get-now(-1) }, "index");
    assertRaises(() -> { a.get-now(1.2) }, "index");
}}

@a-method["set-now"
  #:contract (a-arrow (A-of "a") N "a" No)
  #:args (list (list "self" #f) (list "index" #f) (list "value" #f))
  #:return No
]

Updates the value at the given @tt{index}, returning @pyret-id["Nothing"
"<global>"].

The update is stateful, so all references to the array see the
update.  Hence the @pyret{-now} suffix; in the example below,
calling @pyret{a.get-now()} at two different points
in the program produces two different results.

Using an index too large, negative, or not a whole number raises an error.

Similar to @pyret-id["raw-array-set" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "a", "b", "c"];
    assertEquals(a.get-now(0), "a");
    a.set-now(0, "d");
    assertEquals(a.get-now(0), "d");
    b = a;
    a.set-now(0, "f");
    assertEqualsRoughly(a, [A.array: "f", "b", "c"]);
    assertEqualsRoughly(b, [A.array: "f", "b", "c"]);
    c = b.set-now(0, 'z');
    assertEquals(c, nothing);
    assertRaises(() -> { b.set-now(4, "hi") }, "index");
}}

@a-method["length"
  #:contract (a-arrow (A-of "a") N)
  #:args (list (list "self" #f))
  #:return N
]

Returns the length of the array.  The length of an array is set when it is
created and cannot be changed.

Similar to @pyret-id["length" "lists"] and @pyret-id["raw-array-length" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "a", "b"];
    assertEquals(a.length(), 2);
    b = [A.array: ];
    assertEquals(b.length(), 0);
}}

@a-method["filter"
    #:contract (a-arrow (A-of "a") (a-arrow "a" B) (A-of "a"))
    #:args (list (list "self" #f) (list "f" #f))
    #:return (A-of "a")]
    
  Applies function @pyret{f} to each element of @pyret{self} from left to right,
  constructing a new @pyret{Array} out of the elements for which @pyret{f}
  returned @pyret{true}.

Similar to @pyret-id["filter" "lists"] and @pyret-id["raw-array-filter" "raw-arrays"].

  @examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "apple", "banana", "plum"];
    p-words = a.filter((s) -> string-contains(s, "p"));
    assertEqualsRoughly(p-words, [A.array: "apple", "plum"]);
}}
  
@a-method["map"
    #:contract (a-arrow (A-of "a") (a-arrow "a" "b") (A-of "b"))
    #:args (list (list "self" #f) (list "f" #f))
    #:return (A-of "b")]
    
Applies function @pyret{f} to each element of the arrays from left to right, and
constructs a new @pyret{Array} out of the return values in the corresponding order.
The original array remains unchanged.

@tt{a} represents the type of the elements in the original @pyret{Array}, @tt{b} is
the type of the elements in the new @pyret{Array}.

Similar to @pyret-id["map" "lists"] and @pyret-id["raw-array-map" "raw-arrays"].

  @examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "apple", "banana", "plum"];
    lengths = a.map(string-length);
    assertEqualsRoughly(lengths, [A.array: 5, 6, 4]);
    assertEqualsRoughly(a, [A.array: "apple", "banana", "plum"]);
}}

@a-method["fold"
    #:contract (a-arrow (A-of "a") (a-arrow "b" "a" N "b") "b" N "b")
    #:args (list (list "self" #f) (list "f" #f) (list "init" #f) (list "start-index" #f))
    #:return "b"]
    
Combines the elements in the array with a function that accumulates
each element with an intermediate result. Has an
argument order that works with @pyret{for}. The numeric argument to the
accumulator is the index of the current element.

Similar to @pyret-id["fold" "lists"] and @pyret-id["raw-array-fold" "raw-arrays"].

  @examples[#:show-try-it #t]{import arrays as A
Object sum-even-minus-odd(Array<Object> a) {
    Object is-even(n) {
        return (n / 2) == num-floor(n / 2);
    }
    Object sum-ith(int sum-so-far, int new-n, int idx) {
        return if (is-even(idx)) {
            return sum-so-far + new-n;
        } else {
            return sum-so-far - new-n;
        }
    }
    return a.fold(sum-ith, 0, 0);
}
@"@"Check void test() {
    assertEquals(sum-even-minus-odd([A.array: ]), 0);
    assertEquals(sum-even-minus-odd([A.array: 1]), 1);
    assertEquals(sum-even-minus-odd([A.array: 1, 2]), (1 - 2));
    assertEquals(sum-even-minus-odd([A.array: 1, 2, 3]), (1 + 3) - 2);
    assertEquals(sum-even-minus-odd([A.array: 1, 2, 3, 4]), ((1 + 3) - (2 + 4)));
}}

@a-method["concat"
    #:contract (a-arrow (A-of "a") (A-of "a") (A-of "a"))
    #:args (list (list "self" #f) (list "other" #f))
    #:return (A-of "a")]

  Creates a new array with all the elements of the current array
  followed by all the elements of @pyret{other}.

Similar to @pyret-id["append" "lists"] and @pyret-id["raw-array-concat" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "To", "be", "or"];
    assertEqualsRoughly(a.concat([A.array: "not", "to", "be"]), [A.array: "To", "be", "or", "not", "to", "be"]);
    assertEqualsRoughly(a, [A.array: "To", "be", "or"]);
    /* TODO(pyret2jayret): check-op is-not=~ */ a is-not=~ [A.array: "To", "be", "or", "not", "to", "be"];
}}

@a-method["duplicate"
    #:contract (a-arrow (A-of "a"))
    #:args (list (list "self" #f))
    #:return (A-of "a")]

  Returns a copy of the given array, such that corresponding elements in the
  result are @secref["eq-fun-identical"] to those in the source array.

Similar to @pyret-id["raw-array-duplicate" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
data Person {
}
@"@"Check void test() {
    ps1 = [A.array: p("Alice", 30), p("Bob", 40)];
    ps2 = ps1.duplicate();
    assertEquals(ps2.get-now(0), ps1.get-now(0));
    ps2.get-now(1) ! {age 57 }
    assertEquals(ps1.get-now(1) ! age, 57);
}}

@a-method["sort-nums"
    #:contract (a-arrow (A-of "a") B)
    #:args (list (list "self" #f) (list "asc" #f))
    #:return (A-of "a")]

  Sorts the given array @emph{in-place} in ascending or descending order
  according to the @pyret{asc} parameter. Returns a reference to the
  original array, which will have its contents mutably updated.

Similar to @pyret-id["raw-array-sort-nums" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: 3, 1, 4, 1, 5, 9, 2];
    asc = a.sort-nums(true);
    /* TODO(pyret2jayret): check-op is<=> */ asc is<=> a;
    assertEqualsRoughly(a, [A.array: 1, 1, 2, 3, 4, 5, 9]);
    a.sort-nums(false);
    assertEqualsRoughly(a, [A.array: 9, 5, 4, 3, 2, 1, 1]);
}}

@a-method["sort-by"
    #:contract (a-arrow (A-of "a") (a-arrow "a" N) B)
    #:args (list (list "self" #f) (list "key" #f) (list "asc" #f))
    #:return (A-of "a")]

  Creates a new array containing the sorted contents of the given array. The sort
  order is determined by calling the @pyret{key} function on each element to
  get a number, and sorting the elements by their key value (in increasing key
  order if @pyret{asc} is @pyret{true}, decreasing if @pyret{false}). Ties are
  broken by the order in which the element is present in the initial array.

Similar to @pyret-id["raw-array-sort-by" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "let", "us", "go", "then", "you", "and", "i"];
    asc = a.sort-by(string-length, true);
    assertEqualsRoughly(asc, [A.array: "i", "us", "go", "let", "you", "and", "then"]);
    /* TODO(pyret2jayret): check-op is-not=~ */ asc is-not=~ a;
    desc = a.sort-by(string-length, false);
    assertEqualsRoughly(desc, [A.array: "then", "let", "you", "and", "us", "go", "i"]);
    assertEqualsRoughly(a, [A.array: "let", "us", "go", "then", "you", "and", "i"]);
}}


@a-method["to-list-now"
  #:contract (a-arrow (A-of "a") (L-of "a"))
  #:args (list (list "self" #f))
  #:return (L-of "a")
]

    Converts a @pyret-id{Array} to a @pyret-id["List" "lists"] containing
    the same elements in the same order. This method has a
@pyret{-now} suffix because its answer can change from one call to the next if,
for example, @a-ref["set-now"] is subsequently used.

    Note that it does @emph{not} recursively convert @pyret-id{Array}s;
    only the top-level is converted.

Similar to @pyret-id["raw-array-to-list" "raw-arrays"].

@examples[#:show-try-it #t]{import arrays as A
import lists as L
@"@"Check void test() {
    a = [A.array: 1, 2, 3];
    assertEquals(a.to-list-now(), [L.list: 1, 2, 3]);
    a2 = array-of([A.array: ], 3);
    assertEqualsRoughly(a2.to-list-now(), [L.list: [A.array: ], [A.array: ], [A.array: ]]);
    /* TODO(pyret2jayret): check-op is-not=~ */ a2.to-list-now() is-not=~ [L.list: [L.list: ], [L.list: ], [L.list: ]];
    a.set-now(0, 5);
    assertEquals(a.to-list-now(), [L.list: 5, 2, 3]);
}}



@section{Array Functions}

@function["array-get-now"
  #:contract (a-arrow (A-of "a") N "a")
  #:args (list (list "array" #f) (list "index" #f))
  #:return "a"
]

Equivalent to @pyret{array}@a-ref["get-now"]@pyret{(index)}.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: 0, 1, 2];
    assertEquals(A.array-get-now(a, 1), 1);
}}
          
@function["array-set-now"
  #:contract (a-arrow (A-of "a") N "a" (A-of "a"))
  #:args (list (list "array" #f) (list "index" #f) (list "value" #f))
  #:return No
]

Equivalent to @pyret{array}@a-ref["set-now"]@; TODO(pyret2jayret): parse failed (no shifts)
@pyret{(index, value)}.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = A.array-of("a", 3);
    assertEqualsRoughly(a, [A.array: "a", "a", "a"]);
    A.array-set-now(a, 1, "b");
    assertEqualsRoughly(a, [A.array: "a", "b", "a"]);
}}

@function["array-length"
  #:contract (a-arrow (A-of "a") N)
  #:args (list (list "array" #f))
  #:return N
]

Equivalent to @pyret{array}@a-ref["length"]@pyret{()}.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = A.array-of("a", 3);
    assertEqualsRoughly(a, [A.array: "a", "a", "a"]);
    assertEquals(A.array-length(a), 3);
}}

@function["array-filter"
  #:contract (a-arrow (a-arrow "a" B) (A-of "a"))
  #:args (list (list "f" #f) (list "array" #f))
  #:return (A-of "a")
]

Equivalent to @pyret{array}@a-ref["filter"]@pyret{(f)}, with an argument order
designed for @pyret{for}.


@function["array-map"
  #:contract (a-arrow (a-arrow "a" "b") (A-of "a"))
  #:args (list (list "f" #f) (list "array" #f))
  #:return (A-of "b")
]

Equivalent to @pyret{array}@a-ref["map"]@pyret{(f)}, with an argument order
designed for @pyret{for}.

@function["array-fold"
  #:contract (a-arrow (a-arrow "b" "a" N) "b" (A-of "a") N)
  #:args (list (list "f" #f) (list "init" #f) (list "array" #f) (list "start-index" #f))
  #:return "b"
]

Equivalent to @pyret{array}@a-ref["fold"]@; TODO(pyret2jayret): parse failed (no shifts)
@pyret{(f, init, start-index)}, with an argument order
designed for @pyret{for}.

@function["array-concat"
  #:contract (a-arrow (A-of "a") (A-of "a"))
  #:args (list (list "array1" #f) (list "array2" #f))
  #:return (A-of "a")
]

Equivalent to @pyret{array1}@a-ref["concat"]@pyret{(array2)}.

@function["array-duplicate"
  #:contract (a-arrow (A-of "a"))
  #:args (list (list "array" #f))
  #:return (A-of "a")
]

Equivalent to @pyret{array}@a-ref["duplicate"]@pyret{()}.

@function["array-sort-nums"
  #:contract (a-arrow (A-of "a") B)
  #:args (list (list "array" #f) (list "asc" #f))
  #:return (A-of "a")
]

Equivalent to @pyret{array}@a-ref["sort-nums"]@pyret{(asc)}.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: 3, 1, 4, 1, 5, 9, 2];
    asc = A.array-sort-nums(a, true);
    /* TODO(pyret2jayret): check-op is<=> */ asc is<=> a;
    assertEqualsRoughly(a, [A.array: 1, 1, 2, 3, 4, 5, 9]);
    A.array-sort-nums(a, false);
    assertEqualsRoughly(a, [A.array: 9, 5, 4, 3, 2, 1, 1]);
}}

@function["array-sort-by"
  #:contract (a-arrow (A-of "a") (a-arrow "a" N) B)
  #:args (list (list "array" #f) (list "key" #f) (list "asc" #f))
  #:return (A-of "a")
]

Equivalent to @pyret{array}@a-ref["sort-by"]@; TODO(pyret2jayret): parse failed (no shifts)
@pyret{(key, asc)}.

@examples[#:show-try-it #t]{import arrays as A
@"@"Check void test() {
    a = [A.array: "let", "us", "go", "then", "you", "and", "i"];
    asc = A.array-sort-by(a, string-length, true);
    assertEqualsRoughly(asc, [A.array: "i", "us", "go", "let", "you", "and", "then"]);
    /* TODO(pyret2jayret): check-op is-not=~ */ asc is-not=~ a;
    desc = A.array-sort-by(a, string-length, false);
    assertEqualsRoughly(desc, [A.array: "then", "let", "you", "and", "us", "go", "i"]);
    assertEqualsRoughly(a, [A.array: "let", "us", "go", "then", "you", "and", "i"]);
}}

@function["array-to-list-now"
  #:contract (a-arrow (A-of "a") (L-of "a"))
  #:args (list (list "array" #f))
  #:return (L-of "a")
]

Equivalent to @pyret{array}@a-ref["to-list-now"]@pyret{()}.

@examples[#:show-try-it #t]{import arrays as A
import lists as L
@"@"Check void test() {
    a = A.array-of("a", 3);
    assertEqualsRoughly(a, [A.array: "a", "a", "a"]);
    A.array-set-now(a, 1, "b");
    assertEqualsRoughly(a, [A.array: "a", "b", "a"]);
    l = A.array-to-list-now(a);
    assertEquals(l, [L.list: "a", "b", "a"]);
}}

}
