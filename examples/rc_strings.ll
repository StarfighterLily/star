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
  %t2 = alloca i8*
  %t27 = alloca %Greeting
  %t28 = alloca %Greeting
  %t43 = alloca %Greeting
  %t51 = alloca i8*
  %t123 = alloca i64
  %t227 = alloca i8*
  %t240 = alloca i32
  %t241 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t4 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = call i32 @strlen(i8* %t4)
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i8* @strcpy(i8* %t10, i8* %t3)
  call i8* @strcat(i8* %t10, i8* %t4)
  call void @star_rc_release(i8* %t3)
  call void @star_rc_release(i8* %t4)
  store i8* %t10, i8** %t2
  %t11 = load i8*, i8** %t2
  %t12 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t12)
  call void @star_rc_release(i8* %t11)
  call i32 (i8*, ...) @printf(i8* %t11)
  %t13 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13)
  %t14 = load i8*, i8** %t2
  %t15 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t15)
  %t16 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t17 = call i32 @strlen(i8* %t14)
  %t18 = call i32 @strlen(i8* %t16)
  %t19 = add i32 %t17, %t18
  %t20 = add i32 %t19, 1
  %t21 = sext i32 %t20 to i64
  %t22 = call i8* @star_rc_alloc(i64 %t21, i8* null)
  call i8* @strcpy(i8* %t22, i8* %t14)
  call i8* @strcat(i8* %t22, i8* %t16)
  call void @star_rc_release(i8* %t14)
  call void @star_rc_release(i8* %t16)
  %t23 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t23)
  store i8* %t22, i8** %t2
  %t24 = load i8*, i8** %t2
  %t25 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t25)
  call void @star_rc_release(i8* %t24)
  call i32 (i8*, ...) @printf(i8* %t24)
  %t26 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t26)
  %t29 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t30 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t31 = call i32 @strlen(i8* %t29)
  %t32 = call i32 @strlen(i8* %t30)
  %t33 = add i32 %t31, %t32
  %t34 = add i32 %t33, 1
  %t35 = sext i32 %t34 to i64
  %t36 = call i8* @star_rc_alloc(i64 %t35, i8* null)
  call i8* @strcpy(i8* %t36, i8* %t29)
  call i8* @strcat(i8* %t36, i8* %t30)
  call void @star_rc_release(i8* %t29)
  call void @star_rc_release(i8* %t30)
  %t37 = getelementptr inbounds %Greeting, %Greeting* %t28, i32 0, i32 0
  store i8* %t36, i8** %t37
  %t38 = load %Greeting, %Greeting* %t28
  store %Greeting %t38, %Greeting* %t27
  %t39 = getelementptr inbounds %Greeting, %Greeting* %t27, i32 0, i32 0
  %t40 = load i8*, i8** %t39
  %t41 = load i8*, i8** %t39
  call void @star_rc_retain(i8* %t41)
  call void @star_rc_release(i8* %t40)
  call i32 (i8*, ...) @printf(i8* %t40)
  %t42 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t42)
  %t44 = load %Greeting, %Greeting* %t27
  %t45 = getelementptr inbounds %Greeting, %Greeting* %t27, i32 0, i32 0
  %t46 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t46)
  store %Greeting %t44, %Greeting* %t43
  %t47 = getelementptr inbounds %Greeting, %Greeting* %t43, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = load i8*, i8** %t47
  call void @star_rc_retain(i8* %t49)
  call void @star_rc_release(i8* %t48)
  call i32 (i8*, ...) @printf(i8* %t48)
  %t50 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t50)
  %t52 = getelementptr i8*, i8** null, i32 1
  %t53 = ptrtoint i8** %t52 to i64
  %t54 = mul i64 %t53, 2
  %t55 = call i8* @malloc(i64 %t54)
  %t56 = bitcast i8* %t55 to i8**
  %t57 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t58 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
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
  %t65 = getelementptr inbounds i8*, i8** %t56, i64 0
  store i8* %t64, i8** %t65
  %t66 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t67 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t68 = call i32 @strlen(i8* %t66)
  %t69 = call i32 @strlen(i8* %t67)
  %t70 = add i32 %t68, %t69
  %t71 = add i32 %t70, 1
  %t72 = sext i32 %t71 to i64
  %t73 = call i8* @star_rc_alloc(i64 %t72, i8* null)
  call i8* @strcpy(i8* %t73, i8* %t66)
  call i8* @strcat(i8* %t73, i8* %t67)
  call void @star_rc_release(i8* %t66)
  call void @star_rc_release(i8* %t67)
  %t74 = getelementptr inbounds i8*, i8** %t56, i64 1
  store i8* %t73, i8** %t74
  %t87 = bitcast void (i8*)* @list_release_str to i8*
  %t88 = call i8* @star_rc_alloc(i64 24, i8* %t87)
  %t89 = bitcast i8* %t88 to { i8**, i64, i64 }*
  %t90 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t89, i32 0, i32 0
  store i8** %t56, i8*** %t90
  %t91 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t89, i32 0, i32 1
  store i64 2, i64* %t91
  %t92 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t89, i32 0, i32 2
  store i64 2, i64* %t92
  store i8* %t88, i8** %t51
  %t93 = getelementptr i8*, i8** null, i32 1
  %t94 = ptrtoint i8** %t93 to i64
  %t95 = load i8*, i8** %t51
  %t96 = icmp eq i8* %t95, null
  br i1 %t96, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t97 = bitcast void (i8*)* @list_release_str to i8*
  %t98 = call i8* @star_rc_alloc(i64 24, i8* %t97)
  %t99 = bitcast i8* %t98 to { i8**, i64, i64 }*
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t99, i32 0, i32 0
  store i8** null, i8*** %t100
  %t101 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t99, i32 0, i32 1
  store i64 0, i64* %t101
  %t102 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t99, i32 0, i32 2
  store i64 0, i64* %t102
  store i8* %t98, i8** %t51
  br label %list_cow_done_5
