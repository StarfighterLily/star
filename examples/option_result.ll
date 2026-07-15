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

%Shape = type { i32, [1 x i64] }
%Result__i32__i32 = type { i32, [1 x i64] }
%Option__i32 = type { i32, [1 x i64] }
define %Result__i32__i32 @safe_div(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t4 = alloca %Result__i32__i32
  %t10 = alloca %Result__i32__i32
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = icmp eq i32 %t2, 0
  br i1 %t3, label %if_then_0, label %if_else_1
if_then_0:
  %t5 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t4, i32 0, i32 0
  store i32 1, i32* %t5
  %t6 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t4, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  store i32 1, i32* %t8
  %t9 = load %Result__i32__i32, %Result__i32__i32* %t4
  ret %Result__i32__i32 %t9
if_else_1:
  br label %if_end_2
if_end_2:
  %t11 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t10, i32 0, i32 0
  store i32 0, i32* %t11
  %t12 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t10, i32 0, i32 1
  %t13 = bitcast [1 x i64]* %t12 to { i32 }*
  %t14 = load i32, i32* %t0
  %t15 = load i32, i32* %t1
  %t16 = icmp eq i32 %t15, 0
  %t17 = icmp eq i32 %t14, -2147483648
  %t18 = icmp eq i32 %t15, -1
  %t19 = and i1 %t17, %t18
  %t20 = or i1 %t16, %t19
  br i1 %t20, label %int_div_fail_3, label %int_div_ok_4
int_div_fail_3:
  %t21 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t21)
  call void @exit(i32 1)
  unreachable
int_div_ok_4:
  %t22 = sdiv i32 %t14, %t15
  %t23 = getelementptr inbounds { i32 }, { i32 }* %t13, i32 0, i32 0
  store i32 %t22, i32* %t23
  %t24 = load %Result__i32__i32, %Result__i32__i32* %t10
  ret %Result__i32__i32 %t24
}

define %Option__i32 @first_even(i32 %a, i32 %b, i32 %c) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t2 = alloca i32
  %t12 = alloca %Option__i32
  %t28 = alloca %Option__i32
  %t44 = alloca %Option__i32
  %t51 = alloca %Option__i32
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  store i32 %c, i32* %t2
  %t3 = load i32, i32* %t0
  %t4 = icmp eq i32 2, 0
  %t5 = icmp eq i32 %t3, -2147483648
  %t6 = icmp eq i32 2, -1
  %t7 = and i1 %t5, %t6
  %t8 = or i1 %t4, %t7
  br i1 %t8, label %int_div_fail_5, label %int_div_ok_6
int_div_fail_5:
  %t9 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
int_div_ok_6:
  %t10 = srem i32 %t3, 2
  %t11 = icmp eq i32 %t10, 0
  br i1 %t11, label %if_then_7, label %if_else_8
if_then_7:
  %t13 = getelementptr inbounds %Option__i32, %Option__i32* %t12, i32 0, i32 0
  store i32 1, i32* %t13
  %t14 = getelementptr inbounds %Option__i32, %Option__i32* %t12, i32 0, i32 1
  %t15 = bitcast [1 x i64]* %t14 to { i32 }*
  %t16 = load i32, i32* %t0
  %t17 = getelementptr inbounds { i32 }, { i32 }* %t15, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = load %Option__i32, %Option__i32* %t12
  ret %Option__i32 %t18
if_else_8:
  br label %if_end_9
if_end_9:
  %t19 = load i32, i32* %t1
  %t20 = icmp eq i32 2, 0
  %t21 = icmp eq i32 %t19, -2147483648
  %t22 = icmp eq i32 2, -1
  %t23 = and i1 %t21, %t22
  %t24 = or i1 %t20, %t23
  br i1 %t24, label %int_div_fail_10, label %int_div_ok_11
int_div_fail_10:
  %t25 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t25)
  call void @exit(i32 1)
  unreachable
int_div_ok_11:
  %t26 = srem i32 %t19, 2
  %t27 = icmp eq i32 %t26, 0
  br i1 %t27, label %if_then_12, label %if_else_13
