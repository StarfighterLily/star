; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @snprintf(i8*, i64, i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i32 @strcmp(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv_s(i8*, i8*)
declare i32 @WSAStartup(i16, i8*)
declare i8* @socket(i32, i32, i32)
declare i32 @connect(i8*, i8*, i32)
declare i32 @send(i8*, i8*, i32, i32)
declare i32 @recv(i8*, i8*, i32, i32)
declare i32 @closesocket(i8*)
declare i16 @htons(i16)
declare i32 @inet_addr(i8*)
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
declare i8 @llvm.fptosi.sat.i8.f32(float)
declare i8 @llvm.fptosi.sat.i8.f64(double)
declare i8 @llvm.fptoui.sat.i8.f32(float)
declare i8 @llvm.fptoui.sat.i8.f64(double)
declare i16 @llvm.fptosi.sat.i16.f32(float)
declare i16 @llvm.fptosi.sat.i16.f64(double)
declare i16 @llvm.fptoui.sat.i16.f32(float)
declare i16 @llvm.fptoui.sat.i16.f64(double)
declare i32 @llvm.fptosi.sat.i32.f32(float)
declare i32 @llvm.fptosi.sat.i32.f64(double)
declare i32 @llvm.fptoui.sat.i32.f32(float)
declare i32 @llvm.fptoui.sat.i32.f64(double)
declare i64 @llvm.fptosi.sat.i64.f32(float)
declare i64 @llvm.fptosi.sat.i64.f64(double)
declare i64 @llvm.fptoui.sat.i64.f32(float)
declare i64 @llvm.fptoui.sat.i64.f64(double)
declare { i8, i1 } @llvm.sadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.ssub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.smul.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
declare { i16, i1 } @llvm.sadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.ssub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.smul.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.umul.with.overflow.i16(i16, i16)
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32)

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0

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
  %t1 = alloca i8*
  store i8* %a, i8** %t0
  store i8* %b, i8** %t1
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = load i8*, i8** %t1
  %t5 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t5)
  %t6 = call i32 @strlen(i8* %t2)
  %t7 = call i32 @strlen(i8* %t4)
  %t8 = add i32 %t6, %t7
  %t9 = add i32 %t8, 1
  %t10 = sext i32 %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  call i8* @strcpy(i8* %t11, i8* %t2)
  call i8* @strcat(i8* %t11, i8* %t4)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  %t12 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t12)
  %t13 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t13)
  ret i8* %t11
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t6 = alloca i8*
  %t52 = alloca { i8*, i8* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @fresh_literal()
  call void @star_rc_release(i8* %t0)
  call i32 (i8*, ...) @printf(i8* %t0)
  %t1 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1)
  %t2 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [14 x i8] }, { i64, i8*, [14 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t4 = call i8* @fresh_concat(i8* %t2, i8* %t3)
  call void @star_rc_release(i8* %t4)
  call i32 (i8*, ...) @printf(i8* %t4)
  %t5 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t5)
  %t7 = getelementptr i8*, i8** null, i32 1
  %t8 = ptrtoint i8** %t7 to i64
  %t9 = mul i64 %t8, 3
  %t10 = call i8* @malloc(i64 %t9)
  %t11 = bitcast i8* %t10 to i8**
  %t12 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t13 = getelementptr inbounds i8*, i8** %t11, i64 0
  store i8* %t12, i8** %t13
  %t14 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t15 = getelementptr inbounds i8*, i8** %t11, i64 1
  store i8* %t14, i8** %t15
  %t16 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t17 = getelementptr inbounds i8*, i8** %t11, i64 2
  store i8* %t16, i8** %t17
  %t30 = bitcast void (i8*)* @list_release_str to i8*
  %t31 = call i8* @star_rc_alloc(i64 24, i8* %t30)
  %t32 = bitcast i8* %t31 to { i8**, i64, i64 }*
  %t33 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 0
  store i8** %t11, i8*** %t33
  %t34 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 1
  store i64 3, i64* %t34
  %t35 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 2
  store i64 3, i64* %t35
  store i8* %t31, i8** %t6
  %t36 = load i8*, i8** %t6
  %t37 = icmp eq i8* %t36, null
  br i1 %t37, label %list_read_null_3, label %list_read_real_4
list_read_null_3:
  br label %list_read_end_5
list_read_real_4:
  %t38 = bitcast i8* %t36 to { i8**, i64, i64 }*
  %t39 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t38, i32 0, i32 0
  %t40 = load i8**, i8*** %t39
  %t41 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t38, i32 0, i32 1
  %t42 = load i64, i64* %t41
  br label %list_read_end_5
list_read_end_5:
  %t43 = phi i8** [ null, %list_read_null_3 ], [ %t40, %list_read_real_4 ]
  %t44 = phi i64 [ 0, %list_read_null_3 ], [ %t42, %list_read_real_4 ]
  %t45 = sext i32 1 to i64
  %t46 = icmp ult i64 %t45, %t44
  br i1 %t46, label %list_idx_ok_6, label %list_idx_oob_7
list_idx_ok_6:
  %t47 = getelementptr inbounds i8*, i8** %t43, i64 %t45
  %t48 = load i8*, i8** %t47
  %t49 = load i8*, i8** %t47
  call void @star_rc_retain(i8* %t49)
  br label %list_idx_end_8
list_idx_oob_7:
  br label %list_idx_end_8
list_idx_end_8:
  %t50 = phi i8* [ %t48, %list_idx_ok_6 ], [ null, %list_idx_oob_7 ]
  call void @star_rc_release(i8* %t50)
  call i32 (i8*, ...) @printf(i8* %t50)
  %t51 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51)
  %t65 = getelementptr inbounds { i8* }, { i8* }* null, i32 1
  %t66 = ptrtoint { i8* }* %t65 to i64
  %t70 = bitcast void (i8*)* @closure_9_release_env to i8*
  %t71 = call i8* @star_rc_alloc(i64 %t66, i8* %t70)
  %t72 = bitcast i8* %t71 to { i8* }*
  %t73 = load i8*, i8** %t6
  %t74 = load i8*, i8** %t6
  call void @star_rc_retain(i8* %t74)
  %t75 = getelementptr inbounds { i8* }, { i8* }* %t72, i32 0, i32 0
  store i8* %t73, i8** %t75
  %t76 = bitcast i8* (i8*)* @closure_9 to i8*
  %t77 = insertvalue { i8*, i8* } undef, i8* %t76, 0
  %t78 = insertvalue { i8*, i8* } %t77, i8* %t71, 1
  store { i8*, i8* } %t78, { i8*, i8* }* %t52
  %t79 = load { i8*, i8* }, { i8*, i8* }* %t52
  %t80 = load { i8*, i8* }, { i8*, i8* }* %t52
  %t81 = extractvalue { i8*, i8* } %t80, 1
  call void @star_rc_retain(i8* %t81)
  %t82 = extractvalue { i8*, i8* } %t79, 0
  %t83 = extractvalue { i8*, i8* } %t79, 1
  call void @star_rc_release(i8* %t83)
  %t84 = bitcast i8* %t82 to i8* (i8*)*
  %t85 = call i8* %t84(i8* %t83)
  call void @star_rc_release(i8* %t85)
  call i32 (i8*, ...) @printf(i8* %t85)
  %t86 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86)
  %t87 = load { i8*, i8* }, { i8*, i8* }* %t52
  %t88 = extractvalue { i8*, i8* } %t87, 1
  call void @star_rc_release(i8* %t88)
  %t89 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t89)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t23 = alloca i64
  %t18 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t19 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t18, i32 0, i32 0
  %t20 = load i8**, i8*** %t19
  %t21 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t18, i32 0, i32 1
  %t22 = load i64, i64* %t21
  store i64 0, i64* %t23
  br label %list_release_cond_0
