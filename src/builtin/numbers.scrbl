#lang scribble/base
@(require "../../scribble-api.rkt" "../abbrevs.rkt" scribble/html-properties)

@(define eq '(a-id "EqualityResult" (xref "equality" "EqualityResult")))
@(define eqfun `(a-arrow ,A ,A ,B))
@(define eq3fun `(a-arrow ,A ,A ,eq))
@(define numpred `(a-arrow ,N ,N ,B))

@(append-gen-docs
  `(module "numbers"
    (path "src/js/base/runtime-anf.js")
    (form-spec (name "+ (addition operator)"))
    (form-spec (name "- (subtraction operator)"))
    (form-spec (name "* (multiplication operator)"))
    (form-spec (name "/ (division operator)"))
    (form-spec (name "< (less)"))
    (form-spec (name "> (greater)"))
    (form-spec (name "<= (less or equal)"))
    (form-spec (name ">= (greater or equal)"))
    (form-spec (name "== (equal)"))
    (data-spec
      (name "Number")
      (variants)
      (shared))
    (data-spec
      (name "Exactnum")
      (variants)
      (shared))
    (data-spec
      (name "Roughnum")
      (variants)
      (shared))
    (data-spec
      (name "NumInteger")
      (variants)
      (shared))
    (data-spec
      (name "NumRational")
      (variants)
      (shared))
    (data-spec
      (name "NumPositive")
      (variants)
      (shared))
    (data-spec
      (name "NumNegative")
      (variants)
      (shared))
    (data-spec
      (name "NumNonPositive")
      (variants)
      (shared))
    (data-spec
      (name "NumNonNegative")
      (variants)
      (shared))
    (value-spec
      (name "PI"))
    (fun-spec
      (name "num-equal")
      (arity 2)
      (args ("n1" "n2"))
      (doc ""))
    (fun-spec
      (name "num-max")
      (arity 2)
      (args ("n1" "n2"))
      (doc ""))
    (fun-spec
      (name "num-min")
      (arity 2)
      (args ("n1" "n2"))
      (doc ""))
    (fun-spec
      (name "num-abs")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-sin")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-cos")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-tan")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-asin")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-acos")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-atan")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-atan2")
      (arity 2)
      (args ("dy" "dx"))
      (doc ""))
    (fun-spec
      (name "num-modulo")
      (arity 2)
      (args ("n" "divisor"))
      (doc ""))
    (fun-spec
      (name "num-truncate")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-sqrt")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-sqr")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-ceiling")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-floor")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-round")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-round-even")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-log")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-exp")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-expt")
      (arity 2)
      (args ("base" "exponent"))
      (doc ""))
    (fun-spec
      (name "num-to-rational")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-to-roughnum")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-integer")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-rational")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-roughnum")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-positive")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-negative")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-non-positive")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-is-non-negative")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-to-string")
      (arity 1)
      (args ("n"))
      (doc ""))
    (fun-spec
      (name "num-to-string-digits")
      (arity 2)
      (args ("n" "digits"))
      (doc ""))
    (fun-spec
      (name "num-within-abs")
      (arity 1)
      (args ("tol"))
      (return ,numpred)
      (doc ""))
    (fun-spec
      (name "num-within-rel")
      (arity 1)
      (args ("tol"))
      (return ,numpred)
      (doc ""))
    (fun-spec
      (name "num-within")
      (arity 1)
      (args ("tol"))
      (return ,numpred)
      (doc ""))
    (fun-spec
      (name "within-abs")
      (arity 1)
      (args ("tol"))
      (return ,eqfun)
      (doc ""))
    (fun-spec
      (name "within-abs-now")
      (arity 1)
      (args ("tol"))
      (return ,eqfun)
      (doc ""))
    (fun-spec
      (name "within")
      (arity 1)
      (args ("tol"))
      (return ,eqfun)
      (doc ""))
    (fun-spec
      (name "within-rel")
      (arity 1)
      (args ("tol"))
      (return ,eqfun)
      (doc ""))
    (fun-spec
      (name "within-rel-now")
      (arity 1)
      (args ("tol"))
      (return ,eqfun)
      (doc ""))
    (fun-spec
      (name "within-abs3")
      (arity 1)
      (args ("tol"))
      (return ,eq3fun)
      (doc ""))
    (fun-spec
      (name "within-abs-now3")
      (arity 1)
      (args ("tol"))
      (return ,eq3fun)
      (doc ""))
    (fun-spec
      (name "within-rel3")
      (arity 1)
      (args ("tol"))
      (return ,eq3fun)
      (doc ""))
    (fun-spec
      (name "within-rel-now3")
      (arity 1)
      (args ("tol"))
      (return ,eq3fun)
      (doc ""))
  (fun-spec
    (name "num-random")
    (arity 1)
    (args ("max"))
    (doc ""))
  (fun-spec
    (name "num-random-seed")
    (arity 1)
    (args ("seed"))
    (doc ""))
  (fun-spec
    (name "num-is-fixnum")
    (arity 1)
    (args ("n"))
    (doc ""))
  (fun-spec
    (name "num-exact")
    (arity 1)
    (args ("n"))
    (doc ""))
    ))

