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

%Handler = type { { i8*, i8* } }
define { i8*, i8* } @make_greeter(i8* %name) {
entry:
  %t0 = alloca i8*
  store i8* %name, i8** %t0
  %t7 = getelementptr inbounds { i8* }, { i8* }* null, i32 1
  %t8 = ptrtoint { i8* }* %t7 to i64
  %t12 = bitcast void (i8*)* @closure_0_release_env to i8*
  %t13 = call i8* @star_rc_alloc(i64 %t8, i8* %t12)
  %t14 = bitcast i8* %t13 to { i8* }*
  %t15 = load i8*, i8** %t0
  %t16 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t16)
  %t17 = getelementptr inbounds { i8* }, { i8* }* %t14, i32 0, i32 0
  store i8* %t15, i8** %t17
  %t18 = bitcast i8* (i8*)* @closure_0 to i8*
  %t19 = insertvalue { i8*, i8* } undef, i8* %t18, 0
  %t20 = insertvalue { i8*, i8* } %t19, i8* %t13, 1
  %t21 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t21)
  ret { i8*, i8* } %t20
}

define { i8*, i8* } @make_adder(i32 %base) {
entry:
  %t0 = alloca i32
  store i32 %base, i32* %t0
  %t9 = getelementptr inbounds { i32 }, { i32 }* null, i32 1
  %t10 = ptrtoint { i32 }* %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  %t12 = bitcast i8* %t11 to { i32 }*
  %t13 = load i32, i32* %t0
  %t14 = getelementptr inbounds { i32 }, { i32 }* %t12, i32 0, i32 0
  store i32 %t13, i32* %t14
  %t15 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t16 = insertvalue { i8*, i8* } undef, i8* %t15, 0
  %t17 = insertvalue { i8*, i8* } %t16, i8* %t11, 1
  ret { i8*, i8* } %t17
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca { i8*, i8* }
  %t12 = alloca %Handler
  %t13 = alloca %Handler
  %t27 = alloca i8*
  %t100 = alloca { i8*, i8* }
  %t102 = alloca { i8*, i8* }
  %t170 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t3 = call { i8*, i8* } @make_greeter(i8* %t2)
  store { i8*, i8* } %t3, { i8*, i8* }* %t1
  %t4 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t5 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t6 = extractvalue { i8*, i8* } %t5, 1
  call void @star_rc_retain(i8* %t6)
  %t7 = extractvalue { i8*, i8* } %t4, 0
  %t8 = extractvalue { i8*, i8* } %t4, 1
  call void @star_rc_release(i8* %t8)
  %t9 = bitcast i8* %t7 to i8* (i8*)*
  %t10 = call i8* %t9(i8* %t8)
  call void @star_rc_release(i8* %t10)
  %t11 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i8* %t10)
  %t14 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t15 = call { i8*, i8* } @make_greeter(i8* %t14)
  %t16 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  store { i8*, i8* } %t15, { i8*, i8* }* %t16
  %t17 = load %Handler, %Handler* %t13
  store %Handler %t17, %Handler* %t12
  %t18 = getelementptr inbounds %Handler, %Handler* %t12, i32 0, i32 0
  %t19 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t20 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t21 = extractvalue { i8*, i8* } %t20, 1
  call void @star_rc_retain(i8* %t21)
  %t22 = extractvalue { i8*, i8* } %t19, 0
  %t23 = extractvalue { i8*, i8* } %t19, 1
  call void @star_rc_release(i8* %t23)
  %t24 = bitcast i8* %t22 to i8* (i8*)*
  %t25 = call i8* %t24(i8* %t23)
  call void @star_rc_release(i8* %t25)
  %t26 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t26, i8* %t25)
  %t28 = getelementptr { i8*, i8* }, { i8*, i8* }* null, i32 1
  %t29 = ptrtoint { i8*, i8* }* %t28 to i64
  %t30 = mul i64 %t29, 2
  %t31 = call i8* @malloc(i64 %t30)
  %t32 = bitcast i8* %t31 to { i8*, i8* }*
  %t33 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t34 = call { i8*, i8* } @make_greeter(i8* %t33)
  %t35 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t32, i64 0
  store { i8*, i8* } %t34, { i8*, i8* }* %t35
  %t36 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t37 = call { i8*, i8* } @make_greeter(i8* %t36)
  %t38 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t32, i64 1
  store { i8*, i8* } %t37, { i8*, i8* }* %t38
  %t52 = bitcast void (i8*)* @list_release_closure to i8*
  %t53 = call i8* @star_rc_alloc(i64 24, i8* %t52)
  %t54 = bitcast i8* %t53 to { { i8*, i8* }*, i64, i64 }*
  %t55 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t54, i32 0, i32 0
  store { i8*, i8* }* %t32, { i8*, i8* }** %t55
  %t56 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t54, i32 0, i32 1
  store i64 2, i64* %t56
  %t57 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t54, i32 0, i32 2
  store i64 2, i64* %t57
  store i8* %t53, i8** %t27
  %t58 = load i8*, i8** %t27
  %t59 = icmp eq i8* %t58, null
  br i1 %t59, label %list_read_null_5, label %list_read_real_6