list_cow_check_4:
  %t103 = getelementptr inbounds i8, i8* %t95, i64 -16
  %t104 = bitcast i8* %t103 to i64*
  %t105 = load atomic i64, i64* %t104 seq_cst, align 8
  %t106 = icmp eq i64 %t105, 1
  br i1 %t106, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t107 = bitcast i8* %t95 to { i8**, i64, i64 }*
  %t108 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 0
  %t109 = load i8**, i8*** %t108
  %t110 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 1
  %t111 = load i64, i64* %t110
  %t112 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 2
  %t113 = load i64, i64* %t112
  %t114 = bitcast void (i8*)* @list_release_str to i8*
  %t115 = call i8* @star_rc_alloc(i64 24, i8* %t114)
  %t116 = bitcast i8* %t115 to { i8**, i64, i64 }*
  %t117 = mul i64 %t113, %t94
  %t118 = call i8* @malloc(i64 %t117)
  %t119 = bitcast i8* %t118 to i8**
  %t120 = icmp sgt i64 %t111, 0
  br i1 %t120, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t121 = mul i64 %t111, %t94
  %t122 = bitcast i8** %t109 to i8*
  call i8* @memcpy(i8* %t118, i8* %t122, i64 %t121)
  store i64 0, i64* %t123
  br label %list_cow_retain_cond_9
list_cow_retain_cond_9:
  %t124 = load i64, i64* %t123
  %t125 = icmp slt i64 %t124, %t111
  br i1 %t125, label %list_cow_retain_body_10, label %list_cow_retain_end_11
list_cow_retain_body_10:
  %t126 = getelementptr inbounds i8*, i8** %t119, i64 %t124
  %t127 = load i8*, i8** %t126
  call void @star_rc_retain(i8* %t127)
  %t128 = add i64 %t124, 1
  store i64 %t128, i64* %t123
  br label %list_cow_retain_cond_9
