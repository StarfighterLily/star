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

define i32 @apply_twice({ i8*, i8* } %f, i32 %x) {
entry:
  %t0 = alloca { i8*, i8* }
  store { i8*, i8* } %f, { i8*, i8* }* %t0
  %t1 = alloca i32
  store i32 %x, i32* %t1
  %t2 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t3 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t4 = extractvalue { i8*, i8* } %t3, 1
  call void @star_rc_retain(i8* %t4)
  %t5 = extractvalue { i8*, i8* } %t2, 0
  %t6 = extractvalue { i8*, i8* } %t2, 1
  call void @star_rc_release(i8* %t6)
  %t7 = bitcast i8* %t5 to i32 (i8*, i32)*
  %t8 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t9 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t10 = extractvalue { i8*, i8* } %t9, 1
  call void @star_rc_retain(i8* %t10)
  %t11 = extractvalue { i8*, i8* } %t8, 0
  %t12 = extractvalue { i8*, i8* } %t8, 1
  call void @star_rc_release(i8* %t12)
  %t13 = bitcast i8* %t11 to i32 (i8*, i32)*
  %t14 = load i32, i32* %t1
  %t15 = call i32 %t13(i8* %t12, i32 %t14)
  %t16 = call i32 %t7(i8* %t6, i32 %t15)
  %t17 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t18 = extractvalue { i8*, i8* } %t17, 1
  call void @star_rc_release(i8* %t18)
  ret i32 %t16
}

define i32 @add_one(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = add i32 %t1, 1
  ret i32 %t2
}

define { i8*, i8* } @make_adder(i32 %n) {
entry:
  %t0 = alloca i32
  store i32 %n, i32* %t0
  %t9 = getelementptr inbounds { i32 }, { i32 }* null, i32 1
  %t10 = ptrtoint { i32 }* %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  %t12 = bitcast i8* %t11 to { i32 }*
  %t13 = load i32, i32* %t0
  %t14 = getelementptr inbounds { i32 }, { i32 }* %t12, i32 0, i32 0
  store i32 %t13, i32* %t14
  %t15 = bitcast i32 (i8*, i32)* @closure_0 to i8*
  %t16 = insertvalue { i8*, i8* } undef, i8* %t15, 0
  %t17 = insertvalue { i8*, i8* } %t16, i8* %t11, 1
  ret { i8*, i8* } %t17
}

