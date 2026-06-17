#lang scribble/base
@(require "../../scribble-api.rkt" "../abbrevs.rkt" scriblib/footnote (only-in scribble/manual link))

@(append-gen-docs
  '(module "strings"
    (path "src/js/base/runtime-anf.js")
    (data-spec
      (name "String")
      (variants)
      (shared))
    (fun-spec
      (name "string-equal")
      (arity 2)
      (args ("s1" "s2"))
      (doc ""))
    (fun-spec
      (name "string-contains")
      (arity 2)
      (args ("string-to-search" "string-to-find"))
      (doc ""))
    (form-spec (name "+ (concatenation)"))
    (fun-spec
      (name "string-append")
      (arity 2)
      (args ("front" "back"))
      (doc ""))
    (fun-spec
      (name "string-length")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-to-number")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-repeat")
      (arity 2)
      (args ("s" "n"))
      (doc ""))
    (fun-spec
      (name "string-substring")
      (arity 3)
      (args ("s" "start-index" "end-index"))
      (doc ""))
    (fun-spec
      (name "string-replace")
      (arity 3)
      (args ("original-string" "string-to-find" "replacement-string"))
      (doc ""))
    (fun-spec
      (name "string-split")
      (arity 2)
      (args ("original-string" "string-to-split-on"))
      (doc ""))
    (fun-spec
      (name "string-split-all")
      (arity 2)
      (args ("original-string" "string-to-split-on"))
      (doc ""))
    (fun-spec
      (name "string-char-at")
      (arity 2)
      (args ("s" "n"))
      (doc ""))
    (fun-spec
      (name "string-to-upper")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-toupper")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-to-lower")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-tolower")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-explode")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-index-of")
      (arity 2)
      (args ("original-string" "string-to-find"))
      (doc ""))
    (fun-spec
      (name "string-find")
      (arity 2)
      (args ("original-string" "string-to-find"))
      (doc ""))
    (fun-spec
      (name "string-find-opt")
      (arity 2)
      (args ("original-string" "string-to-find"))
      (doc ""))
    (fun-spec
      (name "string-to-code-point")
      (arity 1)
      (args ("s"))
      (doc ""))
    (fun-spec
      (name "string-from-code-point")
      (arity 1)
      (args ("code"))
      (doc ""))
    (fun-spec
      (name "string-to-code-points")
      (arity 1)
      (args ("codes"))
      (doc ""))
    (fun-spec
      (name "string-from-code-points")
      (arity 1)
      (args ("codes"))
      (doc ""))
      ))

