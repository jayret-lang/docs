#!/usr/bin/env python3
"""prose-rebrand.py — Pyret→Jayret in .scrbl prose, skipping code macro bodies.

Substitutions applied OUTSIDE the bodies of code-emitting Scribble macros
(@pyret-block, @pyret, @pyret-id, @pyret-method, @pyret-method-ref, @code,
@verbatim, @bnf, @examples, @justcode, @repl-examples, @docmodule,
@section-index, @docmodule-internal, ...):

  - code.pyret.org           → code.jayret.org
  - (www.)?pyret.org         → jayret-lang.github.io
  - Pyret  (standalone word) → Jayret
  - pyret  (standalone word, not following @) → jayret
  - .arr   (file extension)  → .jrt

Inside the skipped macros' bodies, we apply ONLY URL substitutions (which are
always safe regardless of context).

Usage:
  python3 tools/prose-rebrand.py [--dry-run] <file.scrbl> [...]
"""

import re
import sys
import argparse

# Macros whose body contents are CODE / IDENTIFIERS / filenames — skip
# prose substitutions inside. Everything else recurses into the body as prose.
SKIP_MACROS = {
    # Pyret/Jayret code macros.
    'pyret-block', 'pyret', 'pyret-id', 'pyret-method', 'pyret-method-ref',
    'pyret-header',
    'jayret-block', 'jayret', 'jayret-id', 'jayret-method', 'jayret-method-ref',
    # Code-ish macros. `verbatim` intentionally NOT here: it contains
    # simulated runtime output, file references, error messages — all of
    # which need to reflect Jayret reality (e.g., `.arr` → `.jrt`).
    'code', 'bnf', 'justcode',
    # Cross-reference anchor IDs — these are usually `s:foo` not prose.
    'seclink', 'secref', 'xref',
    'py-prod', 'prod-ref', 'prod-link',
    # Image / asset macros where arg is a filename.
    'image', 'include-section', 'include-extracted',
    # Type/argument annotation macros — identifier args.
    'a-id', 'a-app', 'a-arrow', 'a-pred', 'a-record', 'a-field',
    'a-named-arrow', 'a-tuple', 'a-dot',
}

URL_SUBS = [
    # The playground lives at jayret-lang.github.io/code, not at a code.*
    # subdomain. Force this rewrite first so it wins over the bare-host one
    # below; also catch any existing `code.jayret.org` URLs from earlier runs.
    (re.compile(r'\bcode\.pyret\.org'), 'jayret-lang.github.io/code'),
    (re.compile(r'\bcode\.jayret\.org'), 'jayret-lang.github.io/code'),
    (re.compile(r'\bwww\.pyret\.org'), 'jayret-lang.github.io'),
    (re.compile(r'(?<!code\.)(?<!www\.)\bpyret\.org\b'), 'jayret-lang.github.io'),
]

PROSE_SUBS = URL_SUBS + [
    # Capital Pyret, not part of an identifier (hyphen or alphanum on either side).
    (re.compile(r'(?<![A-Za-z0-9_-])Pyret(?![A-Za-z0-9_-])'), 'Jayret'),
    # Lowercase pyret, not preceded by @ (which would be a macro call) and not
    # part of a hyphenated/alphanum identifier.
    (re.compile(r'(?<![A-Za-z0-9_@-])pyret(?![A-Za-z0-9_-])'), 'jayret'),
    # File extension .arr in prose.  Matches `foo.arr`, `spies.arr`, etc.
    # (No leading-char restriction so filenames are caught.)
    (re.compile(r'\.arr(?![A-Za-z0-9_])'), '.jrt'),
]


def find_macro_body(s, start_at):
    """Given s[start_at] == '@', locate the macro name and body extent.

    Returns (name, body_start, body_end_exclusive, after_end) where
      - name is the macro identifier (without '@')
      - body_start, body_end_exclusive frame the *body* contents (inside
        outermost braces), or None,None if no { body follows
      - after_end is the position after the closing brace, or after the
        identifier if no body

    Handles optional [...] options between identifier and {.
    Does not handle nested @ macros — but balanced { } counting is done.
    """
    # name: identifier including hyphens.
    name_match = re.match(r'@([A-Za-z][A-Za-z0-9-]*)', s[start_at:])
    if not name_match:
        return None, None, None, start_at + 1
    name = name_match.group(1)
    pos = start_at + name_match.end()
    # Skip optional [options] block — track balanced brackets, allow nested.
    if pos < len(s) and s[pos] == '[':
        depth = 1
        pos += 1
        while pos < len(s) and depth > 0:
            c = s[pos]
            if c == '[':
                depth += 1
            elif c == ']':
                depth -= 1
            pos += 1
    # Now look for { body }.
    if pos < len(s) and s[pos] == '{':
        body_start = pos + 1
        depth = 1
        p = body_start
        while p < len(s) and depth > 0:
            c = s[p]
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    return name, body_start, p, p + 1
            p += 1
        # Unbalanced; bail out.
        return name, body_start, len(s), len(s)
    return name, None, None, pos


