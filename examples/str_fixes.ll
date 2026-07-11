; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)
declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)
declare i32 @ReleaseSemaphore(i8*, i32, i32*)
declare i32 @GetCurrentThreadId()
declare float @llvm.sqrt.f32(float)
declare float @llvm.pow.f32(float, float)
declare float @llvm.fabs.f32(float)
declare float @llvm.floor.f32(float)
declare float @llvm.ceil.f32(float)
declare float @llvm.minnum.f32(float, float)
declare float @llvm.maxnum.f32(float, float)

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@rng.state = global i32 123456789

define i8* @star_rc_alloc(i64 %size, i8* %release_fn) {
entry:
  %total = add i64 %size, 16
  %raw = call i8* @malloc(i64 %total)
  %hdr = bitcast i8* %raw to i64*
  store i64 1, i64* %hdr
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %raw, i64 8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  store i8* %release_fn, i8** %relfn_slot
  %data = getelementptr inbounds i8, i8* %raw, i64 16
  ret i8* %data
}

define void @star_rc_retain(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = add i64 %rc, 1
  store i64 %rc1, i64* %hdr
  br label %done
done:
  ret void
}

define void @star_rc_release(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc1 = sub i64 %rc, 1
  store i64 %rc1, i64* %hdr
  %iszero = icmp eq i64 %rc1, 0
  br i1 %iszero, label %free, label %done
free:
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %p, i64 -8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  %relfn = load i8*, i8** %relfn_slot
  %relfn_isnull = icmp eq i8* %relfn, null
  br i1 %relfn_isnull, label %dofree, label %callrelfn
callrelfn:
  %relfn_typed = bitcast i8* %relfn to void (i8*)*
  call void %relfn_typed(i8* %p)
  br label %dofree
dofree:
  call void @free(i8* %hdr_i8)
  br label %done
done:
  ret void
}

define i8* @fresh_literal() {
entry:
  %t0 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.0, i64 0, i32 2, i64 0
  ret i8* %t0
}

define i8* @fresh_concat(i8* %a, i8* %b) {
entry:
  %t0 = alloca i8*
  store i8* %a, i8** %t0
  %t1 = alloca i8*
  store i8* %b, i8** %t1
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  call void @star_rc_release(i8* %t2)
  %t4 = load i8*, i8** %t1
  %t5 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t5)
  call void @star_rc_release(i8* %t4)
  %t6 = call i32 @strlen(i8* %t2)
  %t7 = call i32 @strlen(i8* %t4)
  %t8 = add i32 %t6, %t7
  %t9 = add i32 %t8, 1
  %t10 = sext i32 %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  call i8* @strcpy(i8* %t11, i8* %t2)
  call i8* @strcat(i8* %t11, i8* %t4)
  %t12 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t12)
  %t13 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t13)
  ret i8* %t11
}

