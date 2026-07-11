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

%Handler = type { { i8*, i8* } }
define { i8*, i8* } @make_greeter(i8* %name) {
entry:
  %t0 = alloca i8*
  store i8* %name, i8** %t0
  %t10 = getelementptr inbounds { i8* }, { i8* }* null, i32 1
  %t11 = ptrtoint { i8* }* %t10 to i64
  %t16 = bitcast void (i8*)* @closure_0_release_env to i8*
  %t17 = call i8* @star_rc_alloc(i64 %t11, i8* %t16)
  %t18 = bitcast i8* %t17 to { i8* }*
  %t19 = load i8*, i8** %t0
  %t20 = load i8*, i8** %t0
  %t21 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t21)
  %t22 = getelementptr inbounds { i8* }, { i8* }* %t18, i32 0, i32 0
  store i8* %t19, i8** %t22
  %t23 = bitcast i8* (i8*)* @closure_0 to i8*
  %t24 = insertvalue { i8*, i8* } undef, i8* %t23, 0
  %t25 = insertvalue { i8*, i8* } %t24, i8* %t17, 1
  %t26 = load i8*, i8** %t0
  %t27 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t27)
  ret { i8*, i8* } %t25
}

define { i8*, i8* } @make_adder(i32 %base) {
entry:
  %t0 = alloca i32
  store i32 %base, i32* %t0
  %t9 = getelementptr inbounds { i32 }, { i32 }* null, i32 1
  %t10 = ptrtoint { i32 }* %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  %t12 = bitcast i8* %t11 to { i32 }*
  %t13 = load i32, i32* %t0
  %t14 = getelementptr inbounds { i32 }, { i32 }* %t12, i32 0, i32 0
  store i32 %t13, i32* %t14
  %t15 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t16 = insertvalue { i8*, i8* } undef, i8* %t15, 0
  %t17 = insertvalue { i8*, i8* } %t16, i8* %t11, 1
  ret { i8*, i8* } %t17
}

define i32 @main() {
entry:
  %t0 = alloca { i8*, i8* }
  %t2 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t1 = alloca i8*
  store i8* %t2, i8** %t1
  %t3 = call { i8*, i8* } @make_greeter(i8* %t1)
  store { i8*, i8* } %t3, { i8*, i8* }* %t0
  %t4 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t5 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t6 = extractvalue { i8*, i8* } %t5, 1
  call void @star_rc_retain(i8* %t6)
  %t7 = extractvalue { i8*, i8* } %t4, 0
  %t8 = extractvalue { i8*, i8* } %t4, 1
  call void @star_rc_release(i8* %t8)
  %t9 = bitcast i8* %t7 to i8* (i8*)*
  %t10 = call i8* %t9(i8* %t8)
  %t11 = load i8*, i8** %t10
  %t12 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i8* %t11)
  %t13 = alloca %Handler
  %t14 = alloca %Handler
  %t16 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t15 = alloca i8*
  store i8* %t16, i8** %t15
  %t17 = call { i8*, i8* } @make_greeter(i8* %t15)
  %t18 = getelementptr inbounds %Handler, %Handler* %t14, i32 0, i32 0
  store { i8*, i8* } %t17, { i8*, i8* }* %t18
  %t19 = load %Handler, %Handler* %t14
  store %Handler %t19, %Handler* %t13
  %t20 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t21 = load { i8*, i8* }, { i8*, i8* }* %t20
  %t22 = load { i8*, i8* }, { i8*, i8* }* %t20
  %t23 = extractvalue { i8*, i8* } %t22, 1
  call void @star_rc_retain(i8* %t23)
  %t24 = extractvalue { i8*, i8* } %t21, 0
  %t25 = extractvalue { i8*, i8* } %t21, 1
  call void @star_rc_release(i8* %t25)
  %t26 = bitcast i8* %t24 to i8* (i8*)*
  %t27 = call i8* %t26(i8* %t25)
  %t28 = load i8*, i8** %t27
  %t29 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t29, i8* %t28)
  %t30 = alloca { { i8*, i8* }*, i64, i64 }
  %t31 = call i8* @malloc(i64 32)
  %t32 = bitcast i8* %t31 to { i8*, i8* }*
  %t34 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t33 = alloca i8*
  store i8* %t34, i8** %t33
  %t35 = call { i8*, i8* } @make_greeter(i8* %t33)
  %t36 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t32, i64 0
  store { i8*, i8* } %t35, { i8*, i8* }* %t36
  %t38 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t37 = alloca i8*
  store i8* %t38, i8** %t37
  %t39 = call { i8*, i8* } @make_greeter(i8* %t37)
  %t40 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t32, i64 1
  store { i8*, i8* } %t39, { i8*, i8* }* %t40
  %t41 = alloca { { i8*, i8* }*, i64, i64 }
  %t42 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t41, i32 0, i32 0
  store { i8*, i8* }* %t32, { i8*, i8* }** %t42
  %t43 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t41, i32 0, i32 1
  store i64 2, i64* %t43
  %t44 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t41, i32 0, i32 2
  store i64 2, i64* %t44
  %t45 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t41
  store { { i8*, i8* }*, i64, i64 } %t45, { { i8*, i8* }*, i64, i64 }* %t30
  %t46 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 0
  %t47 = load { i8*, i8* }*, { i8*, i8* }** %t46
  %t48 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 2
  %t51 = sext i32 0 to i64
  %t52 = icmp ult i64 %t51, %t49
  br i1 %t52, label %list_idx_ok_2, label %list_idx_oob_3