define i32 @main() {
entry:
  %t0 = alloca { i8*, i8* }
  %t4 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t5 = insertvalue { i8*, i8* } undef, i8* %t4, 0
  %t6 = insertvalue { i8*, i8* } %t5, i8* null, 1
  store { i8*, i8* } %t6, { i8*, i8* }* %t0
  %t7 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t8 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t9 = extractvalue { i8*, i8* } %t8, 1
  call void @star_rc_retain(i8* %t9)
  %t10 = extractvalue { i8*, i8* } %t7, 0
  %t11 = extractvalue { i8*, i8* } %t7, 1
  call void @star_rc_release(i8* %t11)
  %t12 = bitcast i8* %t10 to i32 (i8*, i32)*
  %t13 = call i32 %t12(i8* %t11, i32 5)
  %t14 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t13)
  %t15 = alloca i32
  store i32 10, i32* %t15
  %t16 = alloca { i8*, i8* }
  %t30 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* null, i32 1
  %t31 = ptrtoint { { i8*, i8* }, i32 }* %t30 to i64
  %t36 = bitcast void (i8*)* @closure_2_release_env to i8*
  %t37 = call i8* @star_rc_alloc(i64 %t31, i8* %t36)
  %t38 = bitcast i8* %t37 to { { i8*, i8* }, i32 }*
  %t39 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t40 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t41 = extractvalue { i8*, i8* } %t40, 1
  call void @star_rc_retain(i8* %t41)
  %t42 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t38, i32 0, i32 0
  store { i8*, i8* } %t39, { i8*, i8* }* %t42
  %t43 = load i32, i32* %t15
  %t44 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t38, i32 0, i32 1
  store i32 %t43, i32* %t44
  %t45 = bitcast i32 (i8*, i32)* @closure_2 to i8*
  %t46 = insertvalue { i8*, i8* } undef, i8* %t45, 0
  %t47 = insertvalue { i8*, i8* } %t46, i8* %t37, 1
  store { i8*, i8* } %t47, { i8*, i8* }* %t16
  %t48 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t49 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t50 = extractvalue { i8*, i8* } %t49, 1
  call void @star_rc_retain(i8* %t50)
  %t51 = extractvalue { i8*, i8* } %t48, 0
  %t52 = extractvalue { i8*, i8* } %t48, 1
  call void @star_rc_release(i8* %t52)
  %t53 = bitcast i8* %t51 to i32 (i8*, i32)*
  %t54 = call i32 %t53(i8* %t52, i32 7)
  %t55 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t57 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t58 = extractvalue { i8*, i8* } %t57, 1
  call void @star_rc_retain(i8* %t58)
  %t59 = call i32 @apply_twice({ i8*, i8* } %t56, i32 5)
  %t60 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i32 %t59)
  %t61 = call i32 @add_one(i32 5)
  %t62 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i32 %t61)
  %t64 = bitcast i32 (i8*, i32)* @fnval_add_one to i8*
  %t65 = insertvalue { i8*, i8* } undef, i8* %t64, 0
  %t66 = insertvalue { i8*, i8* } %t65, i8* null, 1
  %t67 = call i32 @apply_twice({ i8*, i8* } %t66, i32 5)
  %t68 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t68, i32 %t67)
  %t69 = alloca { i8*, i8* }
  %t70 = call { i8*, i8* } @make_adder(i32 100)
  store { i8*, i8* } %t70, { i8*, i8* }* %t69
  %t71 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t72 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t73 = extractvalue { i8*, i8* } %t72, 1
  call void @star_rc_retain(i8* %t73)
  %t74 = extractvalue { i8*, i8* } %t71, 0
  %t75 = extractvalue { i8*, i8* } %t71, 1
  call void @star_rc_release(i8* %t75)
  %t76 = bitcast i8* %t74 to i32 (i8*, i32)*
  %t77 = call i32 %t76(i8* %t75, i32 5)
  %t78 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t78, i32 %t77)
  %t79 = alloca i32
  store i32 0, i32* %t79
  %t80 = alloca { i8*, i8* }
  %t105 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* null, i32 1
  %t106 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t105 to i64
  %t117 = bitcast void (i8*)* @closure_3_release_env to i8*
  %t118 = call i8* @star_rc_alloc(i64 %t106, i8* %t117)
  %t119 = bitcast i8* %t118 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t120 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t121 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t122 = extractvalue { i8*, i8* } %t121, 1
  call void @star_rc_retain(i8* %t122)
  %t123 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t119, i32 0, i32 0
  store { i8*, i8* } %t120, { i8*, i8* }* %t123
  %t124 = load i32, i32* %t15
  %t125 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t119, i32 0, i32 1
  store i32 %t124, i32* %t125
  %t126 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t127 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t128 = extractvalue { i8*, i8* } %t127, 1
  call void @star_rc_retain(i8* %t128)
  %t129 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t119, i32 0, i32 2
  store { i8*, i8* } %t126, { i8*, i8* }* %t129
  %t130 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t131 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t132 = extractvalue { i8*, i8* } %t131, 1
  call void @star_rc_retain(i8* %t132)
  %t133 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t119, i32 0, i32 3
  store { i8*, i8* } %t130, { i8*, i8* }* %t133
  %t134 = load i32, i32* %t79
  %t135 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t119, i32 0, i32 4
  store i32 %t134, i32* %t135
  %t136 = bitcast i32 (i8*)* @closure_3 to i8*
  %t137 = insertvalue { i8*, i8* } undef, i8* %t136, 0
  %t138 = insertvalue { i8*, i8* } %t137, i8* %t118, 1
  store { i8*, i8* } %t138, { i8*, i8* }* %t80
  store i32 50, i32* %t79
  %t139 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t140 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t141 = extractvalue { i8*, i8* } %t140, 1
  call void @star_rc_retain(i8* %t141)
  %t142 = extractvalue { i8*, i8* } %t139, 0
  %t143 = extractvalue { i8*, i8* } %t139, 1
  call void @star_rc_release(i8* %t143)
  %t144 = bitcast i8* %t142 to i32 (i8*)*
  %t145 = call i32 %t144(i8* %t143)
  %t146 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t146, i32 %t145)
  %t147 = alloca { i8*, i8* }
  %t177 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* null, i32 1
  %t178 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t177 to i64
  %t192 = bitcast void (i8*)* @closure_4_release_env to i8*
  %t193 = call i8* @star_rc_alloc(i64 %t178, i8* %t192)
  %t194 = bitcast i8* %t193 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t195 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t196 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t197 = extractvalue { i8*, i8* } %t196, 1
  call void @star_rc_retain(i8* %t197)
  %t198 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 0
  store { i8*, i8* } %t195, { i8*, i8* }* %t198
  %t199 = load i32, i32* %t15
  %t200 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 1
  store i32 %t199, i32* %t200
  %t201 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t202 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t203 = extractvalue { i8*, i8* } %t202, 1
  call void @star_rc_retain(i8* %t203)
  %t204 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 2
  store { i8*, i8* } %t201, { i8*, i8* }* %t204
  %t205 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t206 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t207 = extractvalue { i8*, i8* } %t206, 1
  call void @star_rc_retain(i8* %t207)
  %t208 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 3
  store { i8*, i8* } %t205, { i8*, i8* }* %t208
  %t209 = load i32, i32* %t79
  %t210 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 4
  store i32 %t209, i32* %t210
  %t211 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t212 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t213 = extractvalue { i8*, i8* } %t212, 1
  call void @star_rc_retain(i8* %t213)
  %t214 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t194, i32 0, i32 5
  store { i8*, i8* } %t211, { i8*, i8* }* %t214
  %t215 = bitcast void (i8*)* @closure_4 to i8*
  %t216 = insertvalue { i8*, i8* } undef, i8* %t215, 0
  %t217 = insertvalue { i8*, i8* } %t216, i8* %t193, 1
  store { i8*, i8* } %t217, { i8*, i8* }* %t147
  %t218 = load { i8*, i8* }, { i8*, i8* }* %t147
  %t219 = load { i8*, i8* }, { i8*, i8* }* %t147
  %t220 = extractvalue { i8*, i8* } %t219, 1
  call void @star_rc_retain(i8* %t220)
  %t221 = extractvalue { i8*, i8* } %t218, 0
  %t222 = extractvalue { i8*, i8* } %t218, 1
  call void @star_rc_release(i8* %t222)
  %t223 = bitcast i8* %t221 to void (i8*)*
  call void %t223(i8* %t222)
  %t224 = load { i8*, i8* }, { i8*, i8* }* %t147
  %t225 = extractvalue { i8*, i8* } %t224, 1
  call void @star_rc_release(i8* %t225)
  %t226 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t227 = extractvalue { i8*, i8* } %t226, 1
  call void @star_rc_release(i8* %t227)
  %t228 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t229 = extractvalue { i8*, i8* } %t228, 1
  call void @star_rc_release(i8* %t229)
  %t230 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t231 = extractvalue { i8*, i8* } %t230, 1
  call void @star_rc_release(i8* %t231)
  %t232 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t233 = extractvalue { i8*, i8* } %t232, 1
  call void @star_rc_release(i8* %t233)
  ret i32 0
}