if_then_12:
  %t29 = getelementptr inbounds %Option__i32, %Option__i32* %t28, i32 0, i32 0
  store i32 1, i32* %t29
  %t30 = getelementptr inbounds %Option__i32, %Option__i32* %t28, i32 0, i32 1
  %t31 = bitcast [1 x i64]* %t30 to { i32 }*
  %t32 = load i32, i32* %t1
  %t33 = getelementptr inbounds { i32 }, { i32 }* %t31, i32 0, i32 0
  store i32 %t32, i32* %t33
  %t34 = load %Option__i32, %Option__i32* %t28
  ret %Option__i32 %t34
if_else_13:
  br label %if_end_14
if_end_14:
  %t35 = load i32, i32* %t2
  %t36 = icmp eq i32 2, 0
  %t37 = icmp eq i32 %t35, -2147483648
  %t38 = icmp eq i32 2, -1
  %t39 = and i1 %t37, %t38
  %t40 = or i1 %t36, %t39
  br i1 %t40, label %int_div_fail_15, label %int_div_ok_16
int_div_fail_15:
  %t41 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t41)
  call void @exit(i32 1)
  unreachable
int_div_ok_16:
  %t42 = srem i32 %t35, 2
  %t43 = icmp eq i32 %t42, 0
  br i1 %t43, label %if_then_17, label %if_else_18
if_then_17:
  %t45 = getelementptr inbounds %Option__i32, %Option__i32* %t44, i32 0, i32 0
  store i32 1, i32* %t45
  %t46 = getelementptr inbounds %Option__i32, %Option__i32* %t44, i32 0, i32 1
  %t47 = bitcast [1 x i64]* %t46 to { i32 }*
  %t48 = load i32, i32* %t2
  %t49 = getelementptr inbounds { i32 }, { i32 }* %t47, i32 0, i32 0
  store i32 %t48, i32* %t49
  %t50 = load %Option__i32, %Option__i32* %t44
  ret %Option__i32 %t50
if_else_18:
  br label %if_end_19
if_end_19:
  %t52 = getelementptr inbounds %Option__i32, %Option__i32* %t51, i32 0, i32 0
  store i32 0, i32* %t52
  %t53 = load %Option__i32, %Option__i32* %t51
  ret %Option__i32 %t53
}

define %Result__i32__i32 @checked_double(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t2 = alloca i32
  %t6 = alloca %Result__i32__i32
  %t26 = alloca %Result__i32__i32
  %t34 = alloca %Result__i32__i32
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  %t3 = load i32, i32* %t0
  %t4 = load i32, i32* %t1
  %t5 = call %Result__i32__i32 @safe_div(i32 %t3, i32 %t4)
  store %Result__i32__i32 %t5, %Result__i32__i32* %t6
  br label %match_scrutinee_8
match_scrutinee_8:
  %t12 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t6, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t11 = icmp eq i32 %t13, 0
  br i1 %t11, label %match_then_0_9, label %match_next_0_10
match_then_0_9:
  %t14 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t6, i32 0, i32 1
  %t15 = bitcast [1 x i64]* %t14 to { i32 }*
  %t16 = getelementptr inbounds { i32 }, { i32 }* %t15, i32 0, i32 0
  %t17 = load i32, i32* %t16
  br label %match_end_7
match_next_0_10:
  %t21 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t6, i32 0, i32 0
  %t22 = load i32, i32* %t21
  %t20 = icmp eq i32 %t22, 1
  br i1 %t20, label %match_then_1_18, label %match_next_1_19
match_then_1_18:
  %t23 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t6, i32 0, i32 1
  %t24 = bitcast [1 x i64]* %t23 to { i32 }*
  %t25 = getelementptr inbounds { i32 }, { i32 }* %t24, i32 0, i32 0
  %t27 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t26, i32 0, i32 0
  store i32 1, i32* %t27
  %t28 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t26, i32 0, i32 1
  %t29 = bitcast [1 x i64]* %t28 to { i32 }*
  %t30 = load i32, i32* %t25
  %t31 = getelementptr inbounds { i32 }, { i32 }* %t29, i32 0, i32 0
  store i32 %t30, i32* %t31
  %t32 = load %Result__i32__i32, %Result__i32__i32* %t26
  ret %Result__i32__i32 %t32
match_next_1_19:
  br label %match_end_7
match_end_7:
  %t33 = phi i32 [ %t17, %match_then_0_9 ], [ undef, %match_next_1_19 ]
  store i32 %t33, i32* %t2
  %t35 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t34, i32 0, i32 1
  %t37 = bitcast [1 x i64]* %t36 to { i32 }*
  %t38 = load i32, i32* %t2
  %t39 = mul i32 %t38, 2
  %t40 = getelementptr inbounds { i32 }, { i32 }* %t37, i32 0, i32 0
  store i32 %t39, i32* %t40
  %t41 = load %Result__i32__i32, %Result__i32__i32* %t34
  ret %Result__i32__i32 %t41
}