list_idx_ok_2:
  %t53 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t47, i64 %t51
  %t54 = load { i8*, i8* }, { i8*, i8* }* %t53
  %t55 = load { i8*, i8* }, { i8*, i8* }* %t53
  %t56 = extractvalue { i8*, i8* } %t55, 1
  call void @star_rc_retain(i8* %t56)
  br label %list_idx_end_4
list_idx_oob_3:
  br label %list_idx_end_4
list_idx_end_4:
  %t57 = phi { i8*, i8* } [ %t54, %list_idx_ok_2 ], [ zeroinitializer, %list_idx_oob_3 ]
  %t58 = extractvalue { i8*, i8* } %t57, 0
  %t59 = extractvalue { i8*, i8* } %t57, 1
  call void @star_rc_release(i8* %t59)
  %t60 = bitcast i8* %t58 to i8* (i8*)*
  %t61 = call i8* %t60(i8* %t59)
  %t62 = load i8*, i8** %t61
  %t63 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t63, i8* %t62)
  %t64 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 0
  %t65 = load { i8*, i8* }*, { i8*, i8* }** %t64
  %t66 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 1
  %t67 = load i64, i64* %t66
  %t68 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 2
  %t69 = sext i32 1 to i64
  %t70 = icmp ult i64 %t69, %t67
  br i1 %t70, label %list_idx_ok_5, label %list_idx_oob_6
list_idx_ok_5:
  %t71 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t65, i64 %t69
  %t72 = load { i8*, i8* }, { i8*, i8* }* %t71
  %t73 = load { i8*, i8* }, { i8*, i8* }* %t71
  %t74 = extractvalue { i8*, i8* } %t73, 1
  call void @star_rc_retain(i8* %t74)
  br label %list_idx_end_7
list_idx_oob_6:
  br label %list_idx_end_7
