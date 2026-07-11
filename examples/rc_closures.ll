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
  %t8 = getelementptr inbounds { i8* }, { i8* }* null, i32 1
  %t9 = ptrtoint { i8* }* %t8 to i64
  %t13 = bitcast void (i8*)* @closure_0_release_env to i8*
  %t14 = call i8* @star_rc_alloc(i64 %t9, i8* %t13)
  %t15 = bitcast i8* %t14 to { i8* }*
  %t16 = load i8*, i8** %t0
  %t17 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t17)
  %t18 = getelementptr inbounds { i8* }, { i8* }* %t15, i32 0, i32 0
  store i8* %t16, i8** %t18
  %t19 = bitcast i8* (i8*)* @closure_0 to i8*
  %t20 = insertvalue { i8*, i8* } undef, i8* %t19, 0
  %t21 = insertvalue { i8*, i8* } %t20, i8* %t14, 1
  %t22 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t22)
  ret { i8*, i8* } %t21
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
  %t1 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = call { i8*, i8* } @make_greeter(i8* %t1)
  store { i8*, i8* } %t2, { i8*, i8* }* %t0
  %t3 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t4 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t5 = extractvalue { i8*, i8* } %t4, 1
  call void @star_rc_retain(i8* %t5)
  %t6 = extractvalue { i8*, i8* } %t3, 0
  %t7 = extractvalue { i8*, i8* } %t3, 1
  call void @star_rc_release(i8* %t7)
  %t8 = bitcast i8* %t6 to i8* (i8*)*
  %t9 = call i8* %t8(i8* %t7)
  %t10 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i8* %t9)
  %t11 = alloca %Handler
  %t12 = alloca %Handler
  %t13 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t14 = call { i8*, i8* } @make_greeter(i8* %t13)
  %t15 = getelementptr inbounds %Handler, %Handler* %t12, i32 0, i32 0
  store { i8*, i8* } %t14, { i8*, i8* }* %t15
  %t16 = load %Handler, %Handler* %t12
  store %Handler %t16, %Handler* %t11
  %t17 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t18 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t19 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t20 = extractvalue { i8*, i8* } %t19, 1
  call void @star_rc_retain(i8* %t20)
  %t21 = extractvalue { i8*, i8* } %t18, 0
  %t22 = extractvalue { i8*, i8* } %t18, 1
  call void @star_rc_release(i8* %t22)
  %t23 = bitcast i8* %t21 to i8* (i8*)*
  %t24 = call i8* %t23(i8* %t22)
  %t25 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i8* %t24)
  %t26 = alloca { { i8*, i8* }*, i64, i64 }
  %t27 = call i8* @malloc(i64 32)
  %t28 = bitcast i8* %t27 to { i8*, i8* }*
  %t29 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t30 = call { i8*, i8* } @make_greeter(i8* %t29)
  %t31 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t28, i64 0
  store { i8*, i8* } %t30, { i8*, i8* }* %t31
  %t32 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t33 = call { i8*, i8* } @make_greeter(i8* %t32)
  %t34 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t28, i64 1
  store { i8*, i8* } %t33, { i8*, i8* }* %t34
  %t35 = alloca { { i8*, i8* }*, i64, i64 }
  %t36 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35, i32 0, i32 0
  store { i8*, i8* }* %t28, { i8*, i8* }** %t36
  %t37 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35, i32 0, i32 1
  store i64 2, i64* %t37
  %t38 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35, i32 0, i32 2
  store i64 2, i64* %t38
  %t39 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35
  store { { i8*, i8* }*, i64, i64 } %t39, { { i8*, i8* }*, i64, i64 }* %t26
  %t40 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 0
  %t41 = load { i8*, i8* }*, { i8*, i8* }** %t40
  %t42 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 2
  %t45 = sext i32 0 to i64
  %t46 = icmp ult i64 %t45, %t43
  br i1 %t46, label %list_idx_ok_2, label %list_idx_oob_3
list_idx_ok_2:
  %t47 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t41, i64 %t45
  %t48 = load { i8*, i8* }, { i8*, i8* }* %t47
  %t49 = load { i8*, i8* }, { i8*, i8* }* %t47
  %t50 = extractvalue { i8*, i8* } %t49, 1
  call void @star_rc_retain(i8* %t50)
  br label %list_idx_end_4
list_idx_oob_3:
  br label %list_idx_end_4
