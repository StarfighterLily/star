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
  %t2 = alloca { i8*, i8* }
  %t13 = alloca %Handler
  %t14 = alloca %Handler
  %t28 = alloca i8*
  %t101 = alloca { i8*, i8* }
  %t103 = alloca { i8*, i8* }
  %t171 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = call { i8*, i8* } @make_greeter(i8* %t3)
  store { i8*, i8* } %t4, { i8*, i8* }* %t2
  %t5 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t6 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t7 = extractvalue { i8*, i8* } %t6, 1
  call void @star_rc_retain(i8* %t7)
  %t8 = extractvalue { i8*, i8* } %t5, 0
  %t9 = extractvalue { i8*, i8* } %t5, 1
  call void @star_rc_release(i8* %t9)
  %t10 = bitcast i8* %t8 to i8* (i8*)*
  %t11 = call i8* %t10(i8* %t9)
  call void @star_rc_release(i8* %t11)
  %t12 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i8* %t11)
  %t15 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t16 = call { i8*, i8* } @make_greeter(i8* %t15)
  %t17 = getelementptr inbounds %Handler, %Handler* %t14, i32 0, i32 0
  store { i8*, i8* } %t16, { i8*, i8* }* %t17
  %t18 = load %Handler, %Handler* %t14
  store %Handler %t18, %Handler* %t13
  %t19 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t20 = load { i8*, i8* }, { i8*, i8* }* %t19
  %t21 = load { i8*, i8* }, { i8*, i8* }* %t19
  %t22 = extractvalue { i8*, i8* } %t21, 1
  call void @star_rc_retain(i8* %t22)
  %t23 = extractvalue { i8*, i8* } %t20, 0
  %t24 = extractvalue { i8*, i8* } %t20, 1
  call void @star_rc_release(i8* %t24)
  %t25 = bitcast i8* %t23 to i8* (i8*)*
  %t26 = call i8* %t25(i8* %t24)
  call void @star_rc_release(i8* %t26)
  %t27 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i8* %t26)
  %t29 = getelementptr { i8*, i8* }, { i8*, i8* }* null, i32 1
  %t30 = ptrtoint { i8*, i8* }* %t29 to i64
  %t31 = mul i64 %t30, 2
  %t32 = call i8* @malloc(i64 %t31)
  %t33 = bitcast i8* %t32 to { i8*, i8* }*
  %t34 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t35 = call { i8*, i8* } @make_greeter(i8* %t34)
  %t36 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t33, i64 0
  store { i8*, i8* } %t35, { i8*, i8* }* %t36
  %t37 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t38 = call { i8*, i8* } @make_greeter(i8* %t37)
  %t39 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t33, i64 1
  store { i8*, i8* } %t38, { i8*, i8* }* %t39
  %t53 = bitcast void (i8*)* @list_release_closure to i8*
  %t54 = call i8* @star_rc_alloc(i64 24, i8* %t53)
  %t55 = bitcast i8* %t54 to { { i8*, i8* }*, i64, i64 }*
  %t56 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t55, i32 0, i32 0
  store { i8*, i8* }* %t33, { i8*, i8* }** %t56
  %t57 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t55, i32 0, i32 1
  store i64 2, i64* %t57
  %t58 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t55, i32 0, i32 2
  store i64 2, i64* %t58
  store i8* %t54, i8** %t28
  %t59 = load i8*, i8** %t28
  %t60 = icmp eq i8* %t59, null
  br i1 %t60, label %list_read_null_5, label %list_read_real_6
list_read_null_5:
  br label %list_read_end_7
list_read_real_6:
  %t61 = bitcast i8* %t59 to { { i8*, i8* }*, i64, i64 }*
  %t62 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t61, i32 0, i32 0
  %t63 = load { i8*, i8* }*, { i8*, i8* }** %t62
  %t64 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t61, i32 0, i32 1
  %t65 = load i64, i64* %t64
  br label %list_read_end_7
list_read_end_7:
  %t66 = phi { i8*, i8* }* [ null, %list_read_null_5 ], [ %t63, %list_read_real_6 ]
  %t67 = phi i64 [ 0, %list_read_null_5 ], [ %t65, %list_read_real_6 ]
  %t68 = sext i32 0 to i64
  %t69 = icmp ult i64 %t68, %t67
  br i1 %t69, label %list_idx_ok_8, label %list_idx_oob_9
list_idx_ok_8:
  %t70 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t66, i64 %t68
  %t71 = load { i8*, i8* }, { i8*, i8* }* %t70
  %t72 = load { i8*, i8* }, { i8*, i8* }* %t70
  %t73 = extractvalue { i8*, i8* } %t72, 1
  call void @star_rc_retain(i8* %t73)
  br label %list_idx_end_10
list_idx_oob_9:
  br label %list_idx_end_10
