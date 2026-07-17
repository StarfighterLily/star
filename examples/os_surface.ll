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

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0
@sym.lock = global i8* null

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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t9 = alloca i64
  %t59 = alloca i32
  %t83 = alloca i8*
  %t101 = alloca i1
  %t111 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = load i32, i32* @star.argc
  %t4 = sext i32 %t3 to i64
  %t5 = load i8**, i8*** @star.argv
  %t6 = mul i64 %t4, 8
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to i8**
  store i64 0, i64* %t9
  br label %args_cond_0
args_cond_0:
  %t10 = load i64, i64* %t9
  %t11 = icmp slt i64 %t10, %t4
  br i1 %t11, label %args_body_1, label %args_end_2
args_body_1:
  %t12 = getelementptr inbounds i8*, i8** %t5, i64 %t10
  %t13 = load i8*, i8** %t12
  %t14 = call i32 @strlen(i8* %t13)
  %t15 = add i32 %t14, 1
  %t16 = sext i32 %t15 to i64
  %t17 = call i8* @star_rc_alloc(i64 %t16, i8* null)
  call i8* @strcpy(i8* %t17, i8* %t13)
  %t18 = getelementptr inbounds i8*, i8** %t8, i64 %t10
  store i8* %t17, i8** %t18
  %t19 = add i64 %t10, 1
  store i64 %t19, i64* %t9
  br label %args_cond_0
args_end_2:
  %t32 = bitcast void (i8*)* @list_release_str to i8*
  %t33 = call i8* @star_rc_alloc(i64 24, i8* %t32)
  %t34 = bitcast i8* %t33 to { i8**, i64, i64 }*
  %t35 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 0
  store i8** %t8, i8*** %t35
  %t36 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 1
  store i64 %t4, i64* %t36
  %t37 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 2
  store i64 %t4, i64* %t37
  store i8* %t33, i8** %t2
  %t38 = load i8*, i8** %t2
  %t39 = icmp eq i8* %t38, null
  br i1 %t39, label %list_read_null_6, label %list_read_real_7
list_read_null_6:
  br label %list_read_end_8
list_read_real_7:
  %t40 = bitcast i8* %t38 to { i8**, i64, i64 }*
  %t41 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t40, i32 0, i32 0
  %t42 = load i8**, i8*** %t41
  %t43 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t40, i32 0, i32 1
  %t44 = load i64, i64* %t43
  br label %list_read_end_8
list_read_end_8:
  %t45 = phi i8** [ null, %list_read_null_6 ], [ %t42, %list_read_real_7 ]
  %t46 = phi i64 [ 0, %list_read_null_6 ], [ %t44, %list_read_real_7 ]
  %t47 = trunc i64 %t46 to i32
  %t48 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48, i32 %t47)
  %t49 = load i8*, i8** %t2
  %t50 = icmp eq i8* %t49, null
  br i1 %t50, label %list_read_null_9, label %list_read_real_10
list_read_null_9:
  br label %list_read_end_11
list_read_real_10:
  %t51 = bitcast i8* %t49 to { i8**, i64, i64 }*
  %t52 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t51, i32 0, i32 0
  %t53 = load i8**, i8*** %t52
  %t54 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t51, i32 0, i32 1
  %t55 = load i64, i64* %t54
  br label %list_read_end_11
list_read_end_11:
  %t56 = phi i8** [ null, %list_read_null_9 ], [ %t53, %list_read_real_10 ]
  %t57 = phi i64 [ 0, %list_read_null_9 ], [ %t55, %list_read_real_10 ]
  %t58 = trunc i64 %t57 to i32
  store i32 0, i32* %t59
  br label %for_cond_12
for_cond_12:
  %t60 = load i32, i32* %t59
  %t61 = icmp slt i32 %t60, %t58
  br i1 %t61, label %for_body_13, label %for_end_15
for_body_13:
  %t62 = load i32, i32* %t59
  %t63 = load i8*, i8** %t2
  %t64 = icmp eq i8* %t63, null
  br i1 %t64, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t65 = bitcast i8* %t63 to { i8**, i64, i64 }*
  %t66 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t65, i32 0, i32 0
  %t67 = load i8**, i8*** %t66
  %t68 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t65, i32 0, i32 1
  %t69 = load i64, i64* %t68
  br label %list_read_end_18
list_read_end_18:
  %t70 = phi i8** [ null, %list_read_null_16 ], [ %t67, %list_read_real_17 ]
  %t71 = phi i64 [ 0, %list_read_null_16 ], [ %t69, %list_read_real_17 ]
  %t72 = load i32, i32* %t59
  %t73 = sext i32 %t72 to i64
  %t74 = icmp ult i64 %t73, %t71
  br i1 %t74, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t75 = getelementptr inbounds i8*, i8** %t70, i64 %t73
  %t76 = load i8*, i8** %t75
  %t77 = load i8*, i8** %t75
  call void @star_rc_retain(i8* %t77)
  br label %list_idx_end_21
list_idx_oob_20:
  %t78 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t78
  br label %list_idx_end_21
list_idx_end_21:
  %t79 = phi i8* [ %t76, %list_idx_ok_19 ], [ %t78, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t79)
  %t80 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t80, i32 %t62, i8* %t79)
  br label %for_step_14
