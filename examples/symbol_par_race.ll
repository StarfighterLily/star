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

%Entity = type { i64 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i32
  %t22 = alloca %Entity
  %t32 = alloca i32
  %t35 = alloca i8*
  %t152 = alloca { i64, i64, i32*, i8** }
  %t167 = alloca { i64, i64, i32*, i8** }
  %t182 = alloca { i64, i64, i32*, i8** }
  %t197 = alloca { i64, i64, i32*, i8** }
  %t225 = alloca { i64, i64, i32*, i8** }
  %t280 = alloca { i64, i64, i32* }
  %t294 = alloca { i64, i64, i32* }
  %t308 = alloca { i64, i64, i32* }
  %t322 = alloca { i64, i64, i32* }
  %t349 = alloca { i64, i64, i32* }
  %t357 = alloca i64
  %t366 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i32 0, i32* %t1
  br label %for_cond_0
for_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 64
  br i1 %t3, label %for_body_1, label %for_end_3
for_body_1:
  %t4 = load %Entity*, %Entity** @arena.Entities.data
  %t5 = icmp eq %Entity* %t4, null
  br i1 %t5, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t6 = getelementptr %Entity, %Entity* null, i32 1
  %t7 = ptrtoint %Entity* %t6 to i64
  %t8 = mul i64 %t7, 1024
  %t9 = call i8* @malloc(i64 %t8)
  %t10 = bitcast i8* %t9 to %Entity*
  store %Entity* %t10, %Entity** @arena.Entities.data
  br label %spawn_ready_5
spawn_ready_5:
  %t11 = load %Entity*, %Entity** @arena.Entities.data
  %t12 = load i64, i64* @arena.Entities.free_top
  %t13 = icmp sgt i64 %t12, 0
  br i1 %t13, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t14 = sub i64 %t12, 1
  store i64 %t14, i64* @arena.Entities.free_top
  %t15 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t14
  %t16 = load i64, i64* %t15
  br label %spawn_store_8
spawn_grow_7:
  %t17 = load i64, i64* @arena.Entities.count
  %t18 = icmp slt i64 %t17, 1024
  br i1 %t18, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t19 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t19)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t20 = add i64 %t17, 1
  store i64 %t20, i64* @arena.Entities.count
  br label %spawn_store_8
spawn_store_8:
  %t21 = phi i64 [ %t16, %spawn_reuse_6 ], [ %t17, %spawn_grow_ok_10 ]
  %t23 = sext i32 0 to i64
  %t24 = getelementptr inbounds %Entity, %Entity* %t22, i32 0, i32 0
  store i64 %t23, i64* %t24
  %t25 = load %Entity, %Entity* %t22
  %t26 = getelementptr inbounds %Entity, %Entity* %t11, i64 %t21
  store %Entity %t25, %Entity* %t26
  %t27 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t21
  %t28 = load i32, i32* %t27
  %t29 = add i32 %t28, 1
  store i32 %t29, i32* %t27
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t30 = load i32, i32* %t1
  %t31 = add i32 %t30, 1
  store i32 %t31, i32* %t1
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t32
  br label %for_cond_12
for_cond_12:
  %t33 = load i32, i32* %t32
  %t34 = icmp slt i32 %t33, 200
  br i1 %t34, label %for_body_13, label %for_end_15
for_body_13:
  %t36 = load i32, i32* %t32
  %t37 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.1, i64 0, i64 0
  %t38 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t37, i32 %t36)
  %t39 = add i32 %t38, 1
  %t40 = sext i32 %t39 to i64
  %t41 = call i8* @star_rc_alloc(i64 %t40, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t41, i64 %t40, i8* %t37, i32 %t36)
  store i8* %t41, i8** %t35
  call void @par.pool.ensure_init()
  %t129 = call i32 @GetCurrentThreadId()
  %t130 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t131 = load i32, i32* %t130
  %t132 = icmp eq i32 %t129, %t131
  %t133 = select i1 %t132, i32 0, i32 -1
  %t134 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t135 = load i32, i32* %t134
  %t136 = icmp eq i32 %t129, %t135
  %t137 = select i1 %t136, i32 1, i32 %t133
  %t138 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t139 = load i32, i32* %t138
  %t140 = icmp eq i32 %t129, %t139
  %t141 = select i1 %t140, i32 2, i32 %t137
  %t142 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t143 = load i32, i32* %t142
  %t144 = icmp eq i32 %t129, %t143
  %t145 = select i1 %t144, i32 3, i32 %t141
  %t146 = icmp sge i32 %t145, 0
  br i1 %t146, label %par_serial_34, label %par_pooled_33
