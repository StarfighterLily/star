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

%Vec3 = type { float, float, float }
%Player = type { i32, %Vec3, i8* }
define void @Player__take_damage(%Player* %self, i32 %amount) {
entry:
  %t0 = alloca %Player*
  %t1 = alloca i32
  store %Player* %self, %Player** %t0
  store i32 %amount, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %Player*, %Player** %t0
  %t4 = getelementptr inbounds %Player, %Player* %t3, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = sub i32 %t5, %t2
  %t7 = load %Player*, %Player** %t0
  %t8 = getelementptr inbounds %Player, %Player* %t7, i32 0, i32 0
  store i32 %t6, i32* %t8
  %t9 = load %Player*, %Player** %t0
  %t10 = getelementptr inbounds %Player, %Player* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  br label %match_scrutinee_13
match_scrutinee_13:
  %t16 = icmp sle i32 %t11, 0
  br i1 %t16, label %match_then_0_14, label %match_next_0_15
match_then_0_14:
  %t17 = load %Player*, %Player** %t0
  %t18 = getelementptr inbounds %Player, %Player* %t17, i32 0, i32 2
  %t19 = load i8*, i8** %t18
  %t20 = load i8*, i8** %t18
  call void @star_rc_retain(i8* %t20)
  call void @star_rc_release(i8* %t19)
  %t21 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t21, i8* %t19)
  br label %match_end_12
match_next_0_15:
  %t24 = load %Player*, %Player** %t0
  %t25 = getelementptr inbounds %Player, %Player* %t24, i32 0, i32 0
  %t26 = load i32, i32* %t25
  %t27 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i32 %t26)
  br label %match_end_12
match_end_12:
  ret void
}

define i32 @Player__remaining_health(%Player* %self) {
entry:
  %t0 = alloca %Player*
  store %Player* %self, %Player** %t0
  %t1 = load %Player*, %Player** %t0
  %t2 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  ret i32 %t3
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca %Player
  %t2 = alloca %Player
  %t4 = alloca %Vec3
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t3 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 0
  store i32 100, i32* %t3
  %t5 = getelementptr inbounds %Vec3, %Vec3* %t4, i32 0, i32 0
  store float 0x0000000000000000, float* %t5
  %t6 = getelementptr inbounds %Vec3, %Vec3* %t4, i32 0, i32 1
  store float 0x0000000000000000, float* %t6
  %t7 = getelementptr inbounds %Vec3, %Vec3* %t4, i32 0, i32 2
  store float 0x0000000000000000, float* %t7
  %t8 = load %Vec3, %Vec3* %t4
  %t9 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 1
  store %Vec3 %t8, %Vec3* %t9
  %t10 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t11 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 2
  store i8* %t10, i8** %t11
  %t12 = load %Player, %Player* %t2
  store %Player %t12, %Player* %t1
  %t13 = call i32 @Player__remaining_health(%Player* %t1)
  %t14 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t13)
  call void @Player__take_damage(%Player* %t1, i32 150)
  %t16 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 2
  %t17 = load i8*, i8** %t16
  call void @star_rc_release(i8* %t17)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"%s has perished.\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"Health critical: %d\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.3 = private unnamed_addr constant [15 x i8] c"remaining: %d\0A\00"
