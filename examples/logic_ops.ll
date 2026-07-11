; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = add i64 %rc, 1
  store i64 %rc1, i64* %hdr
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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc1 = sub i64 %rc, 1
  store i64 %rc1, i64* %hdr
  %iszero = icmp eq i64 %rc1, 0
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
  %t3 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t3)
  %t4 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t4)
  %t5 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t5, i8* %t4)
  %t6 = load i8*, i8** %t0
  %t7 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t7)
  ret i1 true
}

define i32 @main() {
entry:
  %t0 = alloca i32
  store i32 5, i32* %t0
  %t1 = alloca i32
  %t2 = sub i32 0, 3
  store i32 %t2, i32* %t1
  %t3 = load i32, i32* %t0
  %t4 = icmp sgt i32 %t3, 0
  br i1 %t4, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t5 = load i32, i32* %t1
  %t6 = icmp sgt i32 %t5, 0
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t7 = phi i1 [ %t6, %logic_rhs_0 ], [ false, %logic_short_1 ]
  br i1 %t7, label %if_then_3, label %if_else_4
if_then_3:
  %t9 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t8 = alloca i8*
  store i8* %t9, i8** %t8
  %t10 = load i8*, i8** %t8
  call i32 (i8*, ...) @printf(i8* %t10)
  br label %if_end_5
if_else_4:
  %t12 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t11 = alloca i8*
  store i8* %t12, i8** %t11
  %t13 = load i8*, i8** %t11
  call i32 (i8*, ...) @printf(i8* %t13)
  br label %if_end_5
if_end_5:
  %t14 = load i32, i32* %t0
  %t15 = icmp sgt i32 %t14, 0
  br i1 %t15, label %logic_short_7, label %logic_rhs_6
logic_rhs_6:
  %t16 = load i32, i32* %t1
  %t17 = icmp sgt i32 %t16, 0
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t18 = phi i1 [ %t17, %logic_rhs_6 ], [ true, %logic_short_7 ]
  br i1 %t18, label %if_then_9, label %if_else_10
if_then_9:
  %t20 = getelementptr inbounds { i64, i8*, [22 x i8] }, { i64, i8*, [22 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t19 = alloca i8*
  store i8* %t20, i8** %t19
  %t21 = load i8*, i8** %t19
  call i32 (i8*, ...) @printf(i8* %t21)
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t22 = load i32, i32* %t0
  %t23 = icmp sgt i32 %t22, 0
  br i1 %t23, label %logic_rhs_12, label %logic_short_13
logic_rhs_12:
  %t24 = load i32, i32* %t1
  %t25 = icmp sgt i32 %t24, 0
  br label %logic_end_14
logic_short_13:
  br label %logic_end_14
logic_end_14:
  %t26 = phi i1 [ %t25, %logic_rhs_12 ], [ false, %logic_short_13 ]
  %t27 = xor i1 true, %t26
  br i1 %t27, label %if_then_15, label %if_else_16
if_then_15:
  %t29 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t28 = alloca i8*
  store i8* %t29, i8** %t28
  %t30 = load i8*, i8** %t28
  call i32 (i8*, ...) @printf(i8* %t30)
  br label %if_end_17
if_else_16:
  br label %if_end_17
if_end_17:
  %t31 = load i32, i32* %t0
  %t32 = icmp sgt i32 %t31, 0
  br i1 %t32, label %logic_rhs_18, label %logic_short_19
logic_rhs_18:
  %t33 = load i32, i32* %t1
  %t34 = icmp slt i32 %t33, 0
  br label %logic_end_20
logic_short_19:
  br label %logic_end_20
logic_end_20:
  %t35 = phi i1 [ %t34, %logic_rhs_18 ], [ false, %logic_short_19 ]
  br i1 %t35, label %if_then_21, label %if_else_22
if_then_21:
  %t37 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t36 = alloca i8*
  store i8* %t37, i8** %t36
  %t38 = load i8*, i8** %t36
  call i32 (i8*, ...) @printf(i8* %t38)
  br label %if_end_23
if_else_22:
  br label %if_end_23
if_end_23:
  %t39 = load i32, i32* %t0
  %t40 = icmp slt i32 %t39, 0
  br i1 %t40, label %logic_short_25, label %logic_rhs_24
logic_rhs_24:
  %t41 = load i32, i32* %t1
  %t42 = icmp slt i32 %t41, 0
  br label %logic_end_26
logic_short_25:
  br label %logic_end_26
logic_end_26:
  %t43 = phi i1 [ %t42, %logic_rhs_24 ], [ true, %logic_short_25 ]
  br i1 %t43, label %if_then_27, label %if_else_28
if_then_27:
  %t45 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t44 = alloca i8*
  store i8* %t45, i8** %t44
  %t46 = load i8*, i8** %t44
  call i32 (i8*, ...) @printf(i8* %t46)
  br label %if_end_29
if_else_28:
  br label %if_end_29
if_end_29:
  br i1 false, label %logic_rhs_30, label %logic_short_31
logic_rhs_30:
  %t48 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t47 = alloca i8*
  store i8* %t48, i8** %t47
  %t49 = call i1 @side_effect(i8* %t47)
  br label %logic_end_32
logic_short_31:
  br label %logic_end_32
logic_end_32:
  %t50 = phi i1 [ %t49, %logic_rhs_30 ], [ false, %logic_short_31 ]
  br i1 %t50, label %if_then_33, label %if_else_34
if_then_33:
  %t52 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t51 = alloca i8*
  store i8* %t52, i8** %t51
  %t53 = load i8*, i8** %t51
  call i32 (i8*, ...) @printf(i8* %t53)
  br label %if_end_35
if_else_34:
  br label %if_end_35
if_end_35:
  %t55 = getelementptr inbounds { i64, i8*, [26 x i8] }, { i64, i8*, [26 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t54 = alloca i8*
  store i8* %t55, i8** %t54
  %t56 = load i8*, i8** %t54
  call i32 (i8*, ...) @printf(i8* %t56)
  br i1 true, label %logic_short_37, label %logic_rhs_36
logic_rhs_36:
  %t58 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t57 = alloca i8*
  store i8* %t58, i8** %t57
  %t59 = call i1 @side_effect(i8* %t57)
  br label %logic_end_38
logic_short_37:
  br label %logic_end_38
logic_end_38:
  %t60 = phi i1 [ %t59, %logic_rhs_36 ], [ true, %logic_short_37 ]
  br i1 %t60, label %if_then_39, label %if_else_40
if_then_39:
  %t62 = getelementptr inbounds { i64, i8*, [24 x i8] }, { i64, i8*, [24 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t61 = alloca i8*
  store i8* %t62, i8** %t61
  %t63 = load i8*, i8** %t61
  call i32 (i8*, ...) @printf(i8* %t63)
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
