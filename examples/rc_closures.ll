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
  %t26 = alloca i8*
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
  %t48 = bitcast void (i8*)* @list_release_closure to i8*
  %t49 = call i8* @star_rc_alloc(i64 24, i8* %t48)
  %t50 = bitcast i8* %t49 to { { i8*, i8* }*, i64, i64 }*
  %t51 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t50, i32 0, i32 0
  store { i8*, i8* }* %t28, { i8*, i8* }** %t51
  %t52 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t50, i32 0, i32 1
  store i64 2, i64* %t52
  %t53 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t50, i32 0, i32 2
  store i64 2, i64* %t53
  store i8* %t49, i8** %t26
  %t54 = load i8*, i8** %t26
  %t55 = icmp eq i8* %t54, null
  br i1 %t55, label %list_read_null_5, label %list_read_real_6
list_read_null_5:
  br label %list_read_end_7
list_read_real_6:
  %t56 = bitcast i8* %t54 to { { i8*, i8* }*, i64, i64 }*
  %t57 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t56, i32 0, i32 0
  %t58 = load { i8*, i8* }*, { i8*, i8* }** %t57
  %t59 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t56, i32 0, i32 1
  %t60 = load i64, i64* %t59
  br label %list_read_end_7
list_read_end_7:
  %t61 = phi { i8*, i8* }* [ null, %list_read_null_5 ], [ %t58, %list_read_real_6 ]
  %t62 = phi i64 [ 0, %list_read_null_5 ], [ %t60, %list_read_real_6 ]
  %t63 = sext i32 0 to i64
  %t64 = icmp ult i64 %t63, %t62
  br i1 %t64, label %list_idx_ok_8, label %list_idx_oob_9
list_idx_ok_8:
  %t65 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t61, i64 %t63
  %t66 = load { i8*, i8* }, { i8*, i8* }* %t65
  %t67 = load { i8*, i8* }, { i8*, i8* }* %t65
  %t68 = extractvalue { i8*, i8* } %t67, 1
  call void @star_rc_retain(i8* %t68)
  br label %list_idx_end_10
list_idx_oob_9:
  br label %list_idx_end_10
list_idx_end_10:
  %t69 = phi { i8*, i8* } [ %t66, %list_idx_ok_8 ], [ zeroinitializer, %list_idx_oob_9 ]
  %t70 = extractvalue { i8*, i8* } %t69, 0
  %t71 = extractvalue { i8*, i8* } %t69, 1
  call void @star_rc_release(i8* %t71)
  %t72 = bitcast i8* %t70 to i8* (i8*)*
  %t73 = call i8* %t72(i8* %t71)
  %t74 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t74, i8* %t73)
  %t75 = load i8*, i8** %t26
  %t76 = icmp eq i8* %t75, null
  br i1 %t76, label %list_read_null_11, label %list_read_real_12
list_read_null_11:
  br label %list_read_end_13
list_read_real_12:
  %t77 = bitcast i8* %t75 to { { i8*, i8* }*, i64, i64 }*
  %t78 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t77, i32 0, i32 0
  %t79 = load { i8*, i8* }*, { i8*, i8* }** %t78
  %t80 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t77, i32 0, i32 1
  %t81 = load i64, i64* %t80
  br label %list_read_end_13
list_read_end_13:
  %t82 = phi { i8*, i8* }* [ null, %list_read_null_11 ], [ %t79, %list_read_real_12 ]
  %t83 = phi i64 [ 0, %list_read_null_11 ], [ %t81, %list_read_real_12 ]
  %t84 = sext i32 1 to i64
  %t85 = icmp ult i64 %t84, %t83
  br i1 %t85, label %list_idx_ok_14, label %list_idx_oob_15
list_idx_ok_14:
  %t86 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t82, i64 %t84
  %t87 = load { i8*, i8* }, { i8*, i8* }* %t86
  %t88 = load { i8*, i8* }, { i8*, i8* }* %t86
  %t89 = extractvalue { i8*, i8* } %t88, 1
  call void @star_rc_retain(i8* %t89)
  br label %list_idx_end_16
list_idx_oob_15:
  br label %list_idx_end_16