par_pooled_33:
  %t147 = load i64, i64* @arena.Entities.count
  %t148 = mul i64 %t147, 0
  %t149 = sdiv i64 %t148, 4
  %t150 = mul i64 %t147, 1
  %t151 = sdiv i64 %t150, 4
  %t153 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t152, i32 0, i32 0
  store i64 %t149, i64* %t153
  %t154 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t152, i32 0, i32 1
  store i64 %t151, i64* %t154
  %t155 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t152, i32 0, i32 2
  store i32* %t32, i32** %t155
  %t156 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t152, i32 0, i32 3
  store i8** %t35, i8*** %t156
  %t157 = bitcast { i64, i64, i32*, i8** }* %t152 to i8*
  %t158 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t157, i8** %t158
  %t159 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t159
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t161 = load i8*, i8** %t160
  %t162 = call i32 @ReleaseSemaphore(i8* %t161, i32 1, i32* null)
  %t163 = mul i64 %t147, 1
  %t164 = sdiv i64 %t163, 4
  %t165 = mul i64 %t147, 2
  %t166 = sdiv i64 %t165, 4
  %t168 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 0
  store i64 %t164, i64* %t168
  %t169 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 1
  store i64 %t166, i64* %t169
  %t170 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 2
  store i32* %t32, i32** %t170
  %t171 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 3
  store i8** %t35, i8*** %t171
  %t172 = bitcast { i64, i64, i32*, i8** }* %t167 to i8*
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t172, i8** %t173
  %t174 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t174
  %t175 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t176 = load i8*, i8** %t175
  %t177 = call i32 @ReleaseSemaphore(i8* %t176, i32 1, i32* null)
  %t178 = mul i64 %t147, 2
  %t179 = sdiv i64 %t178, 4
  %t180 = mul i64 %t147, 3
  %t181 = sdiv i64 %t180, 4
  %t183 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t182, i32 0, i32 0
  store i64 %t179, i64* %t183
  %t184 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t182, i32 0, i32 1
  store i64 %t181, i64* %t184
  %t185 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t182, i32 0, i32 2
  store i32* %t32, i32** %t185
  %t186 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t182, i32 0, i32 3
  store i8** %t35, i8*** %t186
  %t187 = bitcast { i64, i64, i32*, i8** }* %t182 to i8*
  %t188 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t187, i8** %t188
  %t189 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t189
  %t190 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t191 = load i8*, i8** %t190
  %t192 = call i32 @ReleaseSemaphore(i8* %t191, i32 1, i32* null)
  %t193 = mul i64 %t147, 3
  %t194 = sdiv i64 %t193, 4
  %t195 = mul i64 %t147, 4
  %t196 = sdiv i64 %t195, 4
  %t198 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 0
  store i64 %t194, i64* %t198
  %t199 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 1
  store i64 %t196, i64* %t199
  %t200 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 2
  store i32* %t32, i32** %t200
  %t201 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 3
  store i8** %t35, i8*** %t201
  %t202 = bitcast { i64, i64, i32*, i8** }* %t197 to i8*
  %t203 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t202, i8** %t203
  %t204 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t204
  %t205 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t206 = load i8*, i8** %t205
  %t207 = call i32 @ReleaseSemaphore(i8* %t206, i32 1, i32* null)
  %t208 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t209 = load i8*, i8** %t208
  %t210 = call i32 @WaitForSingleObject(i8* %t209, i32 -1)
  %t211 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t212 = load i8*, i8** %t211
  %t213 = call i32 @WaitForSingleObject(i8* %t212, i32 -1)
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t215 = load i8*, i8** %t214
  %t216 = call i32 @WaitForSingleObject(i8* %t215, i32 -1)
  %t217 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t218 = load i8*, i8** %t217
  %t219 = call i32 @WaitForSingleObject(i8* %t218, i32 -1)
  br label %par_join_38
par_serial_34:
  %t220 = load i32, i32* @par.pool.serial_owner
  %t221 = icmp eq i32 %t220, %t145
  br i1 %t221, label %par_run_36, label %par_acquire_35
par_acquire_35:
  %t222 = load i8*, i8** @par.pool.serial_lock
  %t223 = call i32 @WaitForSingleObject(i8* %t222, i32 -1)
  store i32 %t145, i32* @par.pool.serial_owner
  br label %par_run_36