list_idx_end_10:
  %t74 = phi { i8*, i8* } [ %t71, %list_idx_ok_8 ], [ zeroinitializer, %list_idx_oob_9 ]
  %t75 = extractvalue { i8*, i8* } %t74, 0
  %t76 = extractvalue { i8*, i8* } %t74, 1
  call void @star_rc_release(i8* %t76)
  %t77 = bitcast i8* %t75 to i8* (i8*)*
  %t78 = call i8* %t77(i8* %t76)
  call void @star_rc_release(i8* %t78)
  %t79 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t79, i8* %t78)
  %t80 = load i8*, i8** %t28
  %t81 = icmp eq i8* %t80, null
  br i1 %t81, label %list_read_null_11, label %list_read_real_12
list_read_null_11:
  br label %list_read_end_13
list_read_real_12:
  %t82 = bitcast i8* %t80 to { { i8*, i8* }*, i64, i64 }*
  %t83 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t82, i32 0, i32 0
  %t84 = load { i8*, i8* }*, { i8*, i8* }** %t83
  %t85 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t82, i32 0, i32 1
  %t86 = load i64, i64* %t85
  br label %list_read_end_13
list_read_end_13:
  %t87 = phi { i8*, i8* }* [ null, %list_read_null_11 ], [ %t84, %list_read_real_12 ]
  %t88 = phi i64 [ 0, %list_read_null_11 ], [ %t86, %list_read_real_12 ]
  %t89 = sext i32 1 to i64
  %t90 = icmp ult i64 %t89, %t88
  br i1 %t90, label %list_idx_ok_14, label %list_idx_oob_15
list_idx_ok_14:
  %t91 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t87, i64 %t89
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t91
  %t93 = load { i8*, i8* }, { i8*, i8* }* %t91
  %t94 = extractvalue { i8*, i8* } %t93, 1
  call void @star_rc_retain(i8* %t94)
  br label %list_idx_end_16
list_idx_oob_15:
  br label %list_idx_end_16
list_idx_end_16:
  %t95 = phi { i8*, i8* } [ %t92, %list_idx_ok_14 ], [ zeroinitializer, %list_idx_oob_15 ]
  %t96 = extractvalue { i8*, i8* } %t95, 0
  %t97 = extractvalue { i8*, i8* } %t95, 1
  call void @star_rc_release(i8* %t97)
  %t98 = bitcast i8* %t96 to i8* (i8*)*
  %t99 = call i8* %t98(i8* %t97)
  call void @star_rc_release(i8* %t99)
  %t100 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i8* %t99)
  %t102 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t102, { i8*, i8* }* %t101
  %t126 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* null, i32 1
  %t127 = ptrtoint { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t126 to i64
  %t141 = bitcast void (i8*)* @closure_17_release_env to i8*
  %t142 = call i8* @star_rc_alloc(i64 %t127, i8* %t141)
  %t143 = bitcast i8* %t142 to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t144 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t145 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t146 = extractvalue { i8*, i8* } %t145, 1
  call void @star_rc_retain(i8* %t146)
  %t147 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t143, i32 0, i32 0
  store { i8*, i8* } %t144, { i8*, i8* }* %t147
  %t148 = load %Handler, %Handler* %t13
  %t149 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t150 = load { i8*, i8* }, { i8*, i8* }* %t149
  %t151 = extractvalue { i8*, i8* } %t150, 1
  call void @star_rc_retain(i8* %t151)
  %t152 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t143, i32 0, i32 1
  store %Handler %t148, %Handler* %t152
  %t153 = load i8*, i8** %t28
  %t154 = load i8*, i8** %t28
  call void @star_rc_retain(i8* %t154)
  %t155 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t143, i32 0, i32 2
  store i8* %t153, i8** %t155
  %t156 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t157 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t158 = extractvalue { i8*, i8* } %t157, 1
  call void @star_rc_retain(i8* %t158)
  %t159 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t143, i32 0, i32 3
  store { i8*, i8* } %t156, { i8*, i8* }* %t159
  %t160 = bitcast i32 (i8*, i32)* @closure_17 to i8*
  %t161 = insertvalue { i8*, i8* } undef, i8* %t160, 0
  %t162 = insertvalue { i8*, i8* } %t161, i8* %t142, 1
  store { i8*, i8* } %t162, { i8*, i8* }* %t103
  %t163 = load { i8*, i8* }, { i8*, i8* }* %t103
  %t164 = load { i8*, i8* }, { i8*, i8* }* %t103
  %t165 = extractvalue { i8*, i8* } %t164, 1
  call void @star_rc_retain(i8* %t165)
  %t166 = extractvalue { i8*, i8* } %t163, 0
  %t167 = extractvalue { i8*, i8* } %t163, 1
  call void @star_rc_release(i8* %t167)
  %t168 = bitcast i8* %t166 to i32 (i8*, i32)*
  %t169 = call i32 %t168(i8* %t167, i32 10)
  %t170 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t170, i32 %t169)
  store i32 0, i32* %t171
  br label %while_cond_18
while_cond_18:
  %t172 = load i32, i32* %t171
  %t173 = icmp slt i32 %t172, 3
  br i1 %t173, label %while_body_19, label %while_else_20
