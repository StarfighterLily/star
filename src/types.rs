//! Name and type resolution for Star.
//!
//! The checker performs Hindley-Milner-style inference with explicit type
//! annotations where required (struct fields, parameters, return types). Every
//! expression is given an inferred [`Ty`] after resolution.

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use std::collections::HashMap;

/// A resolved type.
#[derive(Clone, Debug, PartialEq)]
pub enum Ty {
    Int,
    Float,
    Str,
    Bool,
    Vec2,
    Vec3,
    Vec4,
    Mat4,
    Named(String),
}

/// The error type for type checking.
#[derive(Clone, Debug)]
pub struct TypeError {
    pub message: String,
    pub span: Span,
}

/// The checker holds symbol tables and the current error list.
pub struct Checker {
    structs: HashMap<String, StructDef>,
    traits: HashMap<String, TraitDef>,
    errors: Vec<TypeError>,
}

impl Checker {
    pub fn new() -> Self {
        Self {
            structs: HashMap::new(),
            traits: HashMap::new(),
            errors: Vec::new(),
        }
    }

    pub fn check(&mut self, module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
        for item in &module.items {
            match item {
                Item::Struct(s) => { self.structs.insert(s.name.clone(), s.clone()); }
                Item::Trait(t) => { self.traits.insert(t.name.clone(), t.clone()); }
                Item::Impl(_) | Item::Fn(_) => {}
            }
        }

        let mut typed_items = Vec::new();
        for item in &module.items {
            match self.check_item(item) {
                Some(item) => typed_items.push(item),
                None => {}
            }
        }

        if self.errors.is_empty() {
            Ok(TypedModule { items: typed_items })
        } else {
            Err(self.errors_to_diagnostics())
        }
    }

    fn check_item(&mut self, item: &Item) -> Option<TypedItem> {
        match item {
            Item::Struct(s) => Some(TypedItem::Struct(self.check_struct(s))),
            Item::Trait(t) => Some(TypedItem::Trait(TypedTraitDef {
                name: t.name.clone(),
                methods: t.methods.iter().filter_map(|sig| self.check_fn_sig(sig)).collect(),
                span: t.span,
            })),
            Item::Impl(impl_blk) => {
                let checked = self.check_impl(impl_blk)?;
                Some(TypedItem::Impl(checked))
            }
            Item::Fn(f) => {
                let checked = self.check_fn(f)?;
                Some(TypedItem::Fn(checked))
            }
        }
    }

    fn check_struct(&mut self, s: &StructDef) -> TypedStructDef {
        TypedStructDef {
            name: s.name.clone(),
            fields: s.fields.iter().map(|f| {
                let resolved = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
                TypedFieldDef {
                    is_mut: f.is_mut,
                    name: f.name.clone(),
                    ty: resolved,
                    default: f.default.as_ref().map(|e| self.check_expr_infer(e)),
                    decorators: f.decorators.clone(),
                    span: f.span,
                }
            }).collect(),
            span: s.span,
        }
    }

    fn check_impl(&mut self, impl_blk: &ImplBlock) -> Option<TypedImplBlock> {
        if let Some(trait_name) = &impl_blk.trait_name {
            if !self.traits.contains_key(trait_name) {
                self.error(format!("undefined trait `{}`", trait_name), impl_blk.span);
                return None;
            }
        }
        if !self.structs.contains_key(&impl_blk.type_name) {
            self.error(format!("undefined type `{}`", impl_blk.type_name), impl_blk.span);
            return None;
        }
        let struct_ty = Ty::Named(impl_blk.type_name.clone());
        let methods: Vec<TypedFnDef> = impl_blk.methods.iter().filter_map(|m| self.check_fn_with_self_ty(m, &struct_ty)).collect();
        Some(TypedImplBlock {
            trait_name: impl_blk.trait_name.clone(),
            type_name: impl_blk.type_name.clone(),
            methods,
            span: impl_blk.span,
        })
    }

    fn check_fn(&mut self, f: &FnDef) -> Option<TypedFnDef> {
        self.check_fn_with_self_ty(f, &Ty::Named("infer".into()))
    }