par_run_36:
  %t224 = load i64, i64* @arena.Entities.count
  %t226 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 0
  store i64 0, i64* %t226
  %t227 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 1
  store i64 %t224, i64* %t227
  %t228 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 2
  store i32* %t32, i32** %t228
  %t229 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 3
  store i8** %t35, i8*** %t229
  %t230 = bitcast { i64, i64, i32*, i8** }* %t225 to i8*
  %t231 = call i32 @par_worker_16(i8* %t230)
  br i1 %t221, label %par_join_38, label %par_release_37
par_release_37:
  store i32 -1, i32* @par.pool.serial_owner
  %t232 = load i8*, i8** @par.pool.serial_lock
  %t233 = call i32 @ReleaseSemaphore(i8* %t232, i32 1, i32* null)
  br label %par_join_38
par_join_38:
  %t234 = load i8*, i8** %t35
  call void @star_rc_release(i8* %t234)
  br label %for_step_14
for_step_14:
  %t235 = load i32, i32* %t32
  %t236 = add i32 %t235, 1
  store i32 %t236, i32* %t32
  br label %for_cond_12
for_end_15:
  call void @par.pool.ensure_init()
  %t257 = call i32 @GetCurrentThreadId()
  %t258 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t259 = load i32, i32* %t258
  %t260 = icmp eq i32 %t257, %t259
  %t261 = select i1 %t260, i32 0, i32 -1
  %t262 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t263 = load i32, i32* %t262
  %t264 = icmp eq i32 %t257, %t263
  %t265 = select i1 %t264, i32 1, i32 %t261
  %t266 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t267 = load i32, i32* %t266
  %t268 = icmp eq i32 %t257, %t267
  %t269 = select i1 %t268, i32 2, i32 %t265
  %t270 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t271 = load i32, i32* %t270
  %t272 = icmp eq i32 %t257, %t271
  %t273 = select i1 %t272, i32 3, i32 %t269
  %t274 = icmp sge i32 %t273, 0
  br i1 %t274, label %par_serial_46, label %par_pooled_45
par_pooled_45:
  %t275 = load i64, i64* @arena.Entities.count
  %t276 = mul i64 %t275, 0
  %t277 = sdiv i64 %t276, 4
  %t278 = mul i64 %t275, 1
  %t279 = sdiv i64 %t278, 4
  %t281 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t280, i32 0, i32 0
  store i64 %t277, i64* %t281
  %t282 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t280, i32 0, i32 1
  store i64 %t279, i64* %t282
  %t283 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t280, i32 0, i32 2
  store i32* %t32, i32** %t283
  %t284 = bitcast { i64, i64, i32* }* %t280 to i8*
  %t285 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t284, i8** %t285
  %t286 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t286
  %t287 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t288 = load i8*, i8** %t287
  %t289 = call i32 @ReleaseSemaphore(i8* %t288, i32 1, i32* null)
  %t290 = mul i64 %t275, 1
  %t291 = sdiv i64 %t290, 4
  %t292 = mul i64 %t275, 2
  %t293 = sdiv i64 %t292, 4
  %t295 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t294, i32 0, i32 0
  store i64 %t291, i64* %t295
  %t296 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t294, i32 0, i32 1
  store i64 %t293, i64* %t296
  %t297 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t294, i32 0, i32 2
  store i32* %t32, i32** %t297
  %t298 = bitcast { i64, i64, i32* }* %t294 to i8*
  %t299 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t298, i8** %t299
  %t300 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t300
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t302 = load i8*, i8** %t301
  %t303 = call i32 @ReleaseSemaphore(i8* %t302, i32 1, i32* null)
  %t304 = mul i64 %t275, 2
  %t305 = sdiv i64 %t304, 4
  %t306 = mul i64 %t275, 3
  %t307 = sdiv i64 %t306, 4
  %t309 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t308, i32 0, i32 0
  store i64 %t305, i64* %t309
  %t310 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t308, i32 0, i32 1
  store i64 %t307, i64* %t310
  %t311 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t308, i32 0, i32 2
  store i32* %t32, i32** %t311
  %t312 = bitcast { i64, i64, i32* }* %t308 to i8*
  %t313 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t312, i8** %t313
  %t314 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t314
  %t315 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t316 = load i8*, i8** %t315
  %t317 = call i32 @ReleaseSemaphore(i8* %t316, i32 1, i32* null)
  %t318 = mul i64 %t275, 3
  %t319 = sdiv i64 %t318, 4
  %t320 = mul i64 %t275, 4
  %t321 = sdiv i64 %t320, 4
  %t323 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t322, i32 0, i32 0
  store i64 %t319, i64* %t323
  %t324 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t322, i32 0, i32 1
  store i64 %t321, i64* %t324
  %t325 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t322, i32 0, i32 2
  store i32* %t32, i32** %t325
  %t326 = bitcast { i64, i64, i32* }* %t322 to i8*
  %t327 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t326, i8** %t327
  %t328 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t328
  %t329 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t330 = load i8*, i8** %t329
  %t331 = call i32 @ReleaseSemaphore(i8* %t330, i32 1, i32* null)
  %t332 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t333 = load i8*, i8** %t332
  %t334 = call i32 @WaitForSingleObject(i8* %t333, i32 -1)
  %t335 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t336 = load i8*, i8** %t335
  %t337 = call i32 @WaitForSingleObject(i8* %t336, i32 -1)
  %t338 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t339 = load i8*, i8** %t338
  %t340 = call i32 @WaitForSingleObject(i8* %t339, i32 -1)
  %t341 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t342 = load i8*, i8** %t341
  %t343 = call i32 @WaitForSingleObject(i8* %t342, i32 -1)
  br label %par_join_50
