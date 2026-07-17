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
  %t1 = alloca i8*
  %t8 = alloca i64
  %t58 = alloca i32
  %t81 = alloca i8*
  %t99 = alloca i1
  %t109 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = load i32, i32* @star.argc
  %t3 = sext i32 %t2 to i64
  %t4 = load i8**, i8*** @star.argv
  %t5 = mul i64 %t3, 8
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to i8**
  store i64 0, i64* %t8
  br label %args_cond_0
args_cond_0:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t3
  br i1 %t10, label %args_body_1, label %args_end_2
args_body_1:
  %t11 = getelementptr inbounds i8*, i8** %t4, i64 %t9
  %t12 = load i8*, i8** %t11
  %t13 = call i32 @strlen(i8* %t12)
  %t14 = add i32 %t13, 1
  %t15 = sext i32 %t14 to i64
  %t16 = call i8* @star_rc_alloc(i64 %t15, i8* null)
  call i8* @strcpy(i8* %t16, i8* %t12)
  %t17 = getelementptr inbounds i8*, i8** %t7, i64 %t9
  store i8* %t16, i8** %t17
  %t18 = add i64 %t9, 1
  store i64 %t18, i64* %t8
  br label %args_cond_0
args_end_2:
  %t31 = bitcast void (i8*)* @list_release_str to i8*
  %t32 = call i8* @star_rc_alloc(i64 24, i8* %t31)
  %t33 = bitcast i8* %t32 to { i8**, i64, i64 }*
  %t34 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t33, i32 0, i32 0
  store i8** %t7, i8*** %t34
  %t35 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t33, i32 0, i32 1
  store i64 %t3, i64* %t35
  %t36 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t33, i32 0, i32 2
  store i64 %t3, i64* %t36
  store i8* %t32, i8** %t1
  %t37 = load i8*, i8** %t1
  %t38 = icmp eq i8* %t37, null
  br i1 %t38, label %list_read_null_6, label %list_read_real_7
list_read_null_6:
  br label %list_read_end_8
list_read_real_7:
  %t39 = bitcast i8* %t37 to { i8**, i64, i64 }*
  %t40 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t39, i32 0, i32 0
  %t41 = load i8**, i8*** %t40
  %t42 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t39, i32 0, i32 1
  %t43 = load i64, i64* %t42
  br label %list_read_end_8
list_read_end_8:
  %t44 = phi i8** [ null, %list_read_null_6 ], [ %t41, %list_read_real_7 ]
  %t45 = phi i64 [ 0, %list_read_null_6 ], [ %t43, %list_read_real_7 ]
  %t46 = trunc i64 %t45 to i32
  %t47 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i32 %t46)
  %t48 = load i8*, i8** %t1
  %t49 = icmp eq i8* %t48, null
  br i1 %t49, label %list_read_null_9, label %list_read_real_10
list_read_null_9:
  br label %list_read_end_11
list_read_real_10:
  %t50 = bitcast i8* %t48 to { i8**, i64, i64 }*
  %t51 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t50, i32 0, i32 0
  %t52 = load i8**, i8*** %t51
  %t53 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t50, i32 0, i32 1
  %t54 = load i64, i64* %t53
  br label %list_read_end_11
list_read_end_11:
  %t55 = phi i8** [ null, %list_read_null_9 ], [ %t52, %list_read_real_10 ]
  %t56 = phi i64 [ 0, %list_read_null_9 ], [ %t54, %list_read_real_10 ]
  %t57 = trunc i64 %t56 to i32
  store i32 0, i32* %t58
  br label %for_cond_12
for_cond_12:
  %t59 = load i32, i32* %t58
  %t60 = icmp slt i32 %t59, %t57
  br i1 %t60, label %for_body_13, label %for_end_15
for_body_13:
  %t61 = load i32, i32* %t58
  %t62 = load i8*, i8** %t1
  %t63 = icmp eq i8* %t62, null
  br i1 %t63, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t64 = bitcast i8* %t62 to { i8**, i64, i64 }*
  %t65 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t64, i32 0, i32 0
  %t66 = load i8**, i8*** %t65
  %t67 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t64, i32 0, i32 1
  %t68 = load i64, i64* %t67
  br label %list_read_end_18
list_read_end_18:
  %t69 = phi i8** [ null, %list_read_null_16 ], [ %t66, %list_read_real_17 ]
  %t70 = phi i64 [ 0, %list_read_null_16 ], [ %t68, %list_read_real_17 ]
  %t71 = load i32, i32* %t58
  %t72 = sext i32 %t71 to i64
  %t73 = icmp ult i64 %t72, %t70
  br i1 %t73, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t74 = getelementptr inbounds i8*, i8** %t69, i64 %t72
  %t75 = load i8*, i8** %t74
  %t76 = load i8*, i8** %t74
  call void @star_rc_retain(i8* %t76)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t77 = phi i8* [ %t75, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t77)
  %t78 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t78, i32 %t61, i8* %t77)
  br label %for_step_14