list_idx_end_7:
  %t75 = phi { i8*, i8* } [ %t72, %list_idx_ok_5 ], [ zeroinitializer, %list_idx_oob_6 ]
  %t76 = extractvalue { i8*, i8* } %t75, 0
  %t77 = extractvalue { i8*, i8* } %t75, 1
  call void @star_rc_release(i8* %t77)
  %t78 = bitcast i8* %t76 to i8* (i8*)*
  %t79 = call i8* %t78(i8* %t77)
  %t80 = load i8*, i8** %t79
  %t81 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t81, i8* %t80)
  %t82 = alloca { i8*, i8* }
  %t83 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t83, { i8*, i8* }* %t82
  %t84 = alloca { i8*, i8* }
  %t125 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* null, i32 1
  %t126 = ptrtoint { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t125 to i64
  %t150 = bitcast void (i8*)* @closure_8_release_env to i8*
  %t151 = call i8* @star_rc_alloc(i64 %t126, i8* %t150)
  %t152 = bitcast i8* %t151 to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t153 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t154 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t155 = extractvalue { i8*, i8* } %t154, 1
  call void @star_rc_retain(i8* %t155)
  %t156 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t152, i32 0, i32 0
  store { i8*, i8* } %t153, { i8*, i8* }* %t156
  %t157 = load %Handler, %Handler* %t13
  %t158 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t159 = load { i8*, i8* }, { i8*, i8* }* %t158
  %t160 = extractvalue { i8*, i8* } %t159, 1
  call void @star_rc_retain(i8* %t160)
  %t161 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t152, i32 0, i32 1
  store %Handler %t157, %Handler* %t161
  %t162 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30
  %t163 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 0
  %t164 = load { i8*, i8* }*, { i8*, i8* }** %t163
  %t165 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 1
  %t166 = load i64, i64* %t165
  %t167 = alloca i64
  store i64 0, i64* %t167
  br label %rc_walk_cond_15
rc_walk_cond_15:
  %t168 = load i64, i64* %t167
  %t169 = icmp slt i64 %t168, %t166
  br i1 %t169, label %rc_walk_body_16, label %rc_walk_end_17
rc_walk_body_16:
  %t170 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t164, i64 %t168
  %t171 = load { i8*, i8* }, { i8*, i8* }* %t170
  %t172 = extractvalue { i8*, i8* } %t171, 1
  call void @star_rc_retain(i8* %t172)
  %t173 = add i64 %t168, 1
  store i64 %t173, i64* %t167
  br label %rc_walk_cond_15
rc_walk_end_17:
  %t174 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t152, i32 0, i32 2
  store { { i8*, i8* }*, i64, i64 } %t162, { { i8*, i8* }*, i64, i64 }* %t174
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t82
  %t176 = load { i8*, i8* }, { i8*, i8* }* %t82
  %t177 = extractvalue { i8*, i8* } %t176, 1
  call void @star_rc_retain(i8* %t177)
  %t178 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t152, i32 0, i32 3
  store { i8*, i8* } %t175, { i8*, i8* }* %t178
  %t179 = bitcast i32 (i8*, i32)* @closure_8 to i8*
  %t180 = insertvalue { i8*, i8* } undef, i8* %t179, 0
  %t181 = insertvalue { i8*, i8* } %t180, i8* %t151, 1
  store { i8*, i8* } %t181, { i8*, i8* }* %t84
  %t182 = load { i8*, i8* }, { i8*, i8* }* %t84
  %t183 = load { i8*, i8* }, { i8*, i8* }* %t84
  %t184 = extractvalue { i8*, i8* } %t183, 1
  call void @star_rc_retain(i8* %t184)
  %t185 = extractvalue { i8*, i8* } %t182, 0
  %t186 = extractvalue { i8*, i8* } %t182, 1
  call void @star_rc_release(i8* %t186)
  %t187 = bitcast i8* %t185 to i32 (i8*, i32)*
  %t188 = call i32 %t187(i8* %t186, i32 10)
  %t189 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t189, i32 %t188)
  %t190 = alloca i32
  store i32 0, i32* %t190
  br label %while_cond_18
while_cond_18:
  %t191 = load i32, i32* %t190
  %t192 = icmp slt i32 %t191, 3
  br i1 %t192, label %while_body_19, label %while_end_21
while_body_19:
  %t193 = load i32, i32* %t190
  %t194 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t195 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t196 = extractvalue { i8*, i8* } %t195, 1
  call void @star_rc_retain(i8* %t196)
  %t197 = extractvalue { i8*, i8* } %t194, 0
  %t198 = extractvalue { i8*, i8* } %t194, 1
  call void @star_rc_release(i8* %t198)
  %t199 = bitcast i8* %t197 to i8* (i8*)*
  %t200 = call i8* %t199(i8* %t198)
  %t201 = load i8*, i8** %t200
  %t202 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t202, i32 %t193, i8* %t201)
  %t203 = load i32, i32* %t190
  %t204 = add i32 %t203, 1
  store i32 %t204, i32* %t190
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t205 = load { i8*, i8* }, { i8*, i8* }* %t84
  %t206 = extractvalue { i8*, i8* } %t205, 1
  call void @star_rc_release(i8* %t206)
  %t207 = load { i8*, i8* }, { i8*, i8* }* %t82
  %t208 = extractvalue { i8*, i8* } %t207, 1
  call void @star_rc_release(i8* %t208)
  %t209 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 0
  %t210 = load { i8*, i8* }*, { i8*, i8* }** %t209
  %t211 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t30, i32 0, i32 1
  %t212 = load i64, i64* %t211
  %t213 = alloca i64
  store i64 0, i64* %t213
  br label %rc_walk_cond_22
