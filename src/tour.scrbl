#lang scribble/base

@(require
  "../scribble-api.rkt"
  (only-in scriblib/footnote note)
  (only-in scribble/core make-style) 
  (only-in scribble/manual link)
  (only-in scribble/html-properties make-alt-tag))

@(define output verbatim)

@title{A Tour of Pyret}

You can start playing with Pyret right away at
@url{https://code.pyret.org/editor}.  You can copy the examples below, run
them, and play with them to get a feel for the language.

@section{Testing and Assertions}

The simplest way to add a test to a Pyret program is to use a @pyret{check:}
block and a testing assertion.  Try running the following:

@pyret-block{@"@"Check void test() {
    assertEquals("Ahoy " + "world!", "Ahoy world!");
}}

Upon running this program, Pyret reports:

@output{
    Looks shipshape, your 1 test passed, mate!
}

This program uses a @pyret{check:} block to register a set of tests to be run.
The special @pyret{is} statement inside the check block compares the
expressions on the left and right for equality.  It reports the result to the
built-in testing framework, which produces a report when all the tests have
been run.

If we break the test slightly, we can see that Pyret reports the
error for us:

@pyret-block{@"@"Check void test() {
    assertEquals("Ahoy" + "world!", "Ahoy world!");
}}

@output{
    Check block: check-block-1
      test ("Ahoy" + "world!" is "Ahoy world!"): failed, reason:

    Values not equal:
    "Ahoyworld!"
    "Ahoy world!"

      The test failed.
}

The usual flow of writing a Pyret program involves writing tests along with
your code, running your code to check the test output, and repeating until
you're satisfied with the functionality of your program.  The more tests you
write, the more useful feedback you get.

The examples in this tour will all be presented in testing blocks
(you'll see one kind other than @pyret{check:} later).  Unless we're
explicitly pointing out a failure, you can assume that the tests
all pass, and we're showing correct behavior.


@section{Primitive Values and Operators}

Primitives values are the basic building blocks of the language;
structured data exists to organize computation over a small set of
primitive values.  We describe Pyret's primitives here.

@subsection{Numbers}

Numbers can be written with or without decimals.  For example:

@pyret-block{@"@"Check void test() {
    assertEquals(5.0, 5);
}}

Pyret defines a number of binary operators over numbers (the full list is
available in @seclink["s:binop-expr" "the documentation for binary
operators"]):

@pyret-block{@"@"Check void test() {
    assertEquals(4 + 5, 9);
    assertEquals(1 / 3, 2 / 6);
    assertEquals(9 - 3, 6);
    assertEquals(5 > 4, true);
}}

Once we have binary operators, it is natural to ask what operator
precedence Pyret has chosen.  In order to avoid ambiguity and
confusing updates to precedence tables when new operators are
added, chains of operators in Pyret simply disallows mixing
operators without disambiguating parentheses.  For example:

@pyret-block{@"@"Check void test() {
    assertEquals(5 - 4 + 1, 2);
}}

@output{    
  well-formedness: Cannot mix binary operators of different
  types: `+` and `-`. Use parentheses to disambiguate.
}

This holds not just for numeric operations, but for all binary
operators in the language.  To give this program the meaning
intended by the test, we should write:

@pyret-block{@"@"Check void test() {
    assertEquals((5 - 4) + 1, 2);
}}

You can see more utilities on numbers at
@seclink{numbers}.

@section{Booleans}

Pyret has two distinguished boolean values, @pyret{true} and @pyret{false}.  Neither is a
number or string or nullary or any other kind of value; both are booleans and
they are the only two booleans.  The comparison operators on numbers evaluate
to them, for instance:

@pyret-block{@"@"Check void test() {
    assertEquals(3 < 4, true);
    assertEquals((2 + 2) == 5, false);
}}

@section{Strings}

Strings can be written single- or double- quoted. Character escapes like @pyret{\n}
work, and the enclosing quote character can be included if escaped like @; TODO(pyret2jayret): parse failed (no shifts)
@pyret{\"}.

@"@"pyret-block{
"hello world"

"\"yields falsehood when...\" yields falsehood when"

"an example\n\nwith explicit newline\ncharacters"
}

Multi-line strings can be written with three backtick characters:

@pyret-block{@"@"Check void test() {
    s = ```
    a
    multi
    line
    string
    ```;
    assertEquals(s, "a
    multi
    line
    string");
}}

@section{Lists}

Lists aren't primitive values, but they come up a lot in Pyret programs.
Pyret's list are of the head-and-tail variety found in many functional
languages.  They are most easily written as a comma-separated list of values
enclosed in square brackets and using the @pyret-id["list" "lists"]
constructor.  The elements of a list can be accessed through the dot lookup
expression, via the members called `first` and `rest`:

@pyret-block{@"@"Check void test() {
    assertEquals([1, 2, 3].first, 1);
    assertEquals([1, 2, 3].rest, [2, 3]);
}}

It is an error to access a field that isn't there; for example trying to access
@pyret{first} on a list with no elements.  We can use the @pyret-id["raises"
"testing"] test assertion to check the error that's signalled:

@pyret-block{@"@"Check void test() {
    assertRaises(() -> { [].first }, "first");
}}

The @pyret-id["raises" "testing"] form is useful for checking explicit error
conditions.  It succeeds if the expression on the left signals an error with a
message that contains the string on the right.

The @pyret{[]} notation is a convenience form for a more verbose form that
creates the same lists.  The special @pyret-id["empty" "lists"] value is
equivalent to @pyret{[]}, and the @pyret-id["link" "lists"] function
attaches a value to the front of an existing list.  These constructors can be
freely mixed with bracket notation:

@pyret-block{@"@"Check void test() {
    assertEquals(empty, []);
    assertEquals(link(1, empty), [1]);
    assertEquals(link(1, link(2, empty)), [1, 2]);
    assertEquals(link(empty, link(empty, [])), [[], []]);
}}

@section{Identifiers and Binding}

@subsection{Identifiers}

It's often useful to name intermediate results of a computation.  Pyret uses
@pyret{=} to bind identifiers to values:

@pyret-block{@"@"Check void test() {
    list1 = [2, 3];
    list2 = link(1, list1);
    assertEquals(list2, [1, 2, 3]);
}}

Identifiers bound with @pyret{=} are @emph{not} variables.  They cannot be updated, and
they cannot even be re-bound.  So, for example, using @pyret{list1} twice gives an
error:

@pyret-block{@"@"Check void test() {
    list1 = [2, 3];
    list1 = link(1, list1);
    assertEquals(list1, [1, 2, 3]);
}}

@output{
    It looks like you defined the name list1 twice, at
}

Pyret takes a strong stance on the integrity of the @pyret{=} statement.  If the
program says the name is equal to the value, then it had better continue to be!
This has a very real correlation to something every high school algebra class
teaches: the substitutability of names for expressions.  Defining names that,
by default, can later be changed conflicts with basic notions of reasoning
about expressions and programs.

@section{Variables}

For names that can be updated, Pyret provides variables, which are distinct
from identifiers at their declaration site, using @pyret{var}.  Such declarations
must always give an initial value for the name, which can be later updated with
@pyret{=}:

@pyret-block{@"@"Check void test() {
    var x = 10;
    assertEquals(x, 10);
    x = 15;
    assertEquals(x, 15);
}}

Mixing variables and identifiers of the same name is disallowed, and all of the
following programs are errors:

@pyret-block{x = 10;
x = 15;
var x = 10;
x = 15;
x = 10;
var x = 15;}

@section[#:tag "functions-tour"]{Functions}

In Pyret, most functions are defined with a function declaration.
A function declaration looks like:

@pyret-block{Object square(n) {
    return n * n;
}}

This binds the name @pyret{square} to a function.  Note that Pyret has no
explicit @pyret{return} keyword, and the function body “returns” whatever it
evaluates to.  We can call @pyret{square} by passing arguments in parentheses:

@pyret-block{@"@"Check void test() {
    assertEquals(square(4), 16);
    assertEquals(square(2), 4);
}}

Since there are often tests that go along with a function
declaration, a declaration can directly attach a testing block
using @pyret{where:}.  So we could write the above as:

@pyret-block{Object square(n) {
    return n * n;
} where {
    
}}

This runs the same tests as the @pyret{check:} block, but it is now obvious to
the reader (and to the programming environment!) that these tests go with the
@pyret{square} function.

Functions are first-class values in Pyret, which means they can be passed
as arguments to other functions or returned from them:

@pyret-block{Object apply-twice(f, x) {
    return f(f(x));
} where {
    
}}

Functions don't need to have names.  An anonymous function can be
written by using @pyret{lam} rather than @pyret{fun}:

@pyret-block{@"@"Check void test() {
    assertEquals(apply-twice((x) -> x + 1, 10), 12);
}}

@section[#:tag "data-tour"]{Data}

Pyret has a builtin form for declaring and manipulating structured data.

@subsection[#:tag "definitions-tour"]{Definitions}

One example that you've already seen is @pyret-id["List" "lists"]. A
@pyret-id["List" "lists"] list is either @pyret{empty} or it is a @pyret{link}
of an element and another list.  While very important to the code that we
write, @pyret{List}s are not a special internal value, they are just defined
with the @pyret{data} form. A simplified version of what appears in the
standard library of Pyret:

@pyret-block{data List {
    Empty;
    Link(first, rest);
}}

Though this won't actually run, because Pyret will complain that you're trying
to re-define @pyret{List}.  This is the general syntax of a @pyret{data}
definition: the name of the datatype, then a list of one or more variants,
which may have members (like @pyret{link} does), or may not. The values of the
datatype are constructed by calling the constructor with initial members, if
any were defined:

@pyret-block{y = link(10, empty);}

Or by simply writing the name, if the variant doesn't have members defined on
it, in which case it is a singleton value.

@pyret-block{x = empty;}

This is the basic form. In addition to the functions to construct the values,
you also get functions to check whether values are of the type. In this case,
there are two functions: @pyret-id["is-empty" "lists"] checks if a value is the
@pyret{empty} value, and @pyret-id["is-link" "lists"] checks if a value is a
@pyret{link} value:

@pyret-block{@"@"Check void test() {
    assertEquals(is-empty(empty), true);
    assertEquals(is-link(link(1, empty)), true);
}}

@bold{An aside on testing:} There's actually a more natural way to write the
above test.  Along with @pyret-id["is" "testing"] and @pyret-id["raises"
"testing"], Pyret defines a test assertion called @pyret-id["satisfies"
"testing"] that checks if a predicate returns @pyret{true} on a test value.  We
could instead write the above as:

@pyret-block{@"@"Check void test() {
    assertSatisfies(empty, is-empty);
    assertSatisfies(link(1, empty), is-link);
}}

The @pyret{satisfies} form is quite handy for testing properties of a value,
rather than just that a value is equal to another.  The second form also gives
better error reporting than the first (what happens if you swap @pyret{is-link}
and @pyret{is-empty} in either approach?).

@note{Check out @seclink["testing" "the documentation on testing"] to see all
the testing forms.}



@section[#:tag "cases-tour"]{Cases}

A common pattern is to do different things based on the variant of a
@pyret{data} definition.  The @pyret{cases} expression allows you to write
branches that split computation along the boundaries defined by your data
definition.  For example:

@pyret-block{Object length(l) {
    return switch (l) {
        case Empty: yield 0;
        case Link(f, r): yield 1 + length(r);
    }
}}

If you don't care about a specific attribute, you can replace it with an
underscore. Since we did not use @pyret{f} in the @pyret{link} case in the
previous example, we could write it instead as:

@pyret-block{Object length(l) {
    return switch (l) {
        case Empty: yield 0;
        case Link(_, r): yield 1 + length(r);
    }
}}

This makes it clearer to the reader, especially if the blocks become large,
what the program does and does not use.

Finally, it is an error, caught at runtime, to pass a value that isn't of the
type inside the @pyret{cases}, or if a branch isn't defined for the variant
that's passed to @pyret{cases}. If you want to have a catch-all, you can use
@pyret{else} to create a branch that will run if no others match. For example:

@pyret-block{@"@"Check void test() {
    result = switch (empty) {
        case Link(first, _): yield first;
        default: yield 0;
    }
    assertEquals(result, 0);
}}

@section[#:tag "annotations-tour"]{Annotations}

Pyret is not currently a typed language (a static checker is an ongoing
project), but it allows type-like annotations, both to document the type
structure of programs, and for some run-time checking.  Annotations can be
added to function arguments, to variable bindings, and to the members in data
variants.  For example:

@pyret-block{data BinTree {
    Leaf;
    Node(int value, BinTree left, BinTree right);
}}

Note that @pyret{BinTree}, the name of a datatype, can be used as an
annotation.  Any data type that you define can also be used in an annotation.
These annotations will stop the program from creating a @pyret{BinTree} with
fields that don't match the annotations:

@pyret-block{@"@"Check void test() {
    assertRaises(() -> { node("not-a-num", leaf, leaf) }, "Number");
    assertRaises(() -> { node(37, leaf, "not-a-bin-tree") }, "BinTree");
}}

You can also define arbitrary predicates for use in annotations to @emph{refine} the
annotation with additional checks. For example:

@pyret-block{boolean non-negative(int n) {
    return n >= 0;
}
List replicate(Object n, e) {
    return if (n == 0) {
        return [];
    } else {
        return link(e, replicate(n - 1, e));
    }
}}

And if you were to call @pyret{replicate} with a negative number, it would
not run (instead of running forever):

@pyret-block{@"@"Check void test() {
    assertRaises(() -> { replicate(-1, "val") }, "non-negative");
}}

Some kinds of annotations only get limited checks:

@itemlist[

  @item{Arrow annotations, like @; TODO(pyret2jayret): parse failed (no shifts)
@pyret{(Number, String -> String)} will only
  check that the value is a function, and not wrap the function to check its
  arguments.}

  @item{Parameterized annotations, like @pyret{List < Number >}, will only check
  the annotation before the @pyret{<>}, the contents the @pyret{<>} will be ignored.}

  @item{Type variables, like the @pyret{a} in @pyret{(a x) -> x}, accept values of any type}
]

These are features that we plan to check statically rather than at runtime.


@section{Control}

@subsection{For loops}

Pyret provides syntactic support for common patterns of iteration. For example,
to @pyret-id["map" "lists"] over a list, running some block of code to produce a
new value for each existing value, we can write:

@pyret-block{x = [for map(elem : [1, 2, 3, 4]) { yield elem + 2; }];
@"@"Check void test() {
    assertEquals(x, [3, 4, 5, 6]);
}}

Note a few things:

@itemlist[
@item{@pyret{for} is an expression, and is legal to write on the right hand
side of a binding}
@item{The whole @pyret{for} expression evaluates to a value (in this case, a
new list)}
]

The @pyret{for} syntax is designed to create patterns for functional iteration.
Indeed, there are several other built in functions that work with @pyret{for}:

@pyret-block{z = [for filter(elem : [1, 2, 3, 4]) { yield elem < 3; }];
@"@"Check void test() {
    assertEquals(z, [1, 2]);
}
y = [for fold(sum : 0, elem : [1, 2, 3]) { yield sum + elem; }];
@"@"Check void test() {
    assertEquals(y, 6);
}}

And you are free to define your own @pyret{for} operators.  A @pyret{for}
operator is a function that takes a function as its first argument, and a
number of other values as the rest of its arguments.  The function argument is
expected to have the same arity as the number of initial values.  To use the
operator in a @pyret{for} expression, the @pyret{for} header should have a
number of @pyret{from} bindings equal to this arity.  For example:

@pyret-block{Object keep-every-other(body-fun, l) {
    Object iter(flip, lst) {
        return switch (lst) {
            case Empty: yield empty;
            case Link(first, rst): yield if (flip) {
                return link(body-fun(first), iter(not(flip), rst));
            } else {
                return iter(not(flip), rst);
            };
        }
    }
    return iter(true, l);
}
w = [for keep-every-other(elt : range(0, 10)) { yield elt + 1; }];
@"@"Check void test() {
    assertEquals(w, [1, 3, 5, 7, 9]);
}}

What the @pyret{for} expression does is create a new function from the names on
the left-hand sides of the @pyret{from} clauses and the body, and pass that new
function along with the values on the right of @pyret{from} to the operator
(@pyret{keep-every-other}, in this case).

@section{If}

Branching on conditionals is an @pyret{if} branch followed by zero or more
@; TODO(pyret2jayret): parse failed (no shifts)
@pyret{else if} branches and an optional @pyret{else} branch. It is a runtime
error to not match one of the branches - if you are writing code to purely
cause side effects, write a @pyret{when} block instead. A few examples:

@pyret-block{if (x < 10) {
    return print("Small");
} else if (x > 20) {
    return print("Large");
} else {
    return print("Medium");
}}

@pyret-block{if (false) {
    return print("Can't happen");
} else if (false) {
    return print("Can't happen either");
}
// this is a runtime error, Pyret requires an else branch}

@pyret-block{if (true && false) {
} else {
}
// ...
// ...}

Pyret expects that @pyret{if} expressions take some branch, and signals an
error if control falls off the end:

@pyret-block{@"@"Check void test() {
    Object if-falls-off() {
        return if (false) {
            return "";
        } else if (false) {
            return "";
        }
    }
    assertRaises(() -> { if-falls-off() }, "no-branches-matched");
}}

For this reason, Pyret syntactically rules out single-branch if expressions,
which make little sense given this rule.

@subsection{When blocks}

Sometimes there is certain code that should only be run when something is true.
This is code that exists solely to @emph{do} something; often, for example, to
report an error. For example:

@pyret-block{a get-second(List<Object> l) {
    when (l.length() < 2) {
        raise("List too short");
    }
    return l.rest.first;
} where {
    
}}

This covers the cases that single-branch if expressions are usually used for,
but makes it explicit that the body is used for its side effects.

@section{And more...}

This introduction should get you to the point where you can write non-trivial
Pyret programs.  From here, you can check out the rest of the documentation to
learn more about the language and for reference.  If your interest is piqued by
the tour, or if you have suggestions or questions, you should sign up for the
@link["https://groups.google.com/forum/#!forum/pyret-discuss" "Pyret discussion
list"].


