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
  %t4 = alloca i8*
  %t6 = alloca i8*
  %t35 = alloca i1
  %t41 = alloca i1
  %t57 = alloca i8*
  %t67 = alloca i8*
  %t72 = alloca i64
  %t87 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t5 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.1, i64 0, i32 2, i64 0
  store i8* %t5, i8** %t4
  %t7 = load i8*, i8** %t2
  %t8 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t8)
  %t9 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t10 = call i8* @fopen(i8* %t7, i8* %t9)
  call void @star_rc_release(i8* %t7)
  call void @star_rc_release(i8* %t9)
  store i8* %t10, i8** %t6
  %t11 = load i8*, i8** %t6
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %if_then_0, label %if_else_1
if_then_0:
  %t13 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.3, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t13)
  call i32 (i8*, ...) @printf(i8* %t13)
  %t14 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t14)
  %t15 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t15)
  ret i32 0
if_else_1:
  br label %if_end_2
if_end_2:
  %t16 = load i8*, i8** %t6
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %file_null_handle_3, label %file_handle_ok_4
file_null_handle_3:
  %t18 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t18)
  call void @exit(i32 1)
  unreachable
file_handle_ok_4:
  %t19 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t20 = call i32 @strlen(i8* %t19)
  %t21 = sext i32 %t20 to i64
  %t22 = call i64 @fwrite(i8* %t19, i64 1, i64 %t21, i8* %t16)
  call void @star_rc_release(i8* %t19)
  %t23 = icmp eq i64 %t22, %t21
  %t24 = load i8*, i8** %t6
  %t25 = icmp eq i8* %t24, null
  br i1 %t25, label %file_null_handle_5, label %file_handle_ok_6
file_null_handle_5:
  %t26 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t26)
  call void @exit(i32 1)
  unreachable
file_handle_ok_6:
  %t27 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t28 = call i32 @strlen(i8* %t27)
  %t29 = sext i32 %t28 to i64
  %t30 = call i64 @fwrite(i8* %t27, i64 1, i64 %t29, i8* %t24)
  call void @star_rc_release(i8* %t27)
  %t31 = icmp eq i64 %t30, %t29
  %t32 = load i8*, i8** %t6
  %t33 = icmp eq i8* %t32, null
  br i1 %t33, label %file_null_handle_7, label %file_handle_ok_8
file_null_handle_7:
  %t34 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.8, i64 0, i64 0
  call i32 @puts(i8* %t34)
  call void @exit(i32 1)
  unreachable
file_handle_ok_8:
  call i32 @fclose(i8* %t32)
  store i8* null, i8** %t6
  %t36 = load i8*, i8** %t2
  %t37 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t37)
  %t38 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  %t39 = call i8* @fopen(i8* %t36, i8* %t38)
  call void @star_rc_release(i8* %t36)
  %t40 = icmp ne i8* %t39, null
  br i1 %t40, label %file_exists_close_9, label %file_exists_end_10
file_exists_close_9:
  call i32 @fclose(i8* %t39)
  br label %file_exists_end_10
file_exists_end_10:
  store i1 %t40, i1* %t35
  %t42 = load i8*, i8** %t4
  %t43 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t43)
  %t44 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  %t45 = call i8* @fopen(i8* %t42, i8* %t44)
  call void @star_rc_release(i8* %t42)
  %t46 = icmp ne i8* %t45, null
  br i1 %t46, label %file_exists_close_11, label %file_exists_end_12
file_exists_close_11:
  call i32 @fclose(i8* %t45)
  br label %file_exists_end_12
file_exists_end_12:
  store i1 %t46, i1* %t41
  %t47 = load i1, i1* %t35
  %t48 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t49 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t50 = select i1 %t47, i8* %t48, i8* %t49
  %t51 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, i8* %t50)
  %t52 = load i1, i1* %t41
  %t53 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t54 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t55 = select i1 %t52, i8* %t53, i8* %t54
  %t56 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t56, i8* %t55)
  %t58 = load i8*, i8** %t2
  %t59 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t59)
  %t60 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.17, i64 0, i32 2, i64 0
  %t61 = call i8* @fopen(i8* %t58, i8* %t60)
  call void @star_rc_release(i8* %t58)
  call void @star_rc_release(i8* %t60)
  store i8* %t61, i8** %t57
  %t62 = load i8*, i8** %t57
  %t63 = icmp eq i8* %t62, null
  br i1 %t63, label %if_then_13, label %if_else_14
if_then_13:
  %t64 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.18, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t64)
  call i32 (i8*, ...) @printf(i8* %t64)
  %t65 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t65)
  %t66 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t66)
  ret i32 0
if_else_14:
  br label %if_end_15
