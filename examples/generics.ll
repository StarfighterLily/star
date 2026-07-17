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

%Result__i32__str = type { i32, [1 x i64] }
%Box__i32 = type { i32 }
%Box__Box__i32 = type { %Box__i32 }
%Option__i32 = type { i32, [1 x i64] }
define void @print_result(%Result__i32__str %r) {
entry:
  %t0 = alloca %Result__i32__str
  store %Result__i32__str %r, %Result__i32__str* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  br label %match_end_1
match_next_0_4:
  %t16 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 1
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i8* }*
  %t20 = getelementptr inbounds { i8* }, { i8* }* %t19, i32 0, i32 0
  %t21 = load i8*, i8** %t20
  %t22 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t22)
  call void @star_rc_release(i8* %t21)
  %t23 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t23, i8* %t21)
  br label %match_end_1
match_next_1_14:
  br label %match_end_1
match_end_1:
  %t24 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 0
  %t25 = load i32, i32* %t24
  %t26 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 1
  %t27 = icmp eq i32 %t25, 1
  br i1 %t27, label %enum_rc_variant_0, label %enum_rc_next_1
enum_rc_variant_0:
  %t28 = bitcast [1 x i64]* %t26 to { i8* }*
  %t29 = getelementptr inbounds { i8* }, { i8* }* %t28, i32 0, i32 0
  %t30 = load i8*, i8** %t29
  call void @star_rc_release(i8* %t30)
  br label %enum_rc_next_1
enum_rc_next_1:
  ret void
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca %Box__i32
  %t2 = alloca %Box__i32
  %t8 = alloca %Box__Box__i32
  %t9 = alloca %Box__Box__i32
  %t10 = alloca %Box__i32
  %t19 = alloca %Option__i32
  %t20 = alloca %Option__i32
  %t26 = alloca %Option__i32
  %t27 = alloca %Option__i32
  %t37 = alloca %Result__i32__str
  %t38 = alloca %Result__i32__str
  %t44 = alloca %Result__i32__str
  %t45 = alloca %Result__i32__str
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t3 = getelementptr inbounds %Box__i32, %Box__i32* %t2, i32 0, i32 0
  store i32 42, i32* %t3
  %t4 = load %Box__i32, %Box__i32* %t2
  store %Box__i32 %t4, %Box__i32* %t1
  %t5 = getelementptr inbounds %Box__i32, %Box__i32* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t11 = getelementptr inbounds %Box__i32, %Box__i32* %t10, i32 0, i32 0
  store i32 99, i32* %t11
  %t12 = load %Box__i32, %Box__i32* %t10
  %t13 = getelementptr inbounds %Box__Box__i32, %Box__Box__i32* %t9, i32 0, i32 0
  store %Box__i32 %t12, %Box__i32* %t13
  %t14 = load %Box__Box__i32, %Box__Box__i32* %t9
  store %Box__Box__i32 %t14, %Box__Box__i32* %t8
  %t15 = getelementptr inbounds %Box__Box__i32, %Box__Box__i32* %t8, i32 0, i32 0
  %t16 = getelementptr inbounds %Box__i32, %Box__i32* %t15, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t18 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18, i32 %t17)
  %t21 = getelementptr inbounds %Option__i32, %Option__i32* %t20, i32 0, i32 0
  store i32 1, i32* %t21
  %t22 = getelementptr inbounds %Option__i32, %Option__i32* %t20, i32 0, i32 1
  %t23 = bitcast [1 x i64]* %t22 to { i32 }*
  %t24 = getelementptr inbounds { i32 }, { i32 }* %t23, i32 0, i32 0
  store i32 5, i32* %t24
  %t25 = load %Option__i32, %Option__i32* %t20
  store %Option__i32 %t25, %Option__i32* %t19
  %t28 = getelementptr inbounds %Option__i32, %Option__i32* %t27, i32 0, i32 0
  store i32 0, i32* %t28
  %t29 = load %Option__i32, %Option__i32* %t27
  store %Option__i32 %t29, %Option__i32* %t26
  %t30 = load %Option__i32, %Option__i32* %t19
  %t31 = call i32 @unwrap_or__i32(%Option__i32 %t30, i32 0)
  %t32 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t32, i32 %t31)
  %t33 = load %Option__i32, %Option__i32* %t26
  %t34 = sub i32 0, 1
  %t35 = call i32 @unwrap_or__i32(%Option__i32 %t33, i32 %t34)
  %t36 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t36, i32 %t35)
  %t39 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t38, i32 0, i32 0
  store i32 0, i32* %t39
  %t40 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t38, i32 0, i32 1
  %t41 = bitcast [1 x i64]* %t40 to { i32 }*
  %t42 = getelementptr inbounds { i32 }, { i32 }* %t41, i32 0, i32 0
  store i32 10, i32* %t42
  %t43 = load %Result__i32__str, %Result__i32__str* %t38
  store %Result__i32__str %t43, %Result__i32__str* %t37
  %t46 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t45, i32 0, i32 0
  store i32 1, i32* %t46
  %t47 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t45, i32 0, i32 1
  %t48 = bitcast [1 x i64]* %t47 to { i8* }*
  %t49 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t50 = getelementptr inbounds { i8* }, { i8* }* %t48, i32 0, i32 0
  store i8* %t49, i8** %t50
  %t51 = load %Result__i32__str, %Result__i32__str* %t45
  store %Result__i32__str %t51, %Result__i32__str* %t44
  %t52 = load %Result__i32__str, %Result__i32__str* %t37
  %t53 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 1
  %t56 = icmp eq i32 %t54, 1
  br i1 %t56, label %enum_rc_variant_2, label %enum_rc_next_3