rc_walk_cond_22:
  %t214 = load i64, i64* %t213
  %t215 = icmp slt i64 %t214, %t212
  br i1 %t215, label %rc_walk_body_23, label %rc_walk_end_24
rc_walk_body_23:
  %t216 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t210, i64 %t214
  %t217 = load { i8*, i8* }, { i8*, i8* }* %t216
  %t218 = extractvalue { i8*, i8* } %t217, 1
  call void @star_rc_release(i8* %t218)
  %t219 = add i64 %t214, 1
  store i64 %t219, i64* %t213
  br label %rc_walk_cond_22
rc_walk_end_24:
  %t220 = getelementptr inbounds %Handler, %Handler* %t13, i32 0, i32 0
  %t221 = load { i8*, i8* }, { i8*, i8* }* %t220
  %t222 = extractvalue { i8*, i8* } %t221, 1
  call void @star_rc_release(i8* %t222)
  %t223 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t224 = extractvalue { i8*, i8* } %t223, 1
  call void @star_rc_release(i8* %t224)
  ret i32 0
}


; par/swarm worker functions
define i8* @closure_0(i8* %envp) {
entry:
  %t1 = bitcast i8* %envp to { i8* }*
  %t2 = getelementptr inbounds { i8* }, { i8* }* %t1, i32 0, i32 0
  %t3 = load i8*, i8** %t2
  %t4 = alloca i8*
  store i8* %t3, i8** %t4
  %t5 = load i8*, i8** %t4
  %t6 = load i8*, i8** %t4
  %t7 = load i8*, i8** %t6
  call void @star_rc_retain(i8* %t7)
  %t8 = load i8*, i8** %t4
  %t9 = load i8*, i8** %t8
  call void @star_rc_release(i8* %t9)
  ret i8* %t5
}


define void @closure_0_release_env(i8* %envp) {
entry:
  %t12 = bitcast i8* %envp to { i8* }*
  %t13 = getelementptr inbounds { i8* }, { i8* }* %t12, i32 0, i32 0
  %t14 = load i8*, i8** %t13
  %t15 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t15)
  ret void
}


