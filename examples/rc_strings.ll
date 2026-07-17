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

%Greeting = type { i8* }
define i32 @shout_len(i8* %s) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  store i8* %s, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t5 = call i32 @strlen(i8* %t2)
  %t6 = call i32 @strlen(i8* %t4)
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i8* @strcpy(i8* %t10, i8* %t2)
  call i8* @strcat(i8* %t10, i8* %t4)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  store i8* %t10, i8** %t1
  %t11 = load i8*, i8** %t1
  %t12 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t12)
  %t13 = call i32 @strlen(i8* %t11)
  call void @star_rc_release(i8* %t11)
  %t14 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t14)
  %t15 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t15)
  ret i32 %t13
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t26 = alloca %Greeting
  %t27 = alloca %Greeting
  %t42 = alloca %Greeting
  %t50 = alloca i8*
  %t122 = alloca i64
  %t223 = alloca i8*
  %t236 = alloca i32
  %t237 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = add i32 %t4, %t5
  %t7 = add i32 %t6, 1
  %t8 = sext i32 %t7 to i64
  %t9 = call i8* @star_rc_alloc(i64 %t8, i8* null)
  call i8* @strcpy(i8* %t9, i8* %t2)
  call i8* @strcat(i8* %t9, i8* %t3)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t3)
  store i8* %t9, i8** %t1
  %t10 = load i8*, i8** %t1
  %t11 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t11)
  call void @star_rc_release(i8* %t10)
  call i32 (i8*, ...) @printf(i8* %t10)
  %t12 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12)
  %t13 = load i8*, i8** %t1
  %t14 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t14)
  %t15 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t16 = call i32 @strlen(i8* %t13)
  %t17 = call i32 @strlen(i8* %t15)
  %t18 = add i32 %t16, %t17
  %t19 = add i32 %t18, 1
  %t20 = sext i32 %t19 to i64
  %t21 = call i8* @star_rc_alloc(i64 %t20, i8* null)
  call i8* @strcpy(i8* %t21, i8* %t13)
  call i8* @strcat(i8* %t21, i8* %t15)
  call void @star_rc_release(i8* %t13)
  call void @star_rc_release(i8* %t15)
  %t22 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t22)
  store i8* %t21, i8** %t1
  %t23 = load i8*, i8** %t1
  %t24 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t24)
  call void @star_rc_release(i8* %t23)
  call i32 (i8*, ...) @printf(i8* %t23)
  %t25 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25)
  %t28 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t29 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t30 = call i32 @strlen(i8* %t28)
  %t31 = call i32 @strlen(i8* %t29)
  %t32 = add i32 %t30, %t31
  %t33 = add i32 %t32, 1
  %t34 = sext i32 %t33 to i64
  %t35 = call i8* @star_rc_alloc(i64 %t34, i8* null)
  call i8* @strcpy(i8* %t35, i8* %t28)
  call i8* @strcat(i8* %t35, i8* %t29)
  call void @star_rc_release(i8* %t28)
  call void @star_rc_release(i8* %t29)
  %t36 = getelementptr inbounds %Greeting, %Greeting* %t27, i32 0, i32 0
  store i8* %t35, i8** %t36
  %t37 = load %Greeting, %Greeting* %t27
  store %Greeting %t37, %Greeting* %t26
  %t38 = getelementptr inbounds %Greeting, %Greeting* %t26, i32 0, i32 0
  %t39 = load i8*, i8** %t38
  %t40 = load i8*, i8** %t38
  call void @star_rc_retain(i8* %t40)
  call void @star_rc_release(i8* %t39)
  call i32 (i8*, ...) @printf(i8* %t39)
  %t41 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t41)
  %t43 = load %Greeting, %Greeting* %t26
  %t44 = getelementptr inbounds %Greeting, %Greeting* %t26, i32 0, i32 0
  %t45 = load i8*, i8** %t44
  call void @star_rc_retain(i8* %t45)
  store %Greeting %t43, %Greeting* %t42
  %t46 = getelementptr inbounds %Greeting, %Greeting* %t42, i32 0, i32 0
  %t47 = load i8*, i8** %t46
  %t48 = load i8*, i8** %t46
  call void @star_rc_retain(i8* %t48)
  call void @star_rc_release(i8* %t47)
  call i32 (i8*, ...) @printf(i8* %t47)
  %t49 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49)
  %t51 = getelementptr i8*, i8** null, i32 1
  %t52 = ptrtoint i8** %t51 to i64
  %t53 = mul i64 %t52, 2
  %t54 = call i8* @malloc(i64 %t53)
  %t55 = bitcast i8* %t54 to i8**
  %t56 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t57 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t58 = call i32 @strlen(i8* %t56)
  %t59 = call i32 @strlen(i8* %t57)
  %t60 = add i32 %t58, %t59
  %t61 = add i32 %t60, 1
  %t62 = sext i32 %t61 to i64
  %t63 = call i8* @star_rc_alloc(i64 %t62, i8* null)
  call i8* @strcpy(i8* %t63, i8* %t56)
  call i8* @strcat(i8* %t63, i8* %t57)
  call void @star_rc_release(i8* %t56)
  call void @star_rc_release(i8* %t57)
  %t64 = getelementptr inbounds i8*, i8** %t55, i64 0
  store i8* %t63, i8** %t64
  %t65 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t66 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t67 = call i32 @strlen(i8* %t65)
  %t68 = call i32 @strlen(i8* %t66)
  %t69 = add i32 %t67, %t68
  %t70 = add i32 %t69, 1
  %t71 = sext i32 %t70 to i64
  %t72 = call i8* @star_rc_alloc(i64 %t71, i8* null)
  call i8* @strcpy(i8* %t72, i8* %t65)
  call i8* @strcat(i8* %t72, i8* %t66)
  call void @star_rc_release(i8* %t65)
  call void @star_rc_release(i8* %t66)
  %t73 = getelementptr inbounds i8*, i8** %t55, i64 1
  store i8* %t72, i8** %t73
  %t86 = bitcast void (i8*)* @list_release_str to i8*
  %t87 = call i8* @star_rc_alloc(i64 24, i8* %t86)
  %t88 = bitcast i8* %t87 to { i8**, i64, i64 }*
  %t89 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t88, i32 0, i32 0
  store i8** %t55, i8*** %t89
  %t90 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t88, i32 0, i32 1
  store i64 2, i64* %t90
  %t91 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t88, i32 0, i32 2
  store i64 2, i64* %t91
  store i8* %t87, i8** %t50
  %t92 = getelementptr i8*, i8** null, i32 1
  %t93 = ptrtoint i8** %t92 to i64
  %t94 = load i8*, i8** %t50
  %t95 = icmp eq i8* %t94, null
  br i1 %t95, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t96 = bitcast void (i8*)* @list_release_str to i8*
  %t97 = call i8* @star_rc_alloc(i64 24, i8* %t96)
  %t98 = bitcast i8* %t97 to { i8**, i64, i64 }*
  %t99 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 0
  store i8** null, i8*** %t99
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 1
  store i64 0, i64* %t100
  %t101 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 2
  store i64 0, i64* %t101
  store i8* %t97, i8** %t50
  br label %list_cow_done_5