list_read_null_5:
  br label %list_read_end_7
list_read_real_6:
  %t60 = bitcast i8* %t58 to { { i8*, i8* }*, i64, i64 }*
  %t61 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t60, i32 0, i32 0
  %t62 = load { i8*, i8* }*, { i8*, i8* }** %t61
  %t63 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t60, i32 0, i32 1
  %t64 = load i64, i64* %t63
  br label %list_read_end_7
list_read_end_7:
  %t65 = phi { i8*, i8* }* [ null, %list_read_null_5 ], [ %t62, %list_read_real_6 ]
  %t66 = phi i64 [ 0, %list_read_null_5 ], [ %t64, %list_read_real_6 ]
  %t67 = sext i32 0 to i64
  %t68 = icmp ult i64 %t67, %t66
  br i1 %t68, label %list_idx_ok_8, label %list_idx_oob_9
list_idx_ok_8:
  %t69 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t65, i64 %t67
  %t70 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t71 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t72 = extractvalue { i8*, i8* } %t71, 1
  call void @star_rc_retain(i8* %t72)
  br label %list_idx_end_10
list_idx_oob_9:
  br label %list_idx_end_10
list_idx_end_10:
  %t73 = phi { i8*, i8* } [ %t70, %list_idx_ok_8 ], [ zeroinitializer, %list_idx_oob_9 ]
  %t74 = extractvalue { i8*, i8* } %t73, 0
  %t75 = extractvalue { i8*, i8* } %t73, 1
  call void @star_rc_release(i8* %t75)
  %t76 = bitcast i8* %t74 to i8* (i8*)*
  %t77 = call i8* %t76(i8* %t75)
  call void @star_rc_release(i8* %t77)
  %t78 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t78, i8* %t77)
  %t79 = load i8*, i8** %t27
  %t80 = icmp eq i8* %t79, null
  br i1 %t80, label %list_read_null_11, label %list_read_real_12
list_read_null_11:
  br label %list_read_end_13
list_read_real_12:
  %t81 = bitcast i8* %t79 to { { i8*, i8* }*, i64, i64 }*
  %t82 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t81, i32 0, i32 0
  %t83 = load { i8*, i8* }*, { i8*, i8* }** %t82
  %t84 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t81, i32 0, i32 1
  %t85 = load i64, i64* %t84
  br label %list_read_end_13
list_read_end_13:
  %t86 = phi { i8*, i8* }* [ null, %list_read_null_11 ], [ %t83, %list_read_real_12 ]
  %t87 = phi i64 [ 0, %list_read_null_11 ], [ %t85, %list_read_real_12 ]
  %t88 = sext i32 1 to i64
  %t89 = icmp ult i64 %t88, %t87
  br i1 %t89, label %list_idx_ok_14, label %list_idx_oob_15
list_idx_ok_14:
  %t90 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t86, i64 %t88
  %t91 = load { i8*, i8* }, { i8*, i8* }* %t90
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t90
  %t93 = extractvalue { i8*, i8* } %t92, 1
  call void @star_rc_retain(i8* %t93)
  br label %list_idx_end_16
list_idx_oob_15:
  br label %list_idx_end_16