list_idx_end_16:
  %t90 = phi { i8*, i8* } [ %t87, %list_idx_ok_14 ], [ zeroinitializer, %list_idx_oob_15 ]
  %t91 = extractvalue { i8*, i8* } %t90, 0
  %t92 = extractvalue { i8*, i8* } %t90, 1
  call void @star_rc_release(i8* %t92)
  %t93 = bitcast i8* %t91 to i8* (i8*)*
  %t94 = call i8* %t93(i8* %t92)
  %t95 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t95, i8* %t94)
  %t96 = alloca { i8*, i8* }
  %t97 = call { i8*, i8* } @make_adder(i32 5)
  store { i8*, i8* } %t97, { i8*, i8* }* %t96
  %t98 = alloca { i8*, i8* }
  %t129 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* null, i32 1
  %t130 = ptrtoint { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t129 to i64
  %t144 = bitcast void (i8*)* @closure_17_release_env to i8*
  %t145 = call i8* @star_rc_alloc(i64 %t130, i8* %t144)
  %t146 = bitcast i8* %t145 to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t147 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t148 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t149 = extractvalue { i8*, i8* } %t148, 1
  call void @star_rc_retain(i8* %t149)
  %t150 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t146, i32 0, i32 0
  store { i8*, i8* } %t147, { i8*, i8* }* %t150
  %t151 = load %Handler, %Handler* %t11
  %t152 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t153 = load { i8*, i8* }, { i8*, i8* }* %t152
  %t154 = extractvalue { i8*, i8* } %t153, 1
  call void @star_rc_retain(i8* %t154)
  %t155 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t146, i32 0, i32 1
  store %Handler %t151, %Handler* %t155
  %t156 = load i8*, i8** %t26
  %t157 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t157)
  %t158 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t146, i32 0, i32 2
  store i8* %t156, i8** %t158
  %t159 = load { i8*, i8* }, { i8*, i8* }* %t96
  %t160 = load { i8*, i8* }, { i8*, i8* }* %t96
  %t161 = extractvalue { i8*, i8* } %t160, 1
  call void @star_rc_retain(i8* %t161)
  %t162 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t146, i32 0, i32 3
  store { i8*, i8* } %t159, { i8*, i8* }* %t162
  %t163 = bitcast i32 (i8*, i32)* @closure_17 to i8*
  %t164 = insertvalue { i8*, i8* } undef, i8* %t163, 0
  %t165 = insertvalue { i8*, i8* } %t164, i8* %t145, 1
  store { i8*, i8* } %t165, { i8*, i8* }* %t98
  %t166 = load { i8*, i8* }, { i8*, i8* }* %t98
  %t167 = load { i8*, i8* }, { i8*, i8* }* %t98
  %t168 = extractvalue { i8*, i8* } %t167, 1
  call void @star_rc_retain(i8* %t168)
  %t169 = extractvalue { i8*, i8* } %t166, 0
  %t170 = extractvalue { i8*, i8* } %t166, 1
  call void @star_rc_release(i8* %t170)
  %t171 = bitcast i8* %t169 to i32 (i8*, i32)*
  %t172 = call i32 %t171(i8* %t170, i32 10)
  %t173 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t173, i32 %t172)
  %t174 = alloca i32
  store i32 0, i32* %t174
  br label %while_cond_18
while_cond_18:
  %t175 = load i32, i32* %t174
  %t176 = icmp slt i32 %t175, 3
  br i1 %t176, label %while_body_19, label %while_end_21
while_body_19:
  %t177 = load i32, i32* %t174
  %t178 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t179 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t180 = extractvalue { i8*, i8* } %t179, 1
  call void @star_rc_retain(i8* %t180)
  %t181 = extractvalue { i8*, i8* } %t178, 0
  %t182 = extractvalue { i8*, i8* } %t178, 1
  call void @star_rc_release(i8* %t182)
  %t183 = bitcast i8* %t181 to i8* (i8*)*
  %t184 = call i8* %t183(i8* %t182)
  %t185 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t185, i32 %t177, i8* %t184)
  %t186 = load i32, i32* %t174
  %t187 = add i32 %t186, 1
  store i32 %t187, i32* %t174
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t188 = load { i8*, i8* }, { i8*, i8* }* %t98
  %t189 = extractvalue { i8*, i8* } %t188, 1
  call void @star_rc_release(i8* %t189)
  %t190 = load { i8*, i8* }, { i8*, i8* }* %t96
  %t191 = extractvalue { i8*, i8* } %t190, 1
  call void @star_rc_release(i8* %t191)
  %t192 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t192)
  %t193 = getelementptr inbounds %Handler, %Handler* %t11, i32 0, i32 0
  %t194 = load { i8*, i8* }, { i8*, i8* }* %t193
  %t195 = extractvalue { i8*, i8* } %t194, 1
  call void @star_rc_release(i8* %t195)
  %t196 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t197 = extractvalue { i8*, i8* } %t196, 1
  call void @star_rc_release(i8* %t197)
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


