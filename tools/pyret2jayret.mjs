#!/usr/bin/env node
// pyret2jayret.mjs — translate Pyret-syntax code blocks inside .scrbl files to
// Jayret syntax. Operates on bodies of @pyret-block{...}, @examples{...}, and
// @pyret{...} Scribble macros.
//
// Uses the actual Pyret parser (loaded via an AMD shim) for structural
// translation. Comments are preserved by pre-extracting them, parsing the
// comment-stripped source, then re-splicing them line-by-line into the Jayret
// output.

import fs from 'node:fs';
import path from 'node:path';

// ---------------------------------------------------------------------------
// AMD shim — load Pyret's tokenizer and parser as if they were AMD modules.
// ---------------------------------------------------------------------------

const PYRET_LANG = process.env.PYRET_LANG_DIR
  || '/home/artem/Dev/pyret/jayret-lang-landing/pyret-lang';

const _modules = {};
function _shimDefine(name, deps, factory) {
  if (typeof name !== 'string') { factory = deps; deps = name; name = null; }
  const depMods = deps.map(d => {
    if (!(d in _modules)) throw new Error(`missing AMD dep: ${d}`);
    return _modules[d];
  });
  const exported = factory(...depMods);
  if (name) _modules[name] = exported;
}
_shimDefine.amd = {};

function _loadAMD() {
  globalThis.define = _shimDefine;
  const paths = {
    'jglr/cyclicJSON':                `${PYRET_LANG}/lib/jglr/cyclicJSON.js`,
    'jglr/rnglr':                     `${PYRET_LANG}/lib/jglr/rnglr.js`,
    'jglr/jglr':                      `${PYRET_LANG}/lib/jglr/jglr.js`,
    'pyret-base/js/pyret-tokenizer':  `${PYRET_LANG}/src/js/base/pyret-tokenizer.js`,
    'pyret-base/js/pyret-parser':     `${PYRET_LANG}/build/phaseA/js/pyret-parser.js`,
  };
  for (const name of Object.keys(paths)) {
    new Function(fs.readFileSync(paths[name], 'utf8'))();
    if (!(name in _modules)) throw new Error(`AMD module ${name} did not register`);
  }
  return {
    tokenizer: _modules['pyret-base/js/pyret-tokenizer'].Tokenizer,
    grammar:   _modules['pyret-base/js/pyret-parser'].PyretGrammar,
  };
}

const PYRET = _loadAMD();

// ---------------------------------------------------------------------------
// Comment extraction (Pyret tokenizer drops these; we need them for docs).
// ---------------------------------------------------------------------------

// Return { stripped, comments } where `stripped` is the source with each
// comment region replaced by whitespace of equal length (so token positions
// line up), and `comments` is a list of { line, col, text, kind }.
function stripComments(src) {
  const out = [];
  const comments = [];
  let i = 0, line = 1, col = 1;
  const push = (ch) => {
    out.push(ch);
    if (ch === '\n') { line++; col = 1; } else col++;
    i++;
  };
  while (i < src.length) {
    const c = src[i];
    // String literals — skip past them so we don't false-positive on '#' inside.
    if (c === '"' || c === "'") {
      const quote = c;
      push(c);
      while (i < src.length && src[i] !== quote) {
        if (src[i] === '\\' && i + 1 < src.length) { push(src[i]); push(src[i]); }
        else if (src[i] === '\n') break;
        else push(src[i]);
      }
      if (i < src.length && src[i] === quote) push(src[i]);
      continue;
    }
    // Triple-backtick — multi-line string.
    if (c === '`' && src[i + 1] === '`' && src[i + 2] === '`') {
      push(src[i]); push(src[i]); push(src[i]);
      while (i + 2 < src.length && !(src[i] === '`' && src[i + 1] === '`' && src[i + 2] === '`')) {
        push(src[i]);
      }
      if (i + 2 < src.length) { push(src[i]); push(src[i]); push(src[i]); }
      continue;
    }
    // Block comment #| ... |# (nestable in Pyret).
    if (c === '#' && src[i + 1] === '|') {
      const startLine = line, startCol = col;
      let depth = 1, text = '';
      // skip the opening #|
      out.push(' '); out.push(' '); col += 2; i += 2;
      while (i < src.length && depth > 0) {
        if (src[i] === '#' && src[i + 1] === '|') {
          depth++; text += '#|';
          out.push(' '); out.push(' '); col += 2; i += 2;
        } else if (src[i] === '|' && src[i + 1] === '#') {
          depth--;
          if (depth === 0) { out.push(' '); out.push(' '); col += 2; i += 2; break; }
          text += '|#';
          out.push(' '); out.push(' '); col += 2; i += 2;
        } else if (src[i] === '\n') {
          text += '\n';
          out.push('\n'); line++; col = 1; i++;
        } else {
          text += src[i];
          out.push(' '); col++; i++;
        }
      }
      comments.push({ line: startLine, col: startCol, text, kind: 'block' });
      continue;
    }
    // Line comment # ... \n
    if (c === '#') {
      const startLine = line, startCol = col;
      let text = '';
      out.push(' '); col++; i++;
      while (i < src.length && src[i] !== '\n') {
        text += src[i];
        out.push(' '); col++; i++;
      }
      comments.push({ line: startLine, col: startCol, text, kind: 'line' });
      continue;
    }
    push(c);
  }
  return { stripped: out.join(''), comments };
}

// ---------------------------------------------------------------------------
// Pyret CST → Jayret printer.
// ---------------------------------------------------------------------------

// Token name → Jayret rendition. `null` means drop the token entirely (e.g.,
// END, COLON-after-fun-header, BAR-in-data-variants). Default is to keep value.
const TOKEN_MAP = {
  // Block delimiters get stripped — we'll insert braces structurally.
  'COLON': null,
  'END': null,
  'BAR': null,
  // Pyret operators → Jayret operators (most pass through).
  'AND': '&&',
  'OR': '||',
  'NOT': '!',
  'NEQUAL': '!=',
  // Most punctuation, names, numbers, strings pass through with .value.
};

// Pyret type name → Jayret per docs/jayret-spec.md §4.
const TYPE_MAP = {
  Number: 'int',
  String: 'String',
  Boolean: 'boolean',
  Nothing: 'void',
  Any: 'Object',
  Roughnum: 'double',
};