list_idx_end_4:
  %t51 = phi { i8*, i8* } [ %t48, %list_idx_ok_2 ], [ zeroinitializer, %list_idx_oob_3 ]
  %t52 = extractvalue { i8*, i8* } %t51, 0
  %t53 = extractvalue { i8*, i8* } %t51, 1
  call void @star_rc_release(i8* %t53)
  %t54 = bitcast i8* %t52 to i8* (i8*)*
  %t55 = call i8* %t54(i8* %t53)
  %t56 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t56, i8* %t55)
  %t57 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 0
  %t58 = load { i8*, i8* }*, { i8*, i8* }** %t57
  %t59 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 1
  %t60 = load i64, i64* %t59
  %t61 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 2
  %t62 = sext i32 1 to i64
  %t63 = icmp ult i64 %t62, %t60
  br i1 %t63, label %list_idx_ok_5, label %list_idx_oob_6
list_idx_ok_5:
  %t64 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t58, i64 %t62
  %t65 = load { i8*, i8* }, { i8*, i8* }* %t64
  %t66 = load { i8*, i8* }, { i8*, i8* }* %t64
  %t67 = extractvalue { i8*, i8* } %t66, 1
  call void @star_rc_retain(i8* %t67)
  br label %list_idx_end_7
list_idx_oob_6:
  br label %list_idx_end_7
list_idx_end_7:
  %t68 = phi { i8*, i8* } [ %t65, %list_idx_ok_5 ], [ zeroinitializer, %list_idx_oob_6 ]
  %t69 = extractvalue { i8*, i8* } %t68, 0
  %t70 = extractvalue { i8*, i8* } %t68, 1
  call void @star_rc_release(i8* %t70)
  %t71 = bitcast i8* %t69 to i8* (i8*)*
  %t72 = call i8* %t71(i8* %t70)
  %t73 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t73, i8* %t72)
  %t74 = alloca { i8*, i8* }
  %t75 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t75, { i8*, i8* }* %t74
  %t76 = alloca { i8*, i8* }
  %t117 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* null, i32 1
  %t118 = ptrtoint { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t117 to i64
  %t142 = bitcast void (i8*)* @closure_8_release_env to i8*
  %t143 = call i8* @star_rc_alloc(i64 %t118, i8* %t142)
  %t144 = bitcast i8* %t143 to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t145 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t146 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t147 = extractvalue { i8*, i8* } %t146, 1
  call void @star_rc_retain(i8* %t147)
  %t148 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t144, i32 0, i32 0
  store { i8*, i8* } %t145, { i8*, i8* }* %t148
  %t149 = load %Handler, %Handler* %t11
  %t150 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t151 = load { i8*, i8* }, { i8*, i8* }* %t150
  %t152 = extractvalue { i8*, i8* } %t151, 1
  call void @star_rc_retain(i8* %t152)
  %t153 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t144, i32 0, i32 1
  store %Handler %t149, %Handler* %t153
  %t154 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26
  %t155 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 0
  %t156 = load { i8*, i8* }*, { i8*, i8* }** %t155
  %t157 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 1
  %t158 = load i64, i64* %t157
  %t159 = alloca i64
  store i64 0, i64* %t159
  br label %rc_walk_cond_15
rc_walk_cond_15:
  %t160 = load i64, i64* %t159
  %t161 = icmp slt i64 %t160, %t158
  br i1 %t161, label %rc_walk_body_16, label %rc_walk_end_17
rc_walk_body_16:
  %t162 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t156, i64 %t160
  %t163 = load { i8*, i8* }, { i8*, i8* }* %t162
  %t164 = extractvalue { i8*, i8* } %t163, 1
  call void @star_rc_retain(i8* %t164)
  %t165 = add i64 %t160, 1
  store i64 %t165, i64* %t159
  br label %rc_walk_cond_15
rc_walk_end_17:
  %t166 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t144, i32 0, i32 2
  store { { i8*, i8* }*, i64, i64 } %t154, { { i8*, i8* }*, i64, i64 }* %t166
  %t167 = load { i8*, i8* }, { i8*, i8* }* %t74
  %t168 = load { i8*, i8* }, { i8*, i8* }* %t74
  %t169 = extractvalue { i8*, i8* } %t168, 1
  call void @star_rc_retain(i8* %t169)
  %t170 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t144, i32 0, i32 3
  store { i8*, i8* } %t167, { i8*, i8* }* %t170
  %t171 = bitcast i32 (i8*, i32)* @closure_8 to i8*
  %t172 = insertvalue { i8*, i8* } undef, i8* %t171, 0
  %t173 = insertvalue { i8*, i8* } %t172, i8* %t143, 1
  store { i8*, i8* } %t173, { i8*, i8* }* %t76
  %t174 = load { i8*, i8* }, { i8*, i8* }* %t76
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t76
  %t176 = extractvalue { i8*, i8* } %t175, 1
  call void @star_rc_retain(i8* %t176)
  %t177 = extractvalue { i8*, i8* } %t174, 0
  %t178 = extractvalue { i8*, i8* } %t174, 1
  call void @star_rc_release(i8* %t178)
  %t179 = bitcast i8* %t177 to i32 (i8*, i32)*
  %t180 = call i32 %t179(i8* %t178, i32 10)
  %t181 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t181, i32 %t180)
  %t182 = alloca i32
  store i32 0, i32* %t182
  br label %while_cond_18
