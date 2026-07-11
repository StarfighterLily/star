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

define i32 @make_stuff(i32 %n) {
entry:
  %t0 = alloca i32
  store i32 %n, i32* %t0
  %t1 = alloca i8*
  %t2 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = add i32 %t4, %t5
  %t7 = add i32 %t6, 1
  %t8 = sext i32 %t7 to i64
  %t9 = call i8* @star_rc_alloc(i64 %t8, i8* null)
  call i8* @strcpy(i8* %t9, i8* %t2)
  call i8* @strcat(i8* %t9, i8* %t3)
  store i8* %t9, i8** %t1
  %t10 = alloca i32
  %t11 = load i8*, i8** %t1
  %t12 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t12)
  call void @star_rc_release(i8* %t11)
  %t13 = call i32 @strlen(i8* %t11)
  %t14 = load i32, i32* %t0
  %t15 = add i32 %t13, %t14
  store i32 %t15, i32* %t10
  %t16 = alloca { i8*, i8* }
  %t31 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* null, i32 1
  %t32 = ptrtoint { i32, i8*, i32 }* %t31 to i64
  %t36 = bitcast void (i8*)* @closure_0_release_env to i8*
  %t37 = call i8* @star_rc_alloc(i64 %t32, i8* %t36)
  %t38 = bitcast i8* %t37 to { i32, i8*, i32 }*
  %t39 = load i32, i32* %t0
  %t40 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t38, i32 0, i32 0
  store i32 %t39, i32* %t40
  %t41 = load i8*, i8** %t1
  %t42 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t42)
  %t43 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t38, i32 0, i32 1
  store i8* %t41, i8** %t43
  %t44 = load i32, i32* %t10
  %t45 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t38, i32 0, i32 2
  store i32 %t44, i32* %t45
  %t46 = bitcast i32 (i8*)* @closure_0 to i8*
  %t47 = insertvalue { i8*, i8* } undef, i8* %t46, 0
  %t48 = insertvalue { i8*, i8* } %t47, i8* %t37, 1
  store { i8*, i8* } %t48, { i8*, i8* }* %t16
  %t49 = load i32, i32* %t10
  %t50 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t51 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t52 = extractvalue { i8*, i8* } %t51, 1
  call void @star_rc_retain(i8* %t52)
  %t53 = extractvalue { i8*, i8* } %t50, 0
  %t54 = extractvalue { i8*, i8* } %t50, 1
  call void @star_rc_release(i8* %t54)
  %t55 = bitcast i8* %t53 to i32 (i8*)*
  %t56 = call i32 %t55(i8* %t54)
  %t57 = add i32 %t49, %t56
  %t58 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t59 = extractvalue { i8*, i8* } %t58, 1
  call void @star_rc_release(i8* %t59)
  %t60 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t60)
  ret i32 %t57
}

define i32 @main() {
entry:
  %t0 = alloca i32
  store i32 0, i32* %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  br label %while_cond_1
while_cond_1:
  %t2 = load i32, i32* %t0
  %t3 = icmp slt i32 %t2, 10000000
  br i1 %t3, label %while_body_2, label %while_end_4
while_body_2:
  %t4 = load i32, i32* %t0
  %t5 = call i32 @make_stuff(i32 %t4)
  %t6 = load i32, i32* %t1
  %t7 = add i32 %t6, %t5
  store i32 %t7, i32* %t1
  %t8 = load i32, i32* %t0
  %t9 = add i32 %t8, 1
  store i32 %t9, i32* %t0
  br label %while_cond_1
while_else_3:
  br label %while_end_4
while_end_4:
  %t10 = load i32, i32* %t1
  %t11 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i32 %t10)
  ret i32 0
}


; par/swarm worker functions
define i32 @closure_0(i8* %envp) {
entry:
  %t17 = bitcast i8* %envp to { i32, i8*, i32 }*
  %t18 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t20 = alloca i32
  store i32 %t19, i32* %t20
  %t21 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t17, i32 0, i32 1
  %t22 = load i8*, i8** %t21
  %t23 = alloca i8*
  store i8* %t22, i8** %t23
  %t24 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t17, i32 0, i32 2
  %t25 = load i32, i32* %t24
  %t26 = alloca i32
  store i32 %t25, i32* %t26
  %t27 = load i8*, i8** %t23
  %t28 = load i8*, i8** %t23
  call void @star_rc_retain(i8* %t28)
  call void @star_rc_release(i8* %t27)
  %t29 = call i32 @strlen(i8* %t27)
  %t30 = load i8*, i8** %t23
  call void @star_rc_release(i8* %t30)
  ret i32 %t29
}


define void @closure_0_release_env(i8* %envp) {
entry:
  %t33 = bitcast i8* %envp to { i32, i8*, i32 }*
  %t34 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t33, i32 0, i32 1
  %t35 = load i8*, i8** %t34
  call void @star_rc_release(i8* %t35)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"hello-\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"world\00" }
@.str.2 = private unnamed_addr constant [18 x i8] c"done, total = %d\0A\00"