; par/swarm worker functions
define i32 @closure_0(i8* %envp, i32 %arg_x) {
entry:
  %t1 = bitcast i8* %envp to { i32 }*
  %t2 = getelementptr inbounds { i32 }, { i32 }* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = alloca i32
  store i32 %t3, i32* %t4
  %t5 = alloca i32
  store i32 %arg_x, i32* %t5
  %t6 = load i32, i32* %t5
  %t7 = load i32, i32* %t4
  %t8 = add i32 %t6, %t7
  ret i32 %t8
}


define i32 @closure_1(i8* %envp, i32 %arg_x) {
entry:
  %t1 = alloca i32
  store i32 %arg_x, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = add i32 %t2, 1
  ret i32 %t3
}


define i32 @closure_2(i8* %envp, i32 %arg_x) {
entry:
  %t17 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t18 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t17, i32 0, i32 0
  %t19 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t20 = alloca { i8*, i8* }
  store { i8*, i8* } %t19, { i8*, i8* }* %t20
  %t21 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t17, i32 0, i32 1
  %t22 = load i32, i32* %t21
  %t23 = alloca i32
  store i32 %t22, i32* %t23
  %t24 = alloca i32
  store i32 %arg_x, i32* %t24
  %t25 = load i32, i32* %t24
  %t26 = load i32, i32* %t23
  %t27 = add i32 %t25, %t26
  %t28 = load { i8*, i8* }, { i8*, i8* }* %t20
  %t29 = extractvalue { i8*, i8* } %t28, 1
  call void @star_rc_release(i8* %t29)
  ret i32 %t27
}


