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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  %t1 = load i32, i32* @star.argc
  %t2 = sext i32 %t1 to i64
  %t3 = load i8**, i8*** @star.argv
  %t4 = mul i64 %t2, 8
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to i8**
  %t7 = alloca i64
  store i64 0, i64* %t7
  br label %args_cond_0
args_cond_0:
  %t8 = load i64, i64* %t7
  %t9 = icmp slt i64 %t8, %t2
  br i1 %t9, label %args_body_1, label %args_end_2
args_body_1:
  %t10 = getelementptr inbounds i8*, i8** %t3, i64 %t8
  %t11 = load i8*, i8** %t10
  %t12 = call i32 @strlen(i8* %t11)
  %t13 = add i32 %t12, 1
  %t14 = sext i32 %t13 to i64
  %t15 = call i8* @star_rc_alloc(i64 %t14, i8* null)
  call i8* @strcpy(i8* %t15, i8* %t11)
  %t16 = getelementptr inbounds i8*, i8** %t6, i64 %t8
  store i8* %t15, i8** %t16
  %t17 = add i64 %t8, 1
  store i64 %t17, i64* %t7
  br label %args_cond_0
args_end_2:
  %t30 = bitcast void (i8*)* @list_release_str to i8*
  %t31 = call i8* @star_rc_alloc(i64 24, i8* %t30)
  %t32 = bitcast i8* %t31 to { i8**, i64, i64 }*
  %t33 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 0
  store i8** %t6, i8*** %t33
  %t34 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 1
  store i64 %t2, i64* %t34
  %t35 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 2
  store i64 %t2, i64* %t35
  store i8* %t31, i8** %t0
  %t36 = load i8*, i8** %t0
  %t37 = icmp eq i8* %t36, null
  br i1 %t37, label %list_read_null_6, label %list_read_real_7
list_read_null_6:
  br label %list_read_end_8
list_read_real_7:
  %t38 = bitcast i8* %t36 to { i8**, i64, i64 }*
  %t39 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t38, i32 0, i32 0
  %t40 = load i8**, i8*** %t39
  %t41 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t38, i32 0, i32 1
  %t42 = load i64, i64* %t41
  br label %list_read_end_8
list_read_end_8:
  %t43 = phi i8** [ null, %list_read_null_6 ], [ %t40, %list_read_real_7 ]
  %t44 = phi i64 [ 0, %list_read_null_6 ], [ %t42, %list_read_real_7 ]
  %t45 = trunc i64 %t44 to i32
  %t46 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t46, i32 %t45)
  %t47 = load i8*, i8** %t0
  %t48 = icmp eq i8* %t47, null
  br i1 %t48, label %list_read_null_9, label %list_read_real_10
list_read_null_9:
  br label %list_read_end_11
list_read_real_10:
  %t49 = bitcast i8* %t47 to { i8**, i64, i64 }*
  %t50 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t51 = load i8**, i8*** %t50
  %t52 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t53 = load i64, i64* %t52
  br label %list_read_end_11
list_read_end_11:
  %t54 = phi i8** [ null, %list_read_null_9 ], [ %t51, %list_read_real_10 ]
  %t55 = phi i64 [ 0, %list_read_null_9 ], [ %t53, %list_read_real_10 ]
  %t56 = trunc i64 %t55 to i32
  %t57 = alloca i32
  store i32 0, i32* %t57
  br label %for_cond_12
for_cond_12:
  %t58 = load i32, i32* %t57
  %t59 = icmp slt i32 %t58, %t56
  br i1 %t59, label %for_body_13, label %for_end_15
for_body_13:
  %t60 = load i32, i32* %t57
  %t61 = load i8*, i8** %t0
  %t62 = icmp eq i8* %t61, null
  br i1 %t62, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t63 = bitcast i8* %t61 to { i8**, i64, i64 }*
  %t64 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t63, i32 0, i32 0
  %t65 = load i8**, i8*** %t64
  %t66 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t63, i32 0, i32 1
  %t67 = load i64, i64* %t66
  br label %list_read_end_18
list_read_end_18:
  %t68 = phi i8** [ null, %list_read_null_16 ], [ %t65, %list_read_real_17 ]
  %t69 = phi i64 [ 0, %list_read_null_16 ], [ %t67, %list_read_real_17 ]
  %t70 = load i32, i32* %t57
  %t71 = sext i32 %t70 to i64
  %t72 = icmp ult i64 %t71, %t69
  br i1 %t72, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t73 = getelementptr inbounds i8*, i8** %t68, i64 %t71
  %t74 = load i8*, i8** %t73
  %t75 = load i8*, i8** %t73
  call void @star_rc_retain(i8* %t75)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t76 = phi i8* [ %t74, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t76)
  %t77 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t77, i32 %t60, i8* %t76)
  br label %for_step_14
for_step_14:
  %t78 = load i32, i32* %t57
  %t79 = add i32 %t78, 1
  store i32 %t79, i32* %t57
  br label %for_cond_12