if_end_15:
  %t68 = load i8*, i8** %t57
  %t69 = icmp eq i8* %t68, null
  br i1 %t69, label %file_null_handle_16, label %file_handle_ok_17
file_null_handle_16:
  %t70 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.19, i64 0, i64 0
  call i32 @puts(i8* %t70)
  call void @exit(i32 1)
  unreachable
file_handle_ok_17:
  %t71 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t72
  br label %file_read_line_cond_18
file_read_line_cond_18:
  %t73 = load i64, i64* %t72
  %t74 = icmp ult i64 %t73, 1023
  br i1 %t74, label %file_read_line_body_19, label %file_read_line_end_21
file_read_line_body_19:
  %t75 = call i32 @fgetc(i8* %t68)
  %t76 = icmp eq i32 %t75, -1
  %t77 = icmp eq i32 %t75, 10
  %t78 = or i1 %t76, %t77
  br i1 %t78, label %file_read_line_end_21, label %file_read_line_store_20
file_read_line_store_20:
  %t79 = getelementptr inbounds i8, i8* %t71, i64 %t73
  %t80 = trunc i32 %t75 to i8
  store i8 %t80, i8* %t79
  %t81 = add i64 %t73, 1
  store i64 %t81, i64* %t72
  br label %file_read_line_cond_18
file_read_line_end_21:
  %t82 = load i64, i64* %t72
  %t83 = getelementptr inbounds i8, i8* %t71, i64 %t82
  store i8 0, i8* %t83
  store i8* %t71, i8** %t67
  %t84 = load i8*, i8** %t67
  %t85 = load i8*, i8** %t67
  call void @star_rc_retain(i8* %t85)
  call void @star_rc_release(i8* %t84)
  %t86 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i8* %t84)
  %t88 = load i8*, i8** %t57
  %t89 = icmp eq i8* %t88, null
  br i1 %t89, label %file_null_handle_22, label %file_handle_ok_23
file_null_handle_22:
  %t90 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t90)
  call void @exit(i32 1)
  unreachable
file_handle_ok_23:
  %t91 = call i32 @ftell(i8* %t88)
  call i32 @fseek(i8* %t88, i32 0, i32 2)
  %t92 = call i32 @ftell(i8* %t88)
  call i32 @fseek(i8* %t88, i32 %t91, i32 0)
  %t93 = sub i32 %t92, %t91
  %t94 = sext i32 %t93 to i64
  %t95 = icmp sge i64 %t94, 0
  %t96 = select i1 %t95, i64 %t94, i64 0
  %t97 = add i64 %t96, 1
  %t98 = call i8* @star_rc_alloc(i64 %t97, i8* null)
  %t99 = call i64 @fread(i8* %t98, i64 1, i64 %t96, i8* %t88)
  %t100 = getelementptr inbounds i8, i8* %t98, i64 %t99
  store i8 0, i8* %t100
  store i8* %t98, i8** %t87
  %t101 = load i8*, i8** %t87
  %t102 = load i8*, i8** %t87
  call void @star_rc_retain(i8* %t102)
  call void @star_rc_release(i8* %t101)
  %t103 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t103, i8* %t101)
  %t104 = load i8*, i8** %t57
  %t105 = icmp eq i8* %t104, null
  br i1 %t105, label %file_null_handle_24, label %file_handle_ok_25
file_null_handle_24:
  %t106 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t106)
  call void @exit(i32 1)
  unreachable
file_handle_ok_25:
  call i32 @fclose(i8* %t104)
  store i8* null, i8** %t57
  %t107 = load i8*, i8** %t87
  call void @star_rc_release(i8* %t107)
  %t108 = load i8*, i8** %t67
  call void @star_rc_release(i8* %t108)
  %t109 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t109)
  %t110 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t110)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"star_file_io_example_scratch.txt\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"star_file_io_example_missing.txt\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"w\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"failed to open for writing\00" }
@.str.4 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"hello from star\0A\00" }
@.str.6 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"second line\0A\00" }
@.str.8 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.9 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.10 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.11 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.12 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.13 = private unnamed_addr constant [31 x i8] c"file_exists(written file): %s\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [31 x i8] c"file_exists(missing file): %s\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.18 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"failed to open for reading\00" }
@.str.19 = private unnamed_addr constant [78 x i8] c"star runtime error: file_read_line(..) called with a null/closed file handle\0A\00"
@.str.20 = private unnamed_addr constant [11 x i8] c"line1: %s\0A\00"
@.str.21 = private unnamed_addr constant [73 x i8] c"star runtime error: file_read(..) called with a null/closed file handle\0A\00"
@.str.22 = private unnamed_addr constant [10 x i8] c"rest: %s\0A\00"
@.str.23 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