par_serial_46:
  %t344 = load i32, i32* @par.pool.serial_owner
  %t345 = icmp eq i32 %t344, %t273
  br i1 %t345, label %par_run_48, label %par_acquire_47
par_acquire_47:
  %t346 = load i8*, i8** @par.pool.serial_lock
  %t347 = call i32 @WaitForSingleObject(i8* %t346, i32 -1)
  store i32 %t273, i32* @par.pool.serial_owner
  br label %par_run_48
par_run_48:
  %t348 = load i64, i64* @arena.Entities.count
  %t350 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t349, i32 0, i32 0
  store i64 0, i64* %t350
  %t351 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t349, i32 0, i32 1
  store i64 %t348, i64* %t351
  %t352 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t349, i32 0, i32 2
  store i32* %t32, i32** %t352
  %t353 = bitcast { i64, i64, i32* }* %t349 to i8*
  %t354 = call i32 @par_worker_39(i8* %t353)
  br i1 %t345, label %par_join_50, label %par_release_49
par_release_49:
  store i32 -1, i32* @par.pool.serial_owner
  %t355 = load i8*, i8** @par.pool.serial_lock
  %t356 = call i32 @ReleaseSemaphore(i8* %t355, i32 1, i32* null)
  br label %par_join_50
par_join_50:
  %t358 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.3, i64 0, i64 0
  %t359 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t358, i32 199)
  %t360 = add i32 %t359, 1
  %t361 = sext i32 %t360 to i64
  %t362 = call i8* @star_rc_alloc(i64 %t361, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t362, i64 %t361, i8* %t358, i32 199)
  %t363 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t363, i32 -1)
  %t364 = load i64, i64* @sym.len
  %t365 = load i8**, i8*** @sym.data
  store i64 0, i64* %t366
  br label %sym_find_cond_51
sym_find_cond_51:
  %t367 = load i64, i64* %t366
  %t368 = icmp slt i64 %t367, %t364
  br i1 %t368, label %sym_find_body_52, label %sym_find_end_54
sym_find_body_52:
  %t369 = getelementptr inbounds i8*, i8** %t365, i64 %t367
  %t370 = load i8*, i8** %t369
  %t371 = call i32 @strcmp(i8* %t370, i8* %t362)
  %t372 = icmp eq i32 %t371, 0
  br i1 %t372, label %sym_find_end_54, label %sym_find_next_53
sym_find_next_53:
  %t373 = add i64 %t367, 1
  store i64 %t373, i64* %t366
  br label %sym_find_cond_51
sym_find_end_54:
  %t374 = load i64, i64* %t366
  %t375 = icmp slt i64 %t374, %t364
  br i1 %t375, label %sym_found_55, label %sym_notfound_56
sym_found_55:
  call void @star_rc_release(i8* %t362)
  br label %sym_done_57
sym_notfound_56:
  %t376 = load i64, i64* @sym.cap
  %t377 = icmp sge i64 %t364, %t376
  br i1 %t377, label %sym_grow_58, label %sym_store_59
sym_grow_58:
  %t378 = mul i64 %t376, 2
  %t379 = icmp sgt i64 %t378, 0
  %t380 = select i1 %t379, i64 %t378, i64 1
  %t381 = mul i64 %t380, 8
  %t382 = call i8* @malloc(i64 %t381)
  %t383 = bitcast i8* %t382 to i8**
  %t384 = icmp sgt i64 %t376, 0
  br i1 %t384, label %sym_copy_60, label %sym_after_copy_61