while_cond_18:
  %t183 = load i32, i32* %t182
  %t184 = icmp slt i32 %t183, 3
  br i1 %t184, label %while_body_19, label %while_end_21
while_body_19:
  %t185 = load i32, i32* %t182
  %t186 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t187 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t188 = extractvalue { i8*, i8* } %t187, 1
  call void @star_rc_retain(i8* %t188)
  %t189 = extractvalue { i8*, i8* } %t186, 0
  %t190 = extractvalue { i8*, i8* } %t186, 1
  call void @star_rc_release(i8* %t190)
  %t191 = bitcast i8* %t189 to i8* (i8*)*
  %t192 = call i8* %t191(i8* %t190)
  %t193 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t193, i32 %t185, i8* %t192)
  %t194 = load i32, i32* %t182
  %t195 = add i32 %t194, 1
  store i32 %t195, i32* %t182
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t196 = load { i8*, i8* }, { i8*, i8* }* %t76
  %t197 = extractvalue { i8*, i8* } %t196, 1
  call void @star_rc_release(i8* %t197)
  %t198 = load { i8*, i8* }, { i8*, i8* }* %t74
  %t199 = extractvalue { i8*, i8* } %t198, 1
  call void @star_rc_release(i8* %t199)
  %t200 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 0
  %t201 = load { i8*, i8* }*, { i8*, i8* }** %t200
  %t202 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t26, i32 0, i32 1
  %t203 = load i64, i64* %t202
  %t204 = alloca i64
  store i64 0, i64* %t204
  br label %rc_walk_cond_22
rc_walk_cond_22:
  %t205 = load i64, i64* %t204
  %t206 = icmp slt i64 %t205, %t203
  br i1 %t206, label %rc_walk_body_23, label %rc_walk_end_24
rc_walk_body_23:
  %t207 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t201, i64 %t205
  %t208 = load { i8*, i8* }, { i8*, i8* }* %t207
  %t209 = extractvalue { i8*, i8* } %t208, 1
  call void @star_rc_release(i8* %t209)
  %t210 = add i64 %t205, 1
  store i64 %t210, i64* %t204
  br label %rc_walk_cond_22
rc_walk_end_24:
  %t211 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t212 = load { i8*, i8* }, { i8*, i8* }* %t211
  %t213 = extractvalue { i8*, i8* } %t212, 1
  call void @star_rc_release(i8* %t213)
  %t214 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t215 = extractvalue { i8*, i8* } %t214, 1
  call void @star_rc_release(i8* %t215)
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
  call void @star_rc_retain(i8* %t6)
  %t7 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t7)
  ret i8* %t5
}


