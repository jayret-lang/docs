#lang scribble/base

@(require scribble/core
          scribble/decode
          (only-in scribble/manual link)
          scriblib/footnote
          "../abbrevs.rkt"
          "../../scribble-api.rkt"
          scribble/html-properties)

@(define (test-index-tag opname)
  (define tag (make-generated-tag))
  (define index-tags (list (pyret opname) "testing"))
  (make-index-element #f
                       (list (make-target-element #f '() `(idx ,tag)))
                       `(idx ,tag)
                       (cons opname (list "testing"))
                       index-tags
                       #f))

@(define (test-doc opname left right)
  @para[#:style "boxed pyret-header"]{
    @(test-index-tag opname)
    @(tt @left " " @(make-header-elt-for (seclink (xref (curr-module-name) opname) (tt opname)) opname) " " @right)
  })

@(define (test-doc1 opname left)
  @para[#:style "boxed pyret-header"]{
    @(test-index-tag opname)
    @(tt @left " " @(make-header-elt-for (seclink (xref (curr-module-name) opname) (tt opname)) opname))
  })

@(define (test-doc-pred opname pred left right)
  @para[#:style "boxed pyret-header"]{
    @(test-index-tag opname)
    @(tt @left " " @(make-header-elt-for (seclink (xref (curr-module-name) opname) (tt opname)) opname) "(" pred ")" " " @right)
  })

@(define (test-pred-use left opname pred right)
  (list @pyret[left] " " @pyret-id[opname]@pyret{(}@|pred|@pyret{)} " " @pyret[left]))

@(append-gen-docs
  '(module "testing"
    (path "src/js/base/runtime-anf.js")))

@docmodule["testing" #:friendly-title "Testing" #:noimport #t]{

@section[#:tag "testing-blocks"]{@pyret{check:} and @pyret{where:} blocks}

Tests in Jayret are written in special @emph{testing blocks}.  These blocks can
contain any Jayret code that isn't toplevel-only (like data definitions and
import or provide statements), and are the only places where
@seclink["testing-operators" "Testing Operators"] can be used.

@subsection{@pyret{check:} blocks}

The simplest testing blocks are @pyret{check:} blocks.  They can be written at
the top-level or inside other testing blocks.  Check blocks are a unit of
reporting test results, so all the test operators that evaluate inside a check
block will be reported as part of that block.  For example, these two check
blocks:

@pyret-block{@"@"Check void aFirstBlock() {
    assertEquals(5, 5);
    assertEquals(4, 5);
}
@"@"Check void aSecondBlock() {
    assertEquals(6, 7);
}}

will report:

@verbatim{
Check block: a first block
  test (5 is 5): ok
  test (4 is 5): failed, reason:
    Values not equal:
    4
    5
  1/2 tests passed in check block: a first block

Check block: a second block
  test (6 is 7): failed, reason:
    Values not equal:
    6
    7
  The test failed.

1/3 tests passed in all check blocks
}

Testing blocks are also a unit of failure: most of the time an error stops the
whole program, but inside a check block (and also inside @pyret-id{raises},
mentioned later), the error is stopped and reported, and Jayret goes on to
evaluating the next check block:

@pyret-block{@"@"Check void errorBlock() {
    raise("an error here doesn't stop the next check block from running");
    assertEquals(string-length("this test doesn't run"), 21);
}
@"@"Check void aLaterBlock() {
    assertEquals(string-length("these tests still run"), 21);
}}

Keep an eye out for the message @pyret{"Check block <some-block> ended in an error (all tests may not have run):"},
because it means that later tests in the
same block may not have run, so the output doesn't reflect all the tests that
were written.

@subsection{@pyret{where:} blocks}

Sometimes a function has tests that are explicitly associated with it.  For
these cases, the function can end in a @pyret{where:} block rather than
immediately with @pyret{end}.  @pyret{where:} blocks run the same way that
@pyret{check:} blocks do, and their name is taken from the function they are
attached to.

@examples{Object double(n) {
    return n + n;
} where {
    
}}

@section[#:tag "testing-operators"]{Testing Operators}

Testing operators should be written on their own line inside a @pyret{check:} or
@pyret{where:} block.  They can check for a number of properties and come in
several forms.

@subsection{Binary Test Operators}

Many useful tests compare two values, whether for a specific type of
@seclink["equality" "equality"] or a more sophisticated predicate.

@test-doc["is" "expr1" "expr2"]

Evaluates @pyret{expr1} and @pyret{expr2} to values, and checks if two values
are equal via @pyret-id["equal-always" "equality"], reporting success if they
are equal, and failure if they are not.

@test-doc["is-not" "expr1" "expr2"]

Like @pyret-id{is}, but failure and success are reversed.

@test-doc["is-roughly" "expr1" "expr2"]

Like @pyret-id{is}, but tolerant of roughnum values: specifically, this is a
shorthand for @pyret-id{is%}(@pyret-id["within" "equality"](0.000001)).

@test-doc-pred["is%" "pred" "expr1" "expr2"]

Evaluates @pyret{expr1} and @pyret{expr2} to values, and @pyret{pred} to a
value that must be a function (an error is reported if @pyret{pred} is not a
function).  It then applies @pyret{pred} to the two values from @pyret{expr1}
and @pyret{expr2}.  If the result of that call is @pyret{true}, reports
success, otherwise reports failure.

@test-doc-pred["is-not%" "pred" "expr1" "expr2"]

Like @pyret-id{is%}, but failure and success are reversed.

@examples{@"@"Check void test() {
    Object less-than(n1, n2) {
        return n1 < n2;
    }
    assertEquals(1, 2);
    assertNotEquals(2, 1);
}
@"@"Check void test() {
    Object longer-than(s1, s2) {
        return string-length(s1) > string-length(s2);
    }
    assertEquals("abc", "ab");
    assertNotEquals("", "");
}
@"@"Check void test() {
    Object equal-any-order(List<Object> l1, List<Object> l2) {
        same-length = (l1.length() == l2.length());
        all-present = [for lists.all(elt : l1) { yield lists.member(l2, elt); }];
        return same-length && all-present;
    }
    assertEquals([1, 2, 3], [3, 2, 1]);
    assertEquals([1, 2, 3], [2, 1, 3]);
    assertNotEquals([1, 2, 3, 3], [2, 1, 3]);
}
@"@"Check void test() {
    Object one-of(ans, elts) {
        return lists.member(elts, ans);
    }
    some-strings = ["123", "132", "213", "231", "312", "321"];
    assertEquals("321", some-strings);
    assertEquals("123", some-strings);
}
@"@"Check void test() {
    Object around(delta) {
        return (actual, target) -> num-abs(target - actual) <= delta;
    }
    assertEquals(5.05, 5);
    assertNotEquals(5.00002, 5);
}}

@test-doc["is==" "expr1" "expr2"]

Shorthand for @(test-pred-use "expr1" "is%" @pyret-id["equal-always" "equality"] "expr2").
Same as @pyret-id{is}.

@test-doc["is-not==" "expr1" "expr2"]

Like @pyret-id{is==}, but failure and success are reversed.
Same as @pyret-id{is-not}.

@test-doc["is=~" "expr1" "expr2"]

Shorthand for @(test-pred-use "expr1" "is%" @pyret-id["equal-now" "equality"] "expr2")

@test-doc["is-not=~" "expr1" "expr2"]

Like @pyret-id{is=~}, but failure and success are reversed.

@test-doc["is<=>" "expr1" "expr2"]

Shorthand for @(test-pred-use "expr1" "is%" @pyret-id["identical" "equality"] "expr2")

@test-doc["is-not<=>" "expr1" "expr2"]

Like @pyret-id{is<=>}, but failure and success are reversed.

@subsection{Unary Test Operators}

@test-doc["satisfies" "expr" "pred"]

Evaluates @pyret{expr} to a value and @pyret{pred} to a value expected to be a
function (if not a function, an error is thrown).  Then, @pyret{pred(val)} is
evaluated, and if the result is @pyret{true}, the test succeeds, and if
@pyret{false}, the test fails.

@test-doc["violates" "expr" "pred"]

Like @pyret-id{satisfies}, but failure and success are reversed.

@examples{@"@"Check void test() {
    assertSatisfies([], is-empty);
    assertSatisfies([], (l) -> l.length() == 0);
    is-odd = (int n) -> num-modulo(n, 2) == 1;
    assertSatisfies(5, is-odd);
    assertViolates(6, is-odd);
}}

@subsection{Exception Test Operators}

@test-doc["raises" "expr" "exn-string"]

Evaluates @pyret{expr} and expects an error to be raised.  If no error is
raised, the test fails.

If an error is the result, the @pyret-id["torepr" "<global>"] function is
called on the exception value, and @pyret-id{raises} checks that
@pyret{exn-string} is contained within that string.  If so, the test passes,
otherwise, it fails.

For simple errors (like those in many programming assignments), it works to use
@pyret-id["raise" "<global>"] on a string value and check that that string is
raised.  For larger programs, it can be useful to construct more sophisticated
error values and use @pyret-id{raises-satisfies} to test them.

@examples{@"@"Check void test() {
    assertRaises(() -> { raise("the roof!") }, "the roof");
    assertRaises(() -> { string-length("too", "many", "strings") }, "arity-mismatch");
    assertRaises(() -> { {}.x }, "field-not-found");
}}

@bold{Warning!} These two tests are not equivalent:

@pyret-block{@"@"Check void actuallyCatchesTheError() {
    assertRaises(() -> { raise("error!") }, "error!");
}
@"@"Check void errorHappensBeforeRaises() {
    value = raise("error!");
    assertRaises(() -> { value }, "error!");
}}

This is because the left-hand-side of @pyret-id{raises} is a special position
that can detect and catch errors, which normal expressions do not do.  So the
second check block fails before even getting to the @pyret-id{raises} line; try
it out and see what happens.

@test-doc["raises-other-than" "expr" "exn-string"]

Like @pyret-id{raises}, but the result must @emph{not} contain @pyret{exn-string}.

@test-doc1["does-not-raise" "expr"]

Evaluates @pyret{expr} and checks that no error is raised while evaluating
it.  The expression can evaluate to any value.

@test-doc["raises-satisfies" "expr" "pred"]

As the name suggests, this combines the idea of @pyret-id{raises} with
@pyret-id{satisfies} and calls @pyret{pred} on the exception that
@pyret{expr} raises (if any).  Still fails if no exception is raised.

@examples{import is-field-not-foundfromerror
@"@"Check void test() {
    o = {}
    assertRaisesSatisfies(() -> { o.x }, is-field-not-found);
}}

@test-doc["raises-violates" "expr" "pred"]

Like @pyret-id{raises-satisfies}, but the predicate must return
@pyret{false}.  Still fails if no exception is raised.

}

@section{Reasons for tests: @pyret{because} clauses}

@test-index-tag{because}

When writing a test case, we may have several goals in mind: we might want to
demonstrate @emph{whether} a particular function works properly, or we might
want to explore @emph{why} a particular function works the way it does.
Consider the following two test cases: when reading them, what meaning do they
convey?

@examples{@"@"Check void test() {
    assertEquals(distance-to-origin(3, 4), 5);
    assertEquals(distance-to-origin(3, 4), num-sqrt(num-sqr(3) + num-sqr(4)));
}}

Reading the first test case is concise and clear: the expected distance is
simply 5.  But why?  Nothing in the expected output gives any insight into how
the function works.  By contrast, the second test case gives far more insight,
and ``shows our work''...but it is also much lengthier.  Writing many such test
cases would get very tedious, very quickly.  Additionally, there's nothing
tying the two test cases together: we have to notice that the two tests are
adjacent in our program and their left sides are identical, to notice that both
tests are about the same input scenario.

Jayret allows us to write test cases in a slightly different way, that addresses
both of these concerns:

@examples{@"@"Check void test() {
    assertRoughlyEquals(distance-to-origin(3, 4), num-sqrt(num-sqr(3) + num-sqr(4)));
}}

Read this aloud as ``The distance to origin of (3, 4) is roughly 5, because the
square-root of three squared plus four squared is roughly 5.''  The @pyret{because}
clause lets us show work, while also connecting the explanation to the original
test case.

Now that there are potentially @emph{three} components to writing a single test
case, there are multiple ways a test case can fail:

@itemlist[
@item{The explanation could be wrong, and so the expected value and the
explanation do not match.}
@item{The expected value could be wrong, and so the explanation does not match
the expected value even if the explanation is correct.}
@item{The function itself could be wrong, and so the left-hand side produces the wrong
value and does not match the expected value.}
@item{The expected value could be wrong, and so the left-hand side does not
match the right-hand side even if the function behaves properly.}
]

As an example of the first case, suppose we had a typo in our explanation (we
used @pyret{num-sqrt} instead of @pyret{num-sqr}):

@pyret-block[#:style "bad-ex"]{@"@"Check void test() {
    assertRoughlyEquals(distance-to-origin(3, 4), num-sqrt(num-sqrt(3) + num-sqr(4)));
}}

Jayret will show us

@image[#:scale 0.5]{src/lang/test-inconsistent.png}

Here, even if the function is defined properly, the explanation and the
expected result are inconsistent.  Jayret will show this inconsistency as a test
failure, even if the left-hand side and the expected value do match --- after
all, we might simply have gotten lucky, and the explanation is more accurate!
A test case using a @pyret{because} clause will pass only if the explanation
matches the expected value @emph{and} the left-hand side matches the expected
value.

Using a @pyret{because} clause is optional, and is most helpful to illustrate a
few select examples to demonstrate how we think a function should be working.
Once we have a few test cases are passing, we can easily add several more and
leave out the @pyret{because} clauses for them...but if any of them
unexpectedly fail, we can easily add a @pyret{because} clause to them to help
debug the failure.

@subsection{Using @pyret{because} with other testing operators}

For an arbitrary test case @; TODO(pyret2jayret): parse failed (no shifts)
@pyret{expr1 <test-op> expr2 because expr3}, read
this aloud as ``@pyret{expr1 < test-op >;
expr2} because @pyret{expr3 < test-op >;
expr2}.''  So for example:

@itemlist[
@item{@pyret{assertEquals(times-two(3), 2 * 3)} reads as ``@pyret{times-two} of 3
is 6, because two times 3 is 6.''  Note that this reads analogously for
@pyret{is-roughly}, @pyret{is==}, @pyret{is=~}, @pyret{is<=>}, and @; TODO(pyret2jayret): parse failed (no shifts)
@pyret{is%(...)}.}
@item{@pyret{assertSatisfies(times-two(3), 2 * 3)} reads as
``@pyret{times-two} of 3 should be even, because two times 3 should be even.''}
@item{@pyret{assertRaises(() -> { reciprocal(0) }, 1 / 0)} reads as
``The reciprocal of zero raises a division-by-zero error, because @pyret{1 / 0}
raises a division-by-zero error.''}
]

The other testing operators also work with @pyret{because} in the same way,
though it is a bit harder to read them aloud.