list_cow_retain_end_11:
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t116, i32 0, i32 0
  store i8** %t119, i8*** %t129
  %t130 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t116, i32 0, i32 1
  store i64 %t111, i64* %t130
  %t131 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t116, i32 0, i32 2
  store i64 %t113, i64* %t131
  call void @star_rc_release(i8* %t95)
  store i8* %t115, i8** %t51
  br label %list_cow_done_5
list_cow_done_5:
  %t132 = load i8*, i8** %t51
  %t133 = bitcast i8* %t132 to { i8**, i64, i64 }*
  %t134 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t133, i32 0, i32 0
  %t135 = load i8**, i8*** %t134
  %t136 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t133, i32 0, i32 1
  %t137 = load i64, i64* %t136
  %t138 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t133, i32 0, i32 2
  %t139 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t140 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t141 = call i32 @strlen(i8* %t139)
  %t142 = call i32 @strlen(i8* %t140)
  %t143 = add i32 %t141, %t142
  %t144 = add i32 %t143, 1
  %t145 = sext i32 %t144 to i64
  %t146 = call i8* @star_rc_alloc(i64 %t145, i8* null)
  call i8* @strcpy(i8* %t146, i8* %t139)
  call i8* @strcat(i8* %t146, i8* %t140)
  call void @star_rc_release(i8* %t139)
  call void @star_rc_release(i8* %t140)
  %t147 = load i64, i64* %t138
  %t148 = load i8**, i8*** %t134
  %t149 = load i64, i64* %t136
  %t150 = icmp sge i64 %t149, %t147
  br i1 %t150, label %list_push_grow_12, label %list_push_store_13
list_push_grow_12:
  %t151 = mul i64 %t147, 2
  %t152 = icmp sgt i64 %t151, 0
  %t153 = select i1 %t152, i64 %t151, i64 1
  %t154 = getelementptr i8*, i8** null, i32 1
  %t155 = ptrtoint i8** %t154 to i64
  %t156 = mul i64 %t153, %t155
  %t157 = call i8* @malloc(i64 %t156)
  %t158 = bitcast i8* %t157 to i8**
  %t159 = icmp sgt i64 %t147, 0
  br i1 %t159, label %list_push_copy_14, label %list_push_after_copy_15
list_push_copy_14:
  %t160 = mul i64 %t149, %t155
  %t161 = bitcast i8** %t148 to i8*
  call i8* @memcpy(i8* %t157, i8* %t161, i64 %t160)
  call void @free(i8* %t161)
  br label %list_push_after_copy_15
list_push_after_copy_15:
  store i8** %t158, i8*** %t134
  store i64 %t153, i64* %t138
  br label %list_push_store_13
list_push_store_13:
  %t162 = load i8**, i8*** %t134
  %t163 = getelementptr inbounds i8*, i8** %t162, i64 %t149
  store i8* %t146, i8** %t163
  %t164 = add i64 %t149, 1
  store i64 %t164, i64* %t136
  %t165 = load i8*, i8** %t51
  %t166 = icmp eq i8* %t165, null
  br i1 %t166, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t167 = bitcast i8* %t165 to { i8**, i64, i64 }*
  %t168 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t167, i32 0, i32 0
  %t169 = load i8**, i8*** %t168
  %t170 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t167, i32 0, i32 1
  %t171 = load i64, i64* %t170
  br label %list_read_end_18
list_read_end_18:
  %t172 = phi i8** [ null, %list_read_null_16 ], [ %t169, %list_read_real_17 ]
  %t173 = phi i64 [ 0, %list_read_null_16 ], [ %t171, %list_read_real_17 ]
  %t174 = sext i32 0 to i64
  %t175 = icmp ult i64 %t174, %t173
  br i1 %t175, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t176 = getelementptr inbounds i8*, i8** %t172, i64 %t174
  %t177 = load i8*, i8** %t176
  %t178 = load i8*, i8** %t176
  call void @star_rc_retain(i8* %t178)
  br label %list_idx_end_21
list_idx_oob_20:
  %t179 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t179
  br label %list_idx_end_21
list_idx_end_21:
  %t180 = phi i8* [ %t177, %list_idx_ok_19 ], [ %t179, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t180)
  %t181 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t181, i8* %t180)
  %t182 = load i8*, i8** %t51
  %t183 = icmp eq i8* %t182, null
  br i1 %t183, label %list_read_null_22, label %list_read_real_23
