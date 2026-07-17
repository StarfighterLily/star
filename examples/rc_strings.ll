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
  %t0 = alloca i8*
  %t25 = alloca %Greeting
  %t26 = alloca %Greeting
  %t41 = alloca %Greeting
  %t49 = alloca i8*
  %t121 = alloca i64
  %t222 = alloca i8*
  %t235 = alloca i32
  %t236 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t2 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t3 = call i32 @strlen(i8* %t1)
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = add i32 %t3, %t4
  %t6 = add i32 %t5, 1
  %t7 = sext i32 %t6 to i64
  %t8 = call i8* @star_rc_alloc(i64 %t7, i8* null)
  call i8* @strcpy(i8* %t8, i8* %t1)
  call i8* @strcat(i8* %t8, i8* %t2)
  call void @star_rc_release(i8* %t1)
  call void @star_rc_release(i8* %t2)
  store i8* %t8, i8** %t0
  %t9 = load i8*, i8** %t0
  %t10 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t10)
  call void @star_rc_release(i8* %t9)
  call i32 (i8*, ...) @printf(i8* %t9)
  %t11 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11)
  %t12 = load i8*, i8** %t0
  %t13 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t13)
  %t14 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t15 = call i32 @strlen(i8* %t12)
  %t16 = call i32 @strlen(i8* %t14)
  %t17 = add i32 %t15, %t16
  %t18 = add i32 %t17, 1
  %t19 = sext i32 %t18 to i64
  %t20 = call i8* @star_rc_alloc(i64 %t19, i8* null)
  call i8* @strcpy(i8* %t20, i8* %t12)
  call i8* @strcat(i8* %t20, i8* %t14)
  call void @star_rc_release(i8* %t12)
  call void @star_rc_release(i8* %t14)
  %t21 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t21)
  store i8* %t20, i8** %t0
  %t22 = load i8*, i8** %t0
  %t23 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t23)
  call void @star_rc_release(i8* %t22)
  call i32 (i8*, ...) @printf(i8* %t22)
  %t24 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24)
  %t27 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t28 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t29 = call i32 @strlen(i8* %t27)
  %t30 = call i32 @strlen(i8* %t28)
  %t31 = add i32 %t29, %t30
  %t32 = add i32 %t31, 1
  %t33 = sext i32 %t32 to i64
  %t34 = call i8* @star_rc_alloc(i64 %t33, i8* null)
  call i8* @strcpy(i8* %t34, i8* %t27)
  call i8* @strcat(i8* %t34, i8* %t28)
  call void @star_rc_release(i8* %t27)
  call void @star_rc_release(i8* %t28)
  %t35 = getelementptr inbounds %Greeting, %Greeting* %t26, i32 0, i32 0
  store i8* %t34, i8** %t35
  %t36 = load %Greeting, %Greeting* %t26
  store %Greeting %t36, %Greeting* %t25
  %t37 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t38 = load i8*, i8** %t37
  %t39 = load i8*, i8** %t37
  call void @star_rc_retain(i8* %t39)
  call void @star_rc_release(i8* %t38)
  call i32 (i8*, ...) @printf(i8* %t38)
  %t40 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t40)
  %t42 = load %Greeting, %Greeting* %t25
  %t43 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t44 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t44)
  store %Greeting %t42, %Greeting* %t41
  %t45 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t46 = load i8*, i8** %t45
  %t47 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t47)
  call void @star_rc_release(i8* %t46)
  call i32 (i8*, ...) @printf(i8* %t46)
  %t48 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48)
  %t50 = getelementptr i8*, i8** null, i32 1
  %t51 = ptrtoint i8** %t50 to i64
  %t52 = mul i64 %t51, 2
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to i8**
  %t55 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t56 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t57 = call i32 @strlen(i8* %t55)
  %t58 = call i32 @strlen(i8* %t56)
  %t59 = add i32 %t57, %t58
  %t60 = add i32 %t59, 1
  %t61 = sext i32 %t60 to i64
  %t62 = call i8* @star_rc_alloc(i64 %t61, i8* null)
  call i8* @strcpy(i8* %t62, i8* %t55)
  call i8* @strcat(i8* %t62, i8* %t56)
  call void @star_rc_release(i8* %t55)
  call void @star_rc_release(i8* %t56)
  %t63 = getelementptr inbounds i8*, i8** %t54, i64 0
  store i8* %t62, i8** %t63
  %t64 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t65 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t66 = call i32 @strlen(i8* %t64)
  %t67 = call i32 @strlen(i8* %t65)
  %t68 = add i32 %t66, %t67
  %t69 = add i32 %t68, 1
  %t70 = sext i32 %t69 to i64
  %t71 = call i8* @star_rc_alloc(i64 %t70, i8* null)
  call i8* @strcpy(i8* %t71, i8* %t64)
  call i8* @strcat(i8* %t71, i8* %t65)
  call void @star_rc_release(i8* %t64)
  call void @star_rc_release(i8* %t65)
  %t72 = getelementptr inbounds i8*, i8** %t54, i64 1
  store i8* %t71, i8** %t72
  %t85 = bitcast void (i8*)* @list_release_str to i8*
  %t86 = call i8* @star_rc_alloc(i64 24, i8* %t85)
  %t87 = bitcast i8* %t86 to { i8**, i64, i64 }*
  %t88 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 0
  store i8** %t54, i8*** %t88
  %t89 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 1
  store i64 2, i64* %t89
  %t90 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 2
  store i64 2, i64* %t90
  store i8* %t86, i8** %t49
  %t91 = getelementptr i8*, i8** null, i32 1
  %t92 = ptrtoint i8** %t91 to i64
  %t93 = load i8*, i8** %t49
  %t94 = icmp eq i8* %t93, null
  br i1 %t94, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t95 = bitcast void (i8*)* @list_release_str to i8*
  %t96 = call i8* @star_rc_alloc(i64 24, i8* %t95)
  %t97 = bitcast i8* %t96 to { i8**, i64, i64 }*
  %t98 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 0
  store i8** null, i8*** %t98
  %t99 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 1
  store i64 0, i64* %t99
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 2
  store i64 0, i64* %t100
  store i8* %t96, i8** %t49
  br label %list_cow_done_5