// Pyret check-op token → Jayret assertion name.
const CHECK_OP_NAME = {
  'is':                  'assertEquals',
  'is-not':              'assertNotEquals',
  'is-roughly':          'assertRoughlyEquals',
  'is==':                'assertEqualsStrict',
  'is=~':                'assertEqualsRoughly',
  'satisfies':           'assertSatisfies',
  'violates':            'assertViolates',
  'raises':              'assertRaises',
  'raises-other-than':   'assertRaisesOtherThan',
  'raises-satisfies':    'assertRaisesSatisfies',
  'raises-violates':     'assertRaisesViolates',
  'does-not-raise':      'assertDoesNotRaise',
};

class JayretPrinter {
  constructor(comments = []) {
    this.parts = [];
    this.indent = 0;
    this.comments = comments.slice().sort((a, b) => a.line - b.line || a.col - b.col);
    this.commentIdx = 0;
    this.lastEmittedLine = 1;
  }

  // ---- output helpers ----
  emit(s) { this.parts.push(s); }
  nl() {
    this.parts.push('\n');
    this.parts.push('    '.repeat(this.indent));
  }
  withIndent(fn) { this.indent++; try { return fn(); } finally { this.indent--; } }
  result() { return this.parts.join(''); }

  // Emit pending comments whose original-source line is ≤ targetLine.
  flushCommentsBefore(targetLine) {
    while (this.commentIdx < this.comments.length
        && this.comments[this.commentIdx].line < targetLine) {
      const c = this.comments[this.commentIdx++];
      if (c.kind === 'line') this.emit('// ' + c.text.replace(/^\s+/, ''));
      else this.emit('/* ' + c.text.trim().replace(/\*\//g, '* /') + ' */');
      this.nl();
    }
  }

  flushRemainingComments() {
    while (this.commentIdx < this.comments.length) {
      const c = this.comments[this.commentIdx++];
      if (c.kind === 'line') { this.nl(); this.emit('// ' + c.text.replace(/^\s+/, '')); }
      else { this.nl(); this.emit('/* ' + c.text.trim() + ' */'); }
    }
  }

  // ---- main dispatch ----
  print(node) {
    if (!node) return;
    if (node.kids === undefined) return this.printToken(node);
    // Heuristic: before emitting a structural node, flush any comments whose
    // source line precedes this node's start.
    if (node.pos && this.commentIdx < this.comments.length) {
      const startLine = node.pos.startRow ?? node.pos.startLine;
      if (typeof startLine === 'number') this.flushCommentsBefore(startLine);
    }
    const handler = HANDLERS[node.name];
    if (handler) return handler.call(this, node);
    // Default: walk kids, emit with spaces between.
    this.printKidsSpaced(node.kids);
  }

  printToken(tok) {
    if (tok.name in TOKEN_MAP) {
      const v = TOKEN_MAP[tok.name];
      if (v !== null) this.emit(v);
      return;
    }
    if (tok.value !== undefined) this.emit(tok.value);
  }

  printKidsSpaced(kids) {
    let first = true;
    for (const k of kids) {
      if (k.kids === undefined && (k.name in TOKEN_MAP) && TOKEN_MAP[k.name] === null) continue;
      if (!first && !endsWithBoundary(this.lastEmitted())) this.emit(' ');
      this.print(k);
      first = false;
    }
  }

  lastEmitted() {
    return this.parts[this.parts.length - 1] || '';
  }

  // ---- token-kind queries ----
  kidByName(node, ...names) {
    return node.kids.find(k => names.includes(k.name));
  }
  kidsByName(node, ...names) {
    return node.kids.filter(k => names.includes(k.name));
  }
  isTok(node, name, val) {
    if (!node || node.kids !== undefined) return false;
    if (node.name !== name) return false;
    if (val !== undefined && node.value !== val) return false;
    return true;
  }
}

function endsWithBoundary(s) {
  if (!s) return true;
  return /[\s(\[{.,;]$/.test(s) || /^[(\[{.,;]$/.test(s);
}

// ---- Production handlers ----
const HANDLERS = {};

// program: [prelude block]
HANDLERS['program'] = function(node) {
  // Prelude + block, separated by a blank line where needed.
  const prelude = node.kids[0];
  const block = node.kids[1];
  if (prelude && prelude.kids && prelude.kids.length > 0) {
    this.print(prelude);
    this.nl();
  }
  this.print(block);
  this.flushRemainingComments();
};

// prelude: list of provide/import/use stmts.
HANDLERS['prelude'] = function(node) {
  let first = true;
  for (const k of node.kids) {
    if (!first) this.nl();
    this.print(k);
    first = false;
  }
};

// block: list of stmts.
HANDLERS['block'] = function(node) {
  let first = true;
  for (const k of node.kids) {
    if (!first) this.nl();
    this.print(k);
    first = false;
  }
};

// stmt: just wraps a single child.
HANDLERS['stmt'] = function(node) {
  this.print(node.kids[0]);
  if (!/[;{}]$/.test(this.lastEmitted())) this.emit(';');
};

// let-expr: [toplevel-binding EQUALS expr]   →  TYPE name = expr;
HANDLERS['let-expr'] = function(node) {
  const binding = node.kids[0];
  const value = node.kids[2];
  this.printBindingDecl(binding, value);
};

HANDLERS['var-expr'] = function(node) {
  // var-expr: VAR toplevel-binding EQUALS expr
  const binding = node.kids[1];
  const value = node.kids[3];
  this.emit('var ');
  this.printBindingDecl(binding, value);
};

HANDLERS['rec-expr'] = function(node) {
  const binding = node.kids[1];
  const value = node.kids[3];
  this.emit('rec ');
  this.printBindingDecl(binding, value);
};

JayretPrinter.prototype.printBindingDecl = function(toplevelBinding, value) {
  // toplevel-binding wraps binding which wraps name-binding or tuple-binding.
  const binding = unwrap(toplevelBinding, ['toplevel-binding', 'binding']);
  let inner = binding;
  if (binding.kids[0] && binding.kids[0].name === 'SHADOW') {
    this.emit('/* shadow */ ');
    inner = binding.kids[1];
  }
  // inner may be a name-binding or tuple-binding.
  if (inner && inner.name === 'tuple-binding') {
    this.emit('/* TODO(pyret2jayret): tuple-binding deferred in Jayret v0.1 */ ');
    this.print(value);
    return;
  }
  // inner.kids[0] is a name-binding or just the NAME token.
  const nameKid = inner && inner.kids ? inner.kids[0] : inner;
  if (nameKid && nameKid.name === 'tuple-binding') {
    this.emit('/* TODO(pyret2jayret): tuple-binding deferred in Jayret v0.1 */ ');
    this.print(value);
    return;
  }
  // name-binding: [NAME [COLONCOLON ann]?] OR just NAME at this position.
  const nameNode = nameKid && nameKid.kids ? nameKid.kids.find(k => k.name === 'NAME') || nameKid.kids[0] : nameKid;
  const colonColonIdx = nameKid && nameKid.kids ? nameKid.kids.findIndex(k => k.name === 'COLONCOLON') : -1;
  if (colonColonIdx >= 0) {
    const annNode = nameKid.kids[colonColonIdx + 1];
    this.emit(jayretType(annNode) + ' ');
  }
  if (nameNode && nameNode.value !== undefined) this.emit(nameNode.value);
  else this.emit('/* unrecognized binding */');
  this.emit(' = ');
  this.print(value);
};

HANDLERS['assign-expr'] = function(node) {
  // assign-expr: NAME COLONEQUAL expr
  this.emit(node.kids[0].value);
  this.emit(' = ');
  this.print(node.kids[2]);
};

HANDLERS['contract-stmt'] = function(node) {
  // contract-stmt: NAME COLONCOLON ann
  this.emit('/* contract: ');
  this.emit(node.kids[0].value);
  this.emit(' :: ');
  this.emit(jayretType(node.kids[2]));
  this.emit(' */');
};

// fun-expr: FUN NAME fun-header COLON doc body where-clause END
HANDLERS['fun-expr'] = function(node) {
  const name = node.kids[1].value;
  const header = node.kids[2];
  const docKid = node.kids[4];
  const bodyKid = node.kids[5];
  const whereKid = node.kids[6];
  const [tyParams, args, retAnn] = parseFunHeader(header);
  this.emit(`${retAnn || 'Object'} ${name}(${args}) {`);
  this.withIndent(() => {
    // doc-string is rarely populated in docs samples; if present, emit as
    // leading // comment.
    if (docKid && docKid.kids && docKid.kids.length > 0) {
      this.nl();
      // doc-string: [DOC STRING] — kids[1] is the string
      const docStr = docKid.kids[1] && docKid.kids[1].value;
      if (docStr) this.emit('// ' + JSON.parse(docStr));
    }
    this.printFnBody(bodyKid);
  });
  this.nl();
  this.emit('}');
  if (whereKid && whereKid.kids && whereKid.kids.length > 0) {
    this.emit(' where {');
    this.withIndent(() => {
      // where-clause: [WHERE COLON block]
      const wb = whereKid.kids[2];
      this.nl();
      this.print(wb);
    });
    this.nl();
    this.emit('}');
  }
};

HANDLERS['lambda-expr'] = function(node) {
  // lambda-expr: LAM fun-header COLON doc body where-clause END
  const header = node.kids[1];
  const body = node.kids[4];
  const [_, args, retAnn] = parseFunHeader(header);
  // Single-expression body? emit arrow form.
  if (body.name === 'block' && body.kids.length === 1) {
    const stmt = body.kids[0];
    if (stmt.kids.length === 1 && stmt.kids[0].name === 'check-test'
        && stmt.kids[0].kids.length === 1) {
      this.emit(`(${args}) -> `);
      this.print(stmt.kids[0].kids[0]);
      return;
    }
  }
  this.emit(`(${args}) -> {`);
  this.withIndent(() => this.printFnBody(body));
  this.nl();
  this.emit('}');
};

JayretPrinter.prototype.printFnBody = function(blockNode) {
  // Emit stmts with the last one prefixed as `return`.
  if (!blockNode || !blockNode.kids) return;
  const stmts = blockNode.kids;
  for (let i = 0; i < stmts.length; i++) {
    this.nl();
    if (i === stmts.length - 1) {
      const inner = unwrapExprStmt(stmts[i]);
      if (inner) {
        this.emit('return ');
        this.print(inner);
        if (!/[;{}]$/.test(this.lastEmitted())) this.emit(';');
        continue;
      }
    }
    this.print(stmts[i]);
  }
};

function unwrapExprStmt(stmt) {
  // stmt -> check-test (with one kid) -> binop-expr (with one kid) -> expr
  if (stmt.name !== 'stmt' || stmt.kids.length !== 1) return null;
  const ct = stmt.kids[0];
  if (ct.name !== 'check-test' || ct.kids.length !== 1) return null;
  return ct.kids[0];
}

// if-expr: IF binop-expr COLON block else-if* (ELSECOLON block)? END
HANDLERS['if-expr'] = function(node) {
  let i = 0;
  const expect = (n) => { if (node.kids[i] && node.kids[i].name === n) return node.kids[i++]; return null; };
  expect('IF');
  const cond = node.kids[i++];
  expect('COLON');
  const thenBlock = node.kids[i++];
  this.emit('if (');
  this.print(cond);
  this.emit(') {');
  this.withIndent(() => this.printIfBranchBody(thenBlock));
  this.nl();
  this.emit('}');
  while (i < node.kids.length && node.kids[i].name === 'else-if') {
    const ei = node.kids[i++];
    // else-if: [ELSEIF binop-expr COLON block]
    const eiCond = ei.kids[1];
    const eiBlock = ei.kids[3];
    this.emit(' else if (');
    this.print(eiCond);
    this.emit(') {');
    this.withIndent(() => this.printIfBranchBody(eiBlock));
    this.nl();
    this.emit('}');
  }
  if (i < node.kids.length && node.kids[i].name === 'ELSECOLON') {
    i++;
    const elseBlock = node.kids[i++];
    this.emit(' else {');
    this.withIndent(() => this.printIfBranchBody(elseBlock));
    this.nl();
    this.emit('}');
  }
};

JayretPrinter.prototype.printIfBranchBody = function(blockNode) {
  // Same as printFnBody — last stmt becomes return.
  this.printFnBody(blockNode);
};

// cases-expr: CASES LPAREN ann RPAREN binop-expr COLON cases-branch* (BAR ELSE THICKARROW block)? END
HANDLERS['cases-expr'] = function(node) {
  // Find the scrutinee (the binop-expr) and branches.
  const scrutinee = node.kids.find(k => k.name === 'binop-expr');
  const branches = node.kids.filter(k => k.name === 'cases-branch');
  const elseIdx = node.kids.findIndex(k => k.name === 'ELSE');
  this.emit('switch (');
  this.print(scrutinee);
  this.emit(') {');
  this.withIndent(() => {
    for (const b of branches) {
      this.nl();
      // cases-branch: BAR NAME cases-args? THICKARROW block
      const variant = b.kids[1].value;
      const argsKid = b.kids.find(k => k.name === 'cases-args');
      const body = b.kids[b.kids.length - 1];
      const variantPascal = variant[0].toUpperCase() + variant.slice(1);
      this.emit(`case ${variantPascal}`);
      if (argsKid) {
        // cases-args: LPAREN cases-binding (COMMA cases-binding)* RPAREN
        const bindings = argsKid.kids.filter(k => k.name === 'cases-binding');
        const parts = bindings.map(b => formatCasesBinding(b));
        this.emit(`(${parts.join(', ')})`);
      }
      this.emit(': yield ');
      this.printCasesBody(body);
      this.emit(';');
    }
    if (elseIdx >= 0) {
      const elseBlock = node.kids[elseIdx + 2]; // BAR ELSE THICKARROW block
      this.nl();
      this.emit('default: yield ');
      this.printCasesBody(elseBlock);
      this.emit(';');
    }
  });
  this.nl();
  this.emit('}');
};

JayretPrinter.prototype.printCasesBody = function(blockNode) {
  if (!blockNode || !blockNode.kids) return;
  if (blockNode.kids.length === 1) {
    const inner = unwrapExprStmt(blockNode.kids[0]);
    if (inner) { this.print(inner); return; }
  }
  // Multi-statement branch — emit as block expression.
  this.emit('block {');
  this.withIndent(() => this.printFnBody(blockNode));
  this.nl();
  this.emit('}');
};

function formatCasesBinding(b) {
  // cases-binding: [SHADOW]? [REF]? binding
  let prefix = '';
  let i = 0;
  if (b.kids[i] && b.kids[i].name === 'SHADOW') { prefix += '/* shadow */ '; i++; }
  if (b.kids[i] && b.kids[i].name === 'REF') { prefix += '/* ref */ '; i++; }
  const binding = b.kids[i];
  return prefix + formatBinding(binding);
}

// data-expr: DATA NAME ty-params COLON data-variant+ data-sharing where-clause END
HANDLERS['data-expr'] = function(node) {
  const name = node.kids[1].value;
  const tyParams = parseTyParams(node.kids[2]);
  const variants = node.kids.filter(k => k.name === 'data-variant');
  const sharing = node.kids.find(k => k.name === 'data-sharing');
  const where = node.kids.find(k => k.name === 'where-clause');
  this.emit(`data ${name}${tyParams ? '<' + tyParams + '>' : ''} {`);
  this.withIndent(() => {
    for (const v of variants) {
      this.nl();
      // data-variant: BAR variant-constructor data-with  OR  BAR NAME data-with (singleton)
      const after = v.kids.slice(1); // drop BAR
      const ctor = after[0];
      const dataWith = after[1];
      if (ctor.name === 'NAME') {
        // singleton variant
        const vname = ctor.value;
        this.emit(`${vname[0].toUpperCase() + vname.slice(1)};`);
      } else {
        // variant-constructor: NAME variant-members
        const vname = ctor.kids[0].value;
        const members = ctor.kids[1];
        const args = members && members.kids
          ? members.kids.filter(k => k.name === 'variant-member').map(formatVariantMember).join(', ')
          : '';
        this.emit(`${vname[0].toUpperCase() + vname.slice(1)}(${args});`);
      }
      // data-with: WITH COLON fields — emit as comment for now (deferred).
      if (dataWith && dataWith.kids && dataWith.kids.length > 0) {
        this.emit(' /* TODO: with: methods */');
      }
    }
    if (sharing && sharing.kids && sharing.kids.length > 0) {
      this.nl();
      this.emit('/* TODO(pyret2jayret): sharing: block deferred in Jayret v0.1 */');
    }
  });
  this.nl();
  this.emit('}');
  if (where && where.kids && where.kids.length > 0) {
    this.emit(' where {');
    this.withIndent(() => {
      const wb = where.kids[2];
      this.nl();
      this.print(wb);
    });
    this.nl();
    this.emit('}');
  }
};

function formatVariantMember(vm) {
  // variant-member: [REF]? binding
  let prefix = '';
  let i = 0;
  if (vm.kids[i] && vm.kids[i].name === 'REF') { prefix += 'ref '; i++; }
  return prefix + formatBinding(vm.kids[i]);
}

// check-expr: CHECK STRING COLON block END  |  CHECKCOLON block END
HANDLERS['check-expr'] = function(node) {
  const checkTok = node.kids[0];
  let name = '';
  let block;
  if (checkTok.name === 'CHECK' || checkTok.name === 'EXAMPLES') {
    const strKid = node.kids[1];
    if (strKid && strKid.name === 'STRING') {
      name = toIdent(JSON.parse(strKid.value));
      block = node.kids[3];
    } else {
      // CHECK without string?
      block = node.kids[1];
    }
  } else {
    block = node.kids[1];
  }
  const fnName = name || 'test';
  this.emit(`@Check void ${fnName}() {`);
  this.withIndent(() => {
    if (block) for (const s of block.kids) { this.nl(); this.print(s); }
  });
  this.nl();
  this.emit('}');
};

// check-test forms — assertions inside check blocks.
HANDLERS['check-test'] = function(node) {
  const kids = node.kids;
  if (kids.length === 1) { this.print(kids[0]); return; }
  if (kids.length >= 3 && kids[1].name === 'check-op') {
    // [left check-op right]  or  [left check-op-postfix [PERCENT refinement RPAREN] right]
    const left = kids[0];
    const op = kids[1];
    const right = kids[kids.length - 1];
    return this.emitCheckOp(op, left, right);
  }
  // check-op-postfix form may appear  — fallback: walk
  this.printKidsSpaced(kids);
};

JayretPrinter.prototype.emitCheckOp = function(opNode, left, right) {
  const opName = opNode.kids[0].name; // IS / ISNOT / ISROUGHLY / ...
  const opKey = opNode.kids[0].value; // 'is', 'is-not', ...
  const fn = CHECK_OP_NAME[opKey];
  if (!fn) {
    this.emit(`/* TODO(pyret2jayret): check-op ${opKey} */ `);
    this.print(left); this.emit(` ${opKey} `); if (right) this.print(right);
    return;
  }
  if (opKey === 'does-not-raise') {
    this.emit(`${fn}(() -> { `);
    this.print(left);
    this.emit(' });');
    return;
  }
  if (opKey === 'raises' || opKey === 'raises-other-than' || opKey === 'raises-satisfies' || opKey === 'raises-violates') {
    this.emit(`${fn}(() -> { `);
    this.print(left);
    this.emit(' }, ');
    if (right) this.print(right);
    this.emit(');');
    return;
  }
  this.emit(`${fn}(`);
  this.print(left);
  this.emit(', ');
  if (right) this.print(right);
  this.emit(');');
};

// binop-expr: [expr]  or  [expr binop expr (binop expr)*]
HANDLERS['binop-expr'] = function(node) {
  for (let i = 0; i < node.kids.length; i++) {
    if (i > 0) this.emit(' ');
    this.print(node.kids[i]);
  }
};

HANDLERS['binop'] = function(node) {
  // binop: a single token. Map AND/OR to &&/||, others pass.
  const t = node.kids[0];
  if (t.name === 'AND') this.emit('&&');
  else if (t.name === 'OR') this.emit('||');
  else this.emit(t.value);
};

// expr is a thin wrapper.
HANDLERS['expr'] = function(node) { for (const k of node.kids) this.print(k); };
HANDLERS['prim-expr'] = function(node) { for (const k of node.kids) this.print(k); };
HANDLERS['paren-expr'] = function(node) {
  // paren-expr: LPAREN binop-expr RPAREN
  this.emit('(');
  this.print(node.kids[1]);
  this.emit(')');
};
HANDLERS['paren-nospace-expr'] = HANDLERS['paren-expr'];

HANDLERS['id-expr'] = function(node) { this.emit(node.kids[0].value); };
HANDLERS['num-expr'] = function(node) { this.emit(node.kids[0].value); };
HANDLERS['frac-expr'] = function(node) {
  // FRACTION (e.g., "1/2") — emit as 1/2 still; Jayret accepts.
  this.emit(node.kids[0].value);
};
HANDLERS['rfrac-expr'] = function(node) { this.emit(node.kids[0].value); };
HANDLERS['string-expr'] = function(node) { this.emit(node.kids[0].value); };
HANDLERS['bool-expr'] = function(node) { this.emit(node.kids[0].value); };

// app-expr: expr app-args  (function application)
HANDLERS['app-expr'] = function(node) {
  this.print(node.kids[0]);
  this.print(node.kids[1]);
};
HANDLERS['app-args'] = function(node) {
  // LPAREN opt-args RPAREN
  this.emit('(');
  const inner = node.kids.find(k => k.name === 'opt-comma-binops' || k.name === 'opt-args' || k.name === 'comma-binops');
  if (inner) this.printCommaList(inner);
  this.emit(')');
};
HANDLERS['opt-args'] = function(node) { this.printCommaList(node); };
HANDLERS['opt-comma-binops'] = function(node) { this.printCommaList(node); };
HANDLERS['comma-binops'] = function(node) { this.printCommaList(node); };

JayretPrinter.prototype.printCommaList = function(node) {
  if (!node || !node.kids) return;
  let needSep = false;
  for (const k of node.kids) {
    if (k.name === 'COMMA') { this.emit(', '); needSep = false; continue; }
    if (needSep) this.emit(', ');
    this.print(k);
    needSep = true;
  }
};

// dot-expr: expr DOT NAME
HANDLERS['dot-expr'] = function(node) {
  this.print(node.kids[0]);
  this.emit('.');
  this.emit(node.kids[2].value);
};

// bracket-expr: expr LBRACK binop-expr RBRACK
HANDLERS['bracket-expr'] = function(node) {
  this.print(node.kids[0]);
  this.emit('[');
  this.print(node.kids[2]);
  this.emit(']');
};

// construct-expr: LBRACK construct-modifier binop-expr COLON opt-comma-binops RBRACK
//                 (i.e., [list: ...] or [tree-set: ...])
HANDLERS['construct-expr'] = function(node) {
  // kids: LBRACK construct-modifier binop-expr COLON opt-comma-binops RBRACK
  const ctorKid = node.kids[2];
  const ctorName = exprToString(ctorKid);
  const items = node.kids[4];
  if (ctorName === 'list') {
    this.emit('[');
    if (items) this.printCommaList(items);
    this.emit(']');
  } else {
    this.emit(`[${ctorName}: `);
    if (items) this.printCommaList(items);
    this.emit(']');
  }
};

// obj-expr: LBRACE obj-fields RBRACE
HANDLERS['obj-expr'] = function(node) {
  this.emit('{');
  const fields = node.kids[1];
  if (fields && fields.kids) {
    let first = true;
    for (const f of fields.kids) {
      if (f.name === 'COMMA') continue;
      if (!first) this.emit(', ');
      this.print(f);
      first = false;
    }
  }
  this.emit('}');
};

HANDLERS['obj-field'] = function(node) {
  // obj-field: NAME COLON binop-expr  or  method-obj-field
  if (node.kids[0].name === 'NAME' && node.kids[1].name === 'COLON') {
    this.emit(node.kids[0].value);
    this.emit(': ');
    this.print(node.kids[2]);
  } else {
    this.printKidsSpaced(node.kids);
  }
};

// tuple-expr: LBRACE binop-expr SEMI binop-expr (SEMI binop-expr)* RBRACE
HANDLERS['tuple-expr'] = function(node) {
  this.emit('/* TODO(pyret2jayret): tuples deferred in Jayret v0.1 */ {');
  let first = true;
  for (const k of node.kids) {
    if (k.name === 'LBRACE' || k.name === 'RBRACE') continue;
    if (k.name === 'SEMI') { this.emit('; '); first = false; continue; }
    if (!first && /[a-zA-Z0-9_)]$/.test(this.lastEmitted())) this.emit(' ');
    this.print(k);
    first = false;
  }
  this.emit('}');
};

// when-expr: WHEN binop-expr [BLOCK]? COLON block END
HANDLERS['when-expr'] = function(node) {
  const cond = node.kids[1];
  const blockNode = node.kids[node.kids.length - 2];
  this.emit('when (');
  this.print(cond);
  this.emit(') {');
  this.withIndent(() => { this.nl(); this.print(blockNode); });
  this.nl(); this.emit('}');
};

// ask-expr: ASK [BLOCK]? COLON ask-branch* (BAR OTHERWISECOLON expr)? END
HANDLERS['ask-expr'] = function(node) {
  this.emit('ask {');
  this.withIndent(() => {
    for (const k of node.kids) {
      if (k.name === 'ask-branch') {
        // BAR binop-expr THENCOLON block
        const cond = k.kids[1];
        const block = k.kids[3];
        this.nl();
        this.print(cond);
        this.emit(' -> ');
        const inner = block.kids.length === 1 ? unwrapExprStmt(block.kids[0]) : null;
        if (inner) this.print(inner);
        else { this.emit('block { '); this.printFnBody(block); this.emit(' }'); }
        this.emit(';');
      } else if (k.name === 'OTHERWISECOLON') {
        this.nl();
        this.emit('otherwise -> ');
      } else if (k.name === 'expr' || k.name === 'binop-expr') {
        // the otherwise expression
        this.print(k);
        this.emit(';');
      }
    }
  });
  this.nl(); this.emit('}');
};

// block-expr: BLOCK COLON block END
HANDLERS['block-expr'] = function(node) {
  this.emit('block {');
  this.withIndent(() => { this.nl(); this.print(node.kids[2]); });
  this.nl(); this.emit('}');
};

// for-expr: FOR expr LPAREN for-bind (COMMA for-bind)* RPAREN return-ann COLON block END
HANDLERS['for-expr'] = function(node) {
  const iter = exprToString(node.kids[1]);
  const binds = node.kids.filter(k => k.name === 'for-bind');
  const retAnnKid = node.kids.find(k => k.name === 'return-ann');
  const block = node.kids[node.kids.length - 2];
  if (iter === 'each' && binds.length === 1) {
    const b = binds[0];
    const bind = b.kids[0]; // binding
    const source = b.kids[2]; // expr
    this.emit('for (');
    this.emit(formatBinding(bind));
    this.emit(' : ');
    this.print(source);
    this.emit(') {');
    this.withIndent(() => { this.nl(); this.print(block); });
    this.nl(); this.emit('}');
    return;
  }
  this.emit(`[for ${iter}(`);
  binds.forEach((b, i) => {
    if (i > 0) this.emit(', ');
    const bind = b.kids[0];
    const source = b.kids[2];
    this.emit(formatBinding(bind));
    this.emit(' : ');
    this.print(source);
  });
  this.emit(') { yield ');
  const inner = block.kids.length === 1 ? unwrapExprStmt(block.kids[0]) : null;
  if (inner) this.print(inner);
  else { this.emit('block { '); this.printFnBody(block); this.emit(' }'); }
  this.emit('; }]');
};

// import-stmt: various forms
HANDLERS['import-stmt'] = function(node) {
  this.emit('import ');
  // walk kids, emit names/paths
  for (let i = 1; i < node.kids.length; i++) {
    const k = node.kids[i];
    if (k.name === 'AS') this.emit(' as ');
    else if (k.name === 'NAME') this.emit(k.value);
    else if (k.name === 'import-source') this.print(k);
    else if (k.kids === undefined && k.value !== undefined) this.emit(k.value);
    else this.print(k);
  }
};

HANDLERS['import-source'] = function(node) { this.printKidsSpaced(node.kids); };
HANDLERS['import-special'] = function(node) {
  // import-special: NAME LPAREN STRING (COMMA STRING)* RPAREN  e.g., file("...")
  this.emit(node.kids[0].value);
  this.emit('(');
  let first = true;
  for (let i = 2; i < node.kids.length - 1; i++) {
    const k = node.kids[i];
    if (k.name === 'COMMA') { this.emit(', '); continue; }
    if (!first) this.emit(', ');
    if (k.name === 'STRING') {
      const raw = JSON.parse(k.value);
      const fixed = raw.endsWith('.arr') ? raw.slice(0, -4) + '.jrt' : raw;
      this.emit(JSON.stringify(fixed));
    } else this.print(k);
    first = false;
  }
  this.emit(')');
};

HANDLERS['provide-stmt'] = function(node) {
  // provide-stmt: PROVIDE stmt END | PROVIDE STAR
  if (node.kids.length === 2 && node.kids[1].name === 'STAR') {
    this.emit('// [Jayret] top-level defs are implicitly `provide *`');
    return;
  }
  this.emit('// [Jayret] explicit `provide`: ');
  this.emit(serializeKids(node.kids.slice(1, -1)));
};
HANDLERS['provide-types-stmt'] = function(node) {
  this.emit('// [Jayret] `provide-types`: ');
  this.emit(serializeKids(node.kids.slice(1)));
};
HANDLERS['include-stmt'] = function(node) {
  this.emit('include ');
  this.printKidsSpaced(node.kids.slice(1));
};
HANDLERS['use-stmt'] = function(node) {
  // use NAME import-source
  this.emit('// [Jayret] use context: ' + serializeKids(node.kids.slice(1)));
};

HANDLERS['spy-stmt'] = function(node) {
  // spy-stmt: SPY [STRING]? COLON [spy-contents]? END
  // Find names inside spy-contents.
  const names = [];
  for (const k of node.kids) {
    if (k.name === 'spy-contents' || k.name === 'spy-content') {
      collectNames(k, names);
    }
  }
  this.emit(`spy(${names.join(', ')})`);
};

function collectNames(node, acc) {
  if (!node) return;
  if (node.name === 'NAME' && node.value) acc.push(node.value);
  if (node.kids) for (const k of node.kids) collectNames(k, acc);
}

// Helpers ----

function unwrap(node, names) {
  let n = node;
  while (n && n.kids && n.kids.length === 1 && names.includes(n.name)) n = n.kids[0];
  return n;
}

function exprToString(node) {
  // Render a node back to its source-y form (best effort).
  if (!node) return '';
  if (node.kids === undefined) return node.value || '';
  return node.kids.map(exprToString).join('');
}

function serializeKids(kids) {
  return kids.map(k => k.kids === undefined ? (k.value || '') : serializeKids(k.kids)).join(' ');
}

function parseFunHeader(header) {
  // fun-header: [ty-params args return-ann]
  const tyParamsKid = header.kids[0];
  const argsKid = header.kids[1];
  const retAnnKid = header.kids[2];
  const tyParams = parseTyParams(tyParamsKid);
  const args = parseArgs(argsKid);
  let retAnn = null;
  if (retAnnKid && retAnnKid.kids && retAnnKid.kids.length > 0) {
    // return-ann: [THINARROW ann]
    const annNode = retAnnKid.kids[1];
    retAnn = jayretType(annNode);
  }
  return [tyParams, args, retAnn];
}

function parseTyParams(node) {
  if (!node || !node.kids || node.kids.length === 0) return null;
  // ty-params: LANGLE list-ty-param* NAME RANGLE
  const names = [];
  for (const k of node.kids) {
    if (k.name === 'NAME') names.push(k.value);
    if (k.name === 'list-ty-param') {
      // list-ty-param: NAME COMMA
      for (const kk of k.kids) if (kk.name === 'NAME') names.push(kk.value);
    }
  }
  return names.join(', ');
}

function parseArgs(node) {
  if (!node || !node.kids) return '';
  // args: PARENNOSPACE binding (COMMA binding)* RPAREN
  const bindings = node.kids.filter(k => k.name === 'binding');
  return bindings.map(formatBinding).join(', ');
}

function formatBinding(binding) {
  // binding: [SHADOW]? name-binding | tuple-binding
  let prefix = '';
  let n = binding;
  if (binding.name === 'binding' && binding.kids[0] && binding.kids[0].name === 'SHADOW') {
    prefix = '/* shadow */ ';
    n = binding.kids[1];
  } else if (binding.kids && binding.kids[0]) {
    n = binding.kids[0];
  }
  if (n.name === 'name-binding') {
    // name-binding: NAME [COLONCOLON ann]?
    const name = n.kids[0].value;
    const ccIdx = n.kids.findIndex(k => k.name === 'COLONCOLON');
    if (ccIdx >= 0) {
      const ann = jayretType(n.kids[ccIdx + 1]);
      return prefix + ann + ' ' + name;
    }
    return prefix + name;
  }
  if (n.name === 'tuple-binding') {
    return prefix + '/* tuple-binding (deferred) */';
  }
  return prefix + serializeKids([n]);
}

function jayretType(ann) {
  if (!ann) return 'Object';
  if (ann.kids === undefined) return ann.value || 'Object';
  if (ann.name === 'name-ann') {
    const name = ann.kids[0].value;
    return TYPE_MAP[name] || name;
  }
  if (ann.name === 'app-ann') {
    // app-ann: name-ann LANGLE ann-list RANGLE
    const base = jayretType(ann.kids[0]);
    const params = ann.kids.slice(2, -1).filter(k => k.name !== 'COMMA').map(jayretType);
    return `${base}<${params.join(', ')}>`;
  }
  if (ann.name === 'record-ann') {
    // record-ann: LBRACE name-ann-field* RBRACE
    const fields = (ann.kids[1] && ann.kids[1].kids) || [];
    return '{' + fields.filter(k => k.name === 'name-ann-field').map(f => {
      const name = f.kids[0].value;
      const fAnn = jayretType(f.kids[2]);
      return fAnn + ' ' + name;
    }).join('; ') + '}';
  }
  if (ann.name === 'arrow-ann') {
    return '/* arrow-ann */ Object';
  }
  if (ann.name === 'tuple-ann') {
    return '/* tuple-ann (deferred) */ Object';
  }
  if (ann.name === 'ann') return jayretType(ann.kids[0]);
  return 'Object';
}

function toIdent(s) {
  const parts = String(s).toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').trim().split(/\s+/);
  if (parts.length === 0) return 'test';
  return parts[0] + parts.slice(1).map(p => p[0].toUpperCase() + p.slice(1)).join('');
}

// ---------------------------------------------------------------------------
// Block-level driver
// ---------------------------------------------------------------------------

function translateBlock(pyretSrc) {
  try {
    const { stripped, comments } = stripComments(pyretSrc);
    const toks = PYRET.tokenizer;
    const grammar = PYRET.grammar;
    toks.tokenizeFrom(stripped);
    const parsed = grammar.parse(toks);
    if (!parsed) return { ok: false, err: 'parse failed (no shifts)', out: pyretSrc };
    const n = grammar.countAllParses(parsed);
    if (n === 0) {
      // get the offending token if possible
      const cur = toks.curTok;
      const where = cur && cur.pos ? ` at line ${cur.pos.startRow}, col ${cur.pos.startCol}` : '';
      const tokDesc = cur ? `${cur.name} '${String(cur.value || '').slice(0, 30)}'` : 'EOF';
      return { ok: false, err: `parse failed${where}, next token: ${tokDesc}`, out: pyretSrc };
    }
    if (n > 1) return { ok: false, err: `ambiguous (${n} parses)`, out: pyretSrc };
    const tree = grammar.constructUniqueParse(parsed);
    const printer = new JayretPrinter(comments);
    printer.print(tree);
    return { ok: true, out: printer.result() };
  } catch (e) {
    return { ok: false, err: e.message, out: pyretSrc };
  }
}

// Inline @pyret{...} translator — many bodies are single keywords or short
// snippets that aren't full Pyret programs (e.g., `#`, `provide`, `lam`,
// `kebab-case-names`). For those we apply a small token-level rewrite. For
// longer bodies we fall through to the block translator.
// Safe inline-token substitutions. We intentionally avoid mapping
// `check:`, `where:`, `else:`, `block:`, etc. to expansions that include a `{`,
// because the @pyret{...} macro body is itself brace-delimited and unbalanced
// braces break Scribble's reader. Those tokens fall through to the pass-through
// branch in translateInline().
const INLINE_TOKEN_MAP = {
  '#': '//',
  '#|': '/*',
  '|#': '*/',
  '::': ':',
  ':=': '=',
  'and': '&&',
  'or': '||',
  'not': '!',
};
function translateInline(pyretSrc) {
  const trimmed = pyretSrc.trim();
  if (trimmed in INLINE_TOKEN_MAP) return { ok: true, out: INLINE_TOKEN_MAP[trimmed] };
  // Single-token bodies: keywords, identifiers, kebab-case names, symbols.
  // These don't form full Pyret programs, but they're meaningful inline tokens
  // referenced in prose — pass them through unchanged rather than flagging
  // every @pyret{import} as a TODO.
  if (/^[A-Za-z_][A-Za-z0-9_?!]*(-[A-Za-z0-9_?!]+)*[:?]?$/.test(trimmed)) {
    return { ok: true, out: trimmed };
  }
  // Punctuation-only or short symbolic snippets — pass through.
  if (trimmed.length <= 6 && !/\s/.test(trimmed)) {
    return { ok: true, out: trimmed };
  }
  // Try block translator. If success, use it (trimmed of trailing semicolon).
  const r = translateBlock(pyretSrc);
  if (r.ok) {
    let out = r.out.trim().replace(/;\s*$/, '');
    return { ok: true, out };
  }
  return { ok: false, err: r.err, out: pyretSrc };
}

// ---------------------------------------------------------------------------
// Scribble walker — find @pyret-block{...}, @examples{...}, @pyret{...} sites.
// ---------------------------------------------------------------------------

const MACRO_RE = /@(pyret-block|examples|pyret)(\[[^\]]*\])?(\{)/g;

function rewriteScribble(src) {
  let out = '';
  let last = 0;
  const stats = { total: 0, ok: 0, failed: 0, byMacro: {} };
  MACRO_RE.lastIndex = 0;
  let m;
  while ((m = MACRO_RE.exec(src)) !== null) {
    const macroName = m[1];
    const opts_ = m[2] || '';
    const openIdx = m.index + m[0].length - 1;
    let depth = 1, i = openIdx + 1, inStr = null;
    while (i < src.length && depth > 0) {
      const c = src[i];
      if (inStr) {
        if (c === '\\') { i += 2; continue; }
        if (c === inStr) inStr = null;
        i++; continue;
      }
      if (c === '"' || c === "'") { inStr = c; i++; continue; }
      if (c === '{') depth++;
      else if (c === '}') { depth--; if (depth === 0) break; }
      i++;
    }
    if (depth !== 0) continue;
    const bodyStart = openIdx + 1;
    const bodyEnd = i;
    const body = src.slice(bodyStart, bodyEnd);

    let translated;
    if (macroName === 'pyret-block' || macroName === 'examples') translated = translateBlock(body);
    else translated = translateInline(body);

    stats.total++;
    stats.byMacro[macroName] = stats.byMacro[macroName] || { ok: 0, failed: 0 };
    if (translated.ok) { stats.ok++; stats.byMacro[macroName].ok++; }
    else { stats.failed++; stats.byMacro[macroName].failed++; }

    // Macro names are left as-is for now (e.g., `@pyret-block` stays
    // `@pyret-block`). The plan was to rename to `@jayret-block` etc., but the
    // diff noise wasn't worth it for v1 — defer the rename to a follow-up
    // commit. The aliases in scribble-api.rkt are still defined so the rename
    // can land later without any other change.
    const renamed = macroName;
    const todo = translated.ok ? '' : `@; TODO(pyret2jayret): ${translated.err}\n`;

    // Scribble's at-reader interprets `@FOO` inside a macro body as a call to
    // the `FOO` binding. Jayret's `@Check` annotation collides with that, so
    // we escape `@` characters in translated output as `@"@"`.
    const escaped = translated.out.replace(/@/g, '@"@"');

    out += src.slice(last, m.index);
    out += todo;
    out += `@${renamed}${opts_}{${escaped}}`;
    last = bodyEnd + 1;
    MACRO_RE.lastIndex = bodyEnd + 1;
  }
  out += src.slice(last);
  return { src: out, stats };
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

function usage() {
  console.log(`Usage: pyret2jayret.mjs [options] <file.scrbl> [...]

Options:
  --dry-run, -n     Print stats; don't write files.
  --check           Exit non-zero if any block fails to translate.
  --in-place, -i    Rewrite files in place.
  --stdout          Print translated output to stdout (one file only).
  --verbose, -v     Show per-block errors.
  --self-test       Run the built-in unit tests.
  --help, -h        Show this help.`);
}

function selfTest() {
  const cases = [
    { name: 'no-ann let-decl',     src: `x = 5`,                                     want: /^x = 5;?\s*$/ },
    { name: 'ann let-decl',        src: `x :: Number = 5`,                           want: /int x = 5;/ },
    { name: 'fun w/ return',       src: `fun square(n :: Number) -> Number:\n  n * n\nend`, want: /int square\(int n\)/ },
    { name: 'if/else',             src: `fun abs(n):\n  if n < 0: (0 - n) else: n end\nend`,     want: /if \(n < 0\)/ },
    { name: 'cases → switch',      src: `cases(List) lst:\n  | empty => 0\n  | link(f, r) => f\nend`, want: /switch \(lst\).*Empty.*Link\(f, r\)/s },
    { name: 'check block',         src: `check "math":\n  1 + 1 is 2\nend`,                  want: /@Check void math\(\).*assertEquals\(1 \+ 1, 2\)/s },
    { name: 'lambda',              src: `lam(n :: Number): n * 2 end`,                      want: /\(int n\) -> n \* 2/ },
    { name: 'data',                src: `data Shape:\n  | circle(r :: Number)\n  | rectangle(w :: Number, h :: Number)\nend`, want: /data Shape \{.*Circle\(int r\);.*Rectangle\(int w, int h\);/s },
    { name: 'list literal',        src: `[list: 1, 2, 3]`,                                  want: /\[1, 2, 3\]/ },
    { name: 'comments preserved',  src: `# a comment\nx = 1`,                               want: /\/\/ a comment/ },
    { name: 'for-each',            src: `for each(x from xs): print(x) end`,               want: /for \(x : xs\) \{/ },
    { name: 'and→&&',              src: `check:\n  (true and false) is false\nend`,        want: /true && false/ },
    { name: 'use context',         src: `use context essentials2021\n\nx = 5`,             want: /use context|TODO|essentials2021/ },
    { name: 'provide *',           src: `provide *\n\nx = 1`,                              want: /provide \*|implicitly|Jayret/ },
  ];
  let pass = 0, fail = 0;
  for (const c of cases) {
    const r = translateBlock(c.src);
    if (!r.ok) { console.log(`FAIL  ${c.name}: ${r.err}`); fail++; continue; }
    if (!c.want.test(r.out)) {
      console.log(`FAIL  ${c.name}\n      got: ${JSON.stringify(r.out.slice(0, 200))}\n      want match: ${c.want}`);
      fail++; continue;
    }
    pass++; console.log(`ok    ${c.name}`);
  }
  console.log(`\n${pass}/${pass + fail} pass`);
  return fail === 0 ? 0 : 1;
}

function main(argv) {
  let dryRun = false, check = false, inPlace = false, stdout = false, verbose = false, selfTestMode = false;
  const files = [];
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') { usage(); return 0; }
    else if (a === '--dry-run' || a === '-n') dryRun = true;
    else if (a === '--check') check = true;
    else if (a === '--in-place' || a === '-i') inPlace = true;
    else if (a === '--stdout') stdout = true;
    else if (a === '--verbose' || a === '-v') verbose = true;
    else if (a === '--self-test') selfTestMode = true;
    else files.push(a);
  }
  if (selfTestMode) return selfTest();
  if (files.length === 0) { usage(); return 1; }
  if (!dryRun && !inPlace && !stdout) dryRun = true;

  let totalOK = 0, totalFailed = 0;
  for (const file of files) {
    const src = fs.readFileSync(file, 'utf8');
    const { src: out, stats } = rewriteScribble(src);
    totalOK += stats.ok; totalFailed += stats.failed;
    if (stdout) process.stdout.write(out);
    else if (inPlace) fs.writeFileSync(file, out);
    const fileLine = `${file}: ${stats.ok}/${stats.total} ok, ${stats.failed} failed`;
    const byMacro = Object.entries(stats.byMacro).map(([k, v]) => `${k}: ${v.ok}/${v.ok + v.failed}`).join(', ');
    console.log(`${fileLine} (${byMacro})`);
  }
  console.log(`\nTotal: ${totalOK} ok, ${totalFailed} failed`);
  if (check && totalFailed > 0) return 2;
  return 0;
}

if (process.argv[1] && process.argv[1].endsWith('pyret2jayret.mjs')) {
  process.exit(main(process.argv));
}

export { translateBlock, translateInline, rewriteScribble, stripComments };
