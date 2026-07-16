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
  %t0 = alloca { i8*, i8* }
  %t11 = alloca %Handler
  %t12 = alloca %Handler
  %t26 = alloca i8*
  %t99 = alloca { i8*, i8* }
  %t101 = alloca { i8*, i8* }
  %t169 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = call { i8*, i8* } @make_greeter(i8* %t1)
  store { i8*, i8* } %t2, { i8*, i8* }* %t0
  %t3 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t4 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t5 = extractvalue { i8*, i8* } %t4, 1
  call void @star_rc_retain(i8* %t5)
  %t6 = extractvalue { i8*, i8* } %t3, 0
  %t7 = extractvalue { i8*, i8* } %t3, 1
  call void @star_rc_release(i8* %t7)
  %t8 = bitcast i8* %t6 to i8* (i8*)*
  %t9 = call i8* %t8(i8* %t7)
  %t10 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i8* %t9)
  %t13 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t14 = call { i8*, i8* } @make_greeter(i8* %t13)
  %t15 = getelementptr inbounds %Handler, %Handler* %t12, i32 0, i32 0
  store { i8*, i8* } %t14, { i8*, i8* }* %t15
  %t16 = load %Handler, %Handler* %t12
  store %Handler %t16, %Handler* %t11
  %t17 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t18 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t19 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t20 = extractvalue { i8*, i8* } %t19, 1
  call void @star_rc_retain(i8* %t20)
  %t21 = extractvalue { i8*, i8* } %t18, 0
  %t22 = extractvalue { i8*, i8* } %t18, 1
  call void @star_rc_release(i8* %t22)
  %t23 = bitcast i8* %t21 to i8* (i8*)*
  %t24 = call i8* %t23(i8* %t22)
  %t25 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i8* %t24)
  %t27 = getelementptr { i8*, i8* }, { i8*, i8* }* null, i32 1
  %t28 = ptrtoint { i8*, i8* }* %t27 to i64
  %t29 = mul i64 %t28, 2
  %t30 = call i8* @malloc(i64 %t29)
  %t31 = bitcast i8* %t30 to { i8*, i8* }*
  %t32 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t33 = call { i8*, i8* } @make_greeter(i8* %t32)
  %t34 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t31, i64 0
  store { i8*, i8* } %t33, { i8*, i8* }* %t34
  %t35 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t36 = call { i8*, i8* } @make_greeter(i8* %t35)
  %t37 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t31, i64 1
  store { i8*, i8* } %t36, { i8*, i8* }* %t37
  %t51 = bitcast void (i8*)* @list_release_closure to i8*
  %t52 = call i8* @star_rc_alloc(i64 24, i8* %t51)
  %t53 = bitcast i8* %t52 to { { i8*, i8* }*, i64, i64 }*
  %t54 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t53, i32 0, i32 0
  store { i8*, i8* }* %t31, { i8*, i8* }** %t54
  %t55 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t53, i32 0, i32 1
  store i64 2, i64* %t55
  %t56 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t53, i32 0, i32 2
  store i64 2, i64* %t56
  store i8* %t52, i8** %t26
  %t57 = load i8*, i8** %t26
  %t58 = icmp eq i8* %t57, null
  br i1 %t58, label %list_read_null_5, label %list_read_real_6
list_read_null_5:
  br label %list_read_end_7
list_read_real_6:
  %t59 = bitcast i8* %t57 to { { i8*, i8* }*, i64, i64 }*
  %t60 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t59, i32 0, i32 0
  %t61 = load { i8*, i8* }*, { i8*, i8* }** %t60
  %t62 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t59, i32 0, i32 1
  %t63 = load i64, i64* %t62
  br label %list_read_end_7
list_read_end_7:
  %t64 = phi { i8*, i8* }* [ null, %list_read_null_5 ], [ %t61, %list_read_real_6 ]
  %t65 = phi i64 [ 0, %list_read_null_5 ], [ %t63, %list_read_real_6 ]
  %t66 = sext i32 0 to i64
  %t67 = icmp ult i64 %t66, %t65
  br i1 %t67, label %list_idx_ok_8, label %list_idx_oob_9
list_idx_ok_8:
  %t68 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t64, i64 %t66
  %t69 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t70 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t71 = extractvalue { i8*, i8* } %t70, 1
  call void @star_rc_retain(i8* %t71)
  br label %list_idx_end_10
list_idx_oob_9:
  br label %list_idx_end_10
list_idx_end_10:
  %t72 = phi { i8*, i8* } [ %t69, %list_idx_ok_8 ], [ zeroinitializer, %list_idx_oob_9 ]
  %t73 = extractvalue { i8*, i8* } %t72, 0
  %t74 = extractvalue { i8*, i8* } %t72, 1
  call void @star_rc_release(i8* %t74)
  %t75 = bitcast i8* %t73 to i8* (i8*)*
  %t76 = call i8* %t75(i8* %t74)
  %t77 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t77, i8* %t76)
  %t78 = load i8*, i8** %t26
  %t79 = icmp eq i8* %t78, null
  br i1 %t79, label %list_read_null_11, label %list_read_real_12
