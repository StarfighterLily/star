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

define i1 @side_effect(i8* %tag) {
entry:
  %t0 = alloca i8*
  store i8* %tag, i8** %t0
  %t1 = load i8*, i8** %t0
  %t2 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t2)
  call void @star_rc_release(i8* %t1)
  %t3 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i8* %t1)
  %t4 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t4)
  ret i1 true
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i32
  %t2 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i32 5, i32* %t1
  %t3 = sub i32 0, 3
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t1
  %t5 = icmp sgt i32 %t4, 0
  br i1 %t5, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t6 = load i32, i32* %t2
  %t7 = icmp sgt i32 %t6, 0
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t8 = phi i1 [ %t7, %logic_rhs_0 ], [ false, %logic_short_1 ]
  br i1 %t8, label %if_then_3, label %if_else_4
if_then_3:
  %t9 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t9)
  call i32 (i8*, ...) @printf(i8* %t9)
  br label %if_end_5
if_else_4:
  %t10 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.2, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t10)
  call i32 (i8*, ...) @printf(i8* %t10)
  br label %if_end_5
if_end_5:
  %t11 = load i32, i32* %t1
  %t12 = icmp sgt i32 %t11, 0
  br i1 %t12, label %logic_short_7, label %logic_rhs_6
logic_rhs_6:
  %t13 = load i32, i32* %t2
  %t14 = icmp sgt i32 %t13, 0
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t15 = phi i1 [ %t14, %logic_rhs_6 ], [ true, %logic_short_7 ]
  br i1 %t15, label %if_then_9, label %if_else_10
if_then_9:
  %t16 = getelementptr inbounds { i64, i8*, [22 x i8] }, { i64, i8*, [22 x i8] }* @.str.3, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t16)
  call i32 (i8*, ...) @printf(i8* %t16)
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t17 = load i32, i32* %t1
  %t18 = icmp sgt i32 %t17, 0
  br i1 %t18, label %logic_rhs_12, label %logic_short_13
logic_rhs_12:
  %t19 = load i32, i32* %t2
  %t20 = icmp sgt i32 %t19, 0
  br label %logic_end_14
logic_short_13:
  br label %logic_end_14
logic_end_14:
  %t21 = phi i1 [ %t20, %logic_rhs_12 ], [ false, %logic_short_13 ]
  %t22 = xor i1 true, %t21
  br i1 %t22, label %if_then_15, label %if_else_16
if_then_15:
  %t23 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.4, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t23)
  call i32 (i8*, ...) @printf(i8* %t23)
  br label %if_end_17
if_else_16:
  br label %if_end_17
if_end_17:
  %t24 = load i32, i32* %t1
  %t25 = icmp sgt i32 %t24, 0
  br i1 %t25, label %logic_rhs_18, label %logic_short_19
logic_rhs_18:
  %t26 = load i32, i32* %t2
  %t27 = icmp slt i32 %t26, 0
  br label %logic_end_20
logic_short_19:
  br label %logic_end_20
logic_end_20:
  %t28 = phi i1 [ %t27, %logic_rhs_18 ], [ false, %logic_short_19 ]
  br i1 %t28, label %if_then_21, label %if_else_22
if_then_21:
  %t29 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t29)
  call i32 (i8*, ...) @printf(i8* %t29)
  br label %if_end_23
if_else_22:
  br label %if_end_23
if_end_23:
  %t30 = load i32, i32* %t1
  %t31 = icmp slt i32 %t30, 0
  br i1 %t31, label %logic_short_25, label %logic_rhs_24
logic_rhs_24:
  %t32 = load i32, i32* %t2
  %t33 = icmp slt i32 %t32, 0
  br label %logic_end_26
logic_short_25:
  br label %logic_end_26
logic_end_26:
  %t34 = phi i1 [ %t33, %logic_rhs_24 ], [ true, %logic_short_25 ]
  br i1 %t34, label %if_then_27, label %if_else_28
if_then_27:
  %t35 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.6, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t35)
  call i32 (i8*, ...) @printf(i8* %t35)
  br label %if_end_29
if_else_28:
  br label %if_end_29
if_end_29:
  br i1 false, label %logic_rhs_30, label %logic_short_31
logic_rhs_30:
  %t36 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t37 = call i1 @side_effect(i8* %t36)
  br label %logic_end_32
logic_short_31:
  br label %logic_end_32
logic_end_32:
  %t38 = phi i1 [ %t37, %logic_rhs_30 ], [ false, %logic_short_31 ]
  br i1 %t38, label %if_then_33, label %if_else_34
if_then_33:
  %t39 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t39)
  call i32 (i8*, ...) @printf(i8* %t39)
  br label %if_end_35
if_else_34:
  br label %if_end_35
if_end_35:
  %t40 = getelementptr inbounds { i64, i8*, [26 x i8] }, { i64, i8*, [26 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t40)
  call i32 (i8*, ...) @printf(i8* %t40)
  br i1 true, label %logic_short_37, label %logic_rhs_36
logic_rhs_36:
  %t41 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t42 = call i1 @side_effect(i8* %t41)
  br label %logic_end_38
logic_short_37:
  br label %logic_end_38
logic_end_38:
  %t43 = phi i1 [ %t42, %logic_rhs_36 ], [ true, %logic_short_37 ]
  br i1 %t43, label %if_then_39, label %if_else_40
if_then_39:
  %t44 = getelementptr inbounds { i64, i8*, [24 x i8] }, { i64, i8*, [24 x i8] }* @.str.11, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t44)
  call i32 (i8*, ...) @printf(i8* %t44)
  br label %if_end_41
if_else_40:
  br label %if_end_41
if_end_41:
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"called: %s\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"both positive (unexpected)\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"not both positive\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [22 x i8] } { i64 -1, i8* null, [22 x i8] c"at least one positive\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"negated and works\00" }
@.str.5 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"symbolic && works\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"symbolic || works\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"and-rhs\00" }
@.str.8 = private unnamed_addr constant { i64, i8*, [12 x i8] } { i64 -1, i8* null, [12 x i8] c"unreachable\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [26 x i8] } { i64 -1, i8* null, [26 x i8] c"false-and short-circuited\00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"or-rhs\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [24 x i8] } { i64 -1, i8* null, [24 x i8] c"true-or short-circuited\00" }