for_step_14:
  %t79 = load i32, i32* %t58
  %t80 = add i32 %t79, 1
  store i32 %t80, i32* %t58
  br label %for_cond_12
for_end_15:
  %t82 = getelementptr inbounds { i64, i8*, [41 x i8] }, { i64, i8*, [41 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t83 = call i8* @getenv(i8* %t82)
  call void @star_rc_release(i8* %t82)
  %t84 = icmp eq i8* %t83, null
  br i1 %t84, label %env_get_null_22, label %env_get_real_23
env_get_null_22:
  %t85 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t85
  br label %env_get_end_24
env_get_real_23:
  %t86 = call i32 @strlen(i8* %t83)
  %t87 = add i32 %t86, 1
  %t88 = sext i32 %t87 to i64
  %t89 = call i8* @star_rc_alloc(i64 %t88, i8* null)
  call i8* @strcpy(i8* %t89, i8* %t83)
  br label %env_get_end_24
env_get_end_24:
  %t90 = phi i8* [ %t85, %env_get_null_22 ], [ %t89, %env_get_real_23 ]
  store i8* %t90, i8** %t81
  %t91 = load i8*, i8** %t81
  %t92 = load i8*, i8** %t81
  call void @star_rc_retain(i8* %t92)
  %t93 = call i32 @strlen(i8* %t91)
  call void @star_rc_release(i8* %t91)
  %t94 = icmp eq i32 %t93, 0
  %t95 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t96 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t97 = select i1 %t94, i8* %t95, i8* %t96
  %t98 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t98, i8* %t97)
  %t100 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t101 = getelementptr inbounds { i64, i8*, [16 x i8] }, { i64, i8*, [16 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t102 = call i32 @_putenv_s(i8* %t100, i8* %t101)
  call void @star_rc_release(i8* %t100)
  call void @star_rc_release(i8* %t101)
  %t103 = icmp eq i32 %t102, 0
  store i1 %t103, i1* %t99
  %t104 = load i1, i1* %t99
  %t105 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t106 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t107 = select i1 %t104, i8* %t105, i8* %t106
  %t108 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t108, i8* %t107)
  %t110 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t111 = call i8* @getenv(i8* %t110)
  call void @star_rc_release(i8* %t110)
  %t112 = icmp eq i8* %t111, null
  br i1 %t112, label %env_get_null_25, label %env_get_real_26
env_get_null_25:
  %t113 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t113
  br label %env_get_end_27
env_get_real_26:
  %t114 = call i32 @strlen(i8* %t111)
  %t115 = add i32 %t114, 1
  %t116 = sext i32 %t115 to i64
  %t117 = call i8* @star_rc_alloc(i64 %t116, i8* null)
  call i8* @strcpy(i8* %t117, i8* %t111)
  br label %env_get_end_27
env_get_end_27:
  %t118 = phi i8* [ %t113, %env_get_null_25 ], [ %t117, %env_get_real_26 ]
  store i8* %t118, i8** %t109
  %t119 = load i8*, i8** %t109
  %t120 = load i8*, i8** %t109
  call void @star_rc_retain(i8* %t120)
  call void @star_rc_release(i8* %t119)
  %t121 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t121, i8* %t119)
  %t122 = load i8*, i8** %t109
  call void @star_rc_release(i8* %t122)
  %t123 = load i8*, i8** %t81
  call void @star_rc_release(i8* %t123)
  %t124 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t124)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t24 = alloca i64
  %t19 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t20 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t19, i32 0, i32 0
  %t21 = load i8**, i8*** %t20
  %t22 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t19, i32 0, i32 1
  %t23 = load i64, i64* %t22
  store i64 0, i64* %t24
  br label %list_release_cond_3
list_release_cond_3:
  %t25 = load i64, i64* %t24
  %t26 = icmp slt i64 %t25, %t23
  br i1 %t26, label %list_release_body_4, label %list_release_end_5
list_release_body_4:
  %t27 = getelementptr inbounds i8*, i8** %t21, i64 %t25
  %t28 = load i8*, i8** %t27
  call void @star_rc_release(i8* %t28)
  %t29 = add i64 %t25, 1
  store i64 %t29, i64* %t24
  br label %list_release_cond_3
list_release_end_5:
  %t30 = bitcast i8** %t21 to i8*
  call void @free(i8* %t30)
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
