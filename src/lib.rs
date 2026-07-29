//! The Star compiler, exposed as a library so both the `star` binary and the
//! integration tests can drive individual stages.
//!
//! Pipeline: source -> [`lexer`] -> [`parser`] -> [`ast`] -> (resolver, types,
//! codegen in later milestones). [`diagnostics`] is shared by every stage.

pub mod ast;
pub mod codegen;
pub mod diagnostics;
pub mod driver;
pub mod ir_check;
pub mod lexer;
pub mod lsp;
pub mod manifest;
pub mod modules;
pub mod parser;
pub mod sequence;
pub mod types;
