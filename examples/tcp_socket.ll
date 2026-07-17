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
  %t4 = alloca i32
  %t5 = alloca i8*
  %t6 = alloca [512 x i8]
  %t17 = alloca [16 x i8]
  %t36 = alloca i8*
  %t38 = alloca i1
  %t52 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  store i32 8080, i32* %t4
  %t7 = getelementptr inbounds [512 x i8], [512 x i8]* %t6, i64 0, i64 0
  call i32 @WSAStartup(i16 514, i8* %t7)
  %t8 = call i8* @socket(i32 2, i32 1, i32 6)
  %t9 = icmp eq i8* %t8, inttoptr (i64 -1 to i8*)
  br i1 %t9, label %tcp_socket_fail_0, label %tcp_socket_ok_1
tcp_socket_fail_0:
  br label %tcp_connect_end_2
tcp_socket_ok_1:
  %t10 = load i8*, i8** %t2
  %t11 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t11)
  %t12 = load i32, i32* %t4
  %t13 = trunc i32 %t12 to i16
  %t14 = call i16 @htons(i16 %t13)
  %t15 = call i32 @inet_addr(i8* %t10)
  call void @star_rc_release(i8* %t10)
  %t16 = icmp eq i32 %t15, -1
  br i1 %t16, label %tcp_addr_invalid_3, label %tcp_addr_valid_4
tcp_addr_invalid_3:
  call i32 @closesocket(i8* %t8)
  br label %tcp_connect_end_2
tcp_addr_valid_4:
  %t18 = getelementptr inbounds [16 x i8], [16 x i8]* %t17, i64 0, i64 0
  %t19 = bitcast i8* %t18 to i16*
  store i16 2, i16* %t19
  %t20 = getelementptr inbounds i8, i8* %t18, i64 2
  %t21 = bitcast i8* %t20 to i16*
  store i16 %t14, i16* %t21
  %t22 = getelementptr inbounds i8, i8* %t18, i64 4
  %t23 = bitcast i8* %t22 to i32*
  store i32 %t15, i32* %t23
  %t24 = getelementptr inbounds i8, i8* %t18, i64 8
  %t25 = bitcast i8* %t24 to i64*
  store i64 0, i64* %t25
  %t26 = call i32 @connect(i8* %t8, i8* %t18, i32 16)
  %t27 = icmp ne i32 %t26, 0
  br i1 %t27, label %tcp_connect_fail_5, label %tcp_connect_ok_6
tcp_connect_fail_5:
  call i32 @closesocket(i8* %t8)
  br label %tcp_connect_end_2
tcp_connect_ok_6:
  br label %tcp_connect_end_2
tcp_connect_end_2:
  %t28 = phi i8* [ null, %tcp_socket_fail_0 ], [ null, %tcp_addr_invalid_3 ], [ null, %tcp_connect_fail_5 ], [ %t8, %tcp_connect_ok_6 ]
  store i8* %t28, i8** %t5
  %t29 = load i8*, i8** %t5
  %t30 = icmp eq i8* %t29, null
  br i1 %t30, label %if_then_7, label %if_else_8
if_then_7:
  %t31 = load i8*, i8** %t2
  %t32 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t32)
  call void @star_rc_release(i8* %t31)
  %t33 = load i32, i32* %t4
  %t34 = getelementptr inbounds [49 x i8], [49 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t34, i8* %t31, i32 %t33)
  %t35 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t35)
  ret i32 0
if_else_8:
  br label %if_end_9
if_end_9:
  %t37 = getelementptr inbounds { i64, i8*, [36 x i8] }, { i64, i8*, [36 x i8] }* @.str.2, i64 0, i32 2, i64 0
  store i8* %t37, i8** %t36
  %t39 = load i8*, i8** %t5
  %t40 = icmp eq i8* %t39, null
  br i1 %t40, label %tcp_null_handle_10, label %tcp_handle_ok_11
tcp_null_handle_10:
  %t41 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t41)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_11:
  %t42 = load i8*, i8** %t36
  %t43 = load i8*, i8** %t36
  call void @star_rc_retain(i8* %t43)
  %t44 = call i32 @strlen(i8* %t42)
  %t45 = call i32 @send(i8* %t39, i8* %t42, i32 %t44, i32 0)
  call void @star_rc_release(i8* %t42)
  %t46 = icmp eq i32 %t45, %t44
  store i1 %t46, i1* %t38
  %t47 = load i1, i1* %t38
  %t48 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.4, i64 0, i64 0
  %t49 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.5, i64 0, i64 0
  %t50 = select i1 %t47, i8* %t48, i8* %t49
  %t51 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, i8* %t50)
  %t53 = load i8*, i8** %t5
  %t54 = icmp eq i8* %t53, null
  br i1 %t54, label %tcp_null_handle_12, label %tcp_handle_ok_13
tcp_null_handle_12:
  %t55 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t55)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_13:
  %t56 = call i8* @star_rc_alloc(i64 4096, i8* null)
  %t57 = call i32 @recv(i8* %t53, i8* %t56, i32 4095, i32 0)
  %t58 = icmp sgt i32 %t57, 0
  %t59 = sext i32 %t57 to i64
  %t60 = select i1 %t58, i64 %t59, i64 0
  %t61 = getelementptr inbounds i8, i8* %t56, i64 %t60
  store i8 0, i8* %t61
  store i8* %t56, i8** %t52
  %t62 = load i8*, i8** %t52
  %t63 = load i8*, i8** %t52
  call void @star_rc_retain(i8* %t63)
  call void @star_rc_release(i8* %t62)
  %t64 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t64, i8* %t62)
  %t65 = load i8*, i8** %t5
  %t66 = icmp eq i8* %t65, null
  br i1 %t66, label %tcp_null_handle_14, label %tcp_handle_ok_15
tcp_null_handle_14:
  %t67 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t67)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_15:
  call i32 @closesocket(i8* %t65)
  store i8* null, i8** %t5
  %t68 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t68)
  %t69 = load i8*, i8** %t36
  call void @star_rc_release(i8* %t69)
  %t70 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t70)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"127.0.0.1\00" }
@.str.1 = private unnamed_addr constant [49 x i8] c"tcp_connect(%s, %d) failed -- no listener there\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [36 x i8] } { i64 -1, i8* null, [36 x i8] c"GET / HTTP/1.0\0AHost: 127.0.0.1\0A\0A\00" }
@.str.3 = private unnamed_addr constant [74 x i8] c"star runtime error: tcp_send(..) called with a null/closed socket handle\0A\00"
@.str.4 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.5 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.6 = private unnamed_addr constant [17 x i8] c"tcp_send ok: %s\0A\00"
@.str.7 = private unnamed_addr constant [74 x i8] c"star runtime error: tcp_recv(..) called with a null/closed socket handle\0A\00"
@.str.8 = private unnamed_addr constant [14 x i8] c"tcp_recv: %s\0A\00"
@.str.9 = private unnamed_addr constant [75 x i8] c"star runtime error: tcp_close(..) called with a null/closed socket handle\0A\00"
