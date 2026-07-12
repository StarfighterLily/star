; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

@star.argc = global i32 0
@star.argv = global i8** null

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
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = atomicrmw add i64* %hdr, i64 1 seq_cst
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
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc_old = atomicrmw sub i64* %hdr, i64 1 seq_cst
  %iszero = icmp eq i64 %rc_old, 1
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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
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
  %t6 = alloca i8*
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
  %t27 = bitcast void (i8*)* @list_release_str to i8*
  %t28 = call i8* @star_rc_alloc(i64 24, i8* %t27)
  %t29 = bitcast i8* %t28 to { i8**, i64, i64 }*
  %t30 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t29, i32 0, i32 0
  store i8** %t8, i8*** %t30
  %t31 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t29, i32 0, i32 1
  store i64 3, i64* %t31
  %t32 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t29, i32 0, i32 2
  store i64 3, i64* %t32
  store i8* %t28, i8** %t6
  %t33 = load i8*, i8** %t6
  %t34 = icmp eq i8* %t33, null
  br i1 %t34, label %list_read_null_3, label %list_read_real_4
list_read_null_3:
  br label %list_read_end_5
list_read_real_4:
  %t35 = bitcast i8* %t33 to { i8**, i64, i64 }*
  %t36 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t35, i32 0, i32 0
  %t37 = load i8**, i8*** %t36
  %t38 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t35, i32 0, i32 1
  %t39 = load i64, i64* %t38
  br label %list_read_end_5
list_read_end_5:
  %t40 = phi i8** [ null, %list_read_null_3 ], [ %t37, %list_read_real_4 ]
  %t41 = phi i64 [ 0, %list_read_null_3 ], [ %t39, %list_read_real_4 ]
  %t42 = sext i32 1 to i64
  %t43 = icmp ult i64 %t42, %t41
  br i1 %t43, label %list_idx_ok_6, label %list_idx_oob_7
list_idx_ok_6:
  %t44 = getelementptr inbounds i8*, i8** %t40, i64 %t42
  %t45 = load i8*, i8** %t44
  %t46 = load i8*, i8** %t44
  call void @star_rc_retain(i8* %t46)
  br label %list_idx_end_8
list_idx_oob_7:
  br label %list_idx_end_8
list_idx_end_8:
  %t47 = phi i8* [ %t45, %list_idx_ok_6 ], [ null, %list_idx_oob_7 ]
  call void @star_rc_release(i8* %t47)
  call i32 (i8*, ...) @printf(i8* %t47)
  %t48 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48)
  %t49 = alloca { i8*, i8* }
  %t63 = getelementptr inbounds { i8* }, { i8* }* null, i32 1
  %t64 = ptrtoint { i8* }* %t63 to i64
  %t68 = bitcast void (i8*)* @closure_9_release_env to i8*
  %t69 = call i8* @star_rc_alloc(i64 %t64, i8* %t68)
  %t70 = bitcast i8* %t69 to { i8* }*
  %t71 = load i8*, i8** %t6
  %t72 = load i8*, i8** %t6
  call void @star_rc_retain(i8* %t72)
  %t73 = getelementptr inbounds { i8* }, { i8* }* %t70, i32 0, i32 0
  store i8* %t71, i8** %t73
  %t74 = bitcast i8* (i8*)* @closure_9 to i8*
  %t75 = insertvalue { i8*, i8* } undef, i8* %t74, 0
  %t76 = insertvalue { i8*, i8* } %t75, i8* %t69, 1
  store { i8*, i8* } %t76, { i8*, i8* }* %t49
  %t77 = load { i8*, i8* }, { i8*, i8* }* %t49
  %t78 = load { i8*, i8* }, { i8*, i8* }* %t49
  %t79 = extractvalue { i8*, i8* } %t78, 1
  call void @star_rc_retain(i8* %t79)
  %t80 = extractvalue { i8*, i8* } %t77, 0
  %t81 = extractvalue { i8*, i8* } %t77, 1
  call void @star_rc_release(i8* %t81)
  %t82 = bitcast i8* %t80 to i8* (i8*)*
  %t83 = call i8* %t82(i8* %t81)
  call i32 (i8*, ...) @printf(i8* %t83)
  %t84 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t84)
  %t85 = load { i8*, i8* }, { i8*, i8* }* %t49
  %t86 = extractvalue { i8*, i8* } %t85, 1
  call void @star_rc_release(i8* %t86)
  %t87 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t87)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t15 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t16 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 0
  %t17 = load i8**, i8*** %t16
  %t18 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 1
  %t19 = load i64, i64* %t18
  %t20 = alloca i64
  store i64 0, i64* %t20
  br label %list_release_cond_0
list_release_cond_0:
  %t21 = load i64, i64* %t20
  %t22 = icmp slt i64 %t21, %t19
  br i1 %t22, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t23 = getelementptr inbounds i8*, i8** %t17, i64 %t21
  %t24 = load i8*, i8** %t23
  call void @star_rc_release(i8* %t24)
  %t25 = add i64 %t21, 1
  store i64 %t25, i64* %t20
  br label %list_release_cond_0
list_release_end_2:
  %t26 = bitcast i8** %t17 to i8*
  call void @free(i8* %t26)
  ret void
}


define i8* @closure_9(i8* %envp) {
entry:
  %t50 = bitcast i8* %envp to { i8* }*
  %t51 = getelementptr inbounds { i8* }, { i8* }* %t50, i32 0, i32 0
  %t52 = load i8*, i8** %t51
  %t53 = alloca i8*
  store i8* %t52, i8** %t53
  %t54 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t55 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t56 = call i32 @strlen(i8* %t54)
  %t57 = call i32 @strlen(i8* %t55)
  %t58 = add i32 %t56, %t57
  %t59 = add i32 %t58, 1
  %t60 = sext i32 %t59 to i64
  %t61 = call i8* @star_rc_alloc(i64 %t60, i8* null)
  call i8* @strcpy(i8* %t61, i8* %t54)
  call i8* @strcat(i8* %t61, i8* %t55)
  %t62 = load i8*, i8** %t53
  call void @star_rc_release(i8* %t62)
  ret i8* %t61
}


define void @closure_9_release_env(i8* %envp) {
entry:
  %t65 = bitcast i8* %envp to { i8* }*
  %t66 = getelementptr inbounds { i8* }, { i8* }* %t65, i32 0, i32 0
  %t67 = load i8*, i8** %t66
  call void @star_rc_release(i8* %t67)
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
