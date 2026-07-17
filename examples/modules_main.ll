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

%geo__Point = type { i32, i32 }
%geo__Shape = type { i32, [1 x i64] }
define i32 @geo__Point__length_sq(%geo__Point* %self) {
entry:
  %t0 = alloca %geo__Point*
  store %geo__Point* %self, %geo__Point** %t0
  %t1 = load %geo__Point*, %geo__Point** %t0
  %t2 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = load %geo__Point*, %geo__Point** %t0
  %t5 = getelementptr inbounds %geo__Point, %geo__Point* %t4, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = mul i32 %t3, %t6
  %t8 = load %geo__Point*, %geo__Point** %t0
  %t9 = getelementptr inbounds %geo__Point, %geo__Point* %t8, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = load %geo__Point*, %geo__Point** %t0
  %t12 = getelementptr inbounds %geo__Point, %geo__Point* %t11, i32 0, i32 1
  %t13 = load i32, i32* %t12
  %t14 = mul i32 %t10, %t13
  %t15 = add i32 %t7, %t14
  ret i32 %t15
}

define i32 @geo__dot(%geo__Point %a, %geo__Point %b) {
entry:
  %t0 = alloca %geo__Point
  %t1 = alloca %geo__Point
  store %geo__Point %a, %geo__Point* %t0
  store %geo__Point %b, %geo__Point* %t1
  %t2 = getelementptr inbounds %geo__Point, %geo__Point* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = mul i32 %t3, %t5
  %t7 = getelementptr inbounds %geo__Point, %geo__Point* %t0, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = mul i32 %t8, %t10
  %t12 = add i32 %t6, %t11
  ret i32 %t12
}

define i32 @geo__area(%geo__Shape %s) {
entry:
  %t0 = alloca %geo__Shape
  store %geo__Shape %s, %geo__Shape* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = mul i32 3, %t11
  %t13 = load i32, i32* %t10
  %t14 = mul i32 %t12, %t13
  ret i32 %t14
match_next_0_4:
  %t18 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t17 = icmp eq i32 %t19, 1
  br i1 %t17, label %match_then_1_15, label %match_next_1_16
match_then_1_15:
  %t20 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 1
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
  %t0 = alloca %geo__Point
  %t1 = alloca %geo__Point
  %t6 = alloca %geo__Point
  %t12 = alloca %geo__Shape
  %t20 = alloca %geo__Shape
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t2 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 0
  store i32 3, i32* %t2
  %t3 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 1
  store i32 4, i32* %t3
  %t4 = load %geo__Point, %geo__Point* %t1
  store %geo__Point %t4, %geo__Point* %t0
  %t5 = load %geo__Point, %geo__Point* %t0
  %t7 = getelementptr inbounds %geo__Point, %geo__Point* %t6, i32 0, i32 0
  store i32 1, i32* %t7
  %t8 = getelementptr inbounds %geo__Point, %geo__Point* %t6, i32 0, i32 1
  store i32 2, i32* %t8
  %t9 = load %geo__Point, %geo__Point* %t6
  %t10 = call i32 @geo__dot(%geo__Point %t5, %geo__Point %t9)
  %t11 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i32 %t10)
  %t13 = getelementptr inbounds %geo__Shape, %geo__Shape* %t12, i32 0, i32 0
  store i32 0, i32* %t13
  %t14 = getelementptr inbounds %geo__Shape, %geo__Shape* %t12, i32 0, i32 1
  %t15 = bitcast [1 x i64]* %t14 to { i32 }*
  %t16 = getelementptr inbounds { i32 }, { i32 }* %t15, i32 0, i32 0
  store i32 2, i32* %t16
  %t17 = load %geo__Shape, %geo__Shape* %t12
  %t18 = call i32 @geo__area(%geo__Shape %t17)
  %t19 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i32 %t18)
  %t21 = getelementptr inbounds %geo__Shape, %geo__Shape* %t20, i32 0, i32 0
  store i32 1, i32* %t21
  %t22 = getelementptr inbounds %geo__Shape, %geo__Shape* %t20, i32 0, i32 1
  %t23 = bitcast [1 x i64]* %t22 to { i32, i32 }*
  %t24 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t23, i32 0, i32 0
  store i32 3, i32* %t24
  %t25 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t23, i32 0, i32 1
  store i32 4, i32* %t25
  %t26 = load %geo__Shape, %geo__Shape* %t20
  %t27 = call i32 @geo__area(%geo__Shape %t26)
  %t28 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t28, i32 %t27)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"dot: %d\0A\00"
@.str.1 = private unnamed_addr constant [17 x i8] c"circle area: %d\0A\00"
@.str.2 = private unnamed_addr constant [15 x i8] c"rect area: %d\0A\00"
