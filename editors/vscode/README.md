# Star language support for VS Code

Editor tooling for `.star` files: syntax highlighting (via a TextMate
grammar), basic bracket/comment/indentation configuration, and
`star check`-driven diagnostics via a minimal Language Server Protocol
client (todo.md P2 #5) -- no completions, no hover, no go-to-definition
yet, just squiggles where `star check` would already have found a
problem, in-editor instead of in a terminal.

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
- `extension.js` -- the extension host entry point. Plain CommonJS (no
  bundler/TypeScript build step, matching this extension's existing
  "cheap to keep in sync" philosophy): it launches `star lsp` as a child
  process over stdio via `vscode-languageclient` and does nothing else.
  The actual diagnostics logic lives entirely in the compiler
  (`src/lsp.rs`'s module doc comment) -- this file is just plumbing.
- `package.json` -- the extension manifest: wires the grammar/language
  config, declares the `vscode-languageclient` dependency, and exposes
  two settings (`star.serverPath`, `star.trace.server`).

## Requirements

A `star` executable that understands the `lsp` subcommand (this repo's
own `cargo build`, or any build of it) reachable one of two ways:

- On `PATH` under the name `star` (or `star.exe` on Windows) -- the
  default, no configuration needed.
- Anywhere else: set the `star.serverPath` setting (File > Preferences >
  Settings, search "star") to the full path of the executable.

If `star lsp` fails to launch (wrong path, executable missing), VS Code
shows an error notification naming the failure -- syntax highlighting
still works either way, since it doesn't depend on the language server
at all.

## Try it locally

VS Code doesn't load an unpacked extension from an arbitrary folder by
default; either symlink or copy this directory into your extensions
folder, or package it properly. Examples below use `code`; substitute
`codium` if you're on VSCodium (same CLI, different binary name -- on
Windows it's typically `%LOCALAPPDATA%\Programs\VSCodium\bin\codium.cmd`,
which the VSCodium installer normally puts on `PATH`).

```sh
cd editors/vscode
npm install   # pulls in vscode-languageclient (a real runtime dependency
              # now, not just a manifest) -- needed before either option
              # below, since the extension `require`s it at activation time.

# Option A: point the editor at this folder directly for one session
code --extensionDevelopmentPath="editors/vscode" .
# or: codium --extensionDevelopmentPath="editors/vscode" .

# Option B: install it like a normal extension
npm install -g @vscode/vsce
vsce package
code --install-extension star-lang-0.2.0.vsix
# or: codium --install-extension star-lang-0.2.0.vsix
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

Diagnostics are published on `textDocument/didOpen`/`didSave`, re-running
the exact same `Driver::compile` pipeline `star check` uses -- not on
every keystroke (`didChange` is accepted but intentionally a no-op; see
`src/lsp.rs`'s module doc comment for why). A diagnostic whose real
location is inside an `import`ed file (rather than the open document
itself) is still surfaced, but anchored at the top of the open file with
the origin file named in the message text, since the server doesn't yet
track imported files' canonical paths -- a natural follow-up once this
minimal version proves out.

Not attempted: completions, hover, go-to-definition, or any
real-time-as-you-type analysis. Each is an additive extension of
`src/lsp.rs`'s `handle_message` dispatch, not a redesign.