@docmodule["numbers" #:noimport #t #:friendly-title "Numbers"]{

Jayret numbers are of two kinds: exact numbers, or @pyret{Exactnum}s, 
and rough numbers or @pyret{Roughnum}s. Both are 
real; finite; and written in base ten.

@margin-note{Note that imaginary numbers were implemented in earlier versions of Jayret,
but are not currently supported.}

@pyret{Exactnum}s are arbitrarily precise rational numbers, including
integers and rational fractions.  For integers whose magnitude is less
than @pyret{(num-expt(2, 53) - 1)}, Jayret internally uses JavaScript
@tt{fixnum}s, in order to optimize basic arithmetic.

@pyret{Roughnum}s are numbers that are necessarily or
deliberately imprecise. These correspond to the same set of
values covered by JavaScript
@tt{fixnum}s (a.k.a. doubles), and thus cover a large but limited range
(magnitude less than @pyret{1.7976931348623157e308}).

Operations on @pyret{Exactnum}s typically return
@pyret{Exactnum}s. However, if the operation can yield irrationals, and it
is not possible to determine that a particular result is
definitely rational, that result is returned as a @pyret{Roughnum}. Thus,
trigonometric functions on @pyret{Exactnum}s typically yield @pyret{Roughnum}
answers, except for well-known edge cases such as the sine or
cosine of zero. Fractional powers of rationals are usually @pyret{Roughnum},
except for small roots where it can be ascertained that an exact
root is possible.

Operations that are non-casting and with at least one argument that is @pyret{Roughnum}
automatically coerce the result to be a @pyret{Roughnum}. This is known
as @pyret{Roughnum} contagion.

@pyret{Exactnum}s allow the usual comparison predicates. @pyret{Roughnum}s do
too, with the significant exception that trying to compare
@pyret{Roughnum}s for equality throws an error.  To write an
equality function that handles @pyret{Roughnum}s, use @pyret-id{within}, as
documented in @seclink["s:bounded-equalities"].

An operation whose numerical result is not determinate or finite
throws an error, with the message signaling either an
overflow or some more specific problem.

@section{Number Annotations}

Several specific type annotations are provided for numbers to allow more precise
value requirements to be specified.

@examples{Exactnum round-distance(NumNonNegative d) {
    return num-round(d);
}}

@type-spec["Number" (list)]{
The type of number values.}
@type-spec["Exactnum" (list)]{
The type of exact number values.}
@type-spec["Roughnum" (list)]{
The type of necessarily or deliberately imprecise values.}
@type-spec["NumInteger" (list)]{
The type of @pyret{Exactnum} integer values.}
@type-spec["NumRational" (list)]{
The type of exact rational number values. Same as @pyret{Exactnum}.}
@type-spec["NumPositive" (list)]{
The type of number values that are greater than zero.}
@type-spec["NumNegative" (list)]{
The type of number values that are less than zero.}
@type-spec["NumNonPositive" (list)]{
The type of number values that are less than or equal to zero.}
@type-spec["NumNonNegative" (list)]{
The type of number values that are equal to or greater than zero.}

@section{Number Literals}

@pyret{Exactnum}s can be integers,  fractions represented
with a solidus, or decimals, with an optional exponent. In the following,
the numerals on the same line all denote the same Jayret number.

@examples{42;
+42;
-42;
22/7;
-22/7;
2.718281828;
+2.718281828;
-2.718281828;
1/2;
0.5;
6.022e23;
+6.022e23;
6.022e+23;
+6.022e+23;
-6.022e23;
-6.022e+23;
-6.022e-23;}

@pyret{Exactnum}s are of arbitrary precision.

@pyret{Roughnum}s are represented with a leading tilde.  You can think of
the tilde as representing a person waving his or her hands vaguely.

They are integers, fractions or decimals, with an optional exponent.

@examples{~42;
~+42;
~-42;
~2.718281828;
~+2.718281828;
~-2.718281828;
~6.022e23;
~+6.022e23;
~6.022e+23;
~+6.022e+23;
~-6.022e23;
~-6.022e+23;
~-6.022e-23;}

@pyret{Roughnum}s cannot be made arbitrarily precise. The absolute value
ranges between 0 and 1.7976931348623157e+308 (JavaScript’s Number.MAX_VALUE) with a
granularity of 5e-324 (JavaScript’s Number.MIN_VALUE).

@section{Number Constants}

@value["PI" RN]

The mathematical constant π, approximated as a @pyret-id["Roughnum"], or
@pyret{~3.141592653589793}.

@section{Number Operators}

@form["+ (addition operator)" "left + right"]{
  @margin-note{If either of the values in an arithmetic operator is a
  @pyret{Roughnum}, the result is a @pyret{Roughnum}}
  When @pyret{left} and @pyret{right} evaluate to numbers, adds them and returns
  the result.

@examples[#:show-try-it #t]{@"@"Check void test() {
    assertEquals(2 + 2, 4);
    assertEquals(4/3 + 1/3, 5/3);
    assertEquals(0.1 + 0.2, 0.3);
}}
}