define i32 @main() {
entry:
  %t0 = call i8* @fresh_literal()
  call i32 (i8*, ...) @printf(i8* %t0)
  %t1 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1)
  %t2 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [14 x i8] }, { i64, i8*, [14 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t4 = call i8* @fresh_concat(i8* %t2, i8* %t3)
  call i32 (i8*, ...) @printf(i8* %t4)
  %t5 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t5)
  %t6 = alloca { i8**, i64, i64 }
  %t7 = call i8* @malloc(i64 24)
  %t8 = bitcast i8* %t7 to i8**
  %t9 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t10 = getelementptr inbounds i8*, i8** %t8, i64 0
  store i8* %t9, i8** %t10
  %t11 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t12 = getelementptr inbounds i8*, i8** %t8, i64 1
  store i8* %t11, i8** %t12
  %t13 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t14 = getelementptr inbounds i8*, i8** %t8, i64 2
  store i8* %t13, i8** %t14
  %t15 = alloca { i8**, i64, i64 }
  %t16 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 0
  store i8** %t8, i8*** %t16
  %t17 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 1
  store i64 3, i64* %t17
  %t18 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 2
  store i64 3, i64* %t18
  %t19 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t15
  store { i8**, i64, i64 } %t19, { i8**, i64, i64 }* %t6
  %t20 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 0
  %t21 = load i8**, i8*** %t20
  %t22 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 1
  %t23 = load i64, i64* %t22
  %t24 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 2
  %t25 = sext i32 1 to i64
  %t26 = icmp ult i64 %t25, %t23
  br i1 %t26, label %list_idx_ok_0, label %list_idx_oob_1
list_idx_ok_0:
  %t27 = getelementptr inbounds i8*, i8** %t21, i64 %t25
  %t28 = load i8*, i8** %t27
  %t29 = load i8*, i8** %t27
  call void @star_rc_retain(i8* %t29)
  br label %list_idx_end_2
list_idx_oob_1:
  br label %list_idx_end_2
list_idx_end_2:
  %t30 = phi i8* [ %t28, %list_idx_ok_0 ], [ null, %list_idx_oob_1 ]
  call void @star_rc_release(i8* %t30)
  call i32 (i8*, ...) @printf(i8* %t30)
  %t31 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31)
  %t32 = alloca { i8*, i8* }
  %t55 = getelementptr inbounds { { i8**, i64, i64 } }, { { i8**, i64, i64 } }* null, i32 1
  %t56 = ptrtoint { { i8**, i64, i64 } }* %t55 to i64
  %t69 = bitcast void (i8*)* @closure_3_release_env to i8*
  %t70 = call i8* @star_rc_alloc(i64 %t56, i8* %t69)
  %t71 = bitcast i8* %t70 to { { i8**, i64, i64 } }*
  %t72 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t6
  %t73 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 0
  %t74 = load i8**, i8*** %t73
  %t75 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 1
  %t76 = load i64, i64* %t75
  %t77 = alloca i64
  store i64 0, i64* %t77
  br label %rc_walk_cond_10
rc_walk_cond_10:
  %t78 = load i64, i64* %t77
  %t79 = icmp slt i64 %t78, %t76
  br i1 %t79, label %rc_walk_body_11, label %rc_walk_end_12
rc_walk_body_11:
  %t80 = getelementptr inbounds i8*, i8** %t74, i64 %t78
  %t81 = load i8*, i8** %t80
  call void @star_rc_retain(i8* %t81)
  %t82 = add i64 %t78, 1
  store i64 %t82, i64* %t77
  br label %rc_walk_cond_10
rc_walk_end_12:
  %t83 = getelementptr inbounds { { i8**, i64, i64 } }, { { i8**, i64, i64 } }* %t71, i32 0, i32 0
  store { i8**, i64, i64 } %t72, { i8**, i64, i64 }* %t83
  %t84 = bitcast i8* (i8*)* @closure_3 to i8*
  %t85 = insertvalue { i8*, i8* } undef, i8* %t84, 0
  %t86 = insertvalue { i8*, i8* } %t85, i8* %t70, 1
  store { i8*, i8* } %t86, { i8*, i8* }* %t32
  %t87 = load { i8*, i8* }, { i8*, i8* }* %t32
  %t88 = load { i8*, i8* }, { i8*, i8* }* %t32
  %t89 = extractvalue { i8*, i8* } %t88, 1
  call void @star_rc_retain(i8* %t89)
  %t90 = extractvalue { i8*, i8* } %t87, 0
  %t91 = extractvalue { i8*, i8* } %t87, 1
  call void @star_rc_release(i8* %t91)
  %t92 = bitcast i8* %t90 to i8* (i8*)*
  %t93 = call i8* %t92(i8* %t91)
  call i32 (i8*, ...) @printf(i8* %t93)
  %t94 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t94)
  %t95 = load { i8*, i8* }, { i8*, i8* }* %t32
  %t96 = extractvalue { i8*, i8* } %t95, 1
  call void @star_rc_release(i8* %t96)
  %t97 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 0
  %t98 = load i8**, i8*** %t97
  %t99 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t6, i32 0, i32 1
  %t100 = load i64, i64* %t99
  %t101 = alloca i64
  store i64 0, i64* %t101
  br label %rc_walk_cond_13