list_read_null_11:
  br label %list_read_end_13
list_read_real_12:
  %t80 = bitcast i8* %t78 to { { i8*, i8* }*, i64, i64 }*
  %t81 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t80, i32 0, i32 0
  %t82 = load { i8*, i8* }*, { i8*, i8* }** %t81
  %t83 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t80, i32 0, i32 1
  %t84 = load i64, i64* %t83
  br label %list_read_end_13
list_read_end_13:
  %t85 = phi { i8*, i8* }* [ null, %list_read_null_11 ], [ %t82, %list_read_real_12 ]
  %t86 = phi i64 [ 0, %list_read_null_11 ], [ %t84, %list_read_real_12 ]
  %t87 = sext i32 1 to i64
  %t88 = icmp ult i64 %t87, %t86
  br i1 %t88, label %list_idx_ok_14, label %list_idx_oob_15
list_idx_ok_14:
  %t89 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t85, i64 %t87
  %t90 = load { i8*, i8* }, { i8*, i8* }* %t89
  %t91 = load { i8*, i8* }, { i8*, i8* }* %t89
  %t92 = extractvalue { i8*, i8* } %t91, 1
  call void @star_rc_retain(i8* %t92)
  br label %list_idx_end_16
list_idx_oob_15:
  br label %list_idx_end_16
list_idx_end_16:
  %t93 = phi { i8*, i8* } [ %t90, %list_idx_ok_14 ], [ zeroinitializer, %list_idx_oob_15 ]
  %t94 = extractvalue { i8*, i8* } %t93, 0
  %t95 = extractvalue { i8*, i8* } %t93, 1
  call void @star_rc_release(i8* %t95)
  %t96 = bitcast i8* %t94 to i8* (i8*)*
  %t97 = call i8* %t96(i8* %t95)
  %t98 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t98, i8* %t97)
  %t100 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t100, { i8*, i8* }* %t99
  %t124 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* null, i32 1
  %t125 = ptrtoint { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t124 to i64
  %t139 = bitcast void (i8*)* @closure_17_release_env to i8*
  %t140 = call i8* @star_rc_alloc(i64 %t125, i8* %t139)
  %t141 = bitcast i8* %t140 to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t142 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t143 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t144 = extractvalue { i8*, i8* } %t143, 1
  call void @star_rc_retain(i8* %t144)
  %t145 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t141, i32 0, i32 0
  store { i8*, i8* } %t142, { i8*, i8* }* %t145
  %t146 = load %Handler, %Handler* %t11
  %t147 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t148 = load { i8*, i8* }, { i8*, i8* }* %t147
  %t149 = extractvalue { i8*, i8* } %t148, 1
  call void @star_rc_retain(i8* %t149)
  %t150 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t141, i32 0, i32 1
  store %Handler %t146, %Handler* %t150
  %t151 = load i8*, i8** %t26
  %t152 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t152)
  %t153 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t141, i32 0, i32 2
  store i8* %t151, i8** %t153
  %t154 = load { i8*, i8* }, { i8*, i8* }* %t99
  %t155 = load { i8*, i8* }, { i8*, i8* }* %t99
  %t156 = extractvalue { i8*, i8* } %t155, 1
  call void @star_rc_retain(i8* %t156)
  %t157 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t141, i32 0, i32 3
  store { i8*, i8* } %t154, { i8*, i8* }* %t157
  %t158 = bitcast i32 (i8*, i32)* @closure_17 to i8*
  %t159 = insertvalue { i8*, i8* } undef, i8* %t158, 0
  %t160 = insertvalue { i8*, i8* } %t159, i8* %t140, 1
  store { i8*, i8* } %t160, { i8*, i8* }* %t101
  %t161 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t162 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t163 = extractvalue { i8*, i8* } %t162, 1
  call void @star_rc_retain(i8* %t163)
  %t164 = extractvalue { i8*, i8* } %t161, 0
  %t165 = extractvalue { i8*, i8* } %t161, 1
  call void @star_rc_release(i8* %t165)
  %t166 = bitcast i8* %t164 to i32 (i8*, i32)*
  %t167 = call i32 %t166(i8* %t165, i32 10)
  %t168 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t168, i32 %t167)
  store i32 0, i32* %t169
  br label %while_cond_18
while_cond_18:
  %t170 = load i32, i32* %t169
  %t171 = icmp slt i32 %t170, 3
  br i1 %t171, label %while_body_19, label %while_else_20
