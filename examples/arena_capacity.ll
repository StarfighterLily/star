; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
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

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i32] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i32
  store i32 0, i32* %t0
  br label %for_cond_0
for_cond_0:
  %t1 = load i32, i32* %t0
  %t2 = icmp slt i32 %t1, 1030
  br i1 %t2, label %for_body_1, label %for_end_3
for_body_1:
  %t3 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t4 = icmp eq %Enemy* %t3, null
  br i1 %t4, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t5 = call i8* @malloc(i64 4096)
  %t6 = bitcast i8* %t5 to %Enemy*
  store %Enemy* %t6, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t7 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t8 = load i64, i64* @arena.Enemies.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Enemies.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_8
spawn_grow_7:
  %t13 = load i64, i64* @arena.Enemies.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t15 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t15)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t16 = add i64 %t13, 1
  store i64 %t16, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t17 = phi i64 [ %t12, %spawn_reuse_6 ], [ %t13, %spawn_grow_ok_10 ]
  %t18 = alloca %Enemy
  %t19 = load i32, i32* %t0
  %t20 = getelementptr inbounds %Enemy, %Enemy* %t18, i32 0, i32 0
  store i32 %t19, i32* %t20
  %t21 = load %Enemy, %Enemy* %t18
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t7, i64 %t17
  store %Enemy %t21, %Enemy* %t22
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t17
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t23
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t26 = load i32, i32* %t0
  %t27 = add i32 %t26, 1
  store i32 %t27, i32* %t0
  br label %for_cond_0
for_end_3:
  %t28 = getelementptr inbounds { i64, i8*, [14 x i8] }, { i64, i8*, [14 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t28)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [14 x i8] } { i64 -1, i8* null, [14 x i8] c"done spawning\00" }