rc_walk_cond_13:
  %t102 = load i64, i64* %t101
  %t103 = icmp slt i64 %t102, %t100
  br i1 %t103, label %rc_walk_body_14, label %rc_walk_end_15
rc_walk_body_14:
  %t104 = getelementptr inbounds i8*, i8** %t98, i64 %t102
  %t105 = load i8*, i8** %t104
  call void @star_rc_release(i8* %t105)
  %t106 = add i64 %t102, 1
  store i64 %t106, i64* %t101
  br label %rc_walk_cond_13
rc_walk_end_15:
  ret i32 0
}


; par/swarm worker functions
define i8* @closure_3(i8* %envp) {
entry:
  %t33 = bitcast i8* %envp to { { i8**, i64, i64 } }*
  %t34 = getelementptr inbounds { { i8**, i64, i64 } }, { { i8**, i64, i64 } }* %t33, i32 0, i32 0
  %t35 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t34
  %t36 = alloca { i8**, i64, i64 }
  store { i8**, i64, i64 } %t35, { i8**, i64, i64 }* %t36
  %t37 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t38 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t39 = call i32 @strlen(i8* %t37)
  %t40 = call i32 @strlen(i8* %t38)
  %t41 = add i32 %t39, %t40
  %t42 = add i32 %t41, 1
  %t43 = sext i32 %t42 to i64
  %t44 = call i8* @star_rc_alloc(i64 %t43, i8* null)
  call i8* @strcpy(i8* %t44, i8* %t37)
  call i8* @strcat(i8* %t44, i8* %t38)
  %t45 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t36, i32 0, i32 0
  %t46 = load i8**, i8*** %t45
  %t47 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t36, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = alloca i64
  store i64 0, i64* %t49
  br label %rc_walk_cond_4
rc_walk_cond_4:
  %t50 = load i64, i64* %t49
  %t51 = icmp slt i64 %t50, %t48
  br i1 %t51, label %rc_walk_body_5, label %rc_walk_end_6
rc_walk_body_5:
  %t52 = getelementptr inbounds i8*, i8** %t46, i64 %t50
  %t53 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t53)
  %t54 = add i64 %t50, 1
  store i64 %t54, i64* %t49
  br label %rc_walk_cond_4
rc_walk_end_6:
  ret i8* %t44
}


define void @closure_3_release_env(i8* %envp) {
entry:
  %t57 = bitcast i8* %envp to { { i8**, i64, i64 } }*
  %t58 = getelementptr inbounds { { i8**, i64, i64 } }, { { i8**, i64, i64 } }* %t57, i32 0, i32 0
  %t59 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t58, i32 0, i32 0
  %t60 = load i8**, i8*** %t59
  %t61 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t58, i32 0, i32 1
  %t62 = load i64, i64* %t61
  %t63 = alloca i64
  store i64 0, i64* %t63
  br label %rc_walk_cond_7
rc_walk_cond_7:
  %t64 = load i64, i64* %t63
  %t65 = icmp slt i64 %t64, %t62
  br i1 %t65, label %rc_walk_body_8, label %rc_walk_end_9
rc_walk_body_8:
  %t66 = getelementptr inbounds i8*, i8** %t60, i64 %t64
  %t67 = load i8*, i8** %t66
  call void @star_rc_release(i8* %t67)
  %t68 = add i64 %t64, 1
  store i64 %t68, i64* %t63
  br label %rc_walk_cond_7
rc_walk_end_9:
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"fresh literal return\00" }
@.str.1 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"fresh \00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [14 x i8] } { i64 -1, i8* null, [14 x i8] c"concat return\00" }
@.str.4 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.9 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"hello \00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"from a closure call\00" }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00"