while_body_19:
  %t172 = load i32, i32* %t169
  %t173 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t174 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t175 = extractvalue { i8*, i8* } %t174, 1
  call void @star_rc_retain(i8* %t175)
  %t176 = extractvalue { i8*, i8* } %t173, 0
  %t177 = extractvalue { i8*, i8* } %t173, 1
  call void @star_rc_release(i8* %t177)
  %t178 = bitcast i8* %t176 to i8* (i8*)*
  %t179 = call i8* %t178(i8* %t177)
  %t180 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t180, i32 %t172, i8* %t179)
  %t181 = load i32, i32* %t169
  %t182 = add i32 %t181, 1
  store i32 %t182, i32* %t169
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t183 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t184 = extractvalue { i8*, i8* } %t183, 1
  call void @star_rc_release(i8* %t184)
  %t185 = load { i8*, i8* }, { i8*, i8* }* %t99
  %t186 = extractvalue { i8*, i8* } %t185, 1
  call void @star_rc_release(i8* %t186)
  %t187 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t187)
  %t188 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t189 = load { i8*, i8* }, { i8*, i8* }* %t188
  %t190 = extractvalue { i8*, i8* } %t189, 1
  call void @star_rc_release(i8* %t190)
  %t191 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t192 = extractvalue { i8*, i8* } %t191, 1
  call void @star_rc_release(i8* %t192)
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
  %t43 = alloca i64
  %t38 = bitcast i8* %objp to { { i8*, i8* }*, i64, i64 }*
  %t39 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t38, i32 0, i32 0
  %t40 = load { i8*, i8* }*, { i8*, i8* }** %t39
  %t41 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t38, i32 0, i32 1
  %t42 = load i64, i64* %t41
  store i64 0, i64* %t43
  br label %list_release_cond_2
list_release_cond_2:
  %t44 = load i64, i64* %t43
  %t45 = icmp slt i64 %t44, %t42
  br i1 %t45, label %list_release_body_3, label %list_release_end_4
list_release_body_3:
  %t46 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t40, i64 %t44
  %t47 = load { i8*, i8* }, { i8*, i8* }* %t46
  %t48 = extractvalue { i8*, i8* } %t47, 1
  call void @star_rc_release(i8* %t48)
  %t49 = add i64 %t44, 1
  store i64 %t49, i64* %t43
  br label %list_release_cond_2
list_release_end_4:
  %t50 = bitcast { i8*, i8* }* %t40 to i8*
  call void @free(i8* %t50)
  ret void
}


define i32 @closure_17(i8* %envp, i32 %arg_x) {
entry:
  %t105 = alloca { i8*, i8* }
  %t108 = alloca %Handler
  %t111 = alloca i8*
  %t114 = alloca { i8*, i8* }
  %t115 = alloca i32
  %t102 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t103 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t102, i32 0, i32 0
  %t104 = load { i8*, i8* }, { i8*, i8* }* %t103
  store { i8*, i8* } %t104, { i8*, i8* }* %t105
  %t106 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t102, i32 0, i32 1
  %t107 = load %Handler, %Handler* %t106
  store %Handler %t107, %Handler* %t108
  %t109 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t102, i32 0, i32 2
  %t110 = load i8*, i8** %t109
  store i8* %t110, i8** %t111
  %t112 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t102, i32 0, i32 3
  %t113 = load { i8*, i8* }, { i8*, i8* }* %t112
  store { i8*, i8* } %t113, { i8*, i8* }* %t114
  store i32 %arg_x, i32* %t115
  %t116 = load { i8*, i8* }, { i8*, i8* }* %t114
  %t117 = load { i8*, i8* }, { i8*, i8* }* %t114
  %t118 = extractvalue { i8*, i8* } %t117, 1
  call void @star_rc_retain(i8* %t118)
  %t119 = extractvalue { i8*, i8* } %t116, 0
  %t120 = extractvalue { i8*, i8* } %t116, 1
  call void @star_rc_release(i8* %t120)
  %t121 = bitcast i8* %t119 to i32 (i8*, i32)*
  %t122 = load i32, i32* %t115
  %t123 = call i32 %t121(i8* %t120, i32 %t122)
  ret i32 %t123
}


define void @closure_17_release_env(i8* %envp) {
entry:
  %t126 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t127 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t126, i32 0, i32 0
  %t128 = load { i8*, i8* }, { i8*, i8* }* %t127
  %t129 = extractvalue { i8*, i8* } %t128, 1
  call void @star_rc_release(i8* %t129)
  %t130 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t126, i32 0, i32 1
  %t131 = getelementptr inbounds %Handler, %Handler* %t130, i32 0, i32 0
  %t132 = load { i8*, i8* }, { i8*, i8* }* %t131
  %t133 = extractvalue { i8*, i8* } %t132, 1
  call void @star_rc_release(i8* %t133)
  %t134 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t126, i32 0, i32 2
  %t135 = load i8*, i8** %t134
  call void @star_rc_release(i8* %t135)
  %t136 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t126, i32 0, i32 3
  %t137 = load { i8*, i8* }, { i8*, i8* }* %t136
  %t138 = extractvalue { i8*, i8* } %t137, 1
  call void @star_rc_release(i8* %t138)
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
