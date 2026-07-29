// VS Code extension host entry point. Deliberately plain CommonJS (no
// TypeScript/bundler step) to match this extension's existing "cheap to
// keep in sync" philosophy (see README.md) -- the only job here is
// launching `star lsp` (todo.md P2 #5) as a child process and handing it to
// `vscode-languageclient`, which owns the actual protocol plumbing.
"use strict";

const { workspace } = require("vscode");
const { LanguageClient, TransportKind } = require("vscode-languageclient/node");

/** @type {import("vscode-languageclient/node").LanguageClient | undefined} */
let client;

function activate(context) {
  const config = workspace.getConfiguration("star");
  const command = config.get("serverPath", "star");

  const serverOptions = {
    run: { command, args: ["lsp"], transport: TransportKind.stdio },
    debug: { command, args: ["lsp"], transport: TransportKind.stdio },
  };

  const clientOptions = {
    documentSelector: [{ scheme: "file", language: "star" }],
  };

  client = new LanguageClient("star", "Star Language Server", serverOptions, clientOptions);

  // `client.start()` returns a promise; a launch failure (e.g. `star` isn't
  // on PATH and `star.serverPath` wasn't set) shows up as a normal VS Code
  // error notification rather than an unhandled rejection.
  client.start().then(undefined, (err) => {
    console.error("Star: failed to start `star lsp`:", err);
  });

  context.subscriptions.push({ dispose: () => client && client.stop() });
}

function deactivate() {
  return client ? client.stop() : undefined;
}

module.exports = { activate, deactivate };
