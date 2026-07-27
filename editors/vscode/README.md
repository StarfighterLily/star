# Star language support for VS Code

Minimal editor tooling for `.star` files: syntax highlighting (via a
TextMate grammar) plus basic bracket/comment/indentation configuration.
No language server, no completions, no diagnostics -- just highlighting,
so it's cheap to keep in sync while the language itself is still moving.

## What's here

- `syntaxes/star.tmLanguage.json` -- the TextMate grammar (`source.star`).
  Standard TextMate JSON, so it also works unmodified as a Sublime Text
  `.tmLanguage`/`.sublime-syntax`-adjacent grammar source, and can be
  registered with GitHub Linguist for highlighting `.star` files on
  github.com.
- `language-configuration.json` -- line comments (`#`), bracket pairs,
  auto-closing quotes/brackets, and indentation rules (Star uses
  significant indentation like Python: a line ending in `:` opens a
  block, `else` dedents to match its `if`).
- `package.json` -- the extension manifest wiring the two files above to
  the `.star` extension.

## Try it locally

VS Code doesn't load an unpacked extension from an arbitrary folder by
default; either symlink or copy this directory into your extensions
folder, or package it properly. Examples below use `code`; substitute
`codium` if you're on VSCodium (same CLI, different binary name -- on
Windows it's typically `%LOCALAPPDATA%\Programs\VSCodium\bin\codium.cmd`,
which the VSCodium installer normally puts on `PATH`).

```sh
# Option A: point the editor at this folder directly for one session
code --extensionDevelopmentPath="editors/vscode" .
# or: codium --extensionDevelopmentPath="editors/vscode" .

# Option B: install it like a normal extension
npm install -g @vscode/vsce
cd editors/vscode
vsce package
code --install-extension star-lang-0.1.0.vsix
# or: codium --install-extension star-lang-0.1.0.vsix
```

## Coverage

Keywords, string/char/f-string literals (including nested `{expr}`
interpolation holes), line comments, numeric literals, the primitive
type names (`i8`..`u64`, `f32`/`f64`, `int`/`float`, `bool`, `char`,
`str`/`String`, `ptr`), `@export`/`@tweakable` field decorators, and
`struct`/`trait`/`enum`/`impl`/`fn`/`system`/`arena`/`const` declaration
names are all recognized. Capitalized identifiers are highlighted as
types anywhere they appear (structs, enum variants, generic arguments)
rather than only at declaration sites, since Star's own naming
convention already reserves `PascalCase` for types.

Not attempted: real type-checking-aware highlighting (e.g.
distinguishing a shadowed local from a global), or anything needing a
language server. See `todo.md` P3 #9 for the scoping decision behind
keeping this to highlighting only for now.