while_body_19:
  %t174 = load i32, i32* %t171
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t176 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t177 = extractvalue { i8*, i8* } %t176, 1
  call void @star_rc_retain(i8* %t177)
  %t178 = extractvalue { i8*, i8* } %t175, 0
  %t179 = extractvalue { i8*, i8* } %t175, 1
  call void @star_rc_release(i8* %t179)
  %t180 = bitcast i8* %t178 to i8* (i8*)*
  %t181 = call i8* %t180(i8* %t179)
  call void @star_rc_release(i8* %t181)
  %t182 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t182, i32 %t174, i8* %t181)
  %t183 = load i32, i32* %t171
  %t184 = add i32 %t183, 1
  store i32 %t184, i32* %t171
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t185 = load { i8*, i8* }, { i8*, i8* }* %t103
  %t186 = extractvalue { i8*, i8* } %t185, 1
  call void @star_rc_release(i8* %t186)
  %t187 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t188 = extractvalue { i8*, i8* } %t187, 1
  call void @star_rc_release(i8* %t188)
  %t189 = load i8*, i8** %t28
  call void @star_rc_release(i8* %t189)
  %t190 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t191 = load { i8*, i8* }, { i8*, i8* }* %t190
  %t192 = extractvalue { i8*, i8* } %t191, 1
  call void @star_rc_release(i8* %t192)
  %t193 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t194 = extractvalue { i8*, i8* } %t193, 1
  call void @star_rc_release(i8* %t194)
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
  %t45 = alloca i64
  %t40 = bitcast i8* %objp to { { i8*, i8* }*, i64, i64 }*
  %t41 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t40, i32 0, i32 0
  %t42 = load { i8*, i8* }*, { i8*, i8* }** %t41
  %t43 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t40, i32 0, i32 1
  %t44 = load i64, i64* %t43
  store i64 0, i64* %t45
  br label %list_release_cond_2
list_release_cond_2:
  %t46 = load i64, i64* %t45
  %t47 = icmp slt i64 %t46, %t44
  br i1 %t47, label %list_release_body_3, label %list_release_end_4
list_release_body_3:
  %t48 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t42, i64 %t46
  %t49 = load { i8*, i8* }, { i8*, i8* }* %t48
  %t50 = extractvalue { i8*, i8* } %t49, 1
  call void @star_rc_release(i8* %t50)
  %t51 = add i64 %t46, 1
  store i64 %t51, i64* %t45
  br label %list_release_cond_2
list_release_end_4:
  %t52 = bitcast { i8*, i8* }* %t42 to i8*
  call void @free(i8* %t52)
  ret void
}


define i32 @closure_17(i8* %envp, i32 %arg_x) {
entry:
  %t107 = alloca { i8*, i8* }
  %t110 = alloca %Handler
  %t113 = alloca i8*
  %t116 = alloca { i8*, i8* }
  %t117 = alloca i32
  %t104 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t105 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t104, i32 0, i32 0
  %t106 = load { i8*, i8* }, { i8*, i8* }* %t105
  store { i8*, i8* } %t106, { i8*, i8* }* %t107
  %t108 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t104, i32 0, i32 1
  %t109 = load %Handler, %Handler* %t108
  store %Handler %t109, %Handler* %t110
  %t111 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t104, i32 0, i32 2
  %t112 = load i8*, i8** %t111
  store i8* %t112, i8** %t113
  %t114 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t104, i32 0, i32 3
  %t115 = load { i8*, i8* }, { i8*, i8* }* %t114
  store { i8*, i8* } %t115, { i8*, i8* }* %t116
  store i32 %arg_x, i32* %t117
  %t118 = load { i8*, i8* }, { i8*, i8* }* %t116
  %t119 = load { i8*, i8* }, { i8*, i8* }* %t116
  %t120 = extractvalue { i8*, i8* } %t119, 1
  call void @star_rc_retain(i8* %t120)
  %t121 = extractvalue { i8*, i8* } %t118, 0
  %t122 = extractvalue { i8*, i8* } %t118, 1
  call void @star_rc_release(i8* %t122)
  %t123 = bitcast i8* %t121 to i32 (i8*, i32)*
  %t124 = load i32, i32* %t117
  %t125 = call i32 %t123(i8* %t122, i32 %t124)
  ret i32 %t125
}


define void @closure_17_release_env(i8* %envp) {
entry:
  %t128 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t129 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t128, i32 0, i32 0
  %t130 = load { i8*, i8* }, { i8*, i8* }* %t129
  %t131 = extractvalue { i8*, i8* } %t130, 1
  call void @star_rc_release(i8* %t131)
  %t132 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t128, i32 0, i32 1
  %t133 = getelementptr inbounds %Handler, %Handler* %t132, i32 0, i32 0
  %t134 = load { i8*, i8* }, { i8*, i8* }* %t133
  %t135 = extractvalue { i8*, i8* } %t134, 1
  call void @star_rc_release(i8* %t135)
  %t136 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t128, i32 0, i32 2
  %t137 = load i8*, i8** %t136
  call void @star_rc_release(i8* %t137)
  %t138 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t128, i32 0, i32 3
  %t139 = load { i8*, i8* }, { i8*, i8* }* %t138
  %t140 = extractvalue { i8*, i8* } %t139, 1
  call void @star_rc_release(i8* %t140)
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