    fn check_fn_with_self_ty(&mut self, f: &FnDef, self_ty: &Ty) -> Option<TypedFnDef> {
        let sig = self.check_fn_sig_with_self_ty(&f.sig, self_ty)?;
        let body = self.check_block(&f.body, &sig)?;
        Some(TypedFnDef { sig, body, span: f.span })
    }

    fn check_fn_sig(&self, sig: &FnSig) -> Option<TypedFnSig> {
        self.check_fn_sig_with_self_ty(sig, &Ty::Named("infer".into()))
    }

    fn check_fn_sig_with_self_ty(&self, sig: &FnSig, self_ty: &Ty) -> Option<TypedFnSig> {
        Some(TypedFnSig {
            name: sig.name.clone(),
            params: sig.params.iter().map(|p| self.check_param_with_self_ty(p, self_ty)).collect(),
            ret: sig.ret.as_ref().and_then(|t| self.resolve_type(t)),
            span: sig.span,
        })
    }

    fn check_param_with_self_ty(&self, p: &Param, self_ty: &Ty) -> TypedParam {
        let ty = if p.is_self {
            self_ty.clone()
        } else {
            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
        };
        TypedParam {
            is_self: p.is_self,
            is_mut: p.is_mut,
            name: p.name.clone(),
            ty,
            span: p.span,
        }
    }

    fn check_block(&mut self, block: &Block, fn_sig: &TypedFnSig) -> Option<TypedBlock> {
        let mut vars: HashMap<String, Ty> = HashMap::new();
        for p in &fn_sig.params {
            vars.insert(p.name.clone(), p.ty.clone());
        }
        let mut stmts = Vec::new();
        for stmt in &block.stmts {
            if let Some(typed) = self.check_stmt(stmt, &mut vars) {
                stmts.push(typed);
            }
        }
        Some(TypedBlock { stmts, span: block.span })
    }

    fn check_stmt(&mut self, stmt: &Stmt, vars: &mut HashMap<String, Ty>) -> Option<TypedStmt> {
        Some(match stmt {
            Stmt::Let { is_mut, name, ty, value, span } => {
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let actual_ty: Ty = ty.as_ref().and_then(|t| self.resolve_type(t))
                    .unwrap_or_else(|| value_typed.clone().into_ty());
                vars.insert(name.clone(), actual_ty.clone());
                TypedStmt::Let { is_mut: *is_mut, name: name.clone(), ty: actual_ty, value: value_typed, span: *span }
            }
            Stmt::Assign { target, op, value, span } => {
                let target_typed = self.infer_expr(target, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                TypedStmt::Assign { target: target_typed, op: *op, value: value_typed, span: *span }
            }
            Stmt::Return { value, span } => {
                let value_typed = value.as_ref().map(|v| self.infer_expr(v, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))));
                TypedStmt::Return { value: value_typed, span: *span }
            }
            Stmt::Expr(expr) => TypedStmt::Expr(self.infer_expr(expr, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
        })
    }

    fn check_expr_infer(&mut self, expr: &Expr) -> TypedExpr {
        let mut dummy_vars = HashMap::new();
        self.infer_expr(expr, &mut dummy_vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))
    }