@docmodule["strings" #:noimport #t #:friendly-title "Strings"]{

@type-spec["String" (list)]{

The type of string values.}
                                                               
A @pyret{String} is a fixed-length array of characters.  This includes not only letters in
the Latin alphabet and numerals, but any Unicode character, including languages
using non-Latin characters, such as Arabic, Russian or Chinese, as well as emoji
defined in the Unicode specification.

@(image "src/builtin/valid-string.png")

@margin-note{If you click on printed strings in the interactive window,
the display will toggle between the character itself and the relevant
Unicode escape code or codes.}

@(image "src/builtin/codes.png")

Internally, a Jayret @pyret{String} is implemented as a JavaScript
@tt{JSString}.  See the @seclink["runtime"] for more context.

@margin-note{One implication of how JavaScript handles Unicode characters is
that characters that are identified by a Unicode code point greater than
65535 are sometimes treated as two characters by Jayret, as noted below.}


@section{String Functions}

  @function["string-equal" #:contract (a-arrow S S B) #:return B]

Returns @pyret{true} if the two strings are equal.
  
@examples{@"@"Check void test() {
    assertEquals(string-equal("abc", "abc"), true);
    assertEquals("abc", "abc");
    assertEquals("abc" == "abc", true);
    assertEquals(string-equal("ab", "abc"), false);
    assertEquals(string-equal("abc     ", "abc"), false);
}}

  @function["string-contains" #:contract (a-arrow S S B) #:return B]

Returns @pyret{true} if @pyret{string-to-find} is contained in
@pyret{string-to-search}.  Returns @pyret{true} if an empty string is passed as
@pyret{string-to-find}.
  
@examples{@"@"Check void test() {
    assertEquals(string-contains("Ahoy, world!", "world"), true);
    assertEquals(string-contains("Ahoy, World!", "world"), false);
    assertEquals(string-contains("world", "Ahoy world"), false);
    assertEquals(string-contains("same string", "same string"), true);
    assertEquals(string-contains("", ""), true);
    assertEquals(string-contains("any string", ""), true);
}}

  @function["string-find" #:contract (a-arrow S S) #:return N]

Return the left-most index (starting from @pyret{0}) where the second argument is found in the first string.

If the string is not found, this raises an exception. Therefore, use this function only when you expect the second argument to be found in the first one.
If you aren't sure, use @pyret{string-find-opt}.
  
@examples{@"@"Check void test() {
    assertEquals(string-find("Hello", "ello"), 1);
    assertEquals(string-find("Hello", "H"), 0);
    assertRaises(() -> { string-find("Hello", "World") }, "");
}}

  @function["string-find-opt" #:contract (a-arrow S S) #:return N]

Return the left-most index (starting from @pyret{0}) where the second argument is found in the first string.

This always returns an @pyret{Option} value. Therefore, this is useful when you aren't sure whether the second argument will be found in the first or not.
If you are confident it will be present, consider using @pyret{string-find}, which returns the number that you can directly use.

@examples{@"@"Check void test() {
    assertEquals(string-find("Hello", "ello"), some(1));
    assertEquals(string-find("Hello", "H"), some(0));
    assertEquals(string-find("Hello", "World"), none);
}}

  @function["string-append" #:contract (a-arrow S S S) #:return S]

Returns a @pyret{String} where @pyret{back} is added to the right of
@pyret{front}.
  
@examples{@"@"Check void test() {
    assertEquals(string-append("a", "b"), "ab");
    assertEquals(string-append("same", "same"), "samesame");
    assertEquals(string-append("", ""), "");
    assertEquals(string-append("", "a"), "a");
    assertEquals(string-append("a", ""), "a");
}}

@form["+ (concatenation)" "front + back"]

When @pyret{front} and @pyret{back} are strings, has the same meaning as
@pyret-id{string-append}.

  @function["string-length" #:contract (a-arrow S N) #:return N]

Returns the number of characters in the string.

@margin-note{@pyret{string-length} reports a count of @pyret{2}
for code points over 65535.}

@examples{@"@"Check void test() {
    assertEquals(string-length(""), 0);
    assertEquals(string-length("    "), 4);
    assertEquals(string-length("four"), 4);
    assertEquals(string-length("🏏"), 2);
}}

  @function["string-to-number" #:contract (a-arrow S N) #:return (O-of N)]

Converts the argument string to a number, returning @pyret-id["none" "option"]
if it is not a valid numeric string, and @pyret-id["some" "option"] number if it is.

@pyret-id{string-to-number} is strict about its inputs, and recognizes exactly
the same numbers that Jayret itself does: no surrounding whitespace, extra
punctuation, or trailing characters are allowed.

@examples{@"@"Check void test() {
    assertEquals(string-to-number("100"), some(100));
    assertEquals(string-to-number("not-a-number"), none);
    assertEquals(string-to-number(" 100"), none);
    assertEquals(string-to-number("100abc"), none);
    assertEquals(string-to-number("1,000"), none);
    assertEquals(string-to-number("1-800-555-1212"), none);
}}

  @function["string-repeat" #:contract (a-arrow S N S) #:return S]

@examples{@"@"Check void test() {
    assertEquals(string-repeat("a", 5), "aaaaa");
    assertEquals(string-repeat("", 1000000), "");
    assertEquals(string-repeat("word ", 3), "word word word ");
    assertEquals(string-repeat("long string", 0), "");
}}

  @function["string-substring" #:contract (a-arrow S N N S) #:return S]

Returns a new string created from the characters of the input string, starting
from @pyret{start-index} (inclusive) and ending at @pyret{end-index} (exclusive).
Raises an exception if @pyret{start-index} is greater than @pyret{end-index}, if @pyret{start-index}
is greater than the length of the string, or if @pyret{end-index} is less than 0.

The returned string always has length @pyret{end-index} - @pyret{start-index}.

@margin-note{@pyret{String} indexes are counted starting from zero for the
first character.}

@examples{@"@"Check void test() {
    assertEquals(string-substring("just the first", 0, 1), "j");
    assertEquals(string-substring("same index", 4, 4), "");
    tws = "length is 12";
    assertEquals(string-substring(tws, 4, 6), "th");
    assertEquals(string-substring(tws, string-length(tws) - 1, string-length(tws)), "2");
    assertRaises(() -> { string-substring(tws, 6, 4) }, "index");
    assertRaises(() -> { string-substring(tws, 6, 13) }, "index");
    assertRaises(() -> { string-substring(tws, 13, 6) }, "index");
    assertRaises(() -> { string-substring(tws, -1, 10) }, "index");
}}

  @function["string-index-of" #:contract (a-arrow S S N) #:return N]

  Returns the index from the beginning of the string where
  @pyret{string-to-find} @emph{first} appears, or @pyret{-1} if the string
  isn't found.

@examples{@"@"Check void test() {
    assertEquals(string-index-of("Jayret", "P"), 0);
    assertEquals(string-index-of("012🤑45", "🤑"), 3);
    assertEquals(string-index-of("🤔🤔🤔", "🤒"), -1);
}}
  
  @function["string-replace" #:contract (a-arrow S S S S) #:return S]

Returns a string where each instance of @pyret{string-to-find} in the
@pyret{original-string} is replaced by @pyret{replacement-string}.

If the string to find is empty @pyret{""}, the @pyret{replacement-string}
will be added between characters but not at the beginning or end of the
string.
  
@examples{@"@"Check void test() {
    assertEquals(string-replace("spaces to hyphens", " ", "-"), "spaces-to-hyphens");
    assertEquals(string-replace("remove: the: colons", ":", ""), "remove the colons");
    assertEquals(string-replace("😊😊🤕😊", "🤕", "😊"), "😊😊😊😊");
    assertEquals(string-replace("rinky dinky", "inky", "azzle"), "razzle dazzle");
    assertEquals(string-replace("a string", "not found", "not replaced"), "a string");
    assertEquals(string-replace("", "", "c"), "");
    assertEquals(string-replace("aaa", "", "b"), "ababa");
}}

  @function["string-split" #:contract (a-arrow S S (L-of S)) #:return (L-of S)]

  Searches for @pyret{string-to-split-on} in @pyret{original-string}.  If it is not found,
  returns a @pyret-id["List" "lists"] containing @pyret{original-string} as its
  single element.

  If it is found, it returns a two-element @pyret-id["List" "lists"], whose
  first element is the portion of the string before @emph{first} occurence of
  @pyret{string-to-split-on}.  The second element contains the portion of the string
  after.  The @pyret{string-to-split-on} is @bold{not} included in either string.  The
  string before and the string after might be empty.

  For splitting beyond the first occurence of the string, see
  @pyret-id["string-split-all"].

@examples{@"@"Check void test() {
    assertEquals(string-split("string", "not found"), ["string"]);
    assertEquals(string-split("string", "g"), ["strin", ""]);
    assertEquals(string-split("string", ""), ["", "string"]);
    assertEquals(string-split("a-b-c", "-"), ["a", "b-c"]);
}}

  @function["string-split-all" #:contract (a-arrow S S) #:return (L-of S)]

  Searches for @pyret{string-to-split-on} in @pyret{original-string}.  If it is not found,
  returns a @pyret-id["List" "lists"] containing @pyret{original-string} as its
  single element.

  If it is found, it returns a @pyret-id["List" "lists"], whose elements are
  the portions of the string that appear in between occurences of
  @pyret{string-to-split-on}.  A match at the beginning or end of the string will add
  an empty string to the beginning or end of the list, respectively.  The empty
  string matches in between every pair of characters.

@examples{@"@"Check void test() {
    assertEquals(string-split-all("string", "not found"), ["string"]);
    assertEquals(string-split-all("a-b-c", "-"), ["a", "b", "c"]);
    assertEquals(string-split-all("split on spaces", " "), ["split", "on", "spaces"]);
    assertEquals(string-split-all("explode", ""), ["e", "x", "p", "l", "o", "d", "e"]);
    assertEquals(string-split-all("bananarama", "na"), ["ba", "", "rama"]);
    assertEquals(string-split-all("bananarama", "a"), ["b", "n", "n", "r", "m", ""]);
}}
  @function["string-explode" #:contract (a-arrow S (L-of S)) #:return (L-of S)]

  A shorthand for @pyret{string-split-all(s, "")}.

  @function["string-char-at" #:contract (a-arrow S N S) #:return S]

Returns a @pyret{String} containing the character at the string index @pyret{n}
from @pyret{String} @pyret{n}.

@examples{@"@"Check void test() {
    assertEquals(string-char-at("abc", 1), "b");
    assertEquals(string-char-at("a", 0), "a");
}}

  @function["string-toupper" #:contract (a-arrow S S) #:return S]

  The same as @pyret{string-to-upper}.

  @function["string-to-upper" #:contract (a-arrow S S) #:return S]

@margin-note{Jayret uses JavaScript's built-in string operations, and so will
have the same behavior as @link["https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/toUpperCase" "toUpperCase"].}
Convert a string to all uppercase characters.  Punctuation and other characters
without an uppercase equivalent are left alone.  Note that because of
characters like @pyret{ß}, the length of the input is not guaranteed to
match the length of the output.

@examples{@"@"Check void test() {
    assertEquals(string-to-upper("a"), "A");
    assertEquals(string-to-upper("I'm not yelling!"), "I'M NOT YELLING!");
    assertEquals(string-to-upper("ß"), "SS");
    assertEquals(string-to-upper("λαμβδα"), "ΛΑΜΒΔΑ");
    assertEquals(string-to-upper("😊"), "😊");
    assertEquals(string-to-upper(" ﷵ‎"), " ﷵ‎");
}}

When performing case-insensitive comparisons, it can be useful to convert both
strings to uppercase first:


@examples{@"@"Check void test() {
    assertEquals(string-to-upper("E.E. Cummings"), string-to-upper("e.e. cummings"));
}}


  @function["string-tolower" #:contract (a-arrow S S) #:return S]

  The same as @pyret{string-to-lower}.

  @function["string-to-lower" #:contract (a-arrow S S) #:return S]

Converts a @pyret{String} to all lower case.
  
@examples{@"@"Check void test() {
    assertEquals(string-to-lower("A"), "a");
    assertEquals(string-to-lower("I'M NOT YELLING!"), "i'm not yelling!");
    assertEquals(string-to-lower("SS"), "ss");
    assertEquals(string-to-lower("ΛΑΜΒΔΑ"), "λαμβδα");
}}

  @function["string-to-code-point" #:contract (a-arrow S N) #:return N]

  @note{For strings
  that contain a single character whose code point is greater than
  @pyret{65535}, this function raises an error.
  To get multiple codes at once for a longer string (or a string with larger code points), use
  @pyret-id{string-to-code-points}.}

  Converts @pyret{s}, which must be a single-character @pyret{String}, to a character
  code -- a @pyret{Number} corresponding to its Unicode code point
  (@url["http://en.wikipedia.org/wiki/Code_point"]).
  

  @examples{@"@"Check void test() {
    assertEquals(string-to-code-point("a"), 97);
    assertEquals(string-to-code-point("
"), 10);
    assertEquals(string-to-code-point("λ"), 955);
}}

  @function["string-to-code-points" #:contract (a-arrow S (L-of N)) #:return (L-of N)]

  Converts the string (of any length) to a list of code points.  Note that
  strings are encoded in such a way that some characters correspond to two code
  points (see the note in @pyret-id{string-to-code-point}).

@examples{@"@"Check void test() {
    assertEquals(string-to-code-points(""), []);
    assertEquals(string-to-code-points("abc"), [97, 98, 99]);
    assertEquals(string-to-code-points("😊"), [55357, 56842]);
    assertEquals(string-to-code-points("𝄞"), [55348, 56606]);
}}

  @function["string-from-code-point" #:contract (a-arrow N S) #:return S]

  @note{Code points greater than 65535 are not supported.  You must encode
  higher code points with a @link["http://en.wikipedia.org/wiki/UTF-16"
  "surrogate pair"] in combination with
  @pyret-id{string-from-code-points} and @pyret-id{string-to-code-points}.}

  Converts the code point @pyret{code} to a Jayret string.

@examples{@"@"Check void test() {
    assertEquals(string-from-code-point(97), "a");
    assertEquals(string-from-code-point(10), "
");
    assertEquals(string-from-code-point(955), "λ");
}}

  @function["string-from-code-points" #:contract (a-arrow (L-of N) S) #:return S]

  Converts from a list of code points to a Jayret string.

@examples{@"@"Check void test() {
    assertEquals(string-from-code-points([]), "");
    assertEquals(string-from-code-points([97, 98, 99]), "abc");
    assertEquals(string-from-code-points([55348, 56606]), "𝄞");
}}

}