define void @closure_2_release_env(i8* %envp) {
entry:
  %t32 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t33 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t32, i32 0, i32 0
  %t34 = load { i8*, i8* }, { i8*, i8* }* %t33
  %t35 = extractvalue { i8*, i8* } %t34, 1
  call void @star_rc_release(i8* %t35)
  ret void
}


define i32 @fnval_add_one(i8* %envp, i32 %arg_0) {
entry:
  %t63 = call i32 @add_one(i32 %arg_0)
  ret i32 %t63
}


define i32 @closure_3(i8* %envp) {
entry:
  %t81 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t82 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 0
  %t83 = load { i8*, i8* }, { i8*, i8* }* %t82
  %t84 = alloca { i8*, i8* }
  store { i8*, i8* } %t83, { i8*, i8* }* %t84
  %t85 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 1
  %t86 = load i32, i32* %t85
  %t87 = alloca i32
  store i32 %t86, i32* %t87
  %t88 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 2
  %t89 = load { i8*, i8* }, { i8*, i8* }* %t88
  %t90 = alloca { i8*, i8* }
  store { i8*, i8* } %t89, { i8*, i8* }* %t90
  %t91 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 3
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t91
  %t93 = alloca { i8*, i8* }
  store { i8*, i8* } %t92, { i8*, i8* }* %t93
  %t94 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 4
  %t95 = load i32, i32* %t94
  %t96 = alloca i32
  store i32 %t95, i32* %t96
  %t97 = load i32, i32* %t96
  %t98 = add i32 %t97, 1
  %t99 = load { i8*, i8* }, { i8*, i8* }* %t93
  %t100 = extractvalue { i8*, i8* } %t99, 1
  call void @star_rc_release(i8* %t100)
  %t101 = load { i8*, i8* }, { i8*, i8* }* %t90
  %t102 = extractvalue { i8*, i8* } %t101, 1
  call void @star_rc_release(i8* %t102)
  %t103 = load { i8*, i8* }, { i8*, i8* }* %t84
  %t104 = extractvalue { i8*, i8* } %t103, 1
  call void @star_rc_release(i8* %t104)
  ret i32 %t98
}


define void @closure_3_release_env(i8* %envp) {
entry:
  %t107 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t108 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t107, i32 0, i32 0
  %t109 = load { i8*, i8* }, { i8*, i8* }* %t108
  %t110 = extractvalue { i8*, i8* } %t109, 1
  call void @star_rc_release(i8* %t110)
  %t111 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t107, i32 0, i32 2
  %t112 = load { i8*, i8* }, { i8*, i8* }* %t111
  %t113 = extractvalue { i8*, i8* } %t112, 1
  call void @star_rc_release(i8* %t113)
  %t114 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t107, i32 0, i32 3
  %t115 = load { i8*, i8* }, { i8*, i8* }* %t114
  %t116 = extractvalue { i8*, i8* } %t115, 1
  call void @star_rc_release(i8* %t116)
  ret void
}