define %Option__i32 @first_even_doubled(i32 %a, i32 %b, i32 %c) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca i32
  %t8 = alloca %Option__i32
  %t25 = alloca %Option__i32
  %t29 = alloca %Option__i32
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  store i32 %c, i32* %t2
  %t4 = load i32, i32* %t0
  %t5 = load i32, i32* %t1
  %t6 = load i32, i32* %t2
  %t7 = call %Option__i32 @first_even(i32 %t4, i32 %t5, i32 %t6)
  store %Option__i32 %t7, %Option__i32* %t8
  br label %match_scrutinee_10
match_scrutinee_10:
  %t14 = getelementptr inbounds %Option__i32, %Option__i32* %t8, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t13 = icmp eq i32 %t15, 1
  br i1 %t13, label %match_then_0_11, label %match_next_0_12
match_then_0_11:
  %t16 = getelementptr inbounds %Option__i32, %Option__i32* %t8, i32 0, i32 1
  %t17 = bitcast [1 x i64]* %t16 to { i32 }*
  %t18 = getelementptr inbounds { i32 }, { i32 }* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t18
  br label %match_end_9
match_next_0_12:
  %t23 = getelementptr inbounds %Option__i32, %Option__i32* %t8, i32 0, i32 0
  %t24 = load i32, i32* %t23
  %t22 = icmp eq i32 %t24, 0
  br i1 %t22, label %match_then_1_20, label %match_next_1_21
match_then_1_20:
  %t26 = getelementptr inbounds %Option__i32, %Option__i32* %t25, i32 0, i32 0
  store i32 0, i32* %t26
  %t27 = load %Option__i32, %Option__i32* %t25
  ret %Option__i32 %t27
match_next_1_21:
  br label %match_end_9
match_end_9:
  %t28 = phi i32 [ %t19, %match_then_0_11 ], [ undef, %match_next_1_21 ]
  store i32 %t28, i32* %t3
  %t30 = getelementptr inbounds %Option__i32, %Option__i32* %t29, i32 0, i32 0
  store i32 1, i32* %t30
  %t31 = getelementptr inbounds %Option__i32, %Option__i32* %t29, i32 0, i32 1
  %t32 = bitcast [1 x i64]* %t31 to { i32 }*
  %t33 = load i32, i32* %t3
  %t34 = mul i32 %t33, 2
  %t35 = getelementptr inbounds { i32 }, { i32 }* %t32, i32 0, i32 0
  store i32 %t34, i32* %t35
  %t36 = load %Option__i32, %Option__i32* %t29
  ret %Option__i32 %t36
}

define i32 @describe_option(%Option__i32 %o) {
entry:
  %t0 = alloca %Option__i32
  store %Option__i32 %o, %Option__i32* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 1
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  ret i32 %t11
match_next_0_4:
  %t15 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t16 = load i32, i32* %t15
  %t14 = icmp eq i32 %t16, 0
  br i1 %t14, label %match_then_1_12, label %match_next_1_13
match_then_1_12:
  %t17 = sub i32 0, 1
  ret i32 %t17
match_next_1_13:
  br label %match_end_1
match_end_1:
  unreachable
}