list_release_cond_0:
  %t24 = load i64, i64* %t23
  %t25 = icmp slt i64 %t24, %t22
  br i1 %t25, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t26 = getelementptr inbounds i8*, i8** %t20, i64 %t24
  %t27 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t27)
  %t28 = add i64 %t24, 1
  store i64 %t28, i64* %t23
  br label %list_release_cond_0
list_release_end_2:
  %t29 = bitcast i8** %t20 to i8*
  call void @free(i8* %t29)
  ret void
}


define i8* @closure_9(i8* %envp) {
entry:
  %t56 = alloca i8*
  %t53 = bitcast i8* %envp to { i8* }*
  %t54 = getelementptr inbounds { i8* }, { i8* }* %t53, i32 0, i32 0
  %t55 = load i8*, i8** %t54
  store i8* %t55, i8** %t56
  %t57 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t58 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t59 = call i32 @strlen(i8* %t57)
  %t60 = call i32 @strlen(i8* %t58)
  %t61 = add i32 %t59, %t60
  %t62 = add i32 %t61, 1
  %t63 = sext i32 %t62 to i64
  %t64 = call i8* @star_rc_alloc(i64 %t63, i8* null)
  call i8* @strcpy(i8* %t64, i8* %t57)
  call i8* @strcat(i8* %t64, i8* %t58)
  call void @star_rc_release(i8* %t57)
  call void @star_rc_release(i8* %t58)
  ret i8* %t64
}


define void @closure_9_release_env(i8* %envp) {
entry:
  %t67 = bitcast i8* %envp to { i8* }*
  %t68 = getelementptr inbounds { i8* }, { i8* }* %t67, i32 0, i32 0
  %t69 = load i8*, i8** %t68
  call void @star_rc_release(i8* %t69)
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