list_read_null_22:
  br label %list_read_end_24
list_read_real_23:
  %t184 = bitcast i8* %t182 to { i8**, i64, i64 }*
  %t185 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t184, i32 0, i32 0
  %t186 = load i8**, i8*** %t185
  %t187 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t184, i32 0, i32 1
  %t188 = load i64, i64* %t187
  br label %list_read_end_24
list_read_end_24:
  %t189 = phi i8** [ null, %list_read_null_22 ], [ %t186, %list_read_real_23 ]
  %t190 = phi i64 [ 0, %list_read_null_22 ], [ %t188, %list_read_real_23 ]
  %t191 = sext i32 1 to i64
  %t192 = icmp ult i64 %t191, %t190
  br i1 %t192, label %list_idx_ok_25, label %list_idx_oob_26
list_idx_ok_25:
  %t193 = getelementptr inbounds i8*, i8** %t189, i64 %t191
  %t194 = load i8*, i8** %t193
  %t195 = load i8*, i8** %t193
  call void @star_rc_retain(i8* %t195)
  br label %list_idx_end_27
list_idx_oob_26:
  %t196 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t196
  br label %list_idx_end_27
list_idx_end_27:
  %t197 = phi i8* [ %t194, %list_idx_ok_25 ], [ %t196, %list_idx_oob_26 ]
  call void @star_rc_release(i8* %t197)
  %t198 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t198, i8* %t197)
  %t199 = load i8*, i8** %t51
  %t200 = icmp eq i8* %t199, null
  br i1 %t200, label %list_read_null_28, label %list_read_real_29
list_read_null_28:
  br label %list_read_end_30
list_read_real_29:
  %t201 = bitcast i8* %t199 to { i8**, i64, i64 }*
  %t202 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t201, i32 0, i32 0
  %t203 = load i8**, i8*** %t202
  %t204 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t201, i32 0, i32 1
  %t205 = load i64, i64* %t204
  br label %list_read_end_30
list_read_end_30:
  %t206 = phi i8** [ null, %list_read_null_28 ], [ %t203, %list_read_real_29 ]
  %t207 = phi i64 [ 0, %list_read_null_28 ], [ %t205, %list_read_real_29 ]
  %t208 = sext i32 2 to i64
  %t209 = icmp ult i64 %t208, %t207
  br i1 %t209, label %list_idx_ok_31, label %list_idx_oob_32
list_idx_ok_31:
  %t210 = getelementptr inbounds i8*, i8** %t206, i64 %t208
  %t211 = load i8*, i8** %t210
  %t212 = load i8*, i8** %t210
  call void @star_rc_retain(i8* %t212)
  br label %list_idx_end_33
list_idx_oob_32:
  %t213 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t213
  br label %list_idx_end_33
list_idx_end_33:
  %t214 = phi i8* [ %t211, %list_idx_ok_31 ], [ %t213, %list_idx_oob_32 ]
  call void @star_rc_release(i8* %t214)
  %t215 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t215, i8* %t214)
  %t216 = load i8*, i8** %t51
  %t217 = icmp eq i8* %t216, null
  br i1 %t217, label %list_read_null_34, label %list_read_real_35
list_read_null_34:
  br label %list_read_end_36
list_read_real_35:
  %t218 = bitcast i8* %t216 to { i8**, i64, i64 }*
  %t219 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t218, i32 0, i32 0
  %t220 = load i8**, i8*** %t219
  %t221 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t218, i32 0, i32 1
  %t222 = load i64, i64* %t221
  br label %list_read_end_36