define void @closure_4(i8* %envp) {
entry:
  %t148 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t149 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 0
  %t150 = load { i8*, i8* }, { i8*, i8* }* %t149
  %t151 = alloca { i8*, i8* }
  store { i8*, i8* } %t150, { i8*, i8* }* %t151
  %t152 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 1
  %t153 = load i32, i32* %t152
  %t154 = alloca i32
  store i32 %t153, i32* %t154
  %t155 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 2
  %t156 = load { i8*, i8* }, { i8*, i8* }* %t155
  %t157 = alloca { i8*, i8* }
  store { i8*, i8* } %t156, { i8*, i8* }* %t157
  %t158 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 3
  %t159 = load { i8*, i8* }, { i8*, i8* }* %t158
  %t160 = alloca { i8*, i8* }
  store { i8*, i8* } %t159, { i8*, i8* }* %t160
  %t161 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 4
  %t162 = load i32, i32* %t161
  %t163 = alloca i32
  store i32 %t162, i32* %t163
  %t164 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t148, i32 0, i32 5
  %t165 = load { i8*, i8* }, { i8*, i8* }* %t164
  %t166 = alloca { i8*, i8* }
  store { i8*, i8* } %t165, { i8*, i8* }* %t166
  %t167 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t167)
  %t168 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t168)
  %t169 = load { i8*, i8* }, { i8*, i8* }* %t166
  %t170 = extractvalue { i8*, i8* } %t169, 1
  call void @star_rc_release(i8* %t170)
  %t171 = load { i8*, i8* }, { i8*, i8* }* %t160
  %t172 = extractvalue { i8*, i8* } %t171, 1
  call void @star_rc_release(i8* %t172)
  %t173 = load { i8*, i8* }, { i8*, i8* }* %t157
  %t174 = extractvalue { i8*, i8* } %t173, 1
  call void @star_rc_release(i8* %t174)
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t151
  %t176 = extractvalue { i8*, i8* } %t175, 1
  call void @star_rc_release(i8* %t176)
  ret void
}


define void @closure_4_release_env(i8* %envp) {
entry:
  %t179 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t180 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 0
  %t181 = load { i8*, i8* }, { i8*, i8* }* %t180
  %t182 = extractvalue { i8*, i8* } %t181, 1
  call void @star_rc_release(i8* %t182)
  %t183 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 2
  %t184 = load { i8*, i8* }, { i8*, i8* }* %t183
  %t185 = extractvalue { i8*, i8* } %t184, 1
  call void @star_rc_release(i8* %t185)
  %t186 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 3
  %t187 = load { i8*, i8* }, { i8*, i8* }* %t186
  %t188 = extractvalue { i8*, i8* } %t187, 1
  call void @star_rc_release(i8* %t188)
  %t189 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 5
  %t190 = load { i8*, i8* }, { i8*, i8* }* %t189
  %t191 = extractvalue { i8*, i8* } %t190, 1
  call void @star_rc_release(i8* %t191)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [14 x i8] c"add1(5) = %d\0A\00"
@.str.1 = private unnamed_addr constant [18 x i8] c"add_base(7) = %d\0A\00"
@.str.2 = private unnamed_addr constant [27 x i8] c"apply_twice(add1, 5) = %d\0A\00"
@.str.3 = private unnamed_addr constant [17 x i8] c"add_one(5) = %d\0A\00"
@.str.4 = private unnamed_addr constant [30 x i8] c"apply_twice(add_one, 5) = %d\0A\00"
@.str.5 = private unnamed_addr constant [15 x i8] c"adder(5) = %d\0A\00"
@.str.6 = private unnamed_addr constant [13 x i8] c"bump() = %d\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [23 x i8] } { i64 -1, i8* null, [23 x i8] c"hi from a void closure\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