define void @closure_0_release_env(i8* %envp) {
entry:
  %t10 = bitcast i8* %envp to { i8* }*
  %t11 = getelementptr inbounds { i8* }, { i8* }* %t10, i32 0, i32 0
  %t12 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t12)
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
  %t77 = bitcast i8* %envp to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t78 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t77, i32 0, i32 0
  %t79 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t80 = alloca { i8*, i8* }
  store { i8*, i8* } %t79, { i8*, i8* }* %t80
  %t81 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t77, i32 0, i32 1
  %t82 = load %Handler, %Handler* %t81
  %t83 = alloca %Handler
  store %Handler %t82, %Handler* %t83
  %t84 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t77, i32 0, i32 2
  %t85 = load { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t84
  %t86 = alloca { { i8*, i8* }*, i64, i64 }
  store { { i8*, i8* }*, i64, i64 } %t85, { { i8*, i8* }*, i64, i64 }* %t86
  %t87 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t77, i32 0, i32 3
  %t88 = load { i8*, i8* }, { i8*, i8* }* %t87
  %t89 = alloca { i8*, i8* }
  store { i8*, i8* } %t88, { i8*, i8* }* %t89
  %t90 = alloca i32
  store i32 %arg_x, i32* %t90
  %t91 = load { i8*, i8* }, { i8*, i8* }* %t89
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t89
  %t93 = extractvalue { i8*, i8* } %t92, 1
  call void @star_rc_retain(i8* %t93)
  %t94 = extractvalue { i8*, i8* } %t91, 0
  %t95 = extractvalue { i8*, i8* } %t91, 1
  call void @star_rc_release(i8* %t95)
  %t96 = bitcast i8* %t94 to i32 (i8*, i32)*
  %t97 = load i32, i32* %t90
  %t98 = call i32 %t96(i8* %t95, i32 %t97)
  %t99 = load { i8*, i8* }, { i8*, i8* }* %t89
  %t100 = extractvalue { i8*, i8* } %t99, 1
  call void @star_rc_release(i8* %t100)
  %t101 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t86, i32 0, i32 0
  %t102 = load { i8*, i8* }*, { i8*, i8* }** %t101
  %t103 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t86, i32 0, i32 1
  %t104 = load i64, i64* %t103
  %t105 = alloca i64
  store i64 0, i64* %t105
  br label %rc_walk_cond_9
rc_walk_cond_9:
  %t106 = load i64, i64* %t105
  %t107 = icmp slt i64 %t106, %t104
  br i1 %t107, label %rc_walk_body_10, label %rc_walk_end_11
rc_walk_body_10:
  %t108 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t102, i64 %t106
  %t109 = load { i8*, i8* }, { i8*, i8* }* %t108
  %t110 = extractvalue { i8*, i8* } %t109, 1
  call void @star_rc_release(i8* %t110)
  %t111 = add i64 %t106, 1
  store i64 %t111, i64* %t105
  br label %rc_walk_cond_9
rc_walk_end_11:
  %t112 = getelementptr inbounds %Handler, %Handler* %t83, i32 0, i32 0
  %t113 = load { i8*, i8* }, { i8*, i8* }* %t112
  %t114 = extractvalue { i8*, i8* } %t113, 1
  call void @star_rc_release(i8* %t114)
  %t115 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t116 = extractvalue { i8*, i8* } %t115, 1
  call void @star_rc_release(i8* %t116)
  ret i32 %t98
}


define void @closure_8_release_env(i8* %envp) {
entry:
  %t119 = bitcast i8* %envp to { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }*
  %t120 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t119, i32 0, i32 0
  %t121 = load { i8*, i8* }, { i8*, i8* }* %t120
  %t122 = extractvalue { i8*, i8* } %t121, 1
  call void @star_rc_release(i8* %t122)
  %t123 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t119, i32 0, i32 1
  %t124 = getelementptr inbounds %Handler, %Handler* %t123, i32 0, i32 0
  %t125 = load { i8*, i8* }, { i8*, i8* }* %t124
  %t126 = extractvalue { i8*, i8* } %t125, 1
  call void @star_rc_release(i8* %t126)
  %t127 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t119, i32 0, i32 2
  %t128 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t127, i32 0, i32 0
  %t129 = load { i8*, i8* }*, { i8*, i8* }** %t128
  %t130 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t127, i32 0, i32 1
  %t131 = load i64, i64* %t130
  %t132 = alloca i64
  store i64 0, i64* %t132
  br label %rc_walk_cond_12
rc_walk_cond_12:
  %t133 = load i64, i64* %t132
  %t134 = icmp slt i64 %t133, %t131
  br i1 %t134, label %rc_walk_body_13, label %rc_walk_end_14
rc_walk_body_13:
  %t135 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t129, i64 %t133
  %t136 = load { i8*, i8* }, { i8*, i8* }* %t135
  %t137 = extractvalue { i8*, i8* } %t136, 1
  call void @star_rc_release(i8* %t137)
  %t138 = add i64 %t133, 1
  store i64 %t138, i64* %t132
  br label %rc_walk_cond_12
rc_walk_end_14:
  %t139 = getelementptr inbounds { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }, { { i8*, i8* }, %Handler, { { i8*, i8* }*, i64, i64 }, { i8*, i8* } }* %t119, i32 0, i32 3
  %t140 = load { i8*, i8* }, { i8*, i8* }* %t139
  %t141 = extractvalue { i8*, i8* } %t140, 1
  call void @star_rc_release(i8* %t141)
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