enum_rc_variant_2:
  %t57 = bitcast [1 x i64]* %t55 to { i8* }*
  %t58 = getelementptr inbounds { i8* }, { i8* }* %t57, i32 0, i32 0
  %t59 = load i8*, i8** %t58
  call void @star_rc_retain(i8* %t59)
  br label %enum_rc_next_3
enum_rc_next_3:
  call void @print_result(%Result__i32__str %t52)
  %t60 = load %Result__i32__str, %Result__i32__str* %t44
  %t61 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 0
  %t62 = load i32, i32* %t61
  %t63 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 1
  %t64 = icmp eq i32 %t62, 1
  br i1 %t64, label %enum_rc_variant_4, label %enum_rc_next_5
enum_rc_variant_4:
  %t65 = bitcast [1 x i64]* %t63 to { i8* }*
  %t66 = getelementptr inbounds { i8* }, { i8* }* %t65, i32 0, i32 0
  %t67 = load i8*, i8** %t66
  call void @star_rc_retain(i8* %t67)
  br label %enum_rc_next_5
enum_rc_next_5:
  call void @print_result(%Result__i32__str %t60)
  %t68 = call i32 @identity__i32(i32 7)
  %t69 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t69, i32 %t68)
  %t70 = call float @identity__f32(float 0x400C000000000000)
  %t71 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.8, i64 0, i64 0
  %t72 = fpext float %t70 to double
  call i32 (i8*, ...) @printf(i8* %t71, double %t72)
  %t73 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 0
  %t74 = load i32, i32* %t73
  %t75 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 1
  %t76 = icmp eq i32 %t74, 1
  br i1 %t76, label %enum_rc_variant_6, label %enum_rc_next_7
enum_rc_variant_6:
  %t77 = bitcast [1 x i64]* %t75 to { i8* }*
  %t78 = getelementptr inbounds { i8* }, { i8* }* %t77, i32 0, i32 0
  %t79 = load i8*, i8** %t78
  call void @star_rc_release(i8* %t79)
  br label %enum_rc_next_7
enum_rc_next_7:
  %t80 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 0
  %t81 = load i32, i32* %t80
  %t82 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 1
  %t83 = icmp eq i32 %t81, 1
  br i1 %t83, label %enum_rc_variant_8, label %enum_rc_next_9
enum_rc_variant_8:
  %t84 = bitcast [1 x i64]* %t82 to { i8* }*
  %t85 = getelementptr inbounds { i8* }, { i8* }* %t84, i32 0, i32 0
  %t86 = load i8*, i8** %t85
  call void @star_rc_release(i8* %t86)
  br label %enum_rc_next_9
enum_rc_next_9:
  ret i32 0
}

define i32 @unwrap_or__i32(%Option__i32 %o, i32 %default) {
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
  ret i32 %t12
match_next_0_5:
  %t16 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t15 = icmp eq i32 %t17, 0
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t18 = load i32, i32* %t1
  ret i32 %t18
match_next_1_14:
  br label %match_end_2
match_end_2:
  unreachable
}

define i32 @identity__i32(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  ret i32 %t1
}

define float @identity__f32(float %x) {
entry:
  %t0 = alloca float
  store float %x, float* %t0
  %t1 = load float, float* %t0
  ret float %t1
}


; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"ok: %d\0A\00"
@.str.1 = private unnamed_addr constant [9 x i8] c"err: %s\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"box: %d\0A\00"
@.str.3 = private unnamed_addr constant [16 x i8] c"nested box: %d\0A\00"
@.str.4 = private unnamed_addr constant [17 x i8] c"unwrap some: %d\0A\00"
@.str.5 = private unnamed_addr constant [17 x i8] c"unwrap none: %d\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bad\00" }
@.str.7 = private unnamed_addr constant [18 x i8] c"identity int: %d\0A\00"
@.str.8 = private unnamed_addr constant [20 x i8] c"identity float: %f\0A\00"