list_cow_check_4:
  %t101 = getelementptr inbounds i8, i8* %t93, i64 -16
  %t102 = bitcast i8* %t101 to i64*
  %t103 = load atomic i64, i64* %t102 seq_cst, align 8
  %t104 = icmp eq i64 %t103, 1
  br i1 %t104, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t105 = bitcast i8* %t93 to { i8**, i64, i64 }*
  %t106 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 0
  %t107 = load i8**, i8*** %t106
  %t108 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 1
  %t109 = load i64, i64* %t108
  %t110 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 2
  %t111 = load i64, i64* %t110
  %t112 = bitcast void (i8*)* @list_release_str to i8*
  %t113 = call i8* @star_rc_alloc(i64 24, i8* %t112)
  %t114 = bitcast i8* %t113 to { i8**, i64, i64 }*
  %t115 = mul i64 %t111, %t92
  %t116 = call i8* @malloc(i64 %t115)
  %t117 = bitcast i8* %t116 to i8**
  %t118 = icmp sgt i64 %t109, 0
  br i1 %t118, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t119 = mul i64 %t109, %t92
  %t120 = bitcast i8** %t107 to i8*
  call i8* @memcpy(i8* %t116, i8* %t120, i64 %t119)
  store i64 0, i64* %t121
  br label %list_cow_retain_cond_9
list_cow_retain_cond_9:
  %t122 = load i64, i64* %t121
  %t123 = icmp slt i64 %t122, %t109
  br i1 %t123, label %list_cow_retain_body_10, label %list_cow_retain_end_11
