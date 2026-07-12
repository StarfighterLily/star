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
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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
  %t1 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t1, i8** %t0
  %t2 = alloca i32
  store i32 8080, i32* %t2
  %t3 = alloca i8*
  %t4 = alloca [512 x i8]
  %t5 = getelementptr inbounds [512 x i8], [512 x i8]* %t4, i64 0, i64 0
  call i32 @WSAStartup(i16 514, i8* %t5)
  %t6 = call i8* @socket(i32 2, i32 1, i32 6)
  %t7 = icmp eq i8* %t6, inttoptr (i64 -1 to i8*)
  br i1 %t7, label %tcp_socket_fail_0, label %tcp_socket_ok_1
tcp_socket_fail_0:
  br label %tcp_connect_end_2
tcp_socket_ok_1:
  %t8 = load i8*, i8** %t0
  %t9 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t9)
  call void @star_rc_release(i8* %t8)
  %t10 = load i32, i32* %t2
  %t11 = trunc i32 %t10 to i16
  %t12 = call i16 @htons(i16 %t11)
  %t13 = call i32 @inet_addr(i8* %t8)
  %t14 = alloca [16 x i8]
  %t15 = getelementptr inbounds [16 x i8], [16 x i8]* %t14, i64 0, i64 0
  %t16 = bitcast i8* %t15 to i16*
  store i16 2, i16* %t16
  %t17 = getelementptr inbounds i8, i8* %t15, i64 2
  %t18 = bitcast i8* %t17 to i16*
  store i16 %t12, i16* %t18
  %t19 = getelementptr inbounds i8, i8* %t15, i64 4
  %t20 = bitcast i8* %t19 to i32*
  store i32 %t13, i32* %t20
  %t21 = getelementptr inbounds i8, i8* %t15, i64 8
  %t22 = bitcast i8* %t21 to i64*
  store i64 0, i64* %t22
  %t23 = call i32 @connect(i8* %t6, i8* %t15, i32 16)
  %t24 = icmp ne i32 %t23, 0
  br i1 %t24, label %tcp_connect_fail_3, label %tcp_connect_ok_4
tcp_connect_fail_3:
  call i32 @closesocket(i8* %t6)
  br label %tcp_connect_end_2
tcp_connect_ok_4:
  br label %tcp_connect_end_2
tcp_connect_end_2:
  %t25 = phi i8* [ null, %tcp_socket_fail_0 ], [ null, %tcp_connect_fail_3 ], [ %t6, %tcp_connect_ok_4 ]
  store i8* %t25, i8** %t3
  %t26 = load i8*, i8** %t3
  %t27 = icmp eq i8* %t26, null
  br i1 %t27, label %if_then_5, label %if_else_6
if_then_5:
  %t28 = load i8*, i8** %t0
  %t29 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t29)
  call void @star_rc_release(i8* %t28)
  %t30 = load i32, i32* %t2
  %t31 = getelementptr inbounds [49 x i8], [49 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i8* %t28, i32 %t30)
  %t32 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t32)
  ret i32 0
if_else_6:
  br label %if_end_7
if_end_7:
  %t33 = alloca i8*
  %t34 = getelementptr inbounds { i64, i8*, [36 x i8] }, { i64, i8*, [36 x i8] }* @.str.2, i64 0, i32 2, i64 0
  store i8* %t34, i8** %t33
  %t35 = alloca i1
  %t36 = load i8*, i8** %t3
  %t37 = icmp eq i8* %t36, null
  br i1 %t37, label %tcp_null_handle_8, label %tcp_handle_ok_9
tcp_null_handle_8:
  %t38 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t38)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_9:
  %t39 = load i8*, i8** %t33
  %t40 = load i8*, i8** %t33
  call void @star_rc_retain(i8* %t40)
  call void @star_rc_release(i8* %t39)
  %t41 = call i32 @strlen(i8* %t39)
  %t42 = call i32 @send(i8* %t36, i8* %t39, i32 %t41, i32 0)
  %t43 = icmp eq i32 %t42, %t41
  store i1 %t43, i1* %t35
  %t44 = load i1, i1* %t35
  %t45 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.4, i64 0, i64 0
  %t46 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.5, i64 0, i64 0
  %t47 = select i1 %t44, i8* %t45, i8* %t46
  %t48 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48, i8* %t47)
  %t49 = alloca i8*
  %t50 = load i8*, i8** %t3
  %t51 = icmp eq i8* %t50, null
  br i1 %t51, label %tcp_null_handle_10, label %tcp_handle_ok_11
tcp_null_handle_10:
  %t52 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t52)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_11:
  %t53 = call i8* @star_rc_alloc(i64 4096, i8* null)
  %t54 = call i32 @recv(i8* %t50, i8* %t53, i32 4095, i32 0)
  %t55 = icmp sgt i32 %t54, 0
  %t56 = sext i32 %t54 to i64
  %t57 = select i1 %t55, i64 %t56, i64 0
  %t58 = getelementptr inbounds i8, i8* %t53, i64 %t57
  store i8 0, i8* %t58
  store i8* %t53, i8** %t49
  %t59 = load i8*, i8** %t49
  %t60 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t60)
  call void @star_rc_release(i8* %t59)
  %t61 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i8* %t59)
  %t62 = load i8*, i8** %t3
  %t63 = icmp eq i8* %t62, null
  br i1 %t63, label %tcp_null_handle_12, label %tcp_handle_ok_13
tcp_null_handle_12:
  %t64 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t64)
  call void @exit(i32 1)
  unreachable
tcp_handle_ok_13:
  call i32 @closesocket(i8* %t62)
  %t65 = load i8*, i8** %t49
  call void @star_rc_release(i8* %t65)
  %t66 = load i8*, i8** %t33
  call void @star_rc_release(i8* %t66)
  %t67 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t67)
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