sym_copy_60:
  %t385 = mul i64 %t364, 8
  %t386 = bitcast i8** %t365 to i8*
  call i8* @memcpy(i8* %t382, i8* %t386, i64 %t385)
  call void @free(i8* %t386)
  br label %sym_after_copy_61
sym_after_copy_61:
  store i8** %t383, i8*** @sym.data
  store i64 %t380, i64* @sym.cap
  br label %sym_store_59
sym_store_59:
  %t387 = load i8**, i8*** @sym.data
  %t388 = getelementptr inbounds i8*, i8** %t387, i64 %t364
  store i8* %t362, i8** %t388
  %t389 = add i64 %t364, 1
  store i64 %t389, i64* @sym.len
  br label %sym_done_57
sym_done_57:
  %t390 = phi i64 [ %t374, %sym_found_55 ], [ %t364, %sym_store_59 ]
  call i32 @ReleaseSemaphore(i8* %t363, i32 1, i32* null)
  store i64 %t390, i64* %t357
  %t391 = load i64, i64* %t357
  %t392 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t392, i64 %t391)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t52 = alloca i64
  %t65 = alloca i64
  %t42 = bitcast i8* %argp to { i64, i64, i32*, i8** }*
  %t43 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t42, i32 0, i32 0
  %t44 = load i64, i64* %t43
  %t45 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t42, i32 0, i32 1
  %t46 = load i64, i64* %t45
  %t47 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t42, i32 0, i32 2
  %t48 = load i32*, i32** %t47
  %t49 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t42, i32 0, i32 3
  %t50 = load i8**, i8*** %t49
  %t51 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t44, i64* %t52
  br label %par_cond_17
par_cond_17:
  %t53 = load i64, i64* %t52
  %t54 = icmp slt i64 %t53, %t46
  br i1 %t54, label %par_body_18, label %par_end_21
par_body_18:
  %t55 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t53
  %t56 = load i32, i32* %t55
  %t57 = and i32 %t56, 1
  %t58 = icmp eq i32 %t57, 1
  br i1 %t58, label %par_live_19, label %par_incr_20
par_live_19:
  %t59 = getelementptr inbounds %Entity, %Entity* %t51, i64 %t53
  %t60 = load i8*, i8** %t50
  %t61 = load i8*, i8** %t50
  call void @star_rc_retain(i8* %t61)
  %t62 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t62, i32 -1)
  %t63 = load i64, i64* @sym.len
  %t64 = load i8**, i8*** @sym.data
  store i64 0, i64* %t65
  br label %sym_find_cond_22
sym_find_cond_22:
  %t66 = load i64, i64* %t65
  %t67 = icmp slt i64 %t66, %t63
  br i1 %t67, label %sym_find_body_23, label %sym_find_end_25
sym_find_body_23:
  %t68 = getelementptr inbounds i8*, i8** %t64, i64 %t66
  %t69 = load i8*, i8** %t68
  %t70 = call i32 @strcmp(i8* %t69, i8* %t60)
  %t71 = icmp eq i32 %t70, 0
  br i1 %t71, label %sym_find_end_25, label %sym_find_next_24
sym_find_next_24:
  %t72 = add i64 %t66, 1
  store i64 %t72, i64* %t65
  br label %sym_find_cond_22
sym_find_end_25:
  %t73 = load i64, i64* %t65
  %t74 = icmp slt i64 %t73, %t63
  br i1 %t74, label %sym_found_26, label %sym_notfound_27
sym_found_26:
  call void @star_rc_release(i8* %t60)
  br label %sym_done_28
sym_notfound_27:
  %t75 = load i64, i64* @sym.cap
  %t76 = icmp sge i64 %t63, %t75
  br i1 %t76, label %sym_grow_29, label %sym_store_30
sym_grow_29:
  %t77 = mul i64 %t75, 2
  %t78 = icmp sgt i64 %t77, 0
  %t79 = select i1 %t78, i64 %t77, i64 1
  %t80 = mul i64 %t79, 8
  %t81 = call i8* @malloc(i64 %t80)
  %t82 = bitcast i8* %t81 to i8**
  %t83 = icmp sgt i64 %t75, 0
  br i1 %t83, label %sym_copy_31, label %sym_after_copy_32