list_read_end_36:
  %t223 = phi i8** [ null, %list_read_null_34 ], [ %t220, %list_read_real_35 ]
  %t224 = phi i64 [ 0, %list_read_null_34 ], [ %t222, %list_read_real_35 ]
  %t225 = trunc i64 %t224 to i32
  %t226 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t226, i32 %t225)
  %t228 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t229 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t230 = call i32 @strlen(i8* %t228)
  %t231 = call i32 @strlen(i8* %t229)
  %t232 = add i32 %t230, %t231
  %t233 = add i32 %t232, 1
  %t234 = sext i32 %t233 to i64
  %t235 = call i8* @star_rc_alloc(i64 %t234, i8* null)
  call i8* @strcpy(i8* %t235, i8* %t228)
  call i8* @strcat(i8* %t235, i8* %t229)
  call void @star_rc_release(i8* %t228)
  call void @star_rc_release(i8* %t229)
  store i8* %t235, i8** %t227
  %t236 = load i8*, i8** %t227
  %t237 = load i8*, i8** %t227
  call void @star_rc_retain(i8* %t237)
  %t238 = call i32 @shout_len(i8* %t236)
  %t239 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t239, i32 %t238)
  store i32 0, i32* %t240
  %t242 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t242, i8** %t241
  br label %while_cond_37
while_cond_37:
  %t243 = load i32, i32* %t240
  %t244 = icmp slt i32 %t243, 5
  br i1 %t244, label %while_body_38, label %while_else_39
while_body_38:
  %t245 = load i8*, i8** %t241
  %t246 = load i8*, i8** %t241
  call void @star_rc_retain(i8* %t246)
  %t247 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t248 = call i32 @strlen(i8* %t245)
  %t249 = call i32 @strlen(i8* %t247)
  %t250 = add i32 %t248, %t249
  %t251 = add i32 %t250, 1
  %t252 = sext i32 %t251 to i64
  %t253 = call i8* @star_rc_alloc(i64 %t252, i8* null)
  call i8* @strcpy(i8* %t253, i8* %t245)
  call i8* @strcat(i8* %t253, i8* %t247)
  call void @star_rc_release(i8* %t245)
  call void @star_rc_release(i8* %t247)
  %t254 = load i8*, i8** %t241
  call void @star_rc_release(i8* %t254)
  store i8* %t253, i8** %t241
  %t255 = load i32, i32* %t240
  %t256 = add i32 %t255, 1
  store i32 %t256, i32* %t240
  br label %while_cond_37
while_else_39:
  br label %while_end_40
while_end_40:
  %t257 = load i8*, i8** %t241
  %t258 = load i8*, i8** %t241
  call void @star_rc_retain(i8* %t258)
  call void @star_rc_release(i8* %t257)
  call i32 (i8*, ...) @printf(i8* %t257)
  %t259 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t259)
  %t260 = load i8*, i8** %t241
  call void @star_rc_release(i8* %t260)
  %t261 = load i8*, i8** %t227
  call void @star_rc_release(i8* %t261)
  %t262 = load i8*, i8** %t51
  call void @star_rc_release(i8* %t262)
  %t263 = getelementptr inbounds %Greeting, %Greeting* %t43, i32 0, i32 0
  %t264 = load i8*, i8** %t263
  call void @star_rc_release(i8* %t264)
  %t265 = getelementptr inbounds %Greeting, %Greeting* %t27, i32 0, i32 0
  %t266 = load i8*, i8** %t265
  call void @star_rc_release(i8* %t266)
  %t267 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t267)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t80 = alloca i64
  %t75 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t76 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t75, i32 0, i32 0
  %t77 = load i8**, i8*** %t76
  %t78 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t75, i32 0, i32 1
  %t79 = load i64, i64* %t78
  store i64 0, i64* %t80
  br label %list_release_cond_0
list_release_cond_0:
  %t81 = load i64, i64* %t80
  %t82 = icmp slt i64 %t81, %t79
  br i1 %t82, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t83 = getelementptr inbounds i8*, i8** %t77, i64 %t81
  %t84 = load i8*, i8** %t83
  call void @star_rc_release(i8* %t84)
  %t85 = add i64 %t81, 1
  store i64 %t85, i64* %t80
  br label %list_release_cond_0
list_release_end_2:
  %t86 = bitcast i8** %t77 to i8*
  call void @free(i8* %t86)
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