@form["- (subtraction operator)" "left - right"]{
  When @pyret{left} and @pyret{right} evaluate to numbers, subtracts
  @pyret{right} from @pyret{left} and returns the result.

@examples[#:show-try-it #t]{@"@"Check void test() {
    assertEquals(6 - 2, 4);
    assertEquals(4/3 - 1/3, 1);
    assertEquals(0.3 - 0.2, 0.1);
}}
}

@form["* (multiplication operator)" "left * right"]{
  When @pyret{left} and @pyret{right} evaluate to numbers, multiplies
  them and returns the result.

@examples[#:show-try-it #t]{@"@"Check void test() {
    assertEquals(2 * 2, 4);
    assertEquals(2 * 1/3, 2/3);
    assertEquals(0.3 * 0.2, 0.06);
}}
}

@form["/ (division operator)" "left / right"]{
  @margin-note{To be used as an operator, @pyret{/} has to have spaces around
  it. This means you need to write @pyret{a / 3} rather than @pyret{a/3} to
  divide the value stored in @pyret{a} by @pyret{3}. Things like @pyret{4/3} and
  @pyret{1/2} are read by Jayret as single
  numbers, and can't have names or other expressions in them.}
  When @pyret{left} and @pyret{right} evaluate to numbers, divides @pyret{left}
  by @pyret{right} and returns the result.

@examples[#:show-try-it #t]{@"@"Check void test() {
    assertEquals(8 / 2, 4);
    assertEquals(8/3 / 2, 4/3);
    assertEquals(0.3 / 10, 0.03);
}}
}

@form["< (less)" "left < right"]
@form["> (greater)" "left < right"]
@form["<= (less or equal)" "left < right"]
@form[">= (greater or equal)" "left < right"]
@form["== (equal)" "left < right"]

Comparison operators. See @seclink["inequalities"].


@section{Number Functions}