    fn infer_expr(&mut self, expr: &Expr, vars: &mut HashMap<String, Ty>) -> Result<TypedExpr, ()> {
        match expr {
            Expr::Int(v, s) => Ok(TypedExpr::Int(*v, Ty::Int, *s)),
            Expr::Float(v, s) => Ok(TypedExpr::Float(*v, Ty::Float, *s)),
            Expr::Str(s, sp) => Ok(TypedExpr::Str(s.clone(), Ty::Str, *sp)),
            Expr::Bool(v, s) => Ok(TypedExpr::Bool(*v, Ty::Bool, *s)),
            Expr::FStr(parts, s) => {
                let mut typed_parts = Vec::new();
                for part in parts {
                    match part {
                        FStrExpr::Literal(lit) => typed_parts.push(TypedFStrExpr::Literal(lit.clone())),
                        FStrExpr::Expr(e) => {
                            let typed = self.infer_expr(e, vars)?;
                            typed_parts.push(TypedFStrExpr::Expr(Box::new(typed)));
                        }
                    }
                }
                Ok(TypedExpr::FStr(typed_parts, Ty::Str, *s))
            }
            Expr::Ident(name, s) => {
                let ty = vars.get(name).cloned().unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Ident { name: name.clone(), ty, span: *s })
            }
            Expr::SelfExpr(s) => {
                // SelfExpr gets the concrete self type from the variable table.
                let ty = vars.get("self").cloned().unwrap_or(Ty::Named("Self".into()));
                Ok(TypedExpr::SelfExpr(ty, *s))
            }
            Expr::Field { base, field, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let field_ty = self.resolve_field_type(&base_expr, field);
                Ok(TypedExpr::Field { base: Box::new(base_expr), field: field.clone(), ty: field_ty, span: *span })
            }
            Expr::Call { callee, args, span } => {
                let callee_expr = self.infer_expr(callee, vars)?;
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty: Ty::Named("unknown".into()), span: *span })
            }
            Expr::Binary { op, lhs, rhs, span } => {
                let lhs_expr = self.infer_expr(lhs, vars)?;
                let rhs_expr = self.infer_expr(rhs, vars)?;
                let ty = match op {
                    BinOp::Add | BinOp::Sub | BinOp::Mul | BinOp::Div | BinOp::Rem => {
                        match (&lhs_expr, &rhs_expr) {
                            (TypedExpr::Float(..), _) | (_, TypedExpr::Float(..)) => Ty::Float,
                            _ => Ty::Int,
                        }
                    }
                    BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge => Ty::Bool,
                };
                Ok(TypedExpr::Binary { op: *op, lhs: Box::new(lhs_expr), rhs: Box::new(rhs_expr), ty, span: *span })
            }
            Expr::Unary { op, operand, span } => {
                let operand_expr = self.infer_expr(operand, vars)?;
                let ty = match op { UnOp::Neg => Ty::Int, UnOp::Not => Ty::Bool };
                Ok(TypedExpr::Unary { op: *op, operand: Box::new(operand_expr), ty, span: *span })
            }
            Expr::Match { scrutinee, arms, span } => {
                let scrutinee_expr = self.infer_expr(scrutinee, vars)?;
                let arm_tys: Vec<TypedMatchArm> = arms.iter().map(|a| self.check_match_arm(a, &scrutinee_expr, vars)).collect();
                let ty = arm_tys.first().map(|a| a.ty.clone()).unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Match { scrutinee: Box::new(scrutinee_expr), arms: arm_tys, ty, span: *span })
            }
            Expr::StructLit { name, args, span } => {
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                Ok(TypedExpr::StructLit { name: name.clone(), args: arg_exprs, ty: Ty::Named(name.clone()), span: *span })
            }
        }
    }

    fn resolve_field_type(&self, base: &TypedExpr, field: &str) -> Ty {
        let name = match base {
            TypedExpr::Ident { ty: Ty::Named(n), .. }
            | TypedExpr::StructLit { ty: Ty::Named(n), .. }
            | TypedExpr::SelfExpr(Ty::Named(n), _) => n,
            _ => return Ty::Named("unknown".into()),
        };
        self.structs.get(name)
            .and_then(|s| s.fields.iter().find(|f| f.name == field))
            .and_then(|f| self.resolve_type(&f.ty))
            .unwrap_or(Ty::Named("unknown".into()))
    }

    fn check_match_arm(&mut self, arm: &MatchArm, _scrutinee_expr: &TypedExpr, _vars: &mut HashMap<String, Ty>) -> TypedMatchArm {
        let dummy_sig = TypedFnSig { name: "match".into(), params: vec![], ret: None, span: arm.span };
        let body = self.check_block(&arm.body, &dummy_sig).unwrap_or(TypedBlock { stmts: vec![], span: arm.span });
        TypedMatchArm { pattern: arm.pattern.clone(), body, ty: Ty::Named("unknown".into()), span: arm.span }
    }

    fn resolve_type(&self, ty: &Type) -> Option<Ty> {
        match ty {
            Type::Named(name) => Some(match name.as_str() {
                "i32" | "i64" | "int" => Ty::Int,
                "f32" | "f64" | "float" => Ty::Float,
                "String" | "str" => Ty::Str,
                "bool" => Ty::Bool,
                "Vec2" => Ty::Vec2,
                "Vec3" => Ty::Vec3,
                "Vec4" => Ty::Vec4,
                "Mat4" => Ty::Mat4,
                _ => Ty::Named(name.clone()),
            }),
            Type::Generic(_, _) => None,
        }
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(TypeError { message: msg.into(), span });
    }

    fn errors_to_diagnostics(&self) -> Vec<Diagnostic> {
        self.errors.iter().map(|e| Diagnostic::error(&e.message, e.span)).collect()
    }
}