list_cow_retain_body_10:
  %t124 = getelementptr inbounds i8*, i8** %t117, i64 %t122
  %t125 = load i8*, i8** %t124
  call void @star_rc_retain(i8* %t125)
  %t126 = add i64 %t122, 1
  store i64 %t126, i64* %t121
  br label %list_cow_retain_cond_9
list_cow_retain_end_11:
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t127 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 0
  store i8** %t117, i8*** %t127
  %t128 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 1
  store i64 %t109, i64* %t128
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 2
  store i64 %t111, i64* %t129
  call void @star_rc_release(i8* %t93)
  store i8* %t113, i8** %t49
  br label %list_cow_done_5
list_cow_done_5:
  %t130 = load i8*, i8** %t49
  %t131 = bitcast i8* %t130 to { i8**, i64, i64 }*
  %t132 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 0
  %t133 = load i8**, i8*** %t132
  %t134 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 1
  %t135 = load i64, i64* %t134
  %t136 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 2
  %t137 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t138 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t139 = call i32 @strlen(i8* %t137)
  %t140 = call i32 @strlen(i8* %t138)
  %t141 = add i32 %t139, %t140
  %t142 = add i32 %t141, 1
  %t143 = sext i32 %t142 to i64
  %t144 = call i8* @star_rc_alloc(i64 %t143, i8* null)
  call i8* @strcpy(i8* %t144, i8* %t137)
  call i8* @strcat(i8* %t144, i8* %t138)
  call void @star_rc_release(i8* %t137)
  call void @star_rc_release(i8* %t138)
  %t145 = load i64, i64* %t136
  %t146 = load i8**, i8*** %t132
  %t147 = load i64, i64* %t134
  %t148 = icmp sge i64 %t147, %t145
  br i1 %t148, label %list_push_grow_12, label %list_push_store_13
list_push_grow_12:
  %t149 = mul i64 %t145, 2
  %t150 = icmp sgt i64 %t149, 0
  %t151 = select i1 %t150, i64 %t149, i64 1
  %t152 = getelementptr i8*, i8** null, i32 1
  %t153 = ptrtoint i8** %t152 to i64
  %t154 = mul i64 %t151, %t153
  %t155 = call i8* @malloc(i64 %t154)
  %t156 = bitcast i8* %t155 to i8**
  %t157 = icmp sgt i64 %t145, 0
  br i1 %t157, label %list_push_copy_14, label %list_push_after_copy_15
list_push_copy_14:
  %t158 = mul i64 %t147, %t153
  %t159 = bitcast i8** %t146 to i8*
  call i8* @memcpy(i8* %t155, i8* %t159, i64 %t158)
  call void @free(i8* %t159)
  br label %list_push_after_copy_15
list_push_after_copy_15:
  store i8** %t156, i8*** %t132
  store i64 %t151, i64* %t136
  br label %list_push_store_13
list_push_store_13:
  %t160 = load i8**, i8*** %t132
  %t161 = getelementptr inbounds i8*, i8** %t160, i64 %t147
  store i8* %t144, i8** %t161
  %t162 = add i64 %t147, 1
  store i64 %t162, i64* %t134
  %t163 = load i8*, i8** %t49
  %t164 = icmp eq i8* %t163, null
  br i1 %t164, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t165 = bitcast i8* %t163 to { i8**, i64, i64 }*
  %t166 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t165, i32 0, i32 0
  %t167 = load i8**, i8*** %t166
  %t168 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t165, i32 0, i32 1
  %t169 = load i64, i64* %t168
  br label %list_read_end_18
list_read_end_18:
  %t170 = phi i8** [ null, %list_read_null_16 ], [ %t167, %list_read_real_17 ]
  %t171 = phi i64 [ 0, %list_read_null_16 ], [ %t169, %list_read_real_17 ]
  %t172 = sext i32 0 to i64
  %t173 = icmp ult i64 %t172, %t171
  br i1 %t173, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t174 = getelementptr inbounds i8*, i8** %t170, i64 %t172
  %t175 = load i8*, i8** %t174
  %t176 = load i8*, i8** %t174
  call void @star_rc_retain(i8* %t176)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t177 = phi i8* [ %t175, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t177)
  %t178 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t178, i8* %t177)
  %t179 = load i8*, i8** %t49
  %t180 = icmp eq i8* %t179, null
  br i1 %t180, label %list_read_null_22, label %list_read_real_23