list_idx_end_16:
  %t94 = phi { i8*, i8* } [ %t91, %list_idx_ok_14 ], [ zeroinitializer, %list_idx_oob_15 ]
  %t95 = extractvalue { i8*, i8* } %t94, 0
  %t96 = extractvalue { i8*, i8* } %t94, 1
  call void @star_rc_release(i8* %t96)
  %t97 = bitcast i8* %t95 to i8* (i8*)*
  %t98 = call i8* %t97(i8* %t96)
  call void @star_rc_release(i8* %t98)
  %t99 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t99, i8* %t98)
  %t101 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t101, { i8*, i8* }* %t100
  %t125 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* null, i32 1
  %t126 = ptrtoint { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t125 to i64
  %t140 = bitcast void (i8*)* @closure_17_release_env to i8*
  %t141 = call i8* @star_rc_alloc(i64 %t126, i8* %t140)
  %t142 = bitcast i8* %t141 to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t143 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t144 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t145 = extractvalue { i8*, i8* } %t144, 1
  call void @star_rc_retain(i8* %t145)
  %t146 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t142, i32 0, i32 0
  store { i8*, i8* } %t143, { i8*, i8* }* %t146
  %t147 = load %Handler, %Handler* %t12
  %t148 = getelementptr inbounds %Handler, %Handler* %t12, i32 0, i32 0
  %t149 = load { i8*, i8* }, { i8*, i8* }* %t148
  %t150 = extractvalue { i8*, i8* } %t149, 1
  call void @star_rc_retain(i8* %t150)
  %t151 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t142, i32 0, i32 1
  store %Handler %t147, %Handler* %t151
  %t152 = load i8*, i8** %t27
  %t153 = load i8*, i8** %t27
  call void @star_rc_retain(i8* %t153)
  %t154 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t142, i32 0, i32 2
  store i8* %t152, i8** %t154
  %t155 = load { i8*, i8* }, { i8*, i8* }* %t100
  %t156 = load { i8*, i8* }, { i8*, i8* }* %t100
  %t157 = extractvalue { i8*, i8* } %t156, 1
  call void @star_rc_retain(i8* %t157)
  %t158 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t142, i32 0, i32 3
  store { i8*, i8* } %t155, { i8*, i8* }* %t158
  %t159 = bitcast i32 (i8*, i32)* @closure_17 to i8*
  %t160 = insertvalue { i8*, i8* } undef, i8* %t159, 0
  %t161 = insertvalue { i8*, i8* } %t160, i8* %t141, 1
  store { i8*, i8* } %t161, { i8*, i8* }* %t102
  %t162 = load { i8*, i8* }, { i8*, i8* }* %t102
  %t163 = load { i8*, i8* }, { i8*, i8* }* %t102
  %t164 = extractvalue { i8*, i8* } %t163, 1
  call void @star_rc_retain(i8* %t164)
  %t165 = extractvalue { i8*, i8* } %t162, 0
  %t166 = extractvalue { i8*, i8* } %t162, 1
  call void @star_rc_release(i8* %t166)
  %t167 = bitcast i8* %t165 to i32 (i8*, i32)*
  %t168 = call i32 %t167(i8* %t166, i32 10)
  %t169 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i32 %t168)
  store i32 0, i32* %t170
  br label %while_cond_18
while_cond_18:
  %t171 = load i32, i32* %t170
  %t172 = icmp slt i32 %t171, 3
  br i1 %t172, label %while_body_19, label %while_else_20
while_body_19:
  %t173 = load i32, i32* %t170
  %t174 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t176 = extractvalue { i8*, i8* } %t175, 1
  call void @star_rc_retain(i8* %t176)
  %t177 = extractvalue { i8*, i8* } %t174, 0
  %t178 = extractvalue { i8*, i8* } %t174, 1
  call void @star_rc_release(i8* %t178)
  %t179 = bitcast i8* %t177 to i8* (i8*)*
  %t180 = call i8* %t179(i8* %t178)
  call void @star_rc_release(i8* %t180)
  %t181 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t181, i32 %t173, i8* %t180)
  %t182 = load i32, i32* %t170
  %t183 = add i32 %t182, 1
  store i32 %t183, i32* %t170
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t184 = load { i8*, i8* }, { i8*, i8* }* %t102
  %t185 = extractvalue { i8*, i8* } %t184, 1
  call void @star_rc_release(i8* %t185)
  %t186 = load { i8*, i8* }, { i8*, i8* }* %t100
  %t187 = extractvalue { i8*, i8* } %t186, 1
  call void @star_rc_release(i8* %t187)
  %t188 = load i8*, i8** %t27
  call void @star_rc_release(i8* %t188)
  %t189 = getelementptr inbounds %Handler, %Handler* %t12, i32 0, i32 0
  %t190 = load { i8*, i8* }, { i8*, i8* }* %t189
  %t191 = extractvalue { i8*, i8* } %t190, 1
  call void @star_rc_release(i8* %t191)
  %t192 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t193 = extractvalue { i8*, i8* } %t192, 1
  call void @star_rc_release(i8* %t193)
  ret i32 0
}


; par/swarm worker functions
define i8* @closure_0(i8* %envp) {
entry:
  %t4 = alloca i8*
  %t1 = bitcast i8* %envp to { i8* }*
  %t2 = getelementptr inbounds { i8* }, { i8* }* %t1, i32 0, i32 0
  %t3 = load i8*, i8** %t2
  store i8* %t3, i8** %t4
  %t5 = load i8*, i8** %t4
  %t6 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t6)
  ret i8* %t5
}


define void @closure_0_release_env(i8* %envp) {
entry:
  %t9 = bitcast i8* %envp to { i8* }*
  %t10 = getelementptr inbounds { i8* }, { i8* }* %t9, i32 0, i32 0
  %t11 = load i8*, i8** %t10
  call void @star_rc_release(i8* %t11)
  ret void
}