define i32 @unwrap_or(%Option__i32 %o, i32 %default) {
entry:
  %t0 = alloca %Option__i32
  %t1 = alloca i32
  store %Option__i32 %o, %Option__i32* %t0
  store i32 %default, i32* %t1
  br label %match_scrutinee_3
match_scrutinee_3:
  %t7 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t8 = load i32, i32* %t7
  %t6 = icmp eq i32 %t8, 1
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t9 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 1
  %t10 = bitcast [1 x i64]* %t9 to { i32 }*
  %t11 = getelementptr inbounds { i32 }, { i32 }* %t10, i32 0, i32 0
  %t12 = load i32, i32* %t11
  br label %match_end_2
match_next_0_5:
  %t16 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 0
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = load i32, i32* %t1
  br label %match_end_2
match_next_1_14:
  br label %match_end_2
match_end_2:
  %t19 = phi i32 [ %t12, %match_then_0_4 ], [ %t18, %match_then_1_13 ], [ undef, %match_next_1_14 ]
  ret i32 %t19
}

define void @describe_sign(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp sle i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t7 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.4, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t7)
  %t8 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8)
  br label %match_end_2
match_next_0_5:
  %t11 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.6, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t11)
  %t12 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12)
  br label %match_end_2
match_end_2:
  %t13 = getelementptr inbounds { i64, i8*, [16 x i8] }, { i64, i8*, [16 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t13)
  %t14 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14)
  ret void
}

define void @print_div(%Result__i32__i32 %r) {
entry:
  %t0 = alloca %Result__i32__i32
  store %Result__i32__i32 %r, %Result__i32__i32* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  br label %match_end_1
match_next_0_4:
  %t16 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 1
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32 }*
  %t20 = getelementptr inbounds { i32 }, { i32 }* %t19, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  br label %match_end_1
match_next_1_14:
  br label %match_end_1
match_end_1:
  ret void
}

define void @print_doubled(%Result__i32__i32 %r) {
entry:
  %t0 = alloca %Result__i32__i32
  store %Result__i32__i32 %r, %Result__i32__i32* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  br label %match_end_1
match_next_0_4:
  %t16 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 1
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = getelementptr inbounds %Result__i32__i32, %Result__i32__i32* %t0, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32 }*
  %t20 = getelementptr inbounds { i32 }, { i32 }* %t19, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  br label %match_end_1
match_next_1_14:
  br label %match_end_1
match_end_1:
  ret void
}

define void @print_option(%Option__i32 %o) {
entry:
  %t0 = alloca %Option__i32
  store %Option__i32 %o, %Option__i32* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 1
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  br label %match_end_1
match_next_0_4:
  %t16 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 0
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = getelementptr inbounds { i64, i8*, [25 x i8] }, { i64, i8*, [25 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t18)
  %t19 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19)
  br label %match_end_1
match_next_1_14:
  br label %match_end_1
match_end_1:
  ret void
}

