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

define i32 @make_stuff(i32 %n) {
entry:
  %t0 = alloca i32
  store i32 %n, i32* %t0
  %t1 = alloca i8*
  %t3 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = alloca i8*
  store i8* %t3, i8** %t2
  %t4 = load i8*, i8** %t2
  %t6 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t5 = alloca i8*
  store i8* %t6, i8** %t5
  %t7 = load i8*, i8** %t5
  %t8 = call i32 @strlen(i8* %t4)
  %t9 = call i32 @strlen(i8* %t7)
  %t10 = add i32 %t8, %t9
  %t11 = add i32 %t10, 1
  %t12 = sext i32 %t11 to i64
  %t13 = call i8* @star_rc_alloc(i64 %t12, i8* null)
  call i8* @strcpy(i8* %t13, i8* %t4)
  call i8* @strcat(i8* %t13, i8* %t7)
  %t14 = alloca i8*
  store i8* %t13, i8** %t14
  store i8* %t14, i8** %t1
  %t15 = alloca i32
  %t16 = load i8*, i8** %t1
  %t17 = load i8*, i8** %t1
  %t18 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t18)
  %t19 = load i8*, i8** %t16
  call void @star_rc_release(i8* %t19)
  %t20 = call i32 @strlen(i8* %t19)
  %t21 = load i32, i32* %t0
  %t22 = add i32 %t20, %t21
  store i32 %t22, i32* %t15
  %t23 = alloca { i8*, i8* }
  %t41 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* null, i32 1
  %t42 = ptrtoint { i32, i8*, i32 }* %t41 to i64
  %t47 = bitcast void (i8*)* @closure_0_release_env to i8*
  %t48 = call i8* @star_rc_alloc(i64 %t42, i8* %t47)
  %t49 = bitcast i8* %t48 to { i32, i8*, i32 }*
  %t50 = load i32, i32* %t0
  %t51 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t49, i32 0, i32 0
  store i32 %t50, i32* %t51
  %t52 = load i8*, i8** %t1
  %t53 = load i8*, i8** %t1
  %t54 = load i8*, i8** %t53
  call void @star_rc_retain(i8* %t54)
  %t55 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t49, i32 0, i32 1
  store i8* %t52, i8** %t55
  %t56 = load i32, i32* %t15
  %t57 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t49, i32 0, i32 2
  store i32 %t56, i32* %t57
  %t58 = bitcast i32 (i8*)* @closure_0 to i8*
  %t59 = insertvalue { i8*, i8* } undef, i8* %t58, 0
  %t60 = insertvalue { i8*, i8* } %t59, i8* %t48, 1
  store { i8*, i8* } %t60, { i8*, i8* }* %t23
  %t61 = load i32, i32* %t15
  %t62 = load { i8*, i8* }, { i8*, i8* }* %t23
  %t63 = load { i8*, i8* }, { i8*, i8* }* %t23
  %t64 = extractvalue { i8*, i8* } %t63, 1
  call void @star_rc_retain(i8* %t64)
  %t65 = extractvalue { i8*, i8* } %t62, 0
  %t66 = extractvalue { i8*, i8* } %t62, 1
  call void @star_rc_release(i8* %t66)
  %t67 = bitcast i8* %t65 to i32 (i8*)*
  %t68 = call i32 %t67(i8* %t66)
  %t69 = add i32 %t61, %t68
  %t70 = load { i8*, i8* }, { i8*, i8* }* %t23
  %t71 = extractvalue { i8*, i8* } %t70, 1
  call void @star_rc_release(i8* %t71)
  %t72 = load i8*, i8** %t1
  %t73 = load i8*, i8** %t72
  call void @star_rc_release(i8* %t73)
  ret i32 %t69
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
  %t24 = bitcast i8* %envp to { i32, i8*, i32 }*
  %t25 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t24, i32 0, i32 0
  %t26 = load i32, i32* %t25
  %t27 = alloca i32
  store i32 %t26, i32* %t27
  %t28 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t24, i32 0, i32 1
  %t29 = load i8*, i8** %t28
  %t30 = alloca i8*
  store i8* %t29, i8** %t30
  %t31 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t24, i32 0, i32 2
  %t32 = load i32, i32* %t31
  %t33 = alloca i32
  store i32 %t32, i32* %t33
  %t34 = load i8*, i8** %t30
  %t35 = load i8*, i8** %t30
  %t36 = load i8*, i8** %t35
  call void @star_rc_retain(i8* %t36)
  %t37 = load i8*, i8** %t34
  call void @star_rc_release(i8* %t37)
  %t38 = call i32 @strlen(i8* %t37)
  %t39 = load i8*, i8** %t30
  %t40 = load i8*, i8** %t39
  call void @star_rc_release(i8* %t40)
  ret i32 %t38
}


define void @closure_0_release_env(i8* %envp) {
entry:
  %t43 = bitcast i8* %envp to { i32, i8*, i32 }*
  %t44 = getelementptr inbounds { i32, i8*, i32 }, { i32, i8*, i32 }* %t43, i32 0, i32 1
  %t45 = load i8*, i8** %t44
  %t46 = load i8*, i8** %t45
  call void @star_rc_release(i8* %t46)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"hello-\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"world\00" }
@.str.2 = private unnamed_addr constant [18 x i8] c"done, total = %d\0A\00"