define void @list_release_closure(i8* %objp) {
entry:
  %t35 = bitcast i8* %objp to { { i8*, i8* }*, i64, i64 }*
  %t36 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35, i32 0, i32 0
  %t37 = load { i8*, i8* }*, { i8*, i8* }** %t36
  %t38 = getelementptr inbounds { { i8*, i8* }*, i64, i64 }, { { i8*, i8* }*, i64, i64 }* %t35, i32 0, i32 1
  %t39 = load i64, i64* %t38
  %t40 = alloca i64
  store i64 0, i64* %t40
  br label %list_release_cond_2
list_release_cond_2:
  %t41 = load i64, i64* %t40
  %t42 = icmp slt i64 %t41, %t39
  br i1 %t42, label %list_release_body_3, label %list_release_end_4
list_release_body_3:
  %t43 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t37, i64 %t41
  %t44 = load { i8*, i8* }, { i8*, i8* }* %t43
  %t45 = extractvalue { i8*, i8* } %t44, 1
  call void @star_rc_release(i8* %t45)
  %t46 = add i64 %t41, 1
  store i64 %t46, i64* %t40
  br label %list_release_cond_2
list_release_end_4:
  %t47 = bitcast { i8*, i8* }* %t37 to i8*
  call void @free(i8* %t47)
  ret void
}


define i32 @closure_17(i8* %envp, i32 %arg_x) {
entry:
  %t99 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t100 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t99, i32 0, i32 0
  %t101 = load { i8*, i8* }, { i8*, i8* }* %t100
  %t102 = alloca { i8*, i8* }
  store { i8*, i8* } %t101, { i8*, i8* }* %t102
  %t103 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t99, i32 0, i32 1
  %t104 = load %Handler, %Handler* %t103
  %t105 = alloca %Handler
  store %Handler %t104, %Handler* %t105
  %t106 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t99, i32 0, i32 2
  %t107 = load i8*, i8** %t106
  %t108 = alloca i8*
  store i8* %t107, i8** %t108
  %t109 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t99, i32 0, i32 3
  %t110 = load { i8*, i8* }, { i8*, i8* }* %t109
  %t111 = alloca { i8*, i8* }
  store { i8*, i8* } %t110, { i8*, i8* }* %t111
  %t112 = alloca i32
  store i32 %arg_x, i32* %t112
  %t113 = load { i8*, i8* }, { i8*, i8* }* %t111
  %t114 = load { i8*, i8* }, { i8*, i8* }* %t111
  %t115 = extractvalue { i8*, i8* } %t114, 1
  call void @star_rc_retain(i8* %t115)
  %t116 = extractvalue { i8*, i8* } %t113, 0
  %t117 = extractvalue { i8*, i8* } %t113, 1
  call void @star_rc_release(i8* %t117)
  %t118 = bitcast i8* %t116 to i32 (i8*, i32)*
  %t119 = load i32, i32* %t112
  %t120 = call i32 %t118(i8* %t117, i32 %t119)
  %t121 = load { i8*, i8* }, { i8*, i8* }* %t111
  %t122 = extractvalue { i8*, i8* } %t121, 1
  call void @star_rc_release(i8* %t122)
  %t123 = load i8*, i8** %t108
  call void @star_rc_release(i8* %t123)
  %t124 = getelementptr inbounds %Handler, %Handler* %t105, i32 0, i32 0
  %t125 = load { i8*, i8* }, { i8*, i8* }* %t124
  %t126 = extractvalue { i8*, i8* } %t125, 1
  call void @star_rc_release(i8* %t126)
  %t127 = load { i8*, i8* }, { i8*, i8* }* %t102
  %t128 = extractvalue { i8*, i8* } %t127, 1
  call void @star_rc_release(i8* %t128)
  ret i32 %t120
}


define void @closure_17_release_env(i8* %envp) {
entry:
  %t131 = bitcast i8* %envp to { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }*
  %t132 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t131, i32 0, i32 0
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t132
  %t134 = extractvalue { i8*, i8* } %t133, 1
  call void @star_rc_release(i8* %t134)
  %t135 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t131, i32 0, i32 1
  %t136 = getelementptr inbounds %Handler, %Handler* %t135, i32 0, i32 0
  %t137 = load { i8*, i8* }, { i8*, i8* }* %t136
  %t138 = extractvalue { i8*, i8* } %t137, 1
  call void @star_rc_release(i8* %t138)
  %t139 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t131, i32 0, i32 2
  %t140 = load i8*, i8** %t139
  call void @star_rc_release(i8* %t140)
  %t141 = getelementptr inbounds { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }, { { i8*, i8* }, %Handler, i8*, { i8*, i8* } }* %t131, i32 0, i32 3
  %t142 = load { i8*, i8* }, { i8*, i8* }* %t141
  %t143 = extractvalue { i8*, i8* } %t142, 1
  call void @star_rc_release(i8* %t143)
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