for_step_14:
  %t81 = load i32, i32* %t59
  %t82 = add i32 %t81, 1
  store i32 %t82, i32* %t59
  br label %for_cond_12
for_end_15:
  %t84 = getelementptr inbounds { i64, i8*, [41 x i8] }, { i64, i8*, [41 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t85 = call i8* @getenv(i8* %t84)
  call void @star_rc_release(i8* %t84)
  %t86 = icmp eq i8* %t85, null
  br i1 %t86, label %env_get_null_22, label %env_get_real_23
env_get_null_22:
  %t87 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t87
  br label %env_get_end_24
env_get_real_23:
  %t88 = call i32 @strlen(i8* %t85)
  %t89 = add i32 %t88, 1
  %t90 = sext i32 %t89 to i64
  %t91 = call i8* @star_rc_alloc(i64 %t90, i8* null)
  call i8* @strcpy(i8* %t91, i8* %t85)
  br label %env_get_end_24
env_get_end_24:
  %t92 = phi i8* [ %t87, %env_get_null_22 ], [ %t91, %env_get_real_23 ]
  store i8* %t92, i8** %t83
  %t93 = load i8*, i8** %t83
  %t94 = load i8*, i8** %t83
  call void @star_rc_retain(i8* %t94)
  %t95 = call i32 @strlen(i8* %t93)
  call void @star_rc_release(i8* %t93)
  %t96 = icmp eq i32 %t95, 0
  %t97 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t98 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t99 = select i1 %t96, i8* %t97, i8* %t98
  %t100 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i8* %t99)
  %t102 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t103 = getelementptr inbounds { i64, i8*, [16 x i8] }, { i64, i8*, [16 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t104 = call i32 @_putenv_s(i8* %t102, i8* %t103)
  call void @star_rc_release(i8* %t102)
  call void @star_rc_release(i8* %t103)
  %t105 = icmp eq i32 %t104, 0
  store i1 %t105, i1* %t101
  %t106 = load i1, i1* %t101
  %t107 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t108 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t109 = select i1 %t106, i8* %t107, i8* %t108
  %t110 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t110, i8* %t109)
  %t112 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t113 = call i8* @getenv(i8* %t112)
  call void @star_rc_release(i8* %t112)
  %t114 = icmp eq i8* %t113, null
  br i1 %t114, label %env_get_null_25, label %env_get_real_26
env_get_null_25:
  %t115 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t115
  br label %env_get_end_27
env_get_real_26:
  %t116 = call i32 @strlen(i8* %t113)
  %t117 = add i32 %t116, 1
  %t118 = sext i32 %t117 to i64
  %t119 = call i8* @star_rc_alloc(i64 %t118, i8* null)
  call i8* @strcpy(i8* %t119, i8* %t113)
  br label %env_get_end_27
env_get_end_27:
  %t120 = phi i8* [ %t115, %env_get_null_25 ], [ %t119, %env_get_real_26 ]
  store i8* %t120, i8** %t111
  %t121 = load i8*, i8** %t111
  %t122 = load i8*, i8** %t111
  call void @star_rc_retain(i8* %t122)
  call void @star_rc_release(i8* %t121)
  %t123 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i8* %t121)
  %t124 = load i8*, i8** %t111
  call void @star_rc_release(i8* %t124)
  %t125 = load i8*, i8** %t83
  call void @star_rc_release(i8* %t125)
  %t126 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t126)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t25 = alloca i64
  %t20 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t21 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t20, i32 0, i32 0
  %t22 = load i8**, i8*** %t21
  %t23 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t20, i32 0, i32 1
  %t24 = load i64, i64* %t23
  store i64 0, i64* %t25
  br label %list_release_cond_3
list_release_cond_3:
  %t26 = load i64, i64* %t25
  %t27 = icmp slt i64 %t26, %t24
  br i1 %t27, label %list_release_body_4, label %list_release_end_5
list_release_body_4:
  %t28 = getelementptr inbounds i8*, i8** %t22, i64 %t26
  %t29 = load i8*, i8** %t28
  call void @star_rc_release(i8* %t29)
  %t30 = add i64 %t26, 1
  store i64 %t30, i64* %t25
  br label %list_release_cond_3
list_release_end_5:
  %t31 = bitcast i8** %t22 to i8*
  call void @free(i8* %t31)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [15 x i8] c"arg count: %d\0A\00"
@.str.1 = private unnamed_addr constant [15 x i8] c"argv[%d] = %s\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [41 x i8] } { i64 -1, i8* null, [41 x i8] c"STAR_OS_SURFACE_DEFINITELY_UNSET_VAR_XYZ\00" }
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [26 x i8] c"missing var is empty: %s\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [28 x i8] } { i64 -1, i8* null, [28 x i8] c"STAR_OS_SURFACE_EXAMPLE_VAR\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [16 x i8] } { i64 -1, i8* null, [16 x i8] c"hello from star\00" }
@.str.8 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.9 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.10 = private unnamed_addr constant [23 x i8] c"env_set succeeded: %s\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [28 x i8] } { i64 -1, i8* null, [28 x i8] c"STAR_OS_SURFACE_EXAMPLE_VAR\00" }
@.str.12 = private unnamed_addr constant [16 x i8] c"round trip: %s\0A\00"