// ===== HIR types =========================================================

#[derive(Clone, Debug)]
pub struct TypedModule {
    pub items: Vec<TypedItem>,
}

#[derive(Clone, Debug)]
pub enum TypedItem {
    Struct(TypedStructDef),
    Trait(TypedTraitDef),
    Impl(TypedImplBlock),
    Fn(TypedFnDef),
}

#[derive(Clone, Debug)]
pub struct TypedStructDef {
    pub name: String,
    pub fields: Vec<TypedFieldDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFieldDef {
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub default: Option<TypedExpr>,
    pub decorators: Vec<String>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedTraitDef {
    pub name: String,
    pub methods: Vec<TypedFnSig>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedImplBlock {
    pub trait_name: Option<String>,
    pub type_name: String,
    pub methods: Vec<TypedFnDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnSig {
    pub name: String,
    pub params: Vec<TypedParam>,
    pub ret: Option<Ty>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnDef {
    pub sig: TypedFnSig,
    pub body: TypedBlock,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedParam {
    pub is_self: bool,
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedBlock {
    pub stmts: Vec<TypedStmt>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub enum TypedStmt {
    Let { is_mut: bool, name: String, ty: Ty, value: TypedExpr, span: Span },
    Assign { target: TypedExpr, op: AssignOp, value: TypedExpr, span: Span },
    Return { value: Option<TypedExpr>, span: Span },
    Expr(TypedExpr),
}

/// A type-checked f-string component.
#[derive(Clone, Debug)]
pub enum TypedFStrExpr {
    Literal(String),
    Expr(Box<TypedExpr>),
}

/// A type-checked expression with its resolved type attached.
/// Literal variants carry their original value for codegen.
#[derive(Clone, Debug)]
pub enum TypedExpr {
    Int(i64, Ty, Span),
    Float(f64, Ty, Span),
    Str(String, Ty, Span),
    Bool(bool, Ty, Span),
    Ident { name: String, ty: Ty, span: Span },
    SelfExpr(Ty, Span),
    Field { base: Box<TypedExpr>, field: String, ty: Ty, span: Span },
    Call { callee: Box<TypedExpr>, args: Vec<TypedExpr>, ty: Ty, span: Span },
    Binary { op: BinOp, lhs: Box<TypedExpr>, rhs: Box<TypedExpr>, ty: Ty, span: Span },
    Unary { op: UnOp, operand: Box<TypedExpr>, ty: Ty, span: Span },
    Match { scrutinee: Box<TypedExpr>, arms: Vec<TypedMatchArm>, ty: Ty, span: Span },
    StructLit { name: String, args: Vec<TypedExpr>, ty: Ty, span: Span },
    FStr(Vec<TypedFStrExpr>, Ty, Span),
    Error(Ty),
}

impl TypedExpr {
    pub fn into_ty(self) -> Ty {
        match self {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _) | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. } | TypedExpr::Binary { ty, .. }
            | TypedExpr::Unary { ty, .. } | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::Error(ty) => ty,
            TypedExpr::Ident { ty, .. } => ty,
            TypedExpr::SelfExpr(ty, _) => ty,
        }
    }
}

#[derive(Clone, Debug)]
pub struct TypedMatchArm {
    pub pattern: Pattern,
    pub body: TypedBlock,
    pub ty: Ty,
    pub span: Span,
}