list_cow_check_4:
  %t102 = getelementptr inbounds i8, i8* %t94, i64 -16
  %t103 = bitcast i8* %t102 to i64*
  %t104 = load atomic i64, i64* %t103 seq_cst, align 8
  %t105 = icmp eq i64 %t104, 1
  br i1 %t105, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t106 = bitcast i8* %t94 to { i8**, i64, i64 }*
  %t107 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t106, i32 0, i32 0
  %t108 = load i8**, i8*** %t107
  %t109 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t106, i32 0, i32 1
  %t110 = load i64, i64* %t109
  %t111 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t106, i32 0, i32 2
  %t112 = load i64, i64* %t111
  %t113 = bitcast void (i8*)* @list_release_str to i8*
  %t114 = call i8* @star_rc_alloc(i64 24, i8* %t113)
  %t115 = bitcast i8* %t114 to { i8**, i64, i64 }*
  %t116 = mul i64 %t112, %t93
  %t117 = call i8* @malloc(i64 %t116)
  %t118 = bitcast i8* %t117 to i8**
  %t119 = icmp sgt i64 %t110, 0
  br i1 %t119, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t120 = mul i64 %t110, %t93
  %t121 = bitcast i8** %t108 to i8*
  call i8* @memcpy(i8* %t117, i8* %t121, i64 %t120)
  store i64 0, i64* %t122
  br label %list_cow_retain_cond_9