define i32 @closure_1(i8* %envp, i32 %arg_x) {
entry:
  %t4 = alloca i32
  %t5 = alloca i32
  %t1 = bitcast i8* %envp to { i32 }*
  %t2 = getelementptr inbounds { i32 }, { i32 }* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  store i32 %t3, i32* %t4
  store i32 %arg_x, i32* %t5
  %t6 = load i32, i32* %t5
  %t7 = load i32, i32* %t4
  %t8 = add i32 %t6, %t7
  ret i32 %t8
}


define void @list_release_closure(i8* %objp) {
entry:
  %t44 = alloca i64
  %t39 = bitcast i8* %objp to { { i8*, i8* }*, i64, i64 }*
  %t40 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t39, i32 0, i32 0
  %t41 = load { i8*, i8* }*, { i8*, i8* }** %t40
  %t42 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t39, i32 0, i32 1
  %t43 = load i64, i64* %t42
  store i64 0, i64* %t44
  br label %list_release_cond_2
list_release_cond_2:
  %t45 = load i64, i64* %t44
  %t46 = icmp slt i64 %t45, %t43
  br i1 %t46, label %list_release_body_3, label %list_release_end_4
list_release_body_3:
  %t47 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t41, i64 %t45
  %t48 = load { i8*, i8* }, { i8*, i8* }* %t47
  %t49 = extractvalue { i8*, i8* } %t48, 1
  call void @star_rc_release(i8* %t49)
  %t50 = add i64 %t45, 1
  store i64 %t50, i64* %t44
  br label %list_release_cond_2
list_release_end_4:
  %t51 = bitcast { i8*, i8* }* %t41 to i8*
  call void @free(i8* %t51)
  ret void
}


define i32 @closure_17(i8* %envp, i32 %arg_x) {
entry:
  %t106 = alloca { i8*, i8* }
  %t109 = alloca %Handler
  %t112 = alloca i8*
  %t115 = alloca { i8*, i8* }
  %t116 = alloca i32
  %t103 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t104 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t103, i32 0, i32 0
  %t105 = load { i8*, i8* }, { i8*, i8* }* %t104
  store { i8*, i8* } %t105, { i8*, i8* }* %t106
  %t107 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t103, i32 0, i32 1
  %t108 = load %Handler, %Handler* %t107
  store %Handler %t108, %Handler* %t109
  %t110 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t103, i32 0, i32 2
  %t111 = load i8*, i8** %t110
  store i8* %t111, i8** %t112
  %t113 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t103, i32 0, i32 3
  %t114 = load { i8*, i8* }, { i8*, i8* }* %t113
  store { i8*, i8* } %t114, { i8*, i8* }* %t115
  store i32 %arg_x, i32* %t116
  %t117 = load { i8*, i8* }, { i8*, i8* }* %t115
  %t118 = load { i8*, i8* }, { i8*, i8* }* %t115
  %t119 = extractvalue { i8*, i8* } %t118, 1
  call void @star_rc_retain(i8* %t119)
  %t120 = extractvalue { i8*, i8* } %t117, 0
  %t121 = extractvalue { i8*, i8* } %t117, 1
  call void @star_rc_release(i8* %t121)
  %t122 = bitcast i8* %t120 to i32 (i8*, i32)*
  %t123 = load i32, i32* %t116
  %t124 = call i32 %t122(i8* %t121, i32 %t123)
  ret i32 %t124
}


define void @closure_17_release_env(i8* %envp) {
entry:
  %t127 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t128 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t127, i32 0, i32 0
  %t129 = load { i8*, i8* }, { i8*, i8* }* %t128
  %t130 = extractvalue { i8*, i8* } %t129, 1
  call void @star_rc_release(i8* %t130)
  %t131 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t127, i32 0, i32 1
  %t132 = getelementptr inbounds %Handler, %Handler* %t131, i32 0, i32 0
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t132
  %t134 = extractvalue { i8*, i8* } %t133, 1
  call void @star_rc_release(i8* %t134)
  %t135 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t127, i32 0, i32 2
  %t136 = load i8*, i8** %t135
  call void @star_rc_release(i8* %t136)
  %t137 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t127, i32 0, i32 3
  %t138 = load { i8*, i8* }, { i8*, i8* }* %t137
  %t139 = extractvalue { i8*, i8* } %t138, 1
  call void @star_rc_release(i8* %t139)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Alice\00" }
@.str.1 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"Bob\00" }
@.str.3 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Carol\00" }
@.str.5 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Dave\00" }
@.str.6 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.7 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"apply_add5(10) = %d\0A\00"
@.str.9 = private unnamed_addr constant [13 x i8] c"tick %d: %s\0A\00"