list_read_null_22:
  br label %list_read_end_24
list_read_real_23:
  %t181 = bitcast i8* %t179 to { i8**, i64, i64 }*
  %t182 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t181, i32 0, i32 0
  %t183 = load i8**, i8*** %t182
  %t184 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t181, i32 0, i32 1
  %t185 = load i64, i64* %t184
  br label %list_read_end_24
list_read_end_24:
  %t186 = phi i8** [ null, %list_read_null_22 ], [ %t183, %list_read_real_23 ]
  %t187 = phi i64 [ 0, %list_read_null_22 ], [ %t185, %list_read_real_23 ]
  %t188 = sext i32 1 to i64
  %t189 = icmp ult i64 %t188, %t187
  br i1 %t189, label %list_idx_ok_25, label %list_idx_oob_26
list_idx_ok_25:
  %t190 = getelementptr inbounds i8*, i8** %t186, i64 %t188
  %t191 = load i8*, i8** %t190
  %t192 = load i8*, i8** %t190
  call void @star_rc_retain(i8* %t192)
  br label %list_idx_end_27
list_idx_oob_26:
  br label %list_idx_end_27
list_idx_end_27:
  %t193 = phi i8* [ %t191, %list_idx_ok_25 ], [ null, %list_idx_oob_26 ]
  call void @star_rc_release(i8* %t193)
  %t194 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t194, i8* %t193)
  %t195 = load i8*, i8** %t49
  %t196 = icmp eq i8* %t195, null
  br i1 %t196, label %list_read_null_28, label %list_read_real_29
list_read_null_28:
  br label %list_read_end_30
list_read_real_29:
  %t197 = bitcast i8* %t195 to { i8**, i64, i64 }*
  %t198 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t197, i32 0, i32 0
  %t199 = load i8**, i8*** %t198
  %t200 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t197, i32 0, i32 1
  %t201 = load i64, i64* %t200
  br label %list_read_end_30
list_read_end_30:
  %t202 = phi i8** [ null, %list_read_null_28 ], [ %t199, %list_read_real_29 ]
  %t203 = phi i64 [ 0, %list_read_null_28 ], [ %t201, %list_read_real_29 ]
  %t204 = sext i32 2 to i64
  %t205 = icmp ult i64 %t204, %t203
  br i1 %t205, label %list_idx_ok_31, label %list_idx_oob_32
list_idx_ok_31:
  %t206 = getelementptr inbounds i8*, i8** %t202, i64 %t204
  %t207 = load i8*, i8** %t206
  %t208 = load i8*, i8** %t206
  call void @star_rc_retain(i8* %t208)
  br label %list_idx_end_33
list_idx_oob_32:
  br label %list_idx_end_33
list_idx_end_33:
  %t209 = phi i8* [ %t207, %list_idx_ok_31 ], [ null, %list_idx_oob_32 ]
  call void @star_rc_release(i8* %t209)
  %t210 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t210, i8* %t209)
  %t211 = load i8*, i8** %t49
  %t212 = icmp eq i8* %t211, null
  br i1 %t212, label %list_read_null_34, label %list_read_real_35
list_read_null_34:
  br label %list_read_end_36
list_read_real_35:
  %t213 = bitcast i8* %t211 to { i8**, i64, i64 }*
  %t214 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t213, i32 0, i32 0
  %t215 = load i8**, i8*** %t214
  %t216 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t213, i32 0, i32 1
  %t217 = load i64, i64* %t216
  br label %list_read_end_36