list_cow_retain_cond_9:
  %t123 = load i64, i64* %t122
  %t124 = icmp slt i64 %t123, %t110
  br i1 %t124, label %list_cow_retain_body_10, label %list_cow_retain_end_11
list_cow_retain_body_10:
  %t125 = getelementptr inbounds i8*, i8** %t118, i64 %t123
  %t126 = load i8*, i8** %t125
  call void @star_rc_retain(i8* %t126)
  %t127 = add i64 %t123, 1
  store i64 %t127, i64* %t122
  br label %list_cow_retain_cond_9
list_cow_retain_end_11:
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t128 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t115, i32 0, i32 0
  store i8** %t118, i8*** %t128
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t115, i32 0, i32 1
  store i64 %t110, i64* %t129
  %t130 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t115, i32 0, i32 2
  store i64 %t112, i64* %t130
  call void @star_rc_release(i8* %t94)
  store i8* %t114, i8** %t50
  br label %list_cow_done_5
list_cow_done_5:
  %t131 = load i8*, i8** %t50
  %t132 = bitcast i8* %t131 to { i8**, i64, i64 }*
  %t133 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t132, i32 0, i32 0
  %t134 = load i8**, i8*** %t133
  %t135 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t132, i32 0, i32 1
  %t136 = load i64, i64* %t135
  %t137 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t132, i32 0, i32 2
  %t138 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t139 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t140 = call i32 @strlen(i8* %t138)
  %t141 = call i32 @strlen(i8* %t139)
  %t142 = add i32 %t140, %t141
  %t143 = add i32 %t142, 1
  %t144 = sext i32 %t143 to i64
  %t145 = call i8* @star_rc_alloc(i64 %t144, i8* null)
  call i8* @strcpy(i8* %t145, i8* %t138)
  call i8* @strcat(i8* %t145, i8* %t139)
  call void @star_rc_release(i8* %t138)
  call void @star_rc_release(i8* %t139)
  %t146 = load i64, i64* %t137
  %t147 = load i8**, i8*** %t133
  %t148 = load i64, i64* %t135
  %t149 = icmp sge i64 %t148, %t146
  br i1 %t149, label %list_push_grow_12, label %list_push_store_13
list_push_grow_12:
  %t150 = mul i64 %t146, 2
  %t151 = icmp sgt i64 %t150, 0
  %t152 = select i1 %t151, i64 %t150, i64 1
  %t153 = getelementptr i8*, i8** null, i32 1
  %t154 = ptrtoint i8** %t153 to i64
  %t155 = mul i64 %t152, %t154
  %t156 = call i8* @malloc(i64 %t155)
  %t157 = bitcast i8* %t156 to i8**
  %t158 = icmp sgt i64 %t146, 0
  br i1 %t158, label %list_push_copy_14, label %list_push_after_copy_15
list_push_copy_14:
  %t159 = mul i64 %t148, %t154
  %t160 = bitcast i8** %t147 to i8*
  call i8* @memcpy(i8* %t156, i8* %t160, i64 %t159)
  call void @free(i8* %t160)
  br label %list_push_after_copy_15
list_push_after_copy_15:
  store i8** %t157, i8*** %t133
  store i64 %t152, i64* %t137
  br label %list_push_store_13
list_push_store_13:
  %t161 = load i8**, i8*** %t133
  %t162 = getelementptr inbounds i8*, i8** %t161, i64 %t148
  store i8* %t145, i8** %t162
  %t163 = add i64 %t148, 1
  store i64 %t163, i64* %t135
  %t164 = load i8*, i8** %t50
  %t165 = icmp eq i8* %t164, null
  br i1 %t165, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t166 = bitcast i8* %t164 to { i8**, i64, i64 }*
  %t167 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t166, i32 0, i32 0
  %t168 = load i8**, i8*** %t167
  %t169 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t166, i32 0, i32 1
  %t170 = load i64, i64* %t169
  br label %list_read_end_18
list_read_end_18:
  %t171 = phi i8** [ null, %list_read_null_16 ], [ %t168, %list_read_real_17 ]
  %t172 = phi i64 [ 0, %list_read_null_16 ], [ %t170, %list_read_real_17 ]
  %t173 = sext i32 0 to i64
  %t174 = icmp ult i64 %t173, %t172
  br i1 %t174, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t175 = getelementptr inbounds i8*, i8** %t171, i64 %t173
  %t176 = load i8*, i8** %t175
  %t177 = load i8*, i8** %t175
  call void @star_rc_retain(i8* %t177)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t178 = phi i8* [ %t176, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t178)
  %t179 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t179, i8* %t178)
  %t180 = load i8*, i8** %t50
  %t181 = icmp eq i8* %t180, null
  br i1 %t181, label %list_read_null_22, label %list_read_real_23