@function["num-equal" #:contract (a-arrow N N B) #:return B]{
If both arguments are @pyret{Exactnum}s, returns a @pyret{Boolean}.
If either argument is @pyret{Roughnum}, raises an error.

@examples{@"@"Check void test() {
    assertEquals(num-equal(2, 2), true);
    assertEquals(num-equal(2, 3), false);
    assertEquals(num-equal(1/2, 0.5), true);
    assertEquals(num-equal(1 / 2, 0.5), true);
    assertEquals(num-equal(1/3, 0.33), false);
    assertRaises(() -> { num-equal(1/3, ~0.33) }, "roughnums cannot be compared for equality");
}}

  }
  @function["num-max" #:contract (a-arrow N N N) #:return N]{
Returns the greater of the two arguments.

@examples{@"@"Check void test() {
    assertEquals(num-max(1, 2), 2);
    assertRoughlyEquals(num-max(2, ~3), ~3);
    assertEquals(num-max(4, ~4), 4);
    assertRoughlyEquals(num-max(~4, 4), ~4);
    assertEquals(num-max(-1.1, 0), 0);
}}

  }
  @function["num-min" #:contract (a-arrow N N N) #:return N]{
Returns the lesser of the two arguments.

@examples{@"@"Check void test() {
    assertEquals(num-min(1, 2), 1);
    assertEquals(num-min(2, ~3), 2);
    assertEquals(num-min(4, ~4), 4);
    assertRoughlyEquals(num-min(~4, 4), ~4);
    assertEquals(num-min(-1.1, 0), -1.1);
}}

  }
  @function["num-abs" #:contract (a-arrow N N) #:return N]{
Returns the absolute value of the argument. The result is an
  @pyret{Exactnum} only if the argument is.

@examples{@"@"Check void test() {
    assertEquals(num-abs(2), 2);
    assertEquals(num-abs(-2.1), 2.1);
    assertRoughlyEquals(num-abs(~2), ~2);
    assertRoughlyEquals(num-abs(~-2.1), ~2.1);
}}

  }
  @function["num-sin" #:contract (a-arrow N N) #:return N]{

Returns the sine of the argument (an angle in radians), usually as a @pyret{Roughnum}.
  If the argument is @pyret{Exactnum} 0, the result is @pyret{Exactnum} 0 too.

@examples{@"@"Check void test() {
    assertEquals(num-sin(0), 0);
    assertEquals(num-sin(1), 0.84);
}}
  }
  @function["num-cos" #:contract (a-arrow N N) #:return N]{

Returns the cosine of the argument (an angle in radians), usually as a @pyret{Roughnum}. If
the argument is @pyret{Exactnum} 0, the result is @pyret{Exactnum} 1.

@examples{@"@"Check void test() {
    assertEquals(num-cos(0), 1);
    assertEquals(num-cos(1), 0.54);
}}
  }
  @function["num-tan" #:contract (a-arrow N N) #:return N]{
Returns the tangent of the argument (an angle in radians), usually as a @pyret{Roughnum}. If
the argument is @pyret{Exactnum} 0, the result is @pyret{Exactnum} 1.

@examples{@"@"Check void test() {
    assertEquals(num-tan(0), 0);
    assertEquals(num-tan(1), 1.56);
}}

  }
  @function["num-asin" #:contract (a-arrow N N) #:return N]{
  
Returns the arcsine of the argument as an angle in radians in the range [-π/2,
π/2], usually as a @pyret{Roughnum}. If the argument is @pyret{Exactnum} 0, the
result is @pyret{Exactnum} 0.

@examples{@"@"Check void test() {
    assertEquals(num-asin(0), 0);
    assertEquals(num-asin(0.84), 1);
}}

  }
  @function["num-acos" #:contract (a-arrow N N) #:return N]{

Returns the arccosine of the argument as an angle in radians in the range [0,
π], usually as a @pyret{Roughnum}. However, if the argument is
@pyret{Exactnum} 1, the result is @pyret{Exactnum} 0.

@examples{@"@"Check void test() {
    assertEquals(num-acos(1), 0);
    assertEquals(num-acos(0.54), 1);
}}
  }
  @function["num-atan" #:contract (a-arrow N N) #:return N]{

Returns the arctangent of the argument as an angle in radians in the range
(-π/2, π/2), usually as a @pyret{Roughnum}. However, if the argument is
@pyret{Exactnum} 0, the result is @pyret{Exactnum} 0.

@examples{@"@"Check void test() {
    assertEquals(num-atan(0), 0);
    assertRoughlyEquals(num-atan(1), (3.141592 * 1/4));
    // 45 degrees = π/4 radians
    assertRoughlyEquals(num-atan(-1), (-3.141592 * 1/4));
    // 315 degrees = -π/4 radians
    assertRoughlyEquals(num-atan(100000000000), (3.141592 / 2));
    // 90 degrees = π/2 radians
    assertRoughlyEquals(num-atan(-100000000000), (-3.141592 / 2));
}
// 270 degrees = -π/2 radians}
  }

  @function["num-atan2" #:contract (a-arrow N N N) #:return N]{

The @pyret{num-atan} function takes a tangent value and returns @emph{a}
corresponding angle, but it is not clear which angle to return: for example,
both @pyret{num-tan(3.141592 * 1/4)} and @pyret{num-tan(3.141592 * 5/4)} have a
tangent of @pyret{~1}.  The @pyret{num-atan2} function produces an angle in
radians in the range [0, 2π], where the tangent value is the @emph{ratio} of
the two arguments: the two arguments represent the (signed)
@emph{height} and @emph{width} of a triangle whose angle is unknown (i.e.,
their ratio is the "rise over run", defining the tangent of that angle).  The
return value of @pyret{num-atan2} chooses which angle to return based on the
following table:

@tabular[
  #:column-properties (list (list (attributes '((style . "padding: 5px;")))))
(list
  (list "If..."         @pyret{dx < 0} @pyret{dx > 0})
  (list @pyret{dy > 0}  "Quadrant II"   "Quadrant I")
  (list @pyret{dy < 0}  "Quadrant III"  "Quadrant IV"))
  ]

@examples{@"@"Check void test() {
    assertEquals(num-atan2(0, 1), 0);
    assertRoughlyEquals(num-atan2(1, 1), (3.141592 * 1/4));
    // 45 degrees
    assertRoughlyEquals(num-atan2(1, -1), (3.141592 * 3/4));
    // 135 degrees 
    assertRoughlyEquals(num-atan2(-1, -1), (3.141592 * 5/4));
    // 225 degrees
    assertRoughlyEquals(num-atan2(-1, 1), (3.141592 * 7/4));
    // 315 degrees
    assertRoughlyEquals(num-atan2(1, 0), (3.141592 * 1/2));
    // 90 degrees
    assertRoughlyEquals(num-atan2(-1, 0), (3.141592 * 3/2));
}
// 270 degrees}
  }

  @function["num-modulo" #:contract (a-arrow N N N) #:return N]{
Returns the modulus of the first argument with respect to the
second, i.e. the remainder when dividing the first number by the second.

@examples{@"@"Check void test() {
    assertEquals(num-modulo(5, 2), 1);
    assertEquals(num-modulo(-5, 2), 1);
    assertEquals(num-modulo(-5, -2), -1);
    assertEquals(num-modulo(7, 3), 1);
    assertEquals(num-modulo(0, 5), 0);
    assertEquals(num-modulo(-7, 3), 2);
}}

It is useful for calculating if one number is a multiple of
another, by checking for a zero remainder.

@examples{boolean is-even(int n) {
    return num-modulo(n, 2) == 0;
} where {
    
}}

  }
  @function["num-truncate" #:contract (a-arrow N N) #:return N]{

Returns the integer part of its argument by cutting off any
decimal part. Does not do any rounding.

@examples{@"@"Check void test() {
    assertEquals(num-truncate(3.14), 3);
    assertEquals(num-truncate(-3.14), -3);
    assertRoughlyEquals(num-truncate(~3.14), ~3);
    assertRoughlyEquals(num-truncate(~-3.14), ~-3);
}}

  }
  @function["num-sqrt" #:contract (a-arrow N N) #:return N]{

Returns the square root of the given argument.  If the argument is an @pyret{Exactnum} and a perfect
square, the result is an @pyret{Exactnum}, otherwise, it is a @pyret{Roughnum}.

@examples{@"@"Check void test() {
    assertEquals(num-sqrt(4), 2);
    assertEquals(num-sqrt(5), ~2.236);
    assertEquals(num-sqrt(~4), ~2);
    assertEquals(num-sqrt(~5), ~2.236);
    assertEquals(num-sqrt(0.04), 1/5);
    assertRaises(() -> { num-sqrt(-1) }, "negative argument");
}}
  }
  @function["num-sqr" #:contract (a-arrow N N) #:return N]{

Returns the square of the given argument.

@examples{@"@"Check void test() {
    assertEquals(num-sqr(4), 16);
    assertEquals(num-sqr(5), 25);
    assertEquals(num-sqr(-4), 16);
    assertRoughlyEquals(num-sqr(~4), ~16);
    assertEquals(num-sqr(0.04), 1/625);
}}

  }
  @function["num-ceiling" #:contract (a-arrow N EN) #:return EN]{

Returns the smallest integer @pyret{Exactnum} greater than or equal to the
argument.

@examples{@"@"Check void test() {
    assertEquals(num-ceiling(4.2), 5);
    assertEquals(num-ceiling(-4.2), -4);
}}

  }
  @function["num-floor" #:contract (a-arrow N EN) #:return EN]{

Returns the largest integer @pyret{Exactnum} less than or equal to the argument.

@examples{@"@"Check void test() {
    assertEquals(num-floor(4.2), 4);
    assertEquals(num-floor(-4.2), -5);
}}
  }
  @function["num-round" #:contract (a-arrow N EN) #:return EN]{

Returns the closest integer @pyret{Exactnum} to the argument. 

@examples{@"@"Check void test() {
    assertEquals(num-round(4.2), 4);
    assertEquals(num-round(4.8), 5);
    assertEquals(num-round(-4.2), -4);
    assertEquals(num-round(-4.8), -5);
}}

If the argument is midway between integers, returns the integer further
away from zero.

@examples{@"@"Check void test() {
    assertEquals(num-round(3.5), 4);
    assertEquals(num-round(2.5), 3);
}}

  }
  @function["num-round-even" #:contract (a-arrow N EN) #:return EN]{

Similar to @pyret{num-round}, except that if the argument is
midway between integers, returns the even integer @pyret{Exactnum}.

@examples{@"@"Check void test() {
    assertEquals(num-round-even(3.5), 4);
    assertEquals(num-round-even(2.5), 2);
}}

  }  @function["num-log" #:contract (a-arrow N N) #:return N]{

Returns the natural logarithm (ln) of the argument, usually as a @pyret{Roughnum}.
If the argument is @pyret{Exactnum} 1, the
result is @pyret{Exactnum} 0. If the argument is non-positive, an error is
thrown.

@examples{@"@"Check void test() {
    assertEquals(num-log(1), 0);
    assertRaises(() -> { num-log(0) }, "non-positive argument");
    assertRaises(() -> { num-log(-1) }, "non-positive argument");
    assertEquals(num-log(2.718281828), 1);
    assertEquals(num-log(10), 2.3);
}}

  }
  @function["num-exp" #:contract (a-arrow N N) #:return N]{

Returns e raised to the argument, usually as a @pyret{Roughnum}.  However, if the
argument is @pyret{Exactnum} 0, the result is
@pyret{Exactnum} 1.

@examples{@"@"Check void test() {
    assertEquals(num-exp(-1), (1 / num-exp(1)));
    assertEquals(num-exp(0), 1);
    assertEquals(num-exp(1), 2.718281828);
    assertEquals(num-exp(3), num-expt(2.718281828, 3));
    assertRaises(() -> { num-exp(710) }, "exp: argument too large: 710");
}}

  }
  @function["num-expt" #:contract (a-arrow N N N) #:return N]{

Returns the first argument raised to the second argument.  An error
is thrown if the first argument is 0 and the second is negative.
If the first argument is @pyret{Exactnum} 0 or 1,
or the second argument is @pyret{Exactnum} 0, then the result is an
@pyret{Exactnum} even if the other argument is a @pyret{Roughnum}.

@examples{@"@"Check void test() {
    assertEquals(num-expt(3, 0), 1);
    assertEquals(num-expt(1, 3), 1);
    assertEquals(num-expt(0, 0), 1);
    assertEquals(num-expt(0, 3), 0);
    assertRaises(() -> { num-expt(0, -3) }, "division by zero");
    assertEquals(num-expt(2, 3), 8);
    assertEquals(num-expt(2, -3), 1/8);
}}

  }


  @function["num-to-roughnum" #:contract (a-arrow N RN) #:return RN]{

Given a number, returns the @pyret{Roughnum} version.

@examples{@"@"Check void test() {
    assertEquals(num-is-roughnum(num-to-roughnum(3.14)), true);
    assertEquals(num-is-roughnum(num-to-roughnum(~3.14)), true);
}}
  }
  @function["num-is-integer" #:contract (a-arrow N B) #:return B]{
Returns @pyret{true} if argument is an @pyret{Exactnum} integer.

@examples{@"@"Check void test() {
    assertEquals(num-is-integer(2), true);
    assertEquals(num-is-integer(1/2), false);
    assertEquals(num-is-integer(1.609), false);
    assertEquals(num-is-integer(~2), false);
}}

  }
  @function["num-is-rational" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if argument is an @pyret{Exactnum} rational.

@examples{@"@"Check void test() {
    assertEquals(num-is-rational(2), true);
    assertEquals(num-is-rational(1/2), true);
    assertEquals(num-is-rational(1.609), true);
    assertEquals(num-is-rational(~2), false);
}}

  }
  @function["num-is-roughnum" #:contract (a-arrow N B) #:return B]{
Returns @pyret{true} if argument is a @pyret{Roughnum}.
@examples{@"@"Check void test() {
    assertEquals(num-is-roughnum(2), false);
    assertEquals(num-is-roughnum(1/2), false);
    assertEquals(num-is-roughnum(1.609), false);
    assertEquals(num-is-roughnum(~2), true);
}}

  }
  @function["num-is-positive" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if argument is greater than zero.

@examples{@"@"Check void test() {
    assertEquals(num-is-positive(~-2), false);
    assertEquals(num-is-positive(-2), false);
    assertEquals(num-is-positive(0), false);
    assertEquals(num-is-positive(-0), false);
    assertEquals(num-is-positive(2), true);
    assertEquals(num-is-positive(~2), true);
}}
  }
  @function["num-is-negative" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if argument is less than zero.

@examples{@"@"Check void test() {
    assertEquals(num-is-negative(~-2), true);
    assertEquals(num-is-negative(-2), true);
    assertEquals(num-is-negative(0), false);
    assertEquals(num-is-negative(-0), false);
    assertEquals(num-is-negative(2), false);
    assertEquals(num-is-negative(~2), false);
}}

  }
  @function["num-is-non-positive" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if argument is less than or equal to zero.
@examples{@"@"Check void test() {
    assertEquals(num-is-non-positive(~-2), true);
    assertEquals(num-is-non-positive(-2), true);
    assertEquals(num-is-non-positive(0), true);
    assertEquals(num-is-non-positive(-0), true);
    assertEquals(num-is-non-positive(2), false);
    assertEquals(num-is-non-positive(~2), false);
}}

  }
  @function["num-is-non-negative" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if argument is greater than or equal to zero.

@examples{@"@"Check void test() {
    assertEquals(num-is-non-negative(~-2), false);
    assertEquals(num-is-non-negative(-2), false);
    assertEquals(num-is-non-negative(0), true);
    assertEquals(num-is-non-negative(-0), true);
    assertEquals(num-is-non-negative(2), true);
    assertEquals(num-is-non-negative(~2), true);
}}
  }
  @function["num-to-string" #:contract (a-arrow N S) #:return S]{
Returns a @pyret{String} representing a literal form of the number.

@examples{@"@"Check void test() {
    assertEquals(num-to-string(2.5), "5/2");
    assertEquals(num-to-string(2), "2");
    assertEquals(num-to-string(2/3), "2/3");
    assertEquals(num-to-string(~2.718), "~2.718");
    assertEquals(num-to-string(~6.022e23), "~6.022e+23");
}}
  }
  @function["num-to-string-digits" #:contract (a-arrow N N S) #:return S]{

Converts the number to a @pyret{String}, providing @pyret{digits} precision in the
output.  If @pyret{digits} is positive, provides that many digits to the right
of the decimal point (including adding zeroes beyond the actual precision of
the number).  If @pyret{digits} is negative, rounds that many positions to the
@emph{left} of the decimal, replacing them with zeroes.

Note that @pyret-id{num-to-string-digits} is only for formatting, and its
output's apparent precision may be unrelated to the actual precision of the
input number, which may have been an approximation, or unrepresentable in
decimal.

@examples{@"@"Check void test() {
    assertEquals(num-to-string-digits(2/3, 3), "0.667");
    assertEquals(num-to-string-digits(-2/3, 3), "-0.667");
    assertEquals(num-to-string-digits(5, 2), "5.00");
    assertEquals(num-to-string-digits(5, 0), "5");
    assertEquals(num-to-string-digits(555, -2), "600");
}}
  }
  @function["num-within-abs" #:contract (a-arrow N (a-arrow N N B))]{

Returns a predicate that checks if the difference of its two
arguments is less than @pyret{tol}.

@examples{@"@"Check void test() {
    assertEquals(1, 1);
    assertEquals(1, ~1);
    assertEquals(~3, ~3);
    assertNotEquals(~2, ~3);
    assertEquals(~2, ~3);
    assertEquals(~2, ~3);
    assertEquals(2, ~3);
    assertEquals(5, 3);
    assertRaises(() -> { num-within-abs(-0.1)(1, 1.05) }, "negative tolerance");
}}

  }
  @function["num-within-rel" #:contract (a-arrow N (a-arrow N N B))]{

Returns a predicate that checks that its first number argument
is no more than the fraction @pyret{tol} off from its second
argument.


@examples{@"@"Check void test() {
    assertEquals(100000, 95000);
    assertNotEquals(100000, 85000);
}}
  }

  @function["num-within" #:contract (a-arrow N (a-arrow N N B))]{
An alias for @pyret-id["num-within-rel" "numbers"], much as @pyret-id["within"
"equality"] and @pyret-id["within-rel" "equality"] are synonyms.
}


  @function["within" #:contract (a-arrow N eqfun)]
  @function["within-abs" #:contract (a-arrow N eqfun)]
  @function["within-rel" #:contract (a-arrow N eqfun)]
  @function["within-abs-now" #:contract (a-arrow N eqfun)]
  @function["within-rel-now" #:contract (a-arrow N eqfun)]

  These comparison functions compare both numbers and structures, and are
  documented in @seclink["s:bounded-equalities"].

  @function["within-abs3" #:contract (a-arrow N eq3fun)]
  @function["within-rel3" #:contract (a-arrow N eq3fun)]
  @function["within-abs-now3" #:contract (a-arrow N eq3fun)]
  @function["within-rel-now3" #:contract (a-arrow N eq3fun)]

  These comparison functions are like the ones above, but return
  @pyret-id["EqualityResult" "equality"]s, and are documented in @seclink["s:total-equality-predicates"].

@section{Random Numbers}

  @function["num-random" #:contract (a-arrow N N) #:return N]{

  Returns a pseudo-random integer from @pyret{0} to @pyret{max - 1}.

@examples{@"@"Check void test() {
    Object between(min, max) {
        return (v) -> (v >= min) && (v <= max);
    }
    for (i : range(0, 100)) {
        block: n = num-random(10);
        print(n);
        assertSatisfies(n, between(0, 10 - 1));
    }
}}

  }
  @function["num-random-seed" #:contract (a-arrow N No) #:return No]{

  Sets the random seed.  Setting the seed to a particular number makes all
  future uses of random produce the same sequence of numbers.  Useful for
  testing and debugging functions that have random behavior.

  @examples{@"@"Check void test() {
    num-random-seed(0);
    n = num-random(1000);
    n2 = num-random(1000);
    assertNotEquals(n, n2);
    num-random-seed(0);
    n3 = num-random(1000);
    assertEquals(n3, n);
    n4 = num-random(1000);
    assertEquals(n4, n2);
}}
  }

The random seed is set globally.  If it is set in tests in a game or another
program that should not run the same way every time, add an identifier you can
set as a flag indicating if you are running the code in testing or production.

@examples{IS-TESTING = true;
// change as needed
when (IS-TESTING) {
    num-random-seed(...);
}}
  
@section{Other Number Functions}

  A few other number functions are useful in limited cases that don't come up
  in most programs.

  @function["num-is-fixnum" #:contract (a-arrow N B) #:return B]{

Returns @pyret{true} if the argument is represented directly as a
primitive
JavaScript number (i.e., JavaScript double).

@examples{@"@"Check void test() {
    assertEquals(num-is-fixnum(10), true);
    assertEquals(num-is-fixnum(~10), false);
    assertEquals(num-is-fixnum(1000000000000000), true);
    assertEquals(num-is-fixnum(10000000000000000), false);
    assertEquals(num-is-fixnum(1.5), false);
}}

@margin-note{Jayret represents @pyret{Exactnums} that are non-integers as tuples, 
and hence even small rationals such as 1.5 are considered non-@tt{fixnum},
although they could be represented as JavaScript doubles.}

  }
  @function["num-exact" #:contract (a-arrow N EN) #:return EN]
  @function["num-to-rational" #:contract (a-arrow N EN) #:return EN]


Given a @pyret{Roughnum}, returns an @pyret{Exactnum} number most equal to it. Given
an @pyret{Exactnum} num, returns it directly.

@margin-note{It is not good practice to indiscriminately convert
 @pyret{Roughnum}s to @pyret{Exactnum}s to make comparison easier.
 Use @pyret{within()} or @pyret{is-roughly}.}

@examples{@"@"Check void test() {
    assertEquals(num-sqrt(2), ~1.4142135623730951);
    assertEquals(num-exact(num-sqrt(2)), 1.4142135623730951);
    assertEquals(num-to-rational(num-sqrt(2)), 1.4142135623730951);
}}

  }