sym_copy_31:
  %t84 = mul i64 %t63, 8
  %t85 = bitcast i8** %t64 to i8*
  call i8* @memcpy(i8* %t81, i8* %t85, i64 %t84)
  call void @free(i8* %t85)
  br label %sym_after_copy_32
sym_after_copy_32:
  store i8** %t82, i8*** @sym.data
  store i64 %t79, i64* @sym.cap
  br label %sym_store_30
sym_store_30:
  %t86 = load i8**, i8*** @sym.data
  %t87 = getelementptr inbounds i8*, i8** %t86, i64 %t63
  store i8* %t60, i8** %t87
  %t88 = add i64 %t63, 1
  store i64 %t88, i64* @sym.len
  br label %sym_done_28
sym_done_28:
  %t89 = phi i64 [ %t73, %sym_found_26 ], [ %t63, %sym_store_30 ]
  call i32 @ReleaseSemaphore(i8* %t62, i32 1, i32* null)
  %t90 = getelementptr inbounds %Entity, %Entity* %t59, i32 0, i32 0
  store i64 %t89, i64* %t90
  br label %par_incr_20
par_incr_20:
  %t91 = add i64 %t53, 1
  store i64 %t91, i64* %t52
  br label %par_cond_17
par_end_21:
  ret i32 0
}


@par.pool.job_fn = global [4 x i32 (i8*)*] zeroinitializer
@par.pool.job_arg = global [4 x i8*] zeroinitializer
@par.pool.start_sem = global [4 x i8*] zeroinitializer
@par.pool.done_sem = global [4 x i8*] zeroinitializer
@par.pool.tid = global [4 x i32] zeroinitializer
@par.pool.inited = global i1 false
@par.pool.serial_lock = global i8* null
@par.pool.serial_owner = global i32 -1

define i32 @par.pool.worker_main(i8* %idx_arg) {
entry:
  %t92 = ptrtoint i8* %idx_arg to i64
  %t93 = trunc i64 %t92 to i32
  %t94 = call i32 @GetCurrentThreadId()
  %t95 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t93
  store i32 %t94, i32* %t95
  br label %loop
loop:
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t93
  %t97 = load i8*, i8** %t96
  %t98 = call i32 @WaitForSingleObject(i8* %t97, i32 -1)
  %t99 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t93
  %t100 = load i32 (i8*)*, i32 (i8*)** %t99
  %t101 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t93
  %t102 = load i8*, i8** %t101
  %t103 = call i32 %t100(i8* %t102)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t93
  %t105 = load i8*, i8** %t104
  %t106 = call i32 @ReleaseSemaphore(i8* %t105, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t107 = load i1, i1* @par.pool.inited
  br i1 %t107, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t108 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t108, i8** @par.pool.serial_lock
  %t109 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t109, i8** %t110
  %t111 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t111, i8** %t112
  %t113 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t114 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t115 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t114, i8** %t115
  %t116 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t117 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t116, i8** %t117
  %t118 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t119 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t119, i8** %t120
  %t121 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t121, i8** %t122
  %t123 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t124 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t125 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t124, i8** %t125
  %t126 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t126, i8** %t127
  %t128 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_39(i8* %argp) {
entry:
  %t245 = alloca i64
  %t237 = bitcast i8* %argp to { i64, i64, i32* }*
  %t238 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t237, i32 0, i32 0
  %t239 = load i64, i64* %t238
  %t240 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t237, i32 0, i32 1
  %t241 = load i64, i64* %t240
  %t242 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t237, i32 0, i32 2
  %t243 = load i32*, i32** %t242
  %t244 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t239, i64* %t245
  br label %par_cond_40
par_cond_40:
  %t246 = load i64, i64* %t245
  %t247 = icmp slt i64 %t246, %t241
  br i1 %t247, label %par_body_41, label %par_end_44
par_body_41:
  %t248 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t246
  %t249 = load i32, i32* %t248
  %t250 = and i32 %t249, 1
  %t251 = icmp eq i32 %t250, 1
  br i1 %t251, label %par_live_42, label %par_incr_43
par_live_42:
  %t252 = getelementptr inbounds %Entity, %Entity* %t244, i64 %t246
  %t253 = getelementptr inbounds %Entity, %Entity* %t252, i32 0, i32 0
  %t254 = load i64, i64* %t253
  %t255 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t255, i64 %t254)
  br label %par_incr_43
par_incr_43:
  %t256 = add i64 %t246, 1
  store i64 %t256, i64* %t245
  br label %par_cond_40
par_end_44:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"%lld\0A\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"check = %lld\0A\00"