list_read_null_22:
  br label %list_read_end_24
list_read_real_23:
  %t182 = bitcast i8* %t180 to { i8**, i64, i64 }*
  %t183 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t182, i32 0, i32 0
  %t184 = load i8**, i8*** %t183
  %t185 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t182, i32 0, i32 1
  %t186 = load i64, i64* %t185
  br label %list_read_end_24
list_read_end_24:
  %t187 = phi i8** [ null, %list_read_null_22 ], [ %t184, %list_read_real_23 ]
  %t188 = phi i64 [ 0, %list_read_null_22 ], [ %t186, %list_read_real_23 ]
  %t189 = sext i32 1 to i64
  %t190 = icmp ult i64 %t189, %t188
  br i1 %t190, label %list_idx_ok_25, label %list_idx_oob_26
list_idx_ok_25:
  %t191 = getelementptr inbounds i8*, i8** %t187, i64 %t189
  %t192 = load i8*, i8** %t191
  %t193 = load i8*, i8** %t191
  call void @star_rc_retain(i8* %t193)
  br label %list_idx_end_27
list_idx_oob_26:
  br label %list_idx_end_27
list_idx_end_27:
  %t194 = phi i8* [ %t192, %list_idx_ok_25 ], [ null, %list_idx_oob_26 ]
  call void @star_rc_release(i8* %t194)
  %t195 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t195, i8* %t194)
  %t196 = load i8*, i8** %t50
  %t197 = icmp eq i8* %t196, null
  br i1 %t197, label %list_read_null_28, label %list_read_real_29
list_read_null_28:
  br label %list_read_end_30
list_read_real_29:
  %t198 = bitcast i8* %t196 to { i8**, i64, i64 }*
  %t199 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t198, i32 0, i32 0
  %t200 = load i8**, i8*** %t199
  %t201 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t198, i32 0, i32 1
  %t202 = load i64, i64* %t201
  br label %list_read_end_30
list_read_end_30:
  %t203 = phi i8** [ null, %list_read_null_28 ], [ %t200, %list_read_real_29 ]
  %t204 = phi i64 [ 0, %list_read_null_28 ], [ %t202, %list_read_real_29 ]
  %t205 = sext i32 2 to i64
  %t206 = icmp ult i64 %t205, %t204
  br i1 %t206, label %list_idx_ok_31, label %list_idx_oob_32
list_idx_ok_31:
  %t207 = getelementptr inbounds i8*, i8** %t203, i64 %t205
  %t208 = load i8*, i8** %t207
  %t209 = load i8*, i8** %t207
  call void @star_rc_retain(i8* %t209)
  br label %list_idx_end_33
list_idx_oob_32:
  br label %list_idx_end_33
list_idx_end_33:
  %t210 = phi i8* [ %t208, %list_idx_ok_31 ], [ null, %list_idx_oob_32 ]
  call void @star_rc_release(i8* %t210)
  %t211 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t211, i8* %t210)
  %t212 = load i8*, i8** %t50
  %t213 = icmp eq i8* %t212, null
  br i1 %t213, label %list_read_null_34, label %list_read_real_35
list_read_null_34:
  br label %list_read_end_36
list_read_real_35:
  %t214 = bitcast i8* %t212 to { i8**, i64, i64 }*
  %t215 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t214, i32 0, i32 0
  %t216 = load i8**, i8*** %t215
  %t217 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t214, i32 0, i32 1
  %t218 = load i64, i64* %t217
  br label %list_read_end_36