def apply_subs(text, sub_list):
    for pattern, replacement in sub_list:
        text = pattern.sub(replacement, text)
    return text


def transform(src):
    """Walk src, applying PROSE_SUBS outside SKIP_MACROS bodies and URL_SUBS
    inside them.  Returns transformed string."""
    out = []
    i = 0
    n = len(src)
    # We collect chunks of "prose" between code-macro bodies, apply PROSE_SUBS
    # to each chunk, and apply URL_SUBS to skipped bodies. Non-skipped macros
    # are not opaque to substitution — we recurse into their bodies as prose.
    prose_buf = []

    def flush_prose():
        if prose_buf:
            out.append(apply_subs(''.join(prose_buf), PROSE_SUBS))
            prose_buf.clear()

    while i < n:
        c = src[i]
        if c != '@':
            prose_buf.append(c)
            i += 1
            continue
        # `@(racket-expr)` — a Racket form embedded in Scribble. Treat the
        # entire balanced paren expression as opaque: it's Racket code, not
        # prose. We still apply URL substitutions inside.
        if i + 1 < n and src[i + 1] == '(':
            flush_prose()
            depth = 1
            p = i + 2
            in_str = None
            while p < n and depth > 0:
                ch = src[p]
                if in_str:
                    if ch == '\\' and p + 1 < n:
                        p += 2; continue
                    if ch == in_str:
                        in_str = None
                    p += 1; continue
                if ch == '"':
                    in_str = '"'; p += 1; continue
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                    if depth == 0:
                        p += 1
                        break
                p += 1
            racket_form = src[i:p]
            out.append(apply_subs(racket_form, URL_SUBS))
            i = p
            continue
        # `@|...|` — explicit element boundary; treat as opaque too.
        if i + 1 < n and src[i + 1] == '|':
            flush_prose()
            p = src.find('|', i + 2)
            if p == -1:
                prose_buf.append(c)
                i += 1
                continue
            out.append(src[i:p + 1])
            i = p + 1
            continue
        # Possible macro invocation. Determine extent.
        name, body_start, body_end, after = find_macro_body(src, i)
        if name is None:
            prose_buf.append(c)
            i += 1
            continue
        # Decide: skip body or recurse into it?
        if name in SKIP_MACROS:
            # Emit prose buffer, then emit macro header verbatim, then the
            # body with only URL substitutions (safe everywhere), then the
            # closing brace.
            flush_prose()
            if body_start is None:
                out.append(src[i:after])
            else:
                head = src[i:body_start]  # includes '@name[...]{
                body = src[body_start:body_end]
                out.append(head)
                out.append(apply_subs(body, URL_SUBS))
                out.append('}')
            i = after
        else:
            # Non-code macro: recurse into the body as prose. The macro name
            # and any options are emitted unchanged; the body becomes prose.
            if body_start is None:
                # No body — just emit name + options.
                prose_buf.append(src[i:after])
                i = after
            else:
                # Flush prose, emit macro head, recursively transform body,
                # emit closing brace.
                flush_prose()
                head = src[i:body_start]
                body = src[body_start:body_end]
                out.append(head)
                out.append(transform(body))
                out.append('}')
                i = after
    flush_prose()
    return ''.join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='+')
    ap.add_argument('--dry-run', '-n', action='store_true',
                    help="Don't write; report counts of changes.")
    args = ap.parse_args()
    total = 0
    for path in args.files:
        with open(path, 'r', encoding='utf-8') as f:
            src = f.read()
        out = transform(src)
        if out == src:
            print(f'{path}: no change')
            continue
        # Count per-pattern hits by applying each transformation to the
        # *changed* portion. Cheap approximation: count diff lines.
        diff_lines = sum(1 for a, b in zip(src.splitlines(), out.splitlines()) if a != b)
        # Plus length-diff lines (added/removed).
        diff_lines += abs(len(src.splitlines()) - len(out.splitlines()))
        print(f'{path}: ~{diff_lines} line(s) changed')
        total += diff_lines
        if not args.dry_run:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(out)
    print(f'\nTotal: ~{total} line(s) changed across {len(args.files)} file(s)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