define i32 @closure_1(i8* %envp, i32 %arg_x) {
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


define i32 @closure_8(i8* %envp, i32 %arg_x) {
entry:
  %t85 = bitcast i8* %envp to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t86 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t85, i32 0, i32 0
  %t87 = load { i8*, i8* }, { i8*, i8* }* %t86
  %t88 = alloca { i8*, i8* }
  store { i8*, i8* } %t87, { i8*, i8* }* %t88
  %t89 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t85, i32 0, i32 1
  %t90 = load %Handler, %Handler* %t89
  %t91 = alloca %Handler
  store %Handler %t90, %Handler* %t91
  %t92 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t85, i32 0, i32 2
  %t93 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t92
  %t94 = alloca { { i8*, i8* }*, i64, i64 }
  store { { i8*, i8* }*, i64, i64 } %t93, { { i8*, i8* }*, i64, i64 }* %t94
  %t95 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t85, i32 0, i32 3
  %t96 = load { i8*, i8* }, { i8*, i8* }* %t95
  %t97 = alloca { i8*, i8* }
  store { i8*, i8* } %t96, { i8*, i8* }* %t97
  %t98 = alloca i32
  store i32 %arg_x, i32* %t98
  %t99 = load { i8*, i8* }, { i8*, i8* }* %t97
  %t100 = load { i8*, i8* }, { i8*, i8* }* %t97
  %t101 = extractvalue { i8*, i8* } %t100, 1
  call void @star_rc_retain(i8* %t101)
  %t102 = extractvalue { i8*, i8* } %t99, 0
  %t103 = extractvalue { i8*, i8* } %t99, 1
  call void @star_rc_release(i8* %t103)
  %t104 = bitcast i8* %t102 to i32 (i8*, i32)*
  %t105 = load i32, i32* %t98
  %t106 = call i32 %t104(i8* %t103, i32 %t105)
  %t107 = load { i8*, i8* }, { i8*, i8* }* %t97
  %t108 = extractvalue { i8*, i8* } %t107, 1
  call void @star_rc_release(i8* %t108)
  %t109 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t94, i32 0, i32 0
  %t110 = load { i8*, i8* }*, { i8*, i8* }** %t109
  %t111 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t94, i32 0, i32 1
  %t112 = load i64, i64* %t111
  %t113 = alloca i64
  store i64 0, i64* %t113
  br label %rc_walk_cond_9
rc_walk_cond_9:
  %t114 = load i64, i64* %t113
  %t115 = icmp slt i64 %t114, %t112
  br i1 %t115, label %rc_walk_body_10, label %rc_walk_end_11
rc_walk_body_10:
  %t116 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t110, i64 %t114
  %t117 = load { i8*, i8* }, { i8*, i8* }* %t116
  %t118 = extractvalue { i8*, i8* } %t117, 1
  call void @star_rc_release(i8* %t118)
  %t119 = add i64 %t114, 1
  store i64 %t119, i64* %t113
  br label %rc_walk_cond_9
rc_walk_end_11:
  %t120 = getelementptr inbounds %Handler, %Handler* %t91, i32 0, i32 0
  %t121 = load { i8*, i8* }, { i8*, i8* }* %t120
  %t122 = extractvalue { i8*, i8* } %t121, 1
  call void @star_rc_release(i8* %t122)
  %t123 = load { i8*, i8* }, { i8*, i8* }* %t88
  %t124 = extractvalue { i8*, i8* } %t123, 1
  call void @star_rc_release(i8* %t124)
  ret i32 %t106
}


define void @closure_8_release_env(i8* %envp) {
entry:
  %t127 = bitcast i8* %envp to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t128 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t127, i32 0, i32 0
  %t129 = load { i8*, i8* }, { i8*, i8* }* %t128
  %t130 = extractvalue { i8*, i8* } %t129, 1
  call void @star_rc_release(i8* %t130)
  %t131 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t127, i32 0, i32 1
  %t132 = getelementptr inbounds %Handler, %Handler* %t131, i32 0, i32 0
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t132
  %t134 = extractvalue { i8*, i8* } %t133, 1
  call void @star_rc_release(i8* %t134)
  %t135 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t127, i32 0, i32 2
  %t136 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load { i8*, i8* }*, { i8*, i8* }** %t136
  %t138 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t135, i32 0, i32 1
  %t139 = load i64, i64* %t138
  %t140 = alloca i64
  store i64 0, i64* %t140
  br label %rc_walk_cond_12
rc_walk_cond_12:
  %t141 = load i64, i64* %t140
  %t142 = icmp slt i64 %t141, %t139
  br i1 %t142, label %rc_walk_body_13, label %rc_walk_end_14
rc_walk_body_13:
  %t143 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t137, i64 %t141
  %t144 = load { i8*, i8* }, { i8*, i8* }* %t143
  %t145 = extractvalue { i8*, i8* } %t144, 1
  call void @star_rc_release(i8* %t145)
  %t146 = add i64 %t141, 1
  store i64 %t146, i64* %t140
  br label %rc_walk_cond_12
rc_walk_end_14:
  %t147 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t127, i32 0, i32 3
  %t148 = load { i8*, i8* }, { i8*, i8* }* %t147
  %t149 = extractvalue { i8*, i8* } %t148, 1
  call void @star_rc_release(i8* %t149)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Alice\00" }
@.str.1 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"Bob\00" }
@.str.3 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Carol\00" }
@.str.5 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Dave\00" }
@.str.6 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.7 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"apply_add5(10) = %d\0A\00"
@.str.9 = private unnamed_addr constant [13 x i8] c"tick %d: %s\0A\00"