list_read_end_36:
  %t219 = phi i8** [ null, %list_read_null_34 ], [ %t216, %list_read_real_35 ]
  %t220 = phi i64 [ 0, %list_read_null_34 ], [ %t218, %list_read_real_35 ]
  %t221 = trunc i64 %t220 to i32
  %t222 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t222, i32 %t221)
  %t224 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t225 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t226 = call i32 @strlen(i8* %t224)
  %t227 = call i32 @strlen(i8* %t225)
  %t228 = add i32 %t226, %t227
  %t229 = add i32 %t228, 1
  %t230 = sext i32 %t229 to i64
  %t231 = call i8* @star_rc_alloc(i64 %t230, i8* null)
  call i8* @strcpy(i8* %t231, i8* %t224)
  call i8* @strcat(i8* %t231, i8* %t225)
  call void @star_rc_release(i8* %t224)
  call void @star_rc_release(i8* %t225)
  store i8* %t231, i8** %t223
  %t232 = load i8*, i8** %t223
  %t233 = load i8*, i8** %t223
  call void @star_rc_retain(i8* %t233)
  %t234 = call i32 @shout_len(i8* %t232)
  %t235 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t235, i32 %t234)
  store i32 0, i32* %t236
  %t238 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t238, i8** %t237
  br label %while_cond_37
while_cond_37:
  %t239 = load i32, i32* %t236
  %t240 = icmp slt i32 %t239, 5
  br i1 %t240, label %while_body_38, label %while_else_39
while_body_38:
  %t241 = load i8*, i8** %t237
  %t242 = load i8*, i8** %t237
  call void @star_rc_retain(i8* %t242)
  %t243 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t244 = call i32 @strlen(i8* %t241)
  %t245 = call i32 @strlen(i8* %t243)
  %t246 = add i32 %t244, %t245
  %t247 = add i32 %t246, 1
  %t248 = sext i32 %t247 to i64
  %t249 = call i8* @star_rc_alloc(i64 %t248, i8* null)
  call i8* @strcpy(i8* %t249, i8* %t241)
  call i8* @strcat(i8* %t249, i8* %t243)
  call void @star_rc_release(i8* %t241)
  call void @star_rc_release(i8* %t243)
  %t250 = load i8*, i8** %t237
  call void @star_rc_release(i8* %t250)
  store i8* %t249, i8** %t237
  %t251 = load i32, i32* %t236
  %t252 = add i32 %t251, 1
  store i32 %t252, i32* %t236
  br label %while_cond_37
while_else_39:
  br label %while_end_40
while_end_40:
  %t253 = load i8*, i8** %t237
  %t254 = load i8*, i8** %t237
  call void @star_rc_retain(i8* %t254)
  call void @star_rc_release(i8* %t253)
  call i32 (i8*, ...) @printf(i8* %t253)
  %t255 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t255)
  %t256 = load i8*, i8** %t237
  call void @star_rc_release(i8* %t256)
  %t257 = load i8*, i8** %t223
  call void @star_rc_release(i8* %t257)
  %t258 = load i8*, i8** %t50
  call void @star_rc_release(i8* %t258)
  %t259 = getelementptr inbounds %Greeting, %Greeting* %t42, i32 0, i32 0
  %t260 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t260)
  %t261 = getelementptr inbounds %Greeting, %Greeting* %t26, i32 0, i32 0
  %t262 = load i8*, i8** %t261
  call void @star_rc_release(i8* %t262)
  %t263 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t263)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t79 = alloca i64
  %t74 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t75 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t76 = load i8**, i8*** %t75
  %t77 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t78 = load i64, i64* %t77
  store i64 0, i64* %t79
  br label %list_release_cond_0
list_release_cond_0:
  %t80 = load i64, i64* %t79
  %t81 = icmp slt i64 %t80, %t78
  br i1 %t81, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t82 = getelementptr inbounds i8*, i8** %t76, i64 %t80
  %t83 = load i8*, i8** %t82
  call void @star_rc_release(i8* %t83)
  %t84 = add i64 %t80, 1
  store i64 %t84, i64* %t79
  br label %list_release_cond_0
list_release_end_2:
  %t85 = bitcast i8** %t76 to i8*
  call void @free(i8* %t85)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"!!!\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"foo\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bar\00" }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"baz\00" }
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"hello\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c" world\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.9 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-1\00" }
@.str.12 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.13 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-2\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-3\00" }
@.str.16 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.17 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.18 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.19 = private unnamed_addr constant [16 x i8] c"words len = %d\0A\00"
@.str.20 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"g\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"o\00" }
@.str.22 = private unnamed_addr constant [20 x i8] c"shout_len(go) = %d\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"start\00" }
@.str.24 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-x\00" }
@.str.25 = private unnamed_addr constant [2 x i8] c"\0A\00"