list_read_end_36:
  %t218 = phi i8** [ null, %list_read_null_34 ], [ %t215, %list_read_real_35 ]
  %t219 = phi i64 [ 0, %list_read_null_34 ], [ %t217, %list_read_real_35 ]
  %t220 = trunc i64 %t219 to i32
  %t221 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t221, i32 %t220)
  %t223 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t224 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t225 = call i32 @strlen(i8* %t223)
  %t226 = call i32 @strlen(i8* %t224)
  %t227 = add i32 %t225, %t226
  %t228 = add i32 %t227, 1
  %t229 = sext i32 %t228 to i64
  %t230 = call i8* @star_rc_alloc(i64 %t229, i8* null)
  call i8* @strcpy(i8* %t230, i8* %t223)
  call i8* @strcat(i8* %t230, i8* %t224)
  call void @star_rc_release(i8* %t223)
  call void @star_rc_release(i8* %t224)
  store i8* %t230, i8** %t222
  %t231 = load i8*, i8** %t222
  %t232 = load i8*, i8** %t222
  call void @star_rc_retain(i8* %t232)
  %t233 = call i32 @shout_len(i8* %t231)
  %t234 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t234, i32 %t233)
  store i32 0, i32* %t235
  %t237 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t237, i8** %t236
  br label %while_cond_37
while_cond_37:
  %t238 = load i32, i32* %t235
  %t239 = icmp slt i32 %t238, 5
  br i1 %t239, label %while_body_38, label %while_else_39
while_body_38:
  %t240 = load i8*, i8** %t236
  %t241 = load i8*, i8** %t236
  call void @star_rc_retain(i8* %t241)
  %t242 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t243 = call i32 @strlen(i8* %t240)
  %t244 = call i32 @strlen(i8* %t242)
  %t245 = add i32 %t243, %t244
  %t246 = add i32 %t245, 1
  %t247 = sext i32 %t246 to i64
  %t248 = call i8* @star_rc_alloc(i64 %t247, i8* null)
  call i8* @strcpy(i8* %t248, i8* %t240)
  call i8* @strcat(i8* %t248, i8* %t242)
  call void @star_rc_release(i8* %t240)
  call void @star_rc_release(i8* %t242)
  %t249 = load i8*, i8** %t236
  call void @star_rc_release(i8* %t249)
  store i8* %t248, i8** %t236
  %t250 = load i32, i32* %t235
  %t251 = add i32 %t250, 1
  store i32 %t251, i32* %t235
  br label %while_cond_37
while_else_39:
  br label %while_end_40
while_end_40:
  %t252 = load i8*, i8** %t236
  %t253 = load i8*, i8** %t236
  call void @star_rc_retain(i8* %t253)
  call void @star_rc_release(i8* %t252)
  call i32 (i8*, ...) @printf(i8* %t252)
  %t254 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t254)
  %t255 = load i8*, i8** %t236
  call void @star_rc_release(i8* %t255)
  %t256 = load i8*, i8** %t222
  call void @star_rc_release(i8* %t256)
  %t257 = load i8*, i8** %t49
  call void @star_rc_release(i8* %t257)
  %t258 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t259 = load i8*, i8** %t258
  call void @star_rc_release(i8* %t259)
  %t260 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t261 = load i8*, i8** %t260
  call void @star_rc_release(i8* %t261)
  %t262 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t262)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t78 = alloca i64
  %t73 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t74 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t73, i32 0, i32 0
  %t75 = load i8**, i8*** %t74
  %t76 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t73, i32 0, i32 1
  %t77 = load i64, i64* %t76
  store i64 0, i64* %t78
  br label %list_release_cond_0
list_release_cond_0:
  %t79 = load i64, i64* %t78
  %t80 = icmp slt i64 %t79, %t77
  br i1 %t80, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t81 = getelementptr inbounds i8*, i8** %t75, i64 %t79
  %t82 = load i8*, i8** %t81
  call void @star_rc_release(i8* %t82)
  %t83 = add i64 %t79, 1
  store i64 %t83, i64* %t78
  br label %list_release_cond_0
list_release_end_2:
  %t84 = bitcast i8** %t75 to i8*
  call void @free(i8* %t84)
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