for_end_15:
  %t80 = alloca i8*
  %t81 = getelementptr inbounds { i64, i8*, [41 x i8] }, { i64, i8*, [41 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t82 = call i8* @getenv(i8* %t81)
  %t83 = icmp eq i8* %t82, null
  br i1 %t83, label %env_get_null_22, label %env_get_real_23
env_get_null_22:
  %t84 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t84
  br label %env_get_end_24
env_get_real_23:
  %t85 = call i32 @strlen(i8* %t82)
  %t86 = add i32 %t85, 1
  %t87 = sext i32 %t86 to i64
  %t88 = call i8* @star_rc_alloc(i64 %t87, i8* null)
  call i8* @strcpy(i8* %t88, i8* %t82)
  br label %env_get_end_24
env_get_end_24:
  %t89 = phi i8* [ %t84, %env_get_null_22 ], [ %t88, %env_get_real_23 ]
  store i8* %t89, i8** %t80
  %t90 = load i8*, i8** %t80
  %t91 = load i8*, i8** %t80
  call void @star_rc_retain(i8* %t91)
  call void @star_rc_release(i8* %t90)
  %t92 = call i32 @strlen(i8* %t90)
  %t93 = icmp eq i32 %t92, 0
  %t94 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t95 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t96 = select i1 %t93, i8* %t94, i8* %t95
  %t97 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t97, i8* %t96)
  %t98 = alloca i1
  %t99 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t100 = getelementptr inbounds { i64, i8*, [16 x i8] }, { i64, i8*, [16 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t101 = call i32 @strlen(i8* %t99)
  %t102 = call i32 @strlen(i8* %t100)
  %t103 = add i32 %t101, %t102
  %t104 = add i32 %t103, 2
  %t105 = sext i32 %t104 to i64
  %t106 = call i8* @malloc(i64 %t105)
  call i8* @strcpy(i8* %t106, i8* %t99)
  %t107 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i8* @strcat(i8* %t106, i8* %t107)
  call i8* @strcat(i8* %t106, i8* %t100)
  %t108 = call i32 @_putenv(i8* %t106)
  call void @free(i8* %t106)
  %t109 = icmp eq i32 %t108, 0
  store i1 %t109, i1* %t98
  %t110 = load i1, i1* %t98
  %t111 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t112 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t113 = select i1 %t110, i8* %t111, i8* %t112
  %t114 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t114, i8* %t113)
  %t115 = alloca i8*
  %t116 = getelementptr inbounds { i64, i8*, [28 x i8] }, { i64, i8*, [28 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t117 = call i8* @getenv(i8* %t116)
  %t118 = icmp eq i8* %t117, null
  br i1 %t118, label %env_get_null_25, label %env_get_real_26
env_get_null_25:
  %t119 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t119
  br label %env_get_end_27
env_get_real_26:
  %t120 = call i32 @strlen(i8* %t117)
  %t121 = add i32 %t120, 1
  %t122 = sext i32 %t121 to i64
  %t123 = call i8* @star_rc_alloc(i64 %t122, i8* null)
  call i8* @strcpy(i8* %t123, i8* %t117)
  br label %env_get_end_27
env_get_end_27:
  %t124 = phi i8* [ %t119, %env_get_null_25 ], [ %t123, %env_get_real_26 ]
  store i8* %t124, i8** %t115
  %t125 = load i8*, i8** %t115
  %t126 = load i8*, i8** %t115
  call void @star_rc_retain(i8* %t126)
  call void @star_rc_release(i8* %t125)
  %t127 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t127, i8* %t125)
  %t128 = load i8*, i8** %t115
  call void @star_rc_release(i8* %t128)
  %t129 = load i8*, i8** %t80
  call void @star_rc_release(i8* %t129)
  %t130 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t130)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t18 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t19 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t18, i32 0, i32 0
  %t20 = load i8**, i8*** %t19
  %t21 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t18, i32 0, i32 1
  %t22 = load i64, i64* %t21
  %t23 = alloca i64
  store i64 0, i64* %t23
  br label %list_release_cond_3
list_release_cond_3:
  %t24 = load i64, i64* %t23
  %t25 = icmp slt i64 %t24, %t22
  br i1 %t25, label %list_release_body_4, label %list_release_end_5
list_release_body_4:
  %t26 = getelementptr inbounds i8*, i8** %t20, i64 %t24
  %t27 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t27)
  %t28 = add i64 %t24, 1
  store i64 %t28, i64* %t23
  br label %list_release_cond_3
list_release_end_5:
  %t29 = bitcast i8** %t20 to i8*
  call void @free(i8* %t29)
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
@.str.8 = private unnamed_addr constant [2 x i8] c"=\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [23 x i8] c"env_set succeeded: %s\0A\00"
@.str.12 = private unnamed_addr constant { i64, i8*, [28 x i8] } { i64 -1, i8* null, [28 x i8] c"STAR_OS_SURFACE_EXAMPLE_VAR\00" }
@.str.13 = private unnamed_addr constant [16 x i8] c"round trip: %s\0A\00"