define i32 @area(%Shape %s) {
entry:
  %t0 = alloca %Shape
  store %Shape %s, %Shape* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = mul i32 3, %t11
  %t13 = load i32, i32* %t10
  %t14 = mul i32 %t12, %t13
  ret i32 %t14
match_next_0_4:
  %t18 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t17 = icmp eq i32 %t19, 1
  br i1 %t17, label %match_then_1_15, label %match_next_1_16
match_then_1_15:
  %t20 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 1
  %t21 = bitcast [1 x i64]* %t20 to { i32, i32 }*
  %t22 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t21, i32 0, i32 1
  %t24 = load i32, i32* %t22
  %t25 = load i32, i32* %t23
  %t26 = mul i32 %t24, %t25
  ret i32 %t26
match_next_1_16:
  br label %match_end_1
match_end_1:
  unreachable
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t8 = alloca %Shape
  %t16 = alloca %Shape
  %t25 = alloca %Option__i32
  %t34 = alloca %Option__i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call %Result__i32__i32 @safe_div(i32 10, i32 2)
  call void @print_div(%Result__i32__i32 %t0)
  %t1 = call %Result__i32__i32 @safe_div(i32 10, i32 0)
  call void @print_div(%Result__i32__i32 %t1)
  %t2 = call %Option__i32 @first_even(i32 1, i32 3, i32 4)
  %t3 = call i32 @describe_option(%Option__i32 %t2)
  %t4 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t4, i32 %t3)
  %t5 = call %Option__i32 @first_even(i32 1, i32 3, i32 5)
  %t6 = call i32 @describe_option(%Option__i32 %t5)
  %t7 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t9 = getelementptr inbounds %Shape, %Shape* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %Shape, %Shape* %t8, i32 0, i32 1
  %t11 = bitcast [1 x i64]* %t10 to { i32 }*
  %t12 = getelementptr inbounds { i32 }, { i32 }* %t11, i32 0, i32 0
  store i32 2, i32* %t12
  %t13 = load %Shape, %Shape* %t8
  %t14 = call i32 @area(%Shape %t13)
  %t15 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t14)
  %t17 = getelementptr inbounds %Shape, %Shape* %t16, i32 0, i32 0
  store i32 1, i32* %t17
  %t18 = getelementptr inbounds %Shape, %Shape* %t16, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32, i32 }*
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 0
  store i32 3, i32* %t20
  %t21 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 1
  store i32 4, i32* %t21
  %t22 = load %Shape, %Shape* %t16
  %t23 = call i32 @area(%Shape %t22)
  %t24 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, i32 %t23)
  %t26 = getelementptr inbounds %Option__i32, %Option__i32* %t25, i32 0, i32 0
  store i32 1, i32* %t26
  %t27 = getelementptr inbounds %Option__i32, %Option__i32* %t25, i32 0, i32 1
  %t28 = bitcast [1 x i64]* %t27 to { i32 }*
  %t29 = getelementptr inbounds { i32 }, { i32 }* %t28, i32 0, i32 0
  store i32 7, i32* %t29
  %t30 = load %Option__i32, %Option__i32* %t25
  %t31 = sub i32 0, 1
  %t32 = call i32 @unwrap_or(%Option__i32 %t30, i32 %t31)
  %t33 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.21, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t33, i32 %t32)
  %t35 = getelementptr inbounds %Option__i32, %Option__i32* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = load %Option__i32, %Option__i32* %t34
  %t37 = sub i32 0, 1
  %t38 = call i32 @unwrap_or(%Option__i32 %t36, i32 %t37)
  %t39 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39, i32 %t38)
  %t40 = sub i32 0, 3
  call void @describe_sign(i32 %t40)
  call void @describe_sign(i32 4)
  %t41 = call %Result__i32__i32 @checked_double(i32 10, i32 2)
  call void @print_doubled(%Result__i32__i32 %t41)
  %t42 = call %Result__i32__i32 @checked_double(i32 10, i32 0)
  call void @print_doubled(%Result__i32__i32 %t42)
  %t43 = call %Option__i32 @first_even_doubled(i32 1, i32 3, i32 4)
  call void @print_option(%Option__i32 %t43)
  %t44 = call %Option__i32 @first_even_doubled(i32 1, i32 3, i32 5)
  call void @print_option(%Option__i32 %t44)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.1 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.2 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.3 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"non-positive\00" }
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"positive\00" }
@.str.7 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [16 x i8] } { i64 -1, i8* null, [16 x i8] c"done describing\00" }
@.str.9 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.10 = private unnamed_addr constant [8 x i8] c"ok: %d\0A\00"
@.str.11 = private unnamed_addr constant [9 x i8] c"err: %d\0A\00"
@.str.12 = private unnamed_addr constant [23 x i8] c"checked_double ok: %d\0A\00"
@.str.13 = private unnamed_addr constant [24 x i8] c"checked_double err: %d\0A\00"
@.str.14 = private unnamed_addr constant [24 x i8] c"first_even_doubled: %d\0A\00"
@.str.15 = private unnamed_addr constant { i64, i8*, [25 x i8] } { i64 -1, i8* null, [25 x i8] c"first_even_doubled: none\00" }
@.str.16 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.17 = private unnamed_addr constant [11 x i8] c"found: %d\0A\00"
@.str.18 = private unnamed_addr constant [11 x i8] c"found: %d\0A\00"
@.str.19 = private unnamed_addr constant [17 x i8] c"circle area: %d\0A\00"
@.str.20 = private unnamed_addr constant [15 x i8] c"rect area: %d\0A\00"
@.str.21 = private unnamed_addr constant [29 x i8] c"unwrap_or(Some(7), -1) = %d\0A\00"
@.str.22 = private unnamed_addr constant [26 x i8] c"unwrap_or(None, -1) = %d\0A\00"
