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

%Point = type { i32, i32 }
%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t57 = alloca i64
  %t81 = alloca i64
  %t90 = alloca i8*
  %t161 = alloca i64
  %t183 = alloca i64
  %t192 = alloca i8*
  %t250 = alloca i64
  %t259 = alloca i8*
  %t263 = alloca %Option__i32
  %t269 = alloca %Option__i32
  %t273 = alloca %Option__i32
  %t306 = alloca i64
  %t315 = alloca i8*
  %t319 = alloca %Option__i32
  %t325 = alloca %Option__i32
  %t329 = alloca %Option__i32
  %t389 = alloca i64
  %t411 = alloca i64
  %t420 = alloca i8*
  %t478 = alloca i64
  %t487 = alloca i8*
  %t491 = alloca %Option__i32
  %t497 = alloca %Option__i32
  %t501 = alloca %Option__i32
  %t521 = alloca i8*
  %t537 = alloca i64
  %t546 = alloca i8*
  %t593 = alloca i64
  %t612 = alloca i64
  %t621 = alloca i8*
  %t632 = alloca %Option__i32
  %t638 = alloca %Option__i32
  %t642 = alloca %Option__i32
  %t676 = alloca i64
  %t685 = alloca i8*
  %t705 = alloca i8*
  %t753 = alloca i64
  %t754 = alloca i1
  %t827 = alloca i64
  %t828 = alloca i1
  %t901 = alloca i64
  %t902 = alloca i1
  %t953 = alloca i64
  %t954 = alloca i1
  %t1009 = alloca i64
  %t1010 = alloca i1
  %t1036 = alloca i64
  %t1037 = alloca i1
  %t1092 = alloca i64
  %t1093 = alloca i1
  %t1121 = alloca i8*
  %t1166 = alloca %Point
  %t1179 = alloca i64
  %t1180 = alloca i1
  %t1247 = alloca %Point
  %t1253 = alloca i64
  %t1254 = alloca i1
  %t1321 = alloca %Point
  %t1327 = alloca i64
  %t1328 = alloca i1
  %t1366 = alloca %Point
  %t1379 = alloca i64
  %t1380 = alloca i1
  %t1393 = alloca %Point
  %t1406 = alloca i64
  %t1407 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i8* null, i8** %t1
  %t2 = getelementptr i8*, i8** null, i32 1
  %t3 = ptrtoint i8** %t2 to i64
  %t4 = getelementptr i32, i32* null, i32 1
  %t5 = ptrtoint i32* %t4 to i64
  %t6 = load i8*, i8** %t1
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t23 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t24 = call i8* @star_rc_alloc(i64 32, i8* %t23)
  %t25 = bitcast i8* %t24 to { i8**, i32*, i64, i64 }*
  %t26 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t25, i32 0, i32 0
  store i8** null, i8*** %t26
  %t27 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t25, i32 0, i32 1
  store i32* null, i32** %t27
  %t28 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t25, i32 0, i32 2
  store i64 0, i64* %t28
  %t29 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t25, i32 0, i32 3
  store i64 0, i64* %t29
  store i8* %t24, i8** %t1
  br label %map_cow_done_2
map_cow_check_1:
  %t30 = getelementptr inbounds i8, i8* %t6, i64 -16
  %t31 = bitcast i8* %t30 to i64*
  %t32 = load atomic i64, i64* %t31 seq_cst, align 8
  %t33 = icmp eq i64 %t32, 1
  br i1 %t33, label %map_cow_done_2, label %map_cow_clone_6
map_cow_clone_6:
  %t34 = bitcast i8* %t6 to { i8**, i32*, i64, i64 }*
  %t35 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t34, i32 0, i32 0
  %t36 = load i8**, i8*** %t35
  %t37 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t34, i32 0, i32 1
  %t38 = load i32*, i32** %t37
  %t39 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t34, i32 0, i32 2
  %t40 = load i64, i64* %t39
  %t41 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t34, i32 0, i32 3
  %t42 = load i64, i64* %t41
  %t43 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t44 = call i8* @star_rc_alloc(i64 32, i8* %t43)
  %t45 = bitcast i8* %t44 to { i8**, i32*, i64, i64 }*
  %t46 = mul i64 %t42, %t3
  %t47 = call i8* @malloc(i64 %t46)
  %t48 = bitcast i8* %t47 to i8**
  %t49 = mul i64 %t42, %t5
  %t50 = call i8* @malloc(i64 %t49)
  %t51 = bitcast i8* %t50 to i32*
  %t52 = icmp sgt i64 %t40, 0
  br i1 %t52, label %map_cow_copy_7, label %map_cow_after_copy_8
map_cow_copy_7:
  %t53 = mul i64 %t40, %t3
  %t54 = bitcast i8** %t36 to i8*
  call i8* @memcpy(i8* %t47, i8* %t54, i64 %t53)
  %t55 = mul i64 %t40, %t5
  %t56 = bitcast i32* %t38 to i8*
  call i8* @memcpy(i8* %t50, i8* %t56, i64 %t55)
  store i64 0, i64* %t57
  br label %map_cow_retain_cond_9
map_cow_retain_cond_9:
  %t58 = load i64, i64* %t57
  %t59 = icmp slt i64 %t58, %t40
  br i1 %t59, label %map_cow_retain_body_10, label %map_cow_retain_end_11
map_cow_retain_body_10:
  %t60 = getelementptr inbounds i8*, i8** %t48, i64 %t58
  %t61 = load i8*, i8** %t60
  call void @star_rc_retain(i8* %t61)
  %t62 = add i64 %t58, 1
  store i64 %t62, i64* %t57
  br label %map_cow_retain_cond_9
map_cow_retain_end_11:
  br label %map_cow_after_copy_8
map_cow_after_copy_8:
  %t63 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t45, i32 0, i32 0
  store i8** %t48, i8*** %t63
  %t64 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t45, i32 0, i32 1
  store i32* %t51, i32** %t64
  %t65 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t45, i32 0, i32 2
  store i64 %t40, i64* %t65
  %t66 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t45, i32 0, i32 3
  store i64 %t42, i64* %t66
  call void @star_rc_release(i8* %t6)
  store i8* %t44, i8** %t1
  br label %map_cow_done_2
map_cow_done_2:
  %t67 = load i8*, i8** %t1
  %t68 = bitcast i8* %t67 to { i8**, i32*, i64, i64 }*
  %t69 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t68, i32 0, i32 0
  %t70 = load i8**, i8*** %t69
  %t71 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t68, i32 0, i32 1
  %t72 = load i32*, i32** %t71
  %t73 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t68, i32 0, i32 2
  %t74 = load i64, i64* %t73
  %t75 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t68, i32 0, i32 3
  %t76 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t77 = load i64, i64* %t73
  %t78 = load i8**, i8*** %t69
  store i64 0, i64* %t81
  br label %map_find_cond_12
map_find_cond_12:
  %t82 = load i64, i64* %t81
  %t83 = icmp slt i64 %t82, %t77
  br i1 %t83, label %map_find_body_13, label %map_find_end_16
map_find_body_13:
  %t84 = getelementptr inbounds i8*, i8** %t78, i64 %t82
  %t85 = load i8*, i8** %t84
  br label %map_find_eq_check_14
map_find_eq_check_14:
  %t86 = call i1 @eq_str(i8* %t85, i8* %t76)
  br i1 %t86, label %map_find_end_16, label %map_find_next_15
map_find_next_15:
  %t87 = add i64 %t82, 1
  store i64 %t87, i64* %t81
  br label %map_find_cond_12
map_find_end_16:
  %t88 = load i64, i64* %t81
  %t89 = icmp slt i64 %t88, %t77
  br i1 %t89, label %map_insert_overwrite_17, label %map_insert_new_18
map_insert_overwrite_17:
  store i8* %t76, i8** %t90
  %t91 = load i8*, i8** %t90
  call void @star_rc_release(i8* %t91)
  %t92 = load i32*, i32** %t71
  %t93 = getelementptr inbounds i32, i32* %t92, i64 %t88
  store i32 30, i32* %t93
  br label %map_insert_after_19
map_insert_new_18:
  %t94 = load i64, i64* %t75
  %t95 = icmp sge i64 %t77, %t94
  br i1 %t95, label %map_insert_grow_20, label %map_insert_store_21
map_insert_grow_20:
  %t96 = mul i64 %t94, 2
  %t97 = icmp sgt i64 %t96, 0
  %t98 = select i1 %t97, i64 %t96, i64 1
  %t99 = getelementptr i8*, i8** null, i32 1
  %t100 = ptrtoint i8** %t99 to i64
  %t101 = mul i64 %t98, %t100
  %t102 = call i8* @malloc(i64 %t101)
  %t103 = bitcast i8* %t102 to i8**
  %t104 = getelementptr i32, i32* null, i32 1
  %t105 = ptrtoint i32* %t104 to i64
  %t106 = mul i64 %t98, %t105
  %t107 = call i8* @malloc(i64 %t106)
  %t108 = bitcast i8* %t107 to i32*
  %t109 = icmp sgt i64 %t94, 0
  br i1 %t109, label %map_insert_copy_22, label %map_insert_after_copy_23
map_insert_copy_22:
  %t110 = load i8**, i8*** %t69
  %t111 = mul i64 %t77, %t100
  %t112 = bitcast i8** %t110 to i8*
  call i8* @memcpy(i8* %t102, i8* %t112, i64 %t111)
  call void @free(i8* %t112)
  %t113 = load i32*, i32** %t71
  %t114 = mul i64 %t77, %t105
  %t115 = bitcast i32* %t113 to i8*
  call i8* @memcpy(i8* %t107, i8* %t115, i64 %t114)
  call void @free(i8* %t115)
  br label %map_insert_after_copy_23
map_insert_after_copy_23:
  store i8** %t103, i8*** %t69
  store i32* %t108, i32** %t71
  store i64 %t98, i64* %t75
  br label %map_insert_store_21
map_insert_store_21:
  %t116 = load i8**, i8*** %t69
  %t117 = load i32*, i32** %t71
  %t118 = getelementptr inbounds i8*, i8** %t116, i64 %t77
  store i8* %t76, i8** %t118
  %t119 = getelementptr inbounds i32, i32* %t117, i64 %t77
  store i32 30, i32* %t119
  %t120 = add i64 %t77, 1
  store i64 %t120, i64* %t73
  br label %map_insert_after_19
map_insert_after_19:
  %t121 = getelementptr i8*, i8** null, i32 1
  %t122 = ptrtoint i8** %t121 to i64
  %t123 = getelementptr i32, i32* null, i32 1
  %t124 = ptrtoint i32* %t123 to i64
  %t125 = load i8*, i8** %t1
  %t126 = icmp eq i8* %t125, null
  br i1 %t126, label %map_cow_alloc_24, label %map_cow_check_25
map_cow_alloc_24:
  %t127 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t128 = call i8* @star_rc_alloc(i64 32, i8* %t127)
  %t129 = bitcast i8* %t128 to { i8**, i32*, i64, i64 }*
  %t130 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t129, i32 0, i32 0
  store i8** null, i8*** %t130
  %t131 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t129, i32 0, i32 1
  store i32* null, i32** %t131
  %t132 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t129, i32 0, i32 2
  store i64 0, i64* %t132
  %t133 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t129, i32 0, i32 3
  store i64 0, i64* %t133
  store i8* %t128, i8** %t1
  br label %map_cow_done_26
map_cow_check_25:
  %t134 = getelementptr inbounds i8, i8* %t125, i64 -16
  %t135 = bitcast i8* %t134 to i64*
  %t136 = load atomic i64, i64* %t135 seq_cst, align 8
  %t137 = icmp eq i64 %t136, 1
  br i1 %t137, label %map_cow_done_26, label %map_cow_clone_27
map_cow_clone_27:
  %t138 = bitcast i8* %t125 to { i8**, i32*, i64, i64 }*
  %t139 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t138, i32 0, i32 0
  %t140 = load i8**, i8*** %t139
  %t141 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t138, i32 0, i32 1
  %t142 = load i32*, i32** %t141
  %t143 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t138, i32 0, i32 2
  %t144 = load i64, i64* %t143
  %t145 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t138, i32 0, i32 3
  %t146 = load i64, i64* %t145
  %t147 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t148 = call i8* @star_rc_alloc(i64 32, i8* %t147)
  %t149 = bitcast i8* %t148 to { i8**, i32*, i64, i64 }*
  %t150 = mul i64 %t146, %t122
  %t151 = call i8* @malloc(i64 %t150)
  %t152 = bitcast i8* %t151 to i8**
  %t153 = mul i64 %t146, %t124
  %t154 = call i8* @malloc(i64 %t153)
  %t155 = bitcast i8* %t154 to i32*
  %t156 = icmp sgt i64 %t144, 0
  br i1 %t156, label %map_cow_copy_28, label %map_cow_after_copy_29
map_cow_copy_28:
  %t157 = mul i64 %t144, %t122
  %t158 = bitcast i8** %t140 to i8*
  call i8* @memcpy(i8* %t151, i8* %t158, i64 %t157)
  %t159 = mul i64 %t144, %t124
  %t160 = bitcast i32* %t142 to i8*
  call i8* @memcpy(i8* %t154, i8* %t160, i64 %t159)
  store i64 0, i64* %t161
  br label %map_cow_retain_cond_30
map_cow_retain_cond_30:
  %t162 = load i64, i64* %t161
  %t163 = icmp slt i64 %t162, %t144
  br i1 %t163, label %map_cow_retain_body_31, label %map_cow_retain_end_32
map_cow_retain_body_31:
  %t164 = getelementptr inbounds i8*, i8** %t152, i64 %t162
  %t165 = load i8*, i8** %t164
  call void @star_rc_retain(i8* %t165)
  %t166 = add i64 %t162, 1
  store i64 %t166, i64* %t161
  br label %map_cow_retain_cond_30
map_cow_retain_end_32:
  br label %map_cow_after_copy_29
map_cow_after_copy_29:
  %t167 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t149, i32 0, i32 0
  store i8** %t152, i8*** %t167
  %t168 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t149, i32 0, i32 1
  store i32* %t155, i32** %t168
  %t169 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t149, i32 0, i32 2
  store i64 %t144, i64* %t169
  %t170 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t149, i32 0, i32 3
  store i64 %t146, i64* %t170
  call void @star_rc_release(i8* %t125)
  store i8* %t148, i8** %t1
  br label %map_cow_done_26
map_cow_done_26:
  %t171 = load i8*, i8** %t1
  %t172 = bitcast i8* %t171 to { i8**, i32*, i64, i64 }*
  %t173 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t172, i32 0, i32 0
  %t174 = load i8**, i8*** %t173
  %t175 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t172, i32 0, i32 1
  %t176 = load i32*, i32** %t175
  %t177 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t172, i32 0, i32 2
  %t178 = load i64, i64* %t177
  %t179 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t172, i32 0, i32 3
  %t180 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t181 = load i64, i64* %t177
  %t182 = load i8**, i8*** %t173
  store i64 0, i64* %t183
  br label %map_find_cond_33
map_find_cond_33:
  %t184 = load i64, i64* %t183
  %t185 = icmp slt i64 %t184, %t181
  br i1 %t185, label %map_find_body_34, label %map_find_end_37
map_find_body_34:
  %t186 = getelementptr inbounds i8*, i8** %t182, i64 %t184
  %t187 = load i8*, i8** %t186
  br label %map_find_eq_check_35
map_find_eq_check_35:
  %t188 = call i1 @eq_str(i8* %t187, i8* %t180)
  br i1 %t188, label %map_find_end_37, label %map_find_next_36
map_find_next_36:
  %t189 = add i64 %t184, 1
  store i64 %t189, i64* %t183
  br label %map_find_cond_33
map_find_end_37:
  %t190 = load i64, i64* %t183
  %t191 = icmp slt i64 %t190, %t181
  br i1 %t191, label %map_insert_overwrite_38, label %map_insert_new_39
map_insert_overwrite_38:
  store i8* %t180, i8** %t192
  %t193 = load i8*, i8** %t192
  call void @star_rc_release(i8* %t193)
  %t194 = load i32*, i32** %t175
  %t195 = getelementptr inbounds i32, i32* %t194, i64 %t190
  store i32 25, i32* %t195
  br label %map_insert_after_40
map_insert_new_39:
  %t196 = load i64, i64* %t179
  %t197 = icmp sge i64 %t181, %t196
  br i1 %t197, label %map_insert_grow_41, label %map_insert_store_42
map_insert_grow_41:
  %t198 = mul i64 %t196, 2
  %t199 = icmp sgt i64 %t198, 0
  %t200 = select i1 %t199, i64 %t198, i64 1
  %t201 = getelementptr i8*, i8** null, i32 1
  %t202 = ptrtoint i8** %t201 to i64
  %t203 = mul i64 %t200, %t202
  %t204 = call i8* @malloc(i64 %t203)
  %t205 = bitcast i8* %t204 to i8**
  %t206 = getelementptr i32, i32* null, i32 1
  %t207 = ptrtoint i32* %t206 to i64
  %t208 = mul i64 %t200, %t207
  %t209 = call i8* @malloc(i64 %t208)
  %t210 = bitcast i8* %t209 to i32*
  %t211 = icmp sgt i64 %t196, 0
  br i1 %t211, label %map_insert_copy_43, label %map_insert_after_copy_44
map_insert_copy_43:
  %t212 = load i8**, i8*** %t173
  %t213 = mul i64 %t181, %t202
  %t214 = bitcast i8** %t212 to i8*
  call i8* @memcpy(i8* %t204, i8* %t214, i64 %t213)
  call void @free(i8* %t214)
  %t215 = load i32*, i32** %t175
  %t216 = mul i64 %t181, %t207
  %t217 = bitcast i32* %t215 to i8*
  call i8* @memcpy(i8* %t209, i8* %t217, i64 %t216)
  call void @free(i8* %t217)
  br label %map_insert_after_copy_44
map_insert_after_copy_44:
  store i8** %t205, i8*** %t173
  store i32* %t210, i32** %t175
  store i64 %t200, i64* %t179
  br label %map_insert_store_42
map_insert_store_42:
  %t218 = load i8**, i8*** %t173
  %t219 = load i32*, i32** %t175
  %t220 = getelementptr inbounds i8*, i8** %t218, i64 %t181
  store i8* %t180, i8** %t220
  %t221 = getelementptr inbounds i32, i32* %t219, i64 %t181
  store i32 25, i32* %t221
  %t222 = add i64 %t181, 1
  store i64 %t222, i64* %t177
  br label %map_insert_after_40
map_insert_after_40:
  %t223 = load i8*, i8** %t1
  %t224 = icmp eq i8* %t223, null
  br i1 %t224, label %map_read_null_45, label %map_read_real_46
map_read_null_45:
  br label %map_read_end_47
map_read_real_46:
  %t225 = bitcast i8* %t223 to { i8**, i32*, i64, i64 }*
  %t226 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t225, i32 0, i32 0
  %t227 = load i8**, i8*** %t226
  %t228 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t225, i32 0, i32 1
  %t229 = load i32*, i32** %t228
  %t230 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t225, i32 0, i32 2
  %t231 = load i64, i64* %t230
  br label %map_read_end_47
map_read_end_47:
  %t232 = phi i8** [ null, %map_read_null_45 ], [ %t227, %map_read_real_46 ]
  %t233 = phi i32* [ null, %map_read_null_45 ], [ %t229, %map_read_real_46 ]
  %t234 = phi i64 [ 0, %map_read_null_45 ], [ %t231, %map_read_real_46 ]
  %t235 = trunc i64 %t234 to i32
  %t236 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t236, i32 %t235)
  %t237 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t238 = load i8*, i8** %t1
  %t239 = icmp eq i8* %t238, null
  br i1 %t239, label %map_read_null_48, label %map_read_real_49
map_read_null_48:
  br label %map_read_end_50
map_read_real_49:
  %t240 = bitcast i8* %t238 to { i8**, i32*, i64, i64 }*
  %t241 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t240, i32 0, i32 0
  %t242 = load i8**, i8*** %t241
  %t243 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t240, i32 0, i32 1
  %t244 = load i32*, i32** %t243
  %t245 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t240, i32 0, i32 2
  %t246 = load i64, i64* %t245
  br label %map_read_end_50
map_read_end_50:
  %t247 = phi i8** [ null, %map_read_null_48 ], [ %t242, %map_read_real_49 ]
  %t248 = phi i32* [ null, %map_read_null_48 ], [ %t244, %map_read_real_49 ]
  %t249 = phi i64 [ 0, %map_read_null_48 ], [ %t246, %map_read_real_49 ]
  store i64 0, i64* %t250
  br label %map_find_cond_51
map_find_cond_51:
  %t251 = load i64, i64* %t250
  %t252 = icmp slt i64 %t251, %t249
  br i1 %t252, label %map_find_body_52, label %map_find_end_55
map_find_body_52:
  %t253 = getelementptr inbounds i8*, i8** %t247, i64 %t251
  %t254 = load i8*, i8** %t253
  br label %map_find_eq_check_53
map_find_eq_check_53:
  %t255 = call i1 @eq_str(i8* %t254, i8* %t237)
  br i1 %t255, label %map_find_end_55, label %map_find_next_54
map_find_next_54:
  %t256 = add i64 %t251, 1
  store i64 %t256, i64* %t250
  br label %map_find_cond_51
map_find_end_55:
  %t257 = load i64, i64* %t250
  %t258 = icmp slt i64 %t257, %t249
  store i8* %t237, i8** %t259
  %t260 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t260)
  br i1 %t258, label %map_get_some_56, label %map_get_none_57
map_get_some_56:
  %t261 = getelementptr inbounds i32, i32* %t248, i64 %t257
  %t262 = load i32, i32* %t261
  %t264 = getelementptr inbounds %Option__i32, %Option__i32* %t263, i32 0, i32 0
  store i32 1, i32* %t264
  %t265 = getelementptr inbounds %Option__i32, %Option__i32* %t263, i32 0, i32 1
  %t266 = bitcast [1 x i64]* %t265 to { i32 }*
  %t267 = getelementptr inbounds { i32 }, { i32 }* %t266, i32 0, i32 0
  store i32 %t262, i32* %t267
  %t268 = load %Option__i32, %Option__i32* %t263
  br label %map_get_end_58
map_get_none_57:
  %t270 = getelementptr inbounds %Option__i32, %Option__i32* %t269, i32 0, i32 0
  store i32 0, i32* %t270
  %t271 = load %Option__i32, %Option__i32* %t269
  br label %map_get_end_58
map_get_end_58:
  %t272 = phi %Option__i32 [ %t268, %map_get_some_56 ], [ %t271, %map_get_none_57 ]
  store %Option__i32 %t272, %Option__i32* %t273
  br label %match_scrutinee_275
match_scrutinee_275:
  %t279 = getelementptr inbounds %Option__i32, %Option__i32* %t273, i32 0, i32 0
  %t280 = load i32, i32* %t279
  %t278 = icmp eq i32 %t280, 1
  br i1 %t278, label %match_then_0_276, label %match_next_0_277
match_then_0_276:
  %t281 = getelementptr inbounds %Option__i32, %Option__i32* %t273, i32 0, i32 1
  %t282 = bitcast [1 x i64]* %t281 to { i32 }*
  %t283 = getelementptr inbounds { i32 }, { i32 }* %t282, i32 0, i32 0
  %t284 = load i32, i32* %t283
  %t285 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t285, i32 %t284)
  br label %match_end_274
match_next_0_277:
  %t289 = getelementptr inbounds %Option__i32, %Option__i32* %t273, i32 0, i32 0
  %t290 = load i32, i32* %t289
  %t288 = icmp eq i32 %t290, 0
  br i1 %t288, label %match_then_1_286, label %match_next_1_287
match_then_1_286:
  %t291 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t291)
  call i32 (i8*, ...) @printf(i8* %t291)
  %t292 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t292)
  br label %match_end_274
match_next_1_287:
  br label %match_end_274
match_end_274:
  %t293 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t294 = load i8*, i8** %t1
  %t295 = icmp eq i8* %t294, null
  br i1 %t295, label %map_read_null_59, label %map_read_real_60
map_read_null_59:
  br label %map_read_end_61
map_read_real_60:
  %t296 = bitcast i8* %t294 to { i8**, i32*, i64, i64 }*
  %t297 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t296, i32 0, i32 0
  %t298 = load i8**, i8*** %t297
  %t299 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t296, i32 0, i32 1
  %t300 = load i32*, i32** %t299
  %t301 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t296, i32 0, i32 2
  %t302 = load i64, i64* %t301
  br label %map_read_end_61
map_read_end_61:
  %t303 = phi i8** [ null, %map_read_null_59 ], [ %t298, %map_read_real_60 ]
  %t304 = phi i32* [ null, %map_read_null_59 ], [ %t300, %map_read_real_60 ]
  %t305 = phi i64 [ 0, %map_read_null_59 ], [ %t302, %map_read_real_60 ]
  store i64 0, i64* %t306
  br label %map_find_cond_62
map_find_cond_62:
  %t307 = load i64, i64* %t306
  %t308 = icmp slt i64 %t307, %t305
  br i1 %t308, label %map_find_body_63, label %map_find_end_66
map_find_body_63:
  %t309 = getelementptr inbounds i8*, i8** %t303, i64 %t307
  %t310 = load i8*, i8** %t309
  br label %map_find_eq_check_64
map_find_eq_check_64:
  %t311 = call i1 @eq_str(i8* %t310, i8* %t293)
  br i1 %t311, label %map_find_end_66, label %map_find_next_65
map_find_next_65:
  %t312 = add i64 %t307, 1
  store i64 %t312, i64* %t306
  br label %map_find_cond_62
map_find_end_66:
  %t313 = load i64, i64* %t306
  %t314 = icmp slt i64 %t313, %t305
  store i8* %t293, i8** %t315
  %t316 = load i8*, i8** %t315
  call void @star_rc_release(i8* %t316)
  br i1 %t314, label %map_get_some_67, label %map_get_none_68
map_get_some_67:
  %t317 = getelementptr inbounds i32, i32* %t304, i64 %t313
  %t318 = load i32, i32* %t317
  %t320 = getelementptr inbounds %Option__i32, %Option__i32* %t319, i32 0, i32 0
  store i32 1, i32* %t320
  %t321 = getelementptr inbounds %Option__i32, %Option__i32* %t319, i32 0, i32 1
  %t322 = bitcast [1 x i64]* %t321 to { i32 }*
  %t323 = getelementptr inbounds { i32 }, { i32 }* %t322, i32 0, i32 0
  store i32 %t318, i32* %t323
  %t324 = load %Option__i32, %Option__i32* %t319
  br label %map_get_end_69
map_get_none_68:
  %t326 = getelementptr inbounds %Option__i32, %Option__i32* %t325, i32 0, i32 0
  store i32 0, i32* %t326
  %t327 = load %Option__i32, %Option__i32* %t325
  br label %map_get_end_69
map_get_end_69:
  %t328 = phi %Option__i32 [ %t324, %map_get_some_67 ], [ %t327, %map_get_none_68 ]
  store %Option__i32 %t328, %Option__i32* %t329
  br label %match_scrutinee_331
match_scrutinee_331:
  %t335 = getelementptr inbounds %Option__i32, %Option__i32* %t329, i32 0, i32 0
  %t336 = load i32, i32* %t335
  %t334 = icmp eq i32 %t336, 1
  br i1 %t334, label %match_then_0_332, label %match_next_0_333
match_then_0_332:
  %t337 = getelementptr inbounds %Option__i32, %Option__i32* %t329, i32 0, i32 1
  %t338 = bitcast [1 x i64]* %t337 to { i32 }*
  %t339 = getelementptr inbounds { i32 }, { i32 }* %t338, i32 0, i32 0
  %t340 = load i32, i32* %t339
  %t341 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t341, i32 %t340)
  br label %match_end_330
match_next_0_333:
  %t345 = getelementptr inbounds %Option__i32, %Option__i32* %t329, i32 0, i32 0
  %t346 = load i32, i32* %t345
  %t344 = icmp eq i32 %t346, 0
  br i1 %t344, label %match_then_1_342, label %match_next_1_343
match_then_1_342:
  %t347 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t347)
  call i32 (i8*, ...) @printf(i8* %t347)
  %t348 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t348)
  br label %match_end_330
match_next_1_343:
  br label %match_end_330
match_end_330:
  %t349 = getelementptr i8*, i8** null, i32 1
  %t350 = ptrtoint i8** %t349 to i64
  %t351 = getelementptr i32, i32* null, i32 1
  %t352 = ptrtoint i32* %t351 to i64
  %t353 = load i8*, i8** %t1
  %t354 = icmp eq i8* %t353, null
  br i1 %t354, label %map_cow_alloc_70, label %map_cow_check_71
map_cow_alloc_70:
  %t355 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t356 = call i8* @star_rc_alloc(i64 32, i8* %t355)
  %t357 = bitcast i8* %t356 to { i8**, i32*, i64, i64 }*
  %t358 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 0
  store i8** null, i8*** %t358
  %t359 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 1
  store i32* null, i32** %t359
  %t360 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 2
  store i64 0, i64* %t360
  %t361 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 3
  store i64 0, i64* %t361
  store i8* %t356, i8** %t1
  br label %map_cow_done_72
map_cow_check_71:
  %t362 = getelementptr inbounds i8, i8* %t353, i64 -16
  %t363 = bitcast i8* %t362 to i64*
  %t364 = load atomic i64, i64* %t363 seq_cst, align 8
  %t365 = icmp eq i64 %t364, 1
  br i1 %t365, label %map_cow_done_72, label %map_cow_clone_73
map_cow_clone_73:
  %t366 = bitcast i8* %t353 to { i8**, i32*, i64, i64 }*
  %t367 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 0
  %t368 = load i8**, i8*** %t367
  %t369 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 1
  %t370 = load i32*, i32** %t369
  %t371 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 2
  %t372 = load i64, i64* %t371
  %t373 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 3
  %t374 = load i64, i64* %t373
  %t375 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t376 = call i8* @star_rc_alloc(i64 32, i8* %t375)
  %t377 = bitcast i8* %t376 to { i8**, i32*, i64, i64 }*
  %t378 = mul i64 %t374, %t350
  %t379 = call i8* @malloc(i64 %t378)
  %t380 = bitcast i8* %t379 to i8**
  %t381 = mul i64 %t374, %t352
  %t382 = call i8* @malloc(i64 %t381)
  %t383 = bitcast i8* %t382 to i32*
  %t384 = icmp sgt i64 %t372, 0
  br i1 %t384, label %map_cow_copy_74, label %map_cow_after_copy_75
map_cow_copy_74:
  %t385 = mul i64 %t372, %t350
  %t386 = bitcast i8** %t368 to i8*
  call i8* @memcpy(i8* %t379, i8* %t386, i64 %t385)
  %t387 = mul i64 %t372, %t352
  %t388 = bitcast i32* %t370 to i8*
  call i8* @memcpy(i8* %t382, i8* %t388, i64 %t387)
  store i64 0, i64* %t389
  br label %map_cow_retain_cond_76
map_cow_retain_cond_76:
  %t390 = load i64, i64* %t389
  %t391 = icmp slt i64 %t390, %t372
  br i1 %t391, label %map_cow_retain_body_77, label %map_cow_retain_end_78
map_cow_retain_body_77:
  %t392 = getelementptr inbounds i8*, i8** %t380, i64 %t390
  %t393 = load i8*, i8** %t392
  call void @star_rc_retain(i8* %t393)
  %t394 = add i64 %t390, 1
  store i64 %t394, i64* %t389
  br label %map_cow_retain_cond_76
map_cow_retain_end_78:
  br label %map_cow_after_copy_75
map_cow_after_copy_75:
  %t395 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t377, i32 0, i32 0
  store i8** %t380, i8*** %t395
  %t396 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t377, i32 0, i32 1
  store i32* %t383, i32** %t396
  %t397 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t377, i32 0, i32 2
  store i64 %t372, i64* %t397
  %t398 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t377, i32 0, i32 3
  store i64 %t374, i64* %t398
  call void @star_rc_release(i8* %t353)
  store i8* %t376, i8** %t1
  br label %map_cow_done_72
map_cow_done_72:
  %t399 = load i8*, i8** %t1
  %t400 = bitcast i8* %t399 to { i8**, i32*, i64, i64 }*
  %t401 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t400, i32 0, i32 0
  %t402 = load i8**, i8*** %t401
  %t403 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t400, i32 0, i32 1
  %t404 = load i32*, i32** %t403
  %t405 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t400, i32 0, i32 2
  %t406 = load i64, i64* %t405
  %t407 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t400, i32 0, i32 3
  %t408 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t409 = load i64, i64* %t405
  %t410 = load i8**, i8*** %t401
  store i64 0, i64* %t411
  br label %map_find_cond_79
map_find_cond_79:
  %t412 = load i64, i64* %t411
  %t413 = icmp slt i64 %t412, %t409
  br i1 %t413, label %map_find_body_80, label %map_find_end_83
map_find_body_80:
  %t414 = getelementptr inbounds i8*, i8** %t410, i64 %t412
  %t415 = load i8*, i8** %t414
  br label %map_find_eq_check_81
map_find_eq_check_81:
  %t416 = call i1 @eq_str(i8* %t415, i8* %t408)
  br i1 %t416, label %map_find_end_83, label %map_find_next_82
map_find_next_82:
  %t417 = add i64 %t412, 1
  store i64 %t417, i64* %t411
  br label %map_find_cond_79
map_find_end_83:
  %t418 = load i64, i64* %t411
  %t419 = icmp slt i64 %t418, %t409
  br i1 %t419, label %map_insert_overwrite_84, label %map_insert_new_85
map_insert_overwrite_84:
  store i8* %t408, i8** %t420
  %t421 = load i8*, i8** %t420
  call void @star_rc_release(i8* %t421)
  %t422 = load i32*, i32** %t403
  %t423 = getelementptr inbounds i32, i32* %t422, i64 %t418
  store i32 31, i32* %t423
  br label %map_insert_after_86
map_insert_new_85:
  %t424 = load i64, i64* %t407
  %t425 = icmp sge i64 %t409, %t424
  br i1 %t425, label %map_insert_grow_87, label %map_insert_store_88
map_insert_grow_87:
  %t426 = mul i64 %t424, 2
  %t427 = icmp sgt i64 %t426, 0
  %t428 = select i1 %t427, i64 %t426, i64 1
  %t429 = getelementptr i8*, i8** null, i32 1
  %t430 = ptrtoint i8** %t429 to i64
  %t431 = mul i64 %t428, %t430
  %t432 = call i8* @malloc(i64 %t431)
  %t433 = bitcast i8* %t432 to i8**
  %t434 = getelementptr i32, i32* null, i32 1
  %t435 = ptrtoint i32* %t434 to i64
  %t436 = mul i64 %t428, %t435
  %t437 = call i8* @malloc(i64 %t436)
  %t438 = bitcast i8* %t437 to i32*
  %t439 = icmp sgt i64 %t424, 0
  br i1 %t439, label %map_insert_copy_89, label %map_insert_after_copy_90
map_insert_copy_89:
  %t440 = load i8**, i8*** %t401
  %t441 = mul i64 %t409, %t430
  %t442 = bitcast i8** %t440 to i8*
  call i8* @memcpy(i8* %t432, i8* %t442, i64 %t441)
  call void @free(i8* %t442)
  %t443 = load i32*, i32** %t403
  %t444 = mul i64 %t409, %t435
  %t445 = bitcast i32* %t443 to i8*
  call i8* @memcpy(i8* %t437, i8* %t445, i64 %t444)
  call void @free(i8* %t445)
  br label %map_insert_after_copy_90
map_insert_after_copy_90:
  store i8** %t433, i8*** %t401
  store i32* %t438, i32** %t403
  store i64 %t428, i64* %t407
  br label %map_insert_store_88
map_insert_store_88:
  %t446 = load i8**, i8*** %t401
  %t447 = load i32*, i32** %t403
  %t448 = getelementptr inbounds i8*, i8** %t446, i64 %t409
  store i8* %t408, i8** %t448
  %t449 = getelementptr inbounds i32, i32* %t447, i64 %t409
  store i32 31, i32* %t449
  %t450 = add i64 %t409, 1
  store i64 %t450, i64* %t405
  br label %map_insert_after_86
map_insert_after_86:
  %t451 = load i8*, i8** %t1
  %t452 = icmp eq i8* %t451, null
  br i1 %t452, label %map_read_null_91, label %map_read_real_92
map_read_null_91:
  br label %map_read_end_93
map_read_real_92:
  %t453 = bitcast i8* %t451 to { i8**, i32*, i64, i64 }*
  %t454 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 0
  %t455 = load i8**, i8*** %t454
  %t456 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 1
  %t457 = load i32*, i32** %t456
  %t458 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 2
  %t459 = load i64, i64* %t458
  br label %map_read_end_93
map_read_end_93:
  %t460 = phi i8** [ null, %map_read_null_91 ], [ %t455, %map_read_real_92 ]
  %t461 = phi i32* [ null, %map_read_null_91 ], [ %t457, %map_read_real_92 ]
  %t462 = phi i64 [ 0, %map_read_null_91 ], [ %t459, %map_read_real_92 ]
  %t463 = trunc i64 %t462 to i32
  %t464 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t464, i32 %t463)
  %t465 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t466 = load i8*, i8** %t1
  %t467 = icmp eq i8* %t466, null
  br i1 %t467, label %map_read_null_94, label %map_read_real_95
map_read_null_94:
  br label %map_read_end_96
map_read_real_95:
  %t468 = bitcast i8* %t466 to { i8**, i32*, i64, i64 }*
  %t469 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t468, i32 0, i32 0
  %t470 = load i8**, i8*** %t469
  %t471 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t468, i32 0, i32 1
  %t472 = load i32*, i32** %t471
  %t473 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t468, i32 0, i32 2
  %t474 = load i64, i64* %t473
  br label %map_read_end_96
map_read_end_96:
  %t475 = phi i8** [ null, %map_read_null_94 ], [ %t470, %map_read_real_95 ]
  %t476 = phi i32* [ null, %map_read_null_94 ], [ %t472, %map_read_real_95 ]
  %t477 = phi i64 [ 0, %map_read_null_94 ], [ %t474, %map_read_real_95 ]
  store i64 0, i64* %t478
  br label %map_find_cond_97
map_find_cond_97:
  %t479 = load i64, i64* %t478
  %t480 = icmp slt i64 %t479, %t477
  br i1 %t480, label %map_find_body_98, label %map_find_end_101
map_find_body_98:
  %t481 = getelementptr inbounds i8*, i8** %t475, i64 %t479
  %t482 = load i8*, i8** %t481
  br label %map_find_eq_check_99
map_find_eq_check_99:
  %t483 = call i1 @eq_str(i8* %t482, i8* %t465)
  br i1 %t483, label %map_find_end_101, label %map_find_next_100
map_find_next_100:
  %t484 = add i64 %t479, 1
  store i64 %t484, i64* %t478
  br label %map_find_cond_97
map_find_end_101:
  %t485 = load i64, i64* %t478
  %t486 = icmp slt i64 %t485, %t477
  store i8* %t465, i8** %t487
  %t488 = load i8*, i8** %t487
  call void @star_rc_release(i8* %t488)
  br i1 %t486, label %map_get_some_102, label %map_get_none_103
map_get_some_102:
  %t489 = getelementptr inbounds i32, i32* %t476, i64 %t485
  %t490 = load i32, i32* %t489
  %t492 = getelementptr inbounds %Option__i32, %Option__i32* %t491, i32 0, i32 0
  store i32 1, i32* %t492
  %t493 = getelementptr inbounds %Option__i32, %Option__i32* %t491, i32 0, i32 1
  %t494 = bitcast [1 x i64]* %t493 to { i32 }*
  %t495 = getelementptr inbounds { i32 }, { i32 }* %t494, i32 0, i32 0
  store i32 %t490, i32* %t495
  %t496 = load %Option__i32, %Option__i32* %t491
  br label %map_get_end_104
map_get_none_103:
  %t498 = getelementptr inbounds %Option__i32, %Option__i32* %t497, i32 0, i32 0
  store i32 0, i32* %t498
  %t499 = load %Option__i32, %Option__i32* %t497
  br label %map_get_end_104
map_get_end_104:
  %t500 = phi %Option__i32 [ %t496, %map_get_some_102 ], [ %t499, %map_get_none_103 ]
  store %Option__i32 %t500, %Option__i32* %t501
  br label %match_scrutinee_503
match_scrutinee_503:
  %t507 = getelementptr inbounds %Option__i32, %Option__i32* %t501, i32 0, i32 0
  %t508 = load i32, i32* %t507
  %t506 = icmp eq i32 %t508, 1
  br i1 %t506, label %match_then_0_504, label %match_next_0_505
match_then_0_504:
  %t509 = getelementptr inbounds %Option__i32, %Option__i32* %t501, i32 0, i32 1
  %t510 = bitcast [1 x i64]* %t509 to { i32 }*
  %t511 = getelementptr inbounds { i32 }, { i32 }* %t510, i32 0, i32 0
  %t512 = load i32, i32* %t511
  %t513 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t513, i32 %t512)
  br label %match_end_502
match_next_0_505:
  %t517 = getelementptr inbounds %Option__i32, %Option__i32* %t501, i32 0, i32 0
  %t518 = load i32, i32* %t517
  %t516 = icmp eq i32 %t518, 0
  br i1 %t516, label %match_then_1_514, label %match_next_1_515
match_then_1_514:
  %t519 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t519)
  call i32 (i8*, ...) @printf(i8* %t519)
  %t520 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t520)
  br label %match_end_502
match_next_1_515:
  br label %match_end_502
match_end_502:
  %t522 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t522, i8** %t521
  %t523 = load i8*, i8** %t521
  %t524 = load i8*, i8** %t521
  call void @star_rc_retain(i8* %t524)
  %t525 = load i8*, i8** %t1
  %t526 = icmp eq i8* %t525, null
  br i1 %t526, label %map_read_null_105, label %map_read_real_106
map_read_null_105:
  br label %map_read_end_107
map_read_real_106:
  %t527 = bitcast i8* %t525 to { i8**, i32*, i64, i64 }*
  %t528 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t527, i32 0, i32 0
  %t529 = load i8**, i8*** %t528
  %t530 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t527, i32 0, i32 1
  %t531 = load i32*, i32** %t530
  %t532 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t527, i32 0, i32 2
  %t533 = load i64, i64* %t532
  br label %map_read_end_107
map_read_end_107:
  %t534 = phi i8** [ null, %map_read_null_105 ], [ %t529, %map_read_real_106 ]
  %t535 = phi i32* [ null, %map_read_null_105 ], [ %t531, %map_read_real_106 ]
  %t536 = phi i64 [ 0, %map_read_null_105 ], [ %t533, %map_read_real_106 ]
  store i64 0, i64* %t537
  br label %map_find_cond_108
map_find_cond_108:
  %t538 = load i64, i64* %t537
  %t539 = icmp slt i64 %t538, %t536
  br i1 %t539, label %map_find_body_109, label %map_find_end_112
map_find_body_109:
  %t540 = getelementptr inbounds i8*, i8** %t534, i64 %t538
  %t541 = load i8*, i8** %t540
  br label %map_find_eq_check_110
map_find_eq_check_110:
  %t542 = call i1 @eq_str(i8* %t541, i8* %t523)
  br i1 %t542, label %map_find_end_112, label %map_find_next_111
map_find_next_111:
  %t543 = add i64 %t538, 1
  store i64 %t543, i64* %t537
  br label %map_find_cond_108
map_find_end_112:
  %t544 = load i64, i64* %t537
  %t545 = icmp slt i64 %t544, %t536
  store i8* %t523, i8** %t546
  %t547 = load i8*, i8** %t546
  call void @star_rc_release(i8* %t547)
  %t548 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t549 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t550 = select i1 %t545, i8* %t548, i8* %t549
  %t551 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t551, i8* %t550)
  %t552 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t553 = getelementptr i8*, i8** null, i32 1
  %t554 = ptrtoint i8** %t553 to i64
  %t555 = getelementptr i32, i32* null, i32 1
  %t556 = ptrtoint i32* %t555 to i64
  %t557 = load i8*, i8** %t1
  %t558 = icmp eq i8* %t557, null
  br i1 %t558, label %map_cow_alloc_113, label %map_cow_check_114
map_cow_alloc_113:
  %t559 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t560 = call i8* @star_rc_alloc(i64 32, i8* %t559)
  %t561 = bitcast i8* %t560 to { i8**, i32*, i64, i64 }*
  %t562 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t561, i32 0, i32 0
  store i8** null, i8*** %t562
  %t563 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t561, i32 0, i32 1
  store i32* null, i32** %t563
  %t564 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t561, i32 0, i32 2
  store i64 0, i64* %t564
  %t565 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t561, i32 0, i32 3
  store i64 0, i64* %t565
  store i8* %t560, i8** %t1
  br label %map_cow_done_115
map_cow_check_114:
  %t566 = getelementptr inbounds i8, i8* %t557, i64 -16
  %t567 = bitcast i8* %t566 to i64*
  %t568 = load atomic i64, i64* %t567 seq_cst, align 8
  %t569 = icmp eq i64 %t568, 1
  br i1 %t569, label %map_cow_done_115, label %map_cow_clone_116
map_cow_clone_116:
  %t570 = bitcast i8* %t557 to { i8**, i32*, i64, i64 }*
  %t571 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t570, i32 0, i32 0
  %t572 = load i8**, i8*** %t571
  %t573 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t570, i32 0, i32 1
  %t574 = load i32*, i32** %t573
  %t575 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t570, i32 0, i32 2
  %t576 = load i64, i64* %t575
  %t577 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t570, i32 0, i32 3
  %t578 = load i64, i64* %t577
  %t579 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t580 = call i8* @star_rc_alloc(i64 32, i8* %t579)
  %t581 = bitcast i8* %t580 to { i8**, i32*, i64, i64 }*
  %t582 = mul i64 %t578, %t554
  %t583 = call i8* @malloc(i64 %t582)
  %t584 = bitcast i8* %t583 to i8**
  %t585 = mul i64 %t578, %t556
  %t586 = call i8* @malloc(i64 %t585)
  %t587 = bitcast i8* %t586 to i32*
  %t588 = icmp sgt i64 %t576, 0
  br i1 %t588, label %map_cow_copy_117, label %map_cow_after_copy_118
map_cow_copy_117:
  %t589 = mul i64 %t576, %t554
  %t590 = bitcast i8** %t572 to i8*
  call i8* @memcpy(i8* %t583, i8* %t590, i64 %t589)
  %t591 = mul i64 %t576, %t556
  %t592 = bitcast i32* %t574 to i8*
  call i8* @memcpy(i8* %t586, i8* %t592, i64 %t591)
  store i64 0, i64* %t593
  br label %map_cow_retain_cond_119
map_cow_retain_cond_119:
  %t594 = load i64, i64* %t593
  %t595 = icmp slt i64 %t594, %t576
  br i1 %t595, label %map_cow_retain_body_120, label %map_cow_retain_end_121
map_cow_retain_body_120:
  %t596 = getelementptr inbounds i8*, i8** %t584, i64 %t594
  %t597 = load i8*, i8** %t596
  call void @star_rc_retain(i8* %t597)
  %t598 = add i64 %t594, 1
  store i64 %t598, i64* %t593
  br label %map_cow_retain_cond_119
map_cow_retain_end_121:
  br label %map_cow_after_copy_118
map_cow_after_copy_118:
  %t599 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t581, i32 0, i32 0
  store i8** %t584, i8*** %t599
  %t600 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t581, i32 0, i32 1
  store i32* %t587, i32** %t600
  %t601 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t581, i32 0, i32 2
  store i64 %t576, i64* %t601
  %t602 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t581, i32 0, i32 3
  store i64 %t578, i64* %t602
  call void @star_rc_release(i8* %t557)
  store i8* %t580, i8** %t1
  br label %map_cow_done_115
map_cow_done_115:
  %t603 = load i8*, i8** %t1
  %t604 = bitcast i8* %t603 to { i8**, i32*, i64, i64 }*
  %t605 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t604, i32 0, i32 0
  %t606 = load i8**, i8*** %t605
  %t607 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t604, i32 0, i32 1
  %t608 = load i32*, i32** %t607
  %t609 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t604, i32 0, i32 2
  %t610 = load i64, i64* %t609
  %t611 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t604, i32 0, i32 3
  store i64 0, i64* %t612
  br label %map_find_cond_122
map_find_cond_122:
  %t613 = load i64, i64* %t612
  %t614 = icmp slt i64 %t613, %t610
  br i1 %t614, label %map_find_body_123, label %map_find_end_126
map_find_body_123:
  %t615 = getelementptr inbounds i8*, i8** %t606, i64 %t613
  %t616 = load i8*, i8** %t615
  br label %map_find_eq_check_124
map_find_eq_check_124:
  %t617 = call i1 @eq_str(i8* %t616, i8* %t552)
  br i1 %t617, label %map_find_end_126, label %map_find_next_125
map_find_next_125:
  %t618 = add i64 %t613, 1
  store i64 %t618, i64* %t612
  br label %map_find_cond_122
map_find_end_126:
  %t619 = load i64, i64* %t612
  %t620 = icmp slt i64 %t619, %t610
  store i8* %t552, i8** %t621
  %t622 = load i8*, i8** %t621
  call void @star_rc_release(i8* %t622)
  br i1 %t620, label %map_remove_some_127, label %map_remove_none_128
map_remove_some_127:
  %t623 = getelementptr inbounds i8*, i8** %t606, i64 %t619
  %t624 = getelementptr inbounds i32, i32* %t608, i64 %t619
  %t625 = load i32, i32* %t624
  %t626 = load i8*, i8** %t623
  call void @star_rc_release(i8* %t626)
  %t627 = sub i64 %t610, 1
  %t628 = getelementptr inbounds i8*, i8** %t606, i64 %t627
  %t629 = load i8*, i8** %t628
  %t630 = getelementptr inbounds i32, i32* %t608, i64 %t627
  %t631 = load i32, i32* %t630
  store i8* %t629, i8** %t623
  store i32 %t631, i32* %t624
  store i64 %t627, i64* %t609
  %t633 = getelementptr inbounds %Option__i32, %Option__i32* %t632, i32 0, i32 0
  store i32 1, i32* %t633
  %t634 = getelementptr inbounds %Option__i32, %Option__i32* %t632, i32 0, i32 1
  %t635 = bitcast [1 x i64]* %t634 to { i32 }*
  %t636 = getelementptr inbounds { i32 }, { i32 }* %t635, i32 0, i32 0
  store i32 %t625, i32* %t636
  %t637 = load %Option__i32, %Option__i32* %t632
  br label %map_remove_end_129
map_remove_none_128:
  %t639 = getelementptr inbounds %Option__i32, %Option__i32* %t638, i32 0, i32 0
  store i32 0, i32* %t639
  %t640 = load %Option__i32, %Option__i32* %t638
  br label %map_remove_end_129
map_remove_end_129:
  %t641 = phi %Option__i32 [ %t637, %map_remove_some_127 ], [ %t640, %map_remove_none_128 ]
  store %Option__i32 %t641, %Option__i32* %t642
  br label %match_scrutinee_644
match_scrutinee_644:
  %t648 = getelementptr inbounds %Option__i32, %Option__i32* %t642, i32 0, i32 0
  %t649 = load i32, i32* %t648
  %t647 = icmp eq i32 %t649, 1
  br i1 %t647, label %match_then_0_645, label %match_next_0_646
match_then_0_645:
  %t650 = getelementptr inbounds %Option__i32, %Option__i32* %t642, i32 0, i32 1
  %t651 = bitcast [1 x i64]* %t650 to { i32 }*
  %t652 = getelementptr inbounds { i32 }, { i32 }* %t651, i32 0, i32 0
  %t653 = load i32, i32* %t652
  %t654 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t654, i32 %t653)
  br label %match_end_643
match_next_0_646:
  %t658 = getelementptr inbounds %Option__i32, %Option__i32* %t642, i32 0, i32 0
  %t659 = load i32, i32* %t658
  %t657 = icmp eq i32 %t659, 0
  br i1 %t657, label %match_then_1_655, label %match_next_1_656
match_then_1_655:
  %t660 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t660)
  call i32 (i8*, ...) @printf(i8* %t660)
  %t661 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t661)
  br label %match_end_643
match_next_1_656:
  br label %match_end_643
match_end_643:
  %t662 = load i8*, i8** %t521
  %t663 = load i8*, i8** %t521
  call void @star_rc_retain(i8* %t663)
  %t664 = load i8*, i8** %t1
  %t665 = icmp eq i8* %t664, null
  br i1 %t665, label %map_read_null_130, label %map_read_real_131
map_read_null_130:
  br label %map_read_end_132
map_read_real_131:
  %t666 = bitcast i8* %t664 to { i8**, i32*, i64, i64 }*
  %t667 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t666, i32 0, i32 0
  %t668 = load i8**, i8*** %t667
  %t669 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t666, i32 0, i32 1
  %t670 = load i32*, i32** %t669
  %t671 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t666, i32 0, i32 2
  %t672 = load i64, i64* %t671
  br label %map_read_end_132
map_read_end_132:
  %t673 = phi i8** [ null, %map_read_null_130 ], [ %t668, %map_read_real_131 ]
  %t674 = phi i32* [ null, %map_read_null_130 ], [ %t670, %map_read_real_131 ]
  %t675 = phi i64 [ 0, %map_read_null_130 ], [ %t672, %map_read_real_131 ]
  store i64 0, i64* %t676
  br label %map_find_cond_133
map_find_cond_133:
  %t677 = load i64, i64* %t676
  %t678 = icmp slt i64 %t677, %t675
  br i1 %t678, label %map_find_body_134, label %map_find_end_137
map_find_body_134:
  %t679 = getelementptr inbounds i8*, i8** %t673, i64 %t677
  %t680 = load i8*, i8** %t679
  br label %map_find_eq_check_135
map_find_eq_check_135:
  %t681 = call i1 @eq_str(i8* %t680, i8* %t662)
  br i1 %t681, label %map_find_end_137, label %map_find_next_136
map_find_next_136:
  %t682 = add i64 %t677, 1
  store i64 %t682, i64* %t676
  br label %map_find_cond_133
map_find_end_137:
  %t683 = load i64, i64* %t676
  %t684 = icmp slt i64 %t683, %t675
  store i8* %t662, i8** %t685
  %t686 = load i8*, i8** %t685
  call void @star_rc_release(i8* %t686)
  %t687 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t688 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t689 = select i1 %t684, i8* %t687, i8* %t688
  %t690 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t690, i8* %t689)
  %t691 = load i8*, i8** %t1
  %t692 = icmp eq i8* %t691, null
  br i1 %t692, label %map_read_null_138, label %map_read_real_139
map_read_null_138:
  br label %map_read_end_140
map_read_real_139:
  %t693 = bitcast i8* %t691 to { i8**, i32*, i64, i64 }*
  %t694 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t693, i32 0, i32 0
  %t695 = load i8**, i8*** %t694
  %t696 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t693, i32 0, i32 1
  %t697 = load i32*, i32** %t696
  %t698 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t693, i32 0, i32 2
  %t699 = load i64, i64* %t698
  br label %map_read_end_140
map_read_end_140:
  %t700 = phi i8** [ null, %map_read_null_138 ], [ %t695, %map_read_real_139 ]
  %t701 = phi i32* [ null, %map_read_null_138 ], [ %t697, %map_read_real_139 ]
  %t702 = phi i64 [ 0, %map_read_null_138 ], [ %t699, %map_read_real_139 ]
  %t703 = trunc i64 %t702 to i32
  %t704 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t704, i32 %t703)
  store i8* null, i8** %t705
  %t706 = getelementptr i32, i32* null, i32 1
  %t707 = ptrtoint i32* %t706 to i64
  %t708 = load i8*, i8** %t705
  %t709 = icmp eq i8* %t708, null
  br i1 %t709, label %set_cow_alloc_141, label %set_cow_check_142
set_cow_alloc_141:
  %t714 = bitcast void (i8*)* @set_release_i32 to i8*
  %t715 = call i8* @star_rc_alloc(i64 24, i8* %t714)
  %t716 = bitcast i8* %t715 to { i32*, i64, i64 }*
  %t717 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t716, i32 0, i32 0
  store i32* null, i32** %t717
  %t718 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t716, i32 0, i32 1
  store i64 0, i64* %t718
  %t719 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t716, i32 0, i32 2
  store i64 0, i64* %t719
  store i8* %t715, i8** %t705
  br label %set_cow_done_143
set_cow_check_142:
  %t720 = getelementptr inbounds i8, i8* %t708, i64 -16
  %t721 = bitcast i8* %t720 to i64*
  %t722 = load atomic i64, i64* %t721 seq_cst, align 8
  %t723 = icmp eq i64 %t722, 1
  br i1 %t723, label %set_cow_done_143, label %set_cow_clone_144
set_cow_clone_144:
  %t724 = bitcast i8* %t708 to { i32*, i64, i64 }*
  %t725 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t724, i32 0, i32 0
  %t726 = load i32*, i32** %t725
  %t727 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t724, i32 0, i32 1
  %t728 = load i64, i64* %t727
  %t729 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t724, i32 0, i32 2
  %t730 = load i64, i64* %t729
  %t731 = bitcast void (i8*)* @set_release_i32 to i8*
  %t732 = call i8* @star_rc_alloc(i64 24, i8* %t731)
  %t733 = bitcast i8* %t732 to { i32*, i64, i64 }*
  %t734 = mul i64 %t730, %t707
  %t735 = call i8* @malloc(i64 %t734)
  %t736 = bitcast i8* %t735 to i32*
  %t737 = icmp sgt i64 %t728, 0
  br i1 %t737, label %set_cow_copy_145, label %set_cow_after_copy_146
set_cow_copy_145:
  %t738 = mul i64 %t728, %t707
  %t739 = bitcast i32* %t726 to i8*
  call i8* @memcpy(i8* %t735, i8* %t739, i64 %t738)
  br label %set_cow_after_copy_146
set_cow_after_copy_146:
  %t740 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t733, i32 0, i32 0
  store i32* %t736, i32** %t740
  %t741 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t733, i32 0, i32 1
  store i64 %t728, i64* %t741
  %t742 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t733, i32 0, i32 2
  store i64 %t730, i64* %t742
  call void @star_rc_release(i8* %t708)
  store i8* %t732, i8** %t705
  br label %set_cow_done_143
set_cow_done_143:
  %t743 = load i8*, i8** %t705
  %t744 = bitcast i8* %t743 to { i32*, i64, i64 }*
  %t745 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t744, i32 0, i32 0
  %t746 = load i32*, i32** %t745
  %t747 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t744, i32 0, i32 1
  %t748 = load i64, i64* %t747
  %t749 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t744, i32 0, i32 2
  %t750 = load i64, i64* %t747
  %t751 = load i32*, i32** %t745
  store i64 0, i64* %t753
  store i1 false, i1* %t754
  br label %find_cond_147
find_cond_147:
  %t755 = load i64, i64* %t753
  %t756 = icmp slt i64 %t755, %t750
  br i1 %t756, label %find_body_148, label %find_end_151
find_body_148:
  %t757 = getelementptr inbounds i32, i32* %t751, i64 %t755
  %t758 = load i32, i32* %t757
  br label %find_eq_check_149
find_eq_check_149:
  %t759 = call i1 @eq_i32(i32 %t758, i32 1)
  br i1 %t759, label %find_end_151, label %find_next_150
find_next_150:
  %t760 = add i64 %t755, 1
  store i64 %t760, i64* %t753
  br label %find_cond_147
find_end_151:
  %t761 = load i64, i64* %t753
  %t762 = icmp slt i64 %t761, %t750
  br i1 %t762, label %set_insert_already_present_152, label %set_insert_do_153
set_insert_already_present_152:
  br label %set_insert_end_154
set_insert_do_153:
  %t763 = load i64, i64* %t749
  %t764 = load i32*, i32** %t745
  %t765 = icmp sge i64 %t750, %t763
  br i1 %t765, label %set_insert_grow_155, label %set_insert_store_156
set_insert_grow_155:
  %t766 = mul i64 %t763, 2
  %t767 = icmp sgt i64 %t766, 0
  %t768 = select i1 %t767, i64 %t766, i64 1
  %t769 = getelementptr i32, i32* null, i32 1
  %t770 = ptrtoint i32* %t769 to i64
  %t771 = mul i64 %t768, %t770
  %t772 = call i8* @malloc(i64 %t771)
  %t773 = bitcast i8* %t772 to i32*
  %t774 = icmp sgt i64 %t763, 0
  br i1 %t774, label %set_insert_copy_157, label %set_insert_after_copy_158
set_insert_copy_157:
  %t775 = mul i64 %t750, %t770
  %t776 = bitcast i32* %t764 to i8*
  call i8* @memcpy(i8* %t772, i8* %t776, i64 %t775)
  call void @free(i8* %t776)
  br label %set_insert_after_copy_158
set_insert_after_copy_158:
  store i32* %t773, i32** %t745
  store i64 %t768, i64* %t749
  br label %set_insert_store_156
set_insert_store_156:
  %t777 = load i32*, i32** %t745
  %t778 = getelementptr inbounds i32, i32* %t777, i64 %t750
  store i32 1, i32* %t778
  %t779 = add i64 %t750, 1
  store i64 %t779, i64* %t747
  br label %set_insert_end_154
set_insert_end_154:
  %t780 = phi i1 [ false, %set_insert_already_present_152 ], [ true, %set_insert_store_156 ]
  %t781 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t782 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t783 = select i1 %t780, i8* %t781, i8* %t782
  %t784 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t784, i8* %t783)
  %t785 = getelementptr i32, i32* null, i32 1
  %t786 = ptrtoint i32* %t785 to i64
  %t787 = load i8*, i8** %t705
  %t788 = icmp eq i8* %t787, null
  br i1 %t788, label %set_cow_alloc_159, label %set_cow_check_160
set_cow_alloc_159:
  %t789 = bitcast void (i8*)* @set_release_i32 to i8*
  %t790 = call i8* @star_rc_alloc(i64 24, i8* %t789)
  %t791 = bitcast i8* %t790 to { i32*, i64, i64 }*
  %t792 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t791, i32 0, i32 0
  store i32* null, i32** %t792
  %t793 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t791, i32 0, i32 1
  store i64 0, i64* %t793
  %t794 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t791, i32 0, i32 2
  store i64 0, i64* %t794
  store i8* %t790, i8** %t705
  br label %set_cow_done_161
set_cow_check_160:
  %t795 = getelementptr inbounds i8, i8* %t787, i64 -16
  %t796 = bitcast i8* %t795 to i64*
  %t797 = load atomic i64, i64* %t796 seq_cst, align 8
  %t798 = icmp eq i64 %t797, 1
  br i1 %t798, label %set_cow_done_161, label %set_cow_clone_162
set_cow_clone_162:
  %t799 = bitcast i8* %t787 to { i32*, i64, i64 }*
  %t800 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t799, i32 0, i32 0
  %t801 = load i32*, i32** %t800
  %t802 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t799, i32 0, i32 1
  %t803 = load i64, i64* %t802
  %t804 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t799, i32 0, i32 2
  %t805 = load i64, i64* %t804
  %t806 = bitcast void (i8*)* @set_release_i32 to i8*
  %t807 = call i8* @star_rc_alloc(i64 24, i8* %t806)
  %t808 = bitcast i8* %t807 to { i32*, i64, i64 }*
  %t809 = mul i64 %t805, %t786
  %t810 = call i8* @malloc(i64 %t809)
  %t811 = bitcast i8* %t810 to i32*
  %t812 = icmp sgt i64 %t803, 0
  br i1 %t812, label %set_cow_copy_163, label %set_cow_after_copy_164
set_cow_copy_163:
  %t813 = mul i64 %t803, %t786
  %t814 = bitcast i32* %t801 to i8*
  call i8* @memcpy(i8* %t810, i8* %t814, i64 %t813)
  br label %set_cow_after_copy_164
set_cow_after_copy_164:
  %t815 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t808, i32 0, i32 0
  store i32* %t811, i32** %t815
  %t816 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t808, i32 0, i32 1
  store i64 %t803, i64* %t816
  %t817 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t808, i32 0, i32 2
  store i64 %t805, i64* %t817
  call void @star_rc_release(i8* %t787)
  store i8* %t807, i8** %t705
  br label %set_cow_done_161
set_cow_done_161:
  %t818 = load i8*, i8** %t705
  %t819 = bitcast i8* %t818 to { i32*, i64, i64 }*
  %t820 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t819, i32 0, i32 0
  %t821 = load i32*, i32** %t820
  %t822 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t819, i32 0, i32 1
  %t823 = load i64, i64* %t822
  %t824 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t819, i32 0, i32 2
  %t825 = load i64, i64* %t822
  %t826 = load i32*, i32** %t820
  store i64 0, i64* %t827
  store i1 false, i1* %t828
  br label %find_cond_165
find_cond_165:
  %t829 = load i64, i64* %t827
  %t830 = icmp slt i64 %t829, %t825
  br i1 %t830, label %find_body_166, label %find_end_169
find_body_166:
  %t831 = getelementptr inbounds i32, i32* %t826, i64 %t829
  %t832 = load i32, i32* %t831
  br label %find_eq_check_167
find_eq_check_167:
  %t833 = call i1 @eq_i32(i32 %t832, i32 2)
  br i1 %t833, label %find_end_169, label %find_next_168
find_next_168:
  %t834 = add i64 %t829, 1
  store i64 %t834, i64* %t827
  br label %find_cond_165
find_end_169:
  %t835 = load i64, i64* %t827
  %t836 = icmp slt i64 %t835, %t825
  br i1 %t836, label %set_insert_already_present_170, label %set_insert_do_171
set_insert_already_present_170:
  br label %set_insert_end_172
set_insert_do_171:
  %t837 = load i64, i64* %t824
  %t838 = load i32*, i32** %t820
  %t839 = icmp sge i64 %t825, %t837
  br i1 %t839, label %set_insert_grow_173, label %set_insert_store_174
set_insert_grow_173:
  %t840 = mul i64 %t837, 2
  %t841 = icmp sgt i64 %t840, 0
  %t842 = select i1 %t841, i64 %t840, i64 1
  %t843 = getelementptr i32, i32* null, i32 1
  %t844 = ptrtoint i32* %t843 to i64
  %t845 = mul i64 %t842, %t844
  %t846 = call i8* @malloc(i64 %t845)
  %t847 = bitcast i8* %t846 to i32*
  %t848 = icmp sgt i64 %t837, 0
  br i1 %t848, label %set_insert_copy_175, label %set_insert_after_copy_176
set_insert_copy_175:
  %t849 = mul i64 %t825, %t844
  %t850 = bitcast i32* %t838 to i8*
  call i8* @memcpy(i8* %t846, i8* %t850, i64 %t849)
  call void @free(i8* %t850)
  br label %set_insert_after_copy_176
set_insert_after_copy_176:
  store i32* %t847, i32** %t820
  store i64 %t842, i64* %t824
  br label %set_insert_store_174
set_insert_store_174:
  %t851 = load i32*, i32** %t820
  %t852 = getelementptr inbounds i32, i32* %t851, i64 %t825
  store i32 2, i32* %t852
  %t853 = add i64 %t825, 1
  store i64 %t853, i64* %t822
  br label %set_insert_end_172
set_insert_end_172:
  %t854 = phi i1 [ false, %set_insert_already_present_170 ], [ true, %set_insert_store_174 ]
  %t855 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t856 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t857 = select i1 %t854, i8* %t855, i8* %t856
  %t858 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t858, i8* %t857)
  %t859 = getelementptr i32, i32* null, i32 1
  %t860 = ptrtoint i32* %t859 to i64
  %t861 = load i8*, i8** %t705
  %t862 = icmp eq i8* %t861, null
  br i1 %t862, label %set_cow_alloc_177, label %set_cow_check_178
set_cow_alloc_177:
  %t863 = bitcast void (i8*)* @set_release_i32 to i8*
  %t864 = call i8* @star_rc_alloc(i64 24, i8* %t863)
  %t865 = bitcast i8* %t864 to { i32*, i64, i64 }*
  %t866 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t865, i32 0, i32 0
  store i32* null, i32** %t866
  %t867 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t865, i32 0, i32 1
  store i64 0, i64* %t867
  %t868 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t865, i32 0, i32 2
  store i64 0, i64* %t868
  store i8* %t864, i8** %t705
  br label %set_cow_done_179
set_cow_check_178:
  %t869 = getelementptr inbounds i8, i8* %t861, i64 -16
  %t870 = bitcast i8* %t869 to i64*
  %t871 = load atomic i64, i64* %t870 seq_cst, align 8
  %t872 = icmp eq i64 %t871, 1
  br i1 %t872, label %set_cow_done_179, label %set_cow_clone_180
set_cow_clone_180:
  %t873 = bitcast i8* %t861 to { i32*, i64, i64 }*
  %t874 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t873, i32 0, i32 0
  %t875 = load i32*, i32** %t874
  %t876 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t873, i32 0, i32 1
  %t877 = load i64, i64* %t876
  %t878 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t873, i32 0, i32 2
  %t879 = load i64, i64* %t878
  %t880 = bitcast void (i8*)* @set_release_i32 to i8*
  %t881 = call i8* @star_rc_alloc(i64 24, i8* %t880)
  %t882 = bitcast i8* %t881 to { i32*, i64, i64 }*
  %t883 = mul i64 %t879, %t860
  %t884 = call i8* @malloc(i64 %t883)
  %t885 = bitcast i8* %t884 to i32*
  %t886 = icmp sgt i64 %t877, 0
  br i1 %t886, label %set_cow_copy_181, label %set_cow_after_copy_182
set_cow_copy_181:
  %t887 = mul i64 %t877, %t860
  %t888 = bitcast i32* %t875 to i8*
  call i8* @memcpy(i8* %t884, i8* %t888, i64 %t887)
  br label %set_cow_after_copy_182
set_cow_after_copy_182:
  %t889 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t882, i32 0, i32 0
  store i32* %t885, i32** %t889
  %t890 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t882, i32 0, i32 1
  store i64 %t877, i64* %t890
  %t891 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t882, i32 0, i32 2
  store i64 %t879, i64* %t891
  call void @star_rc_release(i8* %t861)
  store i8* %t881, i8** %t705
  br label %set_cow_done_179
set_cow_done_179:
  %t892 = load i8*, i8** %t705
  %t893 = bitcast i8* %t892 to { i32*, i64, i64 }*
  %t894 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t893, i32 0, i32 0
  %t895 = load i32*, i32** %t894
  %t896 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t893, i32 0, i32 1
  %t897 = load i64, i64* %t896
  %t898 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t893, i32 0, i32 2
  %t899 = load i64, i64* %t896
  %t900 = load i32*, i32** %t894
  store i64 0, i64* %t901
  store i1 false, i1* %t902
  br label %find_cond_183
find_cond_183:
  %t903 = load i64, i64* %t901
  %t904 = icmp slt i64 %t903, %t899
  br i1 %t904, label %find_body_184, label %find_end_187
find_body_184:
  %t905 = getelementptr inbounds i32, i32* %t900, i64 %t903
  %t906 = load i32, i32* %t905
  br label %find_eq_check_185
find_eq_check_185:
  %t907 = call i1 @eq_i32(i32 %t906, i32 1)
  br i1 %t907, label %find_end_187, label %find_next_186
find_next_186:
  %t908 = add i64 %t903, 1
  store i64 %t908, i64* %t901
  br label %find_cond_183
find_end_187:
  %t909 = load i64, i64* %t901
  %t910 = icmp slt i64 %t909, %t899
  br i1 %t910, label %set_insert_already_present_188, label %set_insert_do_189
set_insert_already_present_188:
  br label %set_insert_end_190
set_insert_do_189:
  %t911 = load i64, i64* %t898
  %t912 = load i32*, i32** %t894
  %t913 = icmp sge i64 %t899, %t911
  br i1 %t913, label %set_insert_grow_191, label %set_insert_store_192
set_insert_grow_191:
  %t914 = mul i64 %t911, 2
  %t915 = icmp sgt i64 %t914, 0
  %t916 = select i1 %t915, i64 %t914, i64 1
  %t917 = getelementptr i32, i32* null, i32 1
  %t918 = ptrtoint i32* %t917 to i64
  %t919 = mul i64 %t916, %t918
  %t920 = call i8* @malloc(i64 %t919)
  %t921 = bitcast i8* %t920 to i32*
  %t922 = icmp sgt i64 %t911, 0
  br i1 %t922, label %set_insert_copy_193, label %set_insert_after_copy_194
set_insert_copy_193:
  %t923 = mul i64 %t899, %t918
  %t924 = bitcast i32* %t912 to i8*
  call i8* @memcpy(i8* %t920, i8* %t924, i64 %t923)
  call void @free(i8* %t924)
  br label %set_insert_after_copy_194
set_insert_after_copy_194:
  store i32* %t921, i32** %t894
  store i64 %t916, i64* %t898
  br label %set_insert_store_192
set_insert_store_192:
  %t925 = load i32*, i32** %t894
  %t926 = getelementptr inbounds i32, i32* %t925, i64 %t899
  store i32 1, i32* %t926
  %t927 = add i64 %t899, 1
  store i64 %t927, i64* %t896
  br label %set_insert_end_190
set_insert_end_190:
  %t928 = phi i1 [ false, %set_insert_already_present_188 ], [ true, %set_insert_store_192 ]
  %t929 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t930 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t931 = select i1 %t928, i8* %t929, i8* %t930
  %t932 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t932, i8* %t931)
  %t933 = load i8*, i8** %t705
  %t934 = icmp eq i8* %t933, null
  br i1 %t934, label %set_read_null_195, label %set_read_real_196
set_read_null_195:
  br label %set_read_end_197
set_read_real_196:
  %t935 = bitcast i8* %t933 to { i32*, i64, i64 }*
  %t936 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t935, i32 0, i32 0
  %t937 = load i32*, i32** %t936
  %t938 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t935, i32 0, i32 1
  %t939 = load i64, i64* %t938
  br label %set_read_end_197
set_read_end_197:
  %t940 = phi i32* [ null, %set_read_null_195 ], [ %t937, %set_read_real_196 ]
  %t941 = phi i64 [ 0, %set_read_null_195 ], [ %t939, %set_read_real_196 ]
  %t942 = trunc i64 %t941 to i32
  %t943 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t943, i32 %t942)
  %t944 = load i8*, i8** %t705
  %t945 = icmp eq i8* %t944, null
  br i1 %t945, label %set_read_null_198, label %set_read_real_199
set_read_null_198:
  br label %set_read_end_200
set_read_real_199:
  %t946 = bitcast i8* %t944 to { i32*, i64, i64 }*
  %t947 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t946, i32 0, i32 0
  %t948 = load i32*, i32** %t947
  %t949 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t946, i32 0, i32 1
  %t950 = load i64, i64* %t949
  br label %set_read_end_200
set_read_end_200:
  %t951 = phi i32* [ null, %set_read_null_198 ], [ %t948, %set_read_real_199 ]
  %t952 = phi i64 [ 0, %set_read_null_198 ], [ %t950, %set_read_real_199 ]
  store i64 0, i64* %t953
  store i1 false, i1* %t954
  br label %find_cond_201
find_cond_201:
  %t955 = load i64, i64* %t953
  %t956 = icmp slt i64 %t955, %t952
  br i1 %t956, label %find_body_202, label %find_end_205
find_body_202:
  %t957 = getelementptr inbounds i32, i32* %t951, i64 %t955
  %t958 = load i32, i32* %t957
  br label %find_eq_check_203
find_eq_check_203:
  %t959 = call i1 @eq_i32(i32 %t958, i32 2)
  br i1 %t959, label %find_end_205, label %find_next_204
find_next_204:
  %t960 = add i64 %t955, 1
  store i64 %t960, i64* %t953
  br label %find_cond_201
find_end_205:
  %t961 = load i64, i64* %t953
  %t962 = icmp slt i64 %t961, %t952
  %t963 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t964 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t965 = select i1 %t962, i8* %t963, i8* %t964
  %t966 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t966, i8* %t965)
  %t967 = getelementptr i32, i32* null, i32 1
  %t968 = ptrtoint i32* %t967 to i64
  %t969 = load i8*, i8** %t705
  %t970 = icmp eq i8* %t969, null
  br i1 %t970, label %set_cow_alloc_206, label %set_cow_check_207
set_cow_alloc_206:
  %t971 = bitcast void (i8*)* @set_release_i32 to i8*
  %t972 = call i8* @star_rc_alloc(i64 24, i8* %t971)
  %t973 = bitcast i8* %t972 to { i32*, i64, i64 }*
  %t974 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t973, i32 0, i32 0
  store i32* null, i32** %t974
  %t975 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t973, i32 0, i32 1
  store i64 0, i64* %t975
  %t976 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t973, i32 0, i32 2
  store i64 0, i64* %t976
  store i8* %t972, i8** %t705
  br label %set_cow_done_208
set_cow_check_207:
  %t977 = getelementptr inbounds i8, i8* %t969, i64 -16
  %t978 = bitcast i8* %t977 to i64*
  %t979 = load atomic i64, i64* %t978 seq_cst, align 8
  %t980 = icmp eq i64 %t979, 1
  br i1 %t980, label %set_cow_done_208, label %set_cow_clone_209
set_cow_clone_209:
  %t981 = bitcast i8* %t969 to { i32*, i64, i64 }*
  %t982 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t981, i32 0, i32 0
  %t983 = load i32*, i32** %t982
  %t984 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t981, i32 0, i32 1
  %t985 = load i64, i64* %t984
  %t986 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t981, i32 0, i32 2
  %t987 = load i64, i64* %t986
  %t988 = bitcast void (i8*)* @set_release_i32 to i8*
  %t989 = call i8* @star_rc_alloc(i64 24, i8* %t988)
  %t990 = bitcast i8* %t989 to { i32*, i64, i64 }*
  %t991 = mul i64 %t987, %t968
  %t992 = call i8* @malloc(i64 %t991)
  %t993 = bitcast i8* %t992 to i32*
  %t994 = icmp sgt i64 %t985, 0
  br i1 %t994, label %set_cow_copy_210, label %set_cow_after_copy_211
set_cow_copy_210:
  %t995 = mul i64 %t985, %t968
  %t996 = bitcast i32* %t983 to i8*
  call i8* @memcpy(i8* %t992, i8* %t996, i64 %t995)
  br label %set_cow_after_copy_211
set_cow_after_copy_211:
  %t997 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t990, i32 0, i32 0
  store i32* %t993, i32** %t997
  %t998 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t990, i32 0, i32 1
  store i64 %t985, i64* %t998
  %t999 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t990, i32 0, i32 2
  store i64 %t987, i64* %t999
  call void @star_rc_release(i8* %t969)
  store i8* %t989, i8** %t705
  br label %set_cow_done_208
set_cow_done_208:
  %t1000 = load i8*, i8** %t705
  %t1001 = bitcast i8* %t1000 to { i32*, i64, i64 }*
  %t1002 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1001, i32 0, i32 0
  %t1003 = load i32*, i32** %t1002
  %t1004 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1001, i32 0, i32 1
  %t1005 = load i64, i64* %t1004
  %t1006 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1001, i32 0, i32 2
  %t1007 = load i64, i64* %t1004
  %t1008 = load i32*, i32** %t1002
  store i64 0, i64* %t1009
  store i1 false, i1* %t1010
  br label %find_cond_212
find_cond_212:
  %t1011 = load i64, i64* %t1009
  %t1012 = icmp slt i64 %t1011, %t1007
  br i1 %t1012, label %find_body_213, label %find_end_216
find_body_213:
  %t1013 = getelementptr inbounds i32, i32* %t1008, i64 %t1011
  %t1014 = load i32, i32* %t1013
  br label %find_eq_check_214
find_eq_check_214:
  %t1015 = call i1 @eq_i32(i32 %t1014, i32 2)
  br i1 %t1015, label %find_end_216, label %find_next_215
find_next_215:
  %t1016 = add i64 %t1011, 1
  store i64 %t1016, i64* %t1009
  br label %find_cond_212
find_end_216:
  %t1017 = load i64, i64* %t1009
  %t1018 = icmp slt i64 %t1017, %t1007
  br i1 %t1018, label %set_remove_do_217, label %set_remove_end_218
set_remove_do_217:
  %t1019 = getelementptr inbounds i32, i32* %t1008, i64 %t1017
  %t1020 = sub i64 %t1007, 1
  %t1021 = getelementptr inbounds i32, i32* %t1008, i64 %t1020
  %t1022 = load i32, i32* %t1021
  store i32 %t1022, i32* %t1019
  store i64 %t1020, i64* %t1004
  br label %set_remove_end_218
set_remove_end_218:
  %t1023 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t1024 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t1025 = select i1 %t1018, i8* %t1023, i8* %t1024
  %t1026 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1026, i8* %t1025)
  %t1027 = load i8*, i8** %t705
  %t1028 = icmp eq i8* %t1027, null
  br i1 %t1028, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t1029 = bitcast i8* %t1027 to { i32*, i64, i64 }*
  %t1030 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1029, i32 0, i32 0
  %t1031 = load i32*, i32** %t1030
  %t1032 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1029, i32 0, i32 1
  %t1033 = load i64, i64* %t1032
  br label %set_read_end_221
set_read_end_221:
  %t1034 = phi i32* [ null, %set_read_null_219 ], [ %t1031, %set_read_real_220 ]
  %t1035 = phi i64 [ 0, %set_read_null_219 ], [ %t1033, %set_read_real_220 ]
  store i64 0, i64* %t1036
  store i1 false, i1* %t1037
  br label %find_cond_222
find_cond_222:
  %t1038 = load i64, i64* %t1036
  %t1039 = icmp slt i64 %t1038, %t1035
  br i1 %t1039, label %find_body_223, label %find_end_226
find_body_223:
  %t1040 = getelementptr inbounds i32, i32* %t1034, i64 %t1038
  %t1041 = load i32, i32* %t1040
  br label %find_eq_check_224
find_eq_check_224:
  %t1042 = call i1 @eq_i32(i32 %t1041, i32 2)
  br i1 %t1042, label %find_end_226, label %find_next_225
find_next_225:
  %t1043 = add i64 %t1038, 1
  store i64 %t1043, i64* %t1036
  br label %find_cond_222
find_end_226:
  %t1044 = load i64, i64* %t1036
  %t1045 = icmp slt i64 %t1044, %t1035
  %t1046 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1047 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1048 = select i1 %t1045, i8* %t1046, i8* %t1047
  %t1049 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1049, i8* %t1048)
  %t1050 = getelementptr i32, i32* null, i32 1
  %t1051 = ptrtoint i32* %t1050 to i64
  %t1052 = load i8*, i8** %t705
  %t1053 = icmp eq i8* %t1052, null
  br i1 %t1053, label %set_cow_alloc_227, label %set_cow_check_228
set_cow_alloc_227:
  %t1054 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1055 = call i8* @star_rc_alloc(i64 24, i8* %t1054)
  %t1056 = bitcast i8* %t1055 to { i32*, i64, i64 }*
  %t1057 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1056, i32 0, i32 0
  store i32* null, i32** %t1057
  %t1058 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1056, i32 0, i32 1
  store i64 0, i64* %t1058
  %t1059 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1056, i32 0, i32 2
  store i64 0, i64* %t1059
  store i8* %t1055, i8** %t705
  br label %set_cow_done_229
set_cow_check_228:
  %t1060 = getelementptr inbounds i8, i8* %t1052, i64 -16
  %t1061 = bitcast i8* %t1060 to i64*
  %t1062 = load atomic i64, i64* %t1061 seq_cst, align 8
  %t1063 = icmp eq i64 %t1062, 1
  br i1 %t1063, label %set_cow_done_229, label %set_cow_clone_230
set_cow_clone_230:
  %t1064 = bitcast i8* %t1052 to { i32*, i64, i64 }*
  %t1065 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1064, i32 0, i32 0
  %t1066 = load i32*, i32** %t1065
  %t1067 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1064, i32 0, i32 1
  %t1068 = load i64, i64* %t1067
  %t1069 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1064, i32 0, i32 2
  %t1070 = load i64, i64* %t1069
  %t1071 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1072 = call i8* @star_rc_alloc(i64 24, i8* %t1071)
  %t1073 = bitcast i8* %t1072 to { i32*, i64, i64 }*
  %t1074 = mul i64 %t1070, %t1051
  %t1075 = call i8* @malloc(i64 %t1074)
  %t1076 = bitcast i8* %t1075 to i32*
  %t1077 = icmp sgt i64 %t1068, 0
  br i1 %t1077, label %set_cow_copy_231, label %set_cow_after_copy_232
set_cow_copy_231:
  %t1078 = mul i64 %t1068, %t1051
  %t1079 = bitcast i32* %t1066 to i8*
  call i8* @memcpy(i8* %t1075, i8* %t1079, i64 %t1078)
  br label %set_cow_after_copy_232
set_cow_after_copy_232:
  %t1080 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1073, i32 0, i32 0
  store i32* %t1076, i32** %t1080
  %t1081 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1073, i32 0, i32 1
  store i64 %t1068, i64* %t1081
  %t1082 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1073, i32 0, i32 2
  store i64 %t1070, i64* %t1082
  call void @star_rc_release(i8* %t1052)
  store i8* %t1072, i8** %t705
  br label %set_cow_done_229
set_cow_done_229:
  %t1083 = load i8*, i8** %t705
  %t1084 = bitcast i8* %t1083 to { i32*, i64, i64 }*
  %t1085 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1084, i32 0, i32 0
  %t1086 = load i32*, i32** %t1085
  %t1087 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1084, i32 0, i32 1
  %t1088 = load i64, i64* %t1087
  %t1089 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1084, i32 0, i32 2
  %t1090 = load i64, i64* %t1087
  %t1091 = load i32*, i32** %t1085
  store i64 0, i64* %t1092
  store i1 false, i1* %t1093
  br label %find_cond_233
find_cond_233:
  %t1094 = load i64, i64* %t1092
  %t1095 = icmp slt i64 %t1094, %t1090
  br i1 %t1095, label %find_body_234, label %find_end_237
find_body_234:
  %t1096 = getelementptr inbounds i32, i32* %t1091, i64 %t1094
  %t1097 = load i32, i32* %t1096
  br label %find_eq_check_235
find_eq_check_235:
  %t1098 = call i1 @eq_i32(i32 %t1097, i32 2)
  br i1 %t1098, label %find_end_237, label %find_next_236
find_next_236:
  %t1099 = add i64 %t1094, 1
  store i64 %t1099, i64* %t1092
  br label %find_cond_233
find_end_237:
  %t1100 = load i64, i64* %t1092
  %t1101 = icmp slt i64 %t1100, %t1090
  br i1 %t1101, label %set_remove_do_238, label %set_remove_end_239
set_remove_do_238:
  %t1102 = getelementptr inbounds i32, i32* %t1091, i64 %t1100
  %t1103 = sub i64 %t1090, 1
  %t1104 = getelementptr inbounds i32, i32* %t1091, i64 %t1103
  %t1105 = load i32, i32* %t1104
  store i32 %t1105, i32* %t1102
  store i64 %t1103, i64* %t1087
  br label %set_remove_end_239
set_remove_end_239:
  %t1106 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1107 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1108 = select i1 %t1101, i8* %t1106, i8* %t1107
  %t1109 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1109, i8* %t1108)
  %t1110 = load i8*, i8** %t705
  %t1111 = icmp eq i8* %t1110, null
  br i1 %t1111, label %set_read_null_240, label %set_read_real_241
set_read_null_240:
  br label %set_read_end_242
set_read_real_241:
  %t1112 = bitcast i8* %t1110 to { i32*, i64, i64 }*
  %t1113 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1112, i32 0, i32 0
  %t1114 = load i32*, i32** %t1113
  %t1115 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1112, i32 0, i32 1
  %t1116 = load i64, i64* %t1115
  br label %set_read_end_242
set_read_end_242:
  %t1117 = phi i32* [ null, %set_read_null_240 ], [ %t1114, %set_read_real_241 ]
  %t1118 = phi i64 [ 0, %set_read_null_240 ], [ %t1116, %set_read_real_241 ]
  %t1119 = trunc i64 %t1118 to i32
  %t1120 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1120, i32 %t1119)
  store i8* null, i8** %t1121
  %t1122 = getelementptr %Point, %Point* null, i32 1
  %t1123 = ptrtoint %Point* %t1122 to i64
  %t1124 = load i8*, i8** %t1121
  %t1125 = icmp eq i8* %t1124, null
  br i1 %t1125, label %set_cow_alloc_243, label %set_cow_check_244
set_cow_alloc_243:
  %t1130 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1131 = call i8* @star_rc_alloc(i64 24, i8* %t1130)
  %t1132 = bitcast i8* %t1131 to { %Point*, i64, i64 }*
  %t1133 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1132, i32 0, i32 0
  store %Point* null, %Point** %t1133
  %t1134 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1132, i32 0, i32 1
  store i64 0, i64* %t1134
  %t1135 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1132, i32 0, i32 2
  store i64 0, i64* %t1135
  store i8* %t1131, i8** %t1121
  br label %set_cow_done_245
set_cow_check_244:
  %t1136 = getelementptr inbounds i8, i8* %t1124, i64 -16
  %t1137 = bitcast i8* %t1136 to i64*
  %t1138 = load atomic i64, i64* %t1137 seq_cst, align 8
  %t1139 = icmp eq i64 %t1138, 1
  br i1 %t1139, label %set_cow_done_245, label %set_cow_clone_246
set_cow_clone_246:
  %t1140 = bitcast i8* %t1124 to { %Point*, i64, i64 }*
  %t1141 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1140, i32 0, i32 0
  %t1142 = load %Point*, %Point** %t1141
  %t1143 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1140, i32 0, i32 1
  %t1144 = load i64, i64* %t1143
  %t1145 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1140, i32 0, i32 2
  %t1146 = load i64, i64* %t1145
  %t1147 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1148 = call i8* @star_rc_alloc(i64 24, i8* %t1147)
  %t1149 = bitcast i8* %t1148 to { %Point*, i64, i64 }*
  %t1150 = mul i64 %t1146, %t1123
  %t1151 = call i8* @malloc(i64 %t1150)
  %t1152 = bitcast i8* %t1151 to %Point*
  %t1153 = icmp sgt i64 %t1144, 0
  br i1 %t1153, label %set_cow_copy_247, label %set_cow_after_copy_248
set_cow_copy_247:
  %t1154 = mul i64 %t1144, %t1123
  %t1155 = bitcast %Point* %t1142 to i8*
  call i8* @memcpy(i8* %t1151, i8* %t1155, i64 %t1154)
  br label %set_cow_after_copy_248
set_cow_after_copy_248:
  %t1156 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1149, i32 0, i32 0
  store %Point* %t1152, %Point** %t1156
  %t1157 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1149, i32 0, i32 1
  store i64 %t1144, i64* %t1157
  %t1158 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1149, i32 0, i32 2
  store i64 %t1146, i64* %t1158
  call void @star_rc_release(i8* %t1124)
  store i8* %t1148, i8** %t1121
  br label %set_cow_done_245
set_cow_done_245:
  %t1159 = load i8*, i8** %t1121
  %t1160 = bitcast i8* %t1159 to { %Point*, i64, i64 }*
  %t1161 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1160, i32 0, i32 0
  %t1162 = load %Point*, %Point** %t1161
  %t1163 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1160, i32 0, i32 1
  %t1164 = load i64, i64* %t1163
  %t1165 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1160, i32 0, i32 2
  %t1167 = getelementptr inbounds %Point, %Point* %t1166, i32 0, i32 0
  store i32 1, i32* %t1167
  %t1168 = getelementptr inbounds %Point, %Point* %t1166, i32 0, i32 1
  store i32 2, i32* %t1168
  %t1169 = load %Point, %Point* %t1166
  %t1170 = load i64, i64* %t1163
  %t1171 = load %Point*, %Point** %t1161
  store i64 0, i64* %t1179
  store i1 false, i1* %t1180
  br label %find_cond_249
find_cond_249:
  %t1181 = load i64, i64* %t1179
  %t1182 = icmp slt i64 %t1181, %t1170
  br i1 %t1182, label %find_body_250, label %find_end_253
find_body_250:
  %t1183 = getelementptr inbounds %Point, %Point* %t1171, i64 %t1181
  %t1184 = load %Point, %Point* %t1183
  br label %find_eq_check_251
find_eq_check_251:
  %t1185 = call i1 @eq_s_Point(%Point %t1184, %Point %t1169)
  br i1 %t1185, label %find_end_253, label %find_next_252
find_next_252:
  %t1186 = add i64 %t1181, 1
  store i64 %t1186, i64* %t1179
  br label %find_cond_249
find_end_253:
  %t1187 = load i64, i64* %t1179
  %t1188 = icmp slt i64 %t1187, %t1170
  br i1 %t1188, label %set_insert_already_present_254, label %set_insert_do_255
set_insert_already_present_254:
  br label %set_insert_end_256
set_insert_do_255:
  %t1189 = load i64, i64* %t1165
  %t1190 = load %Point*, %Point** %t1161
  %t1191 = icmp sge i64 %t1170, %t1189
  br i1 %t1191, label %set_insert_grow_257, label %set_insert_store_258
set_insert_grow_257:
  %t1192 = mul i64 %t1189, 2
  %t1193 = icmp sgt i64 %t1192, 0
  %t1194 = select i1 %t1193, i64 %t1192, i64 1
  %t1195 = getelementptr %Point, %Point* null, i32 1
  %t1196 = ptrtoint %Point* %t1195 to i64
  %t1197 = mul i64 %t1194, %t1196
  %t1198 = call i8* @malloc(i64 %t1197)
  %t1199 = bitcast i8* %t1198 to %Point*
  %t1200 = icmp sgt i64 %t1189, 0
  br i1 %t1200, label %set_insert_copy_259, label %set_insert_after_copy_260
set_insert_copy_259:
  %t1201 = mul i64 %t1170, %t1196
  %t1202 = bitcast %Point* %t1190 to i8*
  call i8* @memcpy(i8* %t1198, i8* %t1202, i64 %t1201)
  call void @free(i8* %t1202)
  br label %set_insert_after_copy_260
set_insert_after_copy_260:
  store %Point* %t1199, %Point** %t1161
  store i64 %t1194, i64* %t1165
  br label %set_insert_store_258
set_insert_store_258:
  %t1203 = load %Point*, %Point** %t1161
  %t1204 = getelementptr inbounds %Point, %Point* %t1203, i64 %t1170
  store %Point %t1169, %Point* %t1204
  %t1205 = add i64 %t1170, 1
  store i64 %t1205, i64* %t1163
  br label %set_insert_end_256
set_insert_end_256:
  %t1206 = phi i1 [ false, %set_insert_already_present_254 ], [ true, %set_insert_store_258 ]
  %t1207 = getelementptr %Point, %Point* null, i32 1
  %t1208 = ptrtoint %Point* %t1207 to i64
  %t1209 = load i8*, i8** %t1121
  %t1210 = icmp eq i8* %t1209, null
  br i1 %t1210, label %set_cow_alloc_261, label %set_cow_check_262
set_cow_alloc_261:
  %t1211 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1212 = call i8* @star_rc_alloc(i64 24, i8* %t1211)
  %t1213 = bitcast i8* %t1212 to { %Point*, i64, i64 }*
  %t1214 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 0
  store %Point* null, %Point** %t1214
  %t1215 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 1
  store i64 0, i64* %t1215
  %t1216 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 2
  store i64 0, i64* %t1216
  store i8* %t1212, i8** %t1121
  br label %set_cow_done_263
set_cow_check_262:
  %t1217 = getelementptr inbounds i8, i8* %t1209, i64 -16
  %t1218 = bitcast i8* %t1217 to i64*
  %t1219 = load atomic i64, i64* %t1218 seq_cst, align 8
  %t1220 = icmp eq i64 %t1219, 1
  br i1 %t1220, label %set_cow_done_263, label %set_cow_clone_264
set_cow_clone_264:
  %t1221 = bitcast i8* %t1209 to { %Point*, i64, i64 }*
  %t1222 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1221, i32 0, i32 0
  %t1223 = load %Point*, %Point** %t1222
  %t1224 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1221, i32 0, i32 1
  %t1225 = load i64, i64* %t1224
  %t1226 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1221, i32 0, i32 2
  %t1227 = load i64, i64* %t1226
  %t1228 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1229 = call i8* @star_rc_alloc(i64 24, i8* %t1228)
  %t1230 = bitcast i8* %t1229 to { %Point*, i64, i64 }*
  %t1231 = mul i64 %t1227, %t1208
  %t1232 = call i8* @malloc(i64 %t1231)
  %t1233 = bitcast i8* %t1232 to %Point*
  %t1234 = icmp sgt i64 %t1225, 0
  br i1 %t1234, label %set_cow_copy_265, label %set_cow_after_copy_266
set_cow_copy_265:
  %t1235 = mul i64 %t1225, %t1208
  %t1236 = bitcast %Point* %t1223 to i8*
  call i8* @memcpy(i8* %t1232, i8* %t1236, i64 %t1235)
  br label %set_cow_after_copy_266
set_cow_after_copy_266:
  %t1237 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1230, i32 0, i32 0
  store %Point* %t1233, %Point** %t1237
  %t1238 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1230, i32 0, i32 1
  store i64 %t1225, i64* %t1238
  %t1239 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1230, i32 0, i32 2
  store i64 %t1227, i64* %t1239
  call void @star_rc_release(i8* %t1209)
  store i8* %t1229, i8** %t1121
  br label %set_cow_done_263
set_cow_done_263:
  %t1240 = load i8*, i8** %t1121
  %t1241 = bitcast i8* %t1240 to { %Point*, i64, i64 }*
  %t1242 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1241, i32 0, i32 0
  %t1243 = load %Point*, %Point** %t1242
  %t1244 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1241, i32 0, i32 1
  %t1245 = load i64, i64* %t1244
  %t1246 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1241, i32 0, i32 2
  %t1248 = getelementptr inbounds %Point, %Point* %t1247, i32 0, i32 0
  store i32 1, i32* %t1248
  %t1249 = getelementptr inbounds %Point, %Point* %t1247, i32 0, i32 1
  store i32 2, i32* %t1249
  %t1250 = load %Point, %Point* %t1247
  %t1251 = load i64, i64* %t1244
  %t1252 = load %Point*, %Point** %t1242
  store i64 0, i64* %t1253
  store i1 false, i1* %t1254
  br label %find_cond_267
find_cond_267:
  %t1255 = load i64, i64* %t1253
  %t1256 = icmp slt i64 %t1255, %t1251
  br i1 %t1256, label %find_body_268, label %find_end_271
find_body_268:
  %t1257 = getelementptr inbounds %Point, %Point* %t1252, i64 %t1255
  %t1258 = load %Point, %Point* %t1257
  br label %find_eq_check_269
find_eq_check_269:
  %t1259 = call i1 @eq_s_Point(%Point %t1258, %Point %t1250)
  br i1 %t1259, label %find_end_271, label %find_next_270
find_next_270:
  %t1260 = add i64 %t1255, 1
  store i64 %t1260, i64* %t1253
  br label %find_cond_267
find_end_271:
  %t1261 = load i64, i64* %t1253
  %t1262 = icmp slt i64 %t1261, %t1251
  br i1 %t1262, label %set_insert_already_present_272, label %set_insert_do_273
set_insert_already_present_272:
  br label %set_insert_end_274
set_insert_do_273:
  %t1263 = load i64, i64* %t1246
  %t1264 = load %Point*, %Point** %t1242
  %t1265 = icmp sge i64 %t1251, %t1263
  br i1 %t1265, label %set_insert_grow_275, label %set_insert_store_276
set_insert_grow_275:
  %t1266 = mul i64 %t1263, 2
  %t1267 = icmp sgt i64 %t1266, 0
  %t1268 = select i1 %t1267, i64 %t1266, i64 1
  %t1269 = getelementptr %Point, %Point* null, i32 1
  %t1270 = ptrtoint %Point* %t1269 to i64
  %t1271 = mul i64 %t1268, %t1270
  %t1272 = call i8* @malloc(i64 %t1271)
  %t1273 = bitcast i8* %t1272 to %Point*
  %t1274 = icmp sgt i64 %t1263, 0
  br i1 %t1274, label %set_insert_copy_277, label %set_insert_after_copy_278
set_insert_copy_277:
  %t1275 = mul i64 %t1251, %t1270
  %t1276 = bitcast %Point* %t1264 to i8*
  call i8* @memcpy(i8* %t1272, i8* %t1276, i64 %t1275)
  call void @free(i8* %t1276)
  br label %set_insert_after_copy_278
set_insert_after_copy_278:
  store %Point* %t1273, %Point** %t1242
  store i64 %t1268, i64* %t1246
  br label %set_insert_store_276
set_insert_store_276:
  %t1277 = load %Point*, %Point** %t1242
  %t1278 = getelementptr inbounds %Point, %Point* %t1277, i64 %t1251
  store %Point %t1250, %Point* %t1278
  %t1279 = add i64 %t1251, 1
  store i64 %t1279, i64* %t1244
  br label %set_insert_end_274
set_insert_end_274:
  %t1280 = phi i1 [ false, %set_insert_already_present_272 ], [ true, %set_insert_store_276 ]
  %t1281 = getelementptr %Point, %Point* null, i32 1
  %t1282 = ptrtoint %Point* %t1281 to i64
  %t1283 = load i8*, i8** %t1121
  %t1284 = icmp eq i8* %t1283, null
  br i1 %t1284, label %set_cow_alloc_279, label %set_cow_check_280
set_cow_alloc_279:
  %t1285 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1286 = call i8* @star_rc_alloc(i64 24, i8* %t1285)
  %t1287 = bitcast i8* %t1286 to { %Point*, i64, i64 }*
  %t1288 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1287, i32 0, i32 0
  store %Point* null, %Point** %t1288
  %t1289 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1287, i32 0, i32 1
  store i64 0, i64* %t1289
  %t1290 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1287, i32 0, i32 2
  store i64 0, i64* %t1290
  store i8* %t1286, i8** %t1121
  br label %set_cow_done_281
set_cow_check_280:
  %t1291 = getelementptr inbounds i8, i8* %t1283, i64 -16
  %t1292 = bitcast i8* %t1291 to i64*
  %t1293 = load atomic i64, i64* %t1292 seq_cst, align 8
  %t1294 = icmp eq i64 %t1293, 1
  br i1 %t1294, label %set_cow_done_281, label %set_cow_clone_282
set_cow_clone_282:
  %t1295 = bitcast i8* %t1283 to { %Point*, i64, i64 }*
  %t1296 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1295, i32 0, i32 0
  %t1297 = load %Point*, %Point** %t1296
  %t1298 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1295, i32 0, i32 1
  %t1299 = load i64, i64* %t1298
  %t1300 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1295, i32 0, i32 2
  %t1301 = load i64, i64* %t1300
  %t1302 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1303 = call i8* @star_rc_alloc(i64 24, i8* %t1302)
  %t1304 = bitcast i8* %t1303 to { %Point*, i64, i64 }*
  %t1305 = mul i64 %t1301, %t1282
  %t1306 = call i8* @malloc(i64 %t1305)
  %t1307 = bitcast i8* %t1306 to %Point*
  %t1308 = icmp sgt i64 %t1299, 0
  br i1 %t1308, label %set_cow_copy_283, label %set_cow_after_copy_284
set_cow_copy_283:
  %t1309 = mul i64 %t1299, %t1282
  %t1310 = bitcast %Point* %t1297 to i8*
  call i8* @memcpy(i8* %t1306, i8* %t1310, i64 %t1309)
  br label %set_cow_after_copy_284
set_cow_after_copy_284:
  %t1311 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1304, i32 0, i32 0
  store %Point* %t1307, %Point** %t1311
  %t1312 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1304, i32 0, i32 1
  store i64 %t1299, i64* %t1312
  %t1313 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1304, i32 0, i32 2
  store i64 %t1301, i64* %t1313
  call void @star_rc_release(i8* %t1283)
  store i8* %t1303, i8** %t1121
  br label %set_cow_done_281
set_cow_done_281:
  %t1314 = load i8*, i8** %t1121
  %t1315 = bitcast i8* %t1314 to { %Point*, i64, i64 }*
  %t1316 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1315, i32 0, i32 0
  %t1317 = load %Point*, %Point** %t1316
  %t1318 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1315, i32 0, i32 1
  %t1319 = load i64, i64* %t1318
  %t1320 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1315, i32 0, i32 2
  %t1322 = getelementptr inbounds %Point, %Point* %t1321, i32 0, i32 0
  store i32 3, i32* %t1322
  %t1323 = getelementptr inbounds %Point, %Point* %t1321, i32 0, i32 1
  store i32 4, i32* %t1323
  %t1324 = load %Point, %Point* %t1321
  %t1325 = load i64, i64* %t1318
  %t1326 = load %Point*, %Point** %t1316
  store i64 0, i64* %t1327
  store i1 false, i1* %t1328
  br label %find_cond_285
find_cond_285:
  %t1329 = load i64, i64* %t1327
  %t1330 = icmp slt i64 %t1329, %t1325
  br i1 %t1330, label %find_body_286, label %find_end_289
find_body_286:
  %t1331 = getelementptr inbounds %Point, %Point* %t1326, i64 %t1329
  %t1332 = load %Point, %Point* %t1331
  br label %find_eq_check_287
find_eq_check_287:
  %t1333 = call i1 @eq_s_Point(%Point %t1332, %Point %t1324)
  br i1 %t1333, label %find_end_289, label %find_next_288
find_next_288:
  %t1334 = add i64 %t1329, 1
  store i64 %t1334, i64* %t1327
  br label %find_cond_285
find_end_289:
  %t1335 = load i64, i64* %t1327
  %t1336 = icmp slt i64 %t1335, %t1325
  br i1 %t1336, label %set_insert_already_present_290, label %set_insert_do_291
set_insert_already_present_290:
  br label %set_insert_end_292
set_insert_do_291:
  %t1337 = load i64, i64* %t1320
  %t1338 = load %Point*, %Point** %t1316
  %t1339 = icmp sge i64 %t1325, %t1337
  br i1 %t1339, label %set_insert_grow_293, label %set_insert_store_294
set_insert_grow_293:
  %t1340 = mul i64 %t1337, 2
  %t1341 = icmp sgt i64 %t1340, 0
  %t1342 = select i1 %t1341, i64 %t1340, i64 1
  %t1343 = getelementptr %Point, %Point* null, i32 1
  %t1344 = ptrtoint %Point* %t1343 to i64
  %t1345 = mul i64 %t1342, %t1344
  %t1346 = call i8* @malloc(i64 %t1345)
  %t1347 = bitcast i8* %t1346 to %Point*
  %t1348 = icmp sgt i64 %t1337, 0
  br i1 %t1348, label %set_insert_copy_295, label %set_insert_after_copy_296
set_insert_copy_295:
  %t1349 = mul i64 %t1325, %t1344
  %t1350 = bitcast %Point* %t1338 to i8*
  call i8* @memcpy(i8* %t1346, i8* %t1350, i64 %t1349)
  call void @free(i8* %t1350)
  br label %set_insert_after_copy_296
set_insert_after_copy_296:
  store %Point* %t1347, %Point** %t1316
  store i64 %t1342, i64* %t1320
  br label %set_insert_store_294
set_insert_store_294:
  %t1351 = load %Point*, %Point** %t1316
  %t1352 = getelementptr inbounds %Point, %Point* %t1351, i64 %t1325
  store %Point %t1324, %Point* %t1352
  %t1353 = add i64 %t1325, 1
  store i64 %t1353, i64* %t1318
  br label %set_insert_end_292
set_insert_end_292:
  %t1354 = phi i1 [ false, %set_insert_already_present_290 ], [ true, %set_insert_store_294 ]
  %t1355 = load i8*, i8** %t1121
  %t1356 = icmp eq i8* %t1355, null
  br i1 %t1356, label %set_read_null_297, label %set_read_real_298
set_read_null_297:
  br label %set_read_end_299
set_read_real_298:
  %t1357 = bitcast i8* %t1355 to { %Point*, i64, i64 }*
  %t1358 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1357, i32 0, i32 0
  %t1359 = load %Point*, %Point** %t1358
  %t1360 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1357, i32 0, i32 1
  %t1361 = load i64, i64* %t1360
  br label %set_read_end_299
set_read_end_299:
  %t1362 = phi %Point* [ null, %set_read_null_297 ], [ %t1359, %set_read_real_298 ]
  %t1363 = phi i64 [ 0, %set_read_null_297 ], [ %t1361, %set_read_real_298 ]
  %t1364 = trunc i64 %t1363 to i32
  %t1365 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1365, i32 %t1364)
  %t1367 = getelementptr inbounds %Point, %Point* %t1366, i32 0, i32 0
  store i32 1, i32* %t1367
  %t1368 = getelementptr inbounds %Point, %Point* %t1366, i32 0, i32 1
  store i32 2, i32* %t1368
  %t1369 = load %Point, %Point* %t1366
  %t1370 = load i8*, i8** %t1121
  %t1371 = icmp eq i8* %t1370, null
  br i1 %t1371, label %set_read_null_300, label %set_read_real_301
set_read_null_300:
  br label %set_read_end_302
set_read_real_301:
  %t1372 = bitcast i8* %t1370 to { %Point*, i64, i64 }*
  %t1373 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1372, i32 0, i32 0
  %t1374 = load %Point*, %Point** %t1373
  %t1375 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1372, i32 0, i32 1
  %t1376 = load i64, i64* %t1375
  br label %set_read_end_302
set_read_end_302:
  %t1377 = phi %Point* [ null, %set_read_null_300 ], [ %t1374, %set_read_real_301 ]
  %t1378 = phi i64 [ 0, %set_read_null_300 ], [ %t1376, %set_read_real_301 ]
  store i64 0, i64* %t1379
  store i1 false, i1* %t1380
  br label %find_cond_303
find_cond_303:
  %t1381 = load i64, i64* %t1379
  %t1382 = icmp slt i64 %t1381, %t1378
  br i1 %t1382, label %find_body_304, label %find_end_307
find_body_304:
  %t1383 = getelementptr inbounds %Point, %Point* %t1377, i64 %t1381
  %t1384 = load %Point, %Point* %t1383
  br label %find_eq_check_305
find_eq_check_305:
  %t1385 = call i1 @eq_s_Point(%Point %t1384, %Point %t1369)
  br i1 %t1385, label %find_end_307, label %find_next_306
find_next_306:
  %t1386 = add i64 %t1381, 1
  store i64 %t1386, i64* %t1379
  br label %find_cond_303
find_end_307:
  %t1387 = load i64, i64* %t1379
  %t1388 = icmp slt i64 %t1387, %t1378
  %t1389 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t1390 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t1391 = select i1 %t1388, i8* %t1389, i8* %t1390
  %t1392 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1392, i8* %t1391)
  %t1394 = getelementptr inbounds %Point, %Point* %t1393, i32 0, i32 0
  store i32 9, i32* %t1394
  %t1395 = getelementptr inbounds %Point, %Point* %t1393, i32 0, i32 1
  store i32 9, i32* %t1395
  %t1396 = load %Point, %Point* %t1393
  %t1397 = load i8*, i8** %t1121
  %t1398 = icmp eq i8* %t1397, null
  br i1 %t1398, label %set_read_null_308, label %set_read_real_309
set_read_null_308:
  br label %set_read_end_310
set_read_real_309:
  %t1399 = bitcast i8* %t1397 to { %Point*, i64, i64 }*
  %t1400 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1399, i32 0, i32 0
  %t1401 = load %Point*, %Point** %t1400
  %t1402 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1399, i32 0, i32 1
  %t1403 = load i64, i64* %t1402
  br label %set_read_end_310
set_read_end_310:
  %t1404 = phi %Point* [ null, %set_read_null_308 ], [ %t1401, %set_read_real_309 ]
  %t1405 = phi i64 [ 0, %set_read_null_308 ], [ %t1403, %set_read_real_309 ]
  store i64 0, i64* %t1406
  store i1 false, i1* %t1407
  br label %find_cond_311
find_cond_311:
  %t1408 = load i64, i64* %t1406
  %t1409 = icmp slt i64 %t1408, %t1405
  br i1 %t1409, label %find_body_312, label %find_end_315
find_body_312:
  %t1410 = getelementptr inbounds %Point, %Point* %t1404, i64 %t1408
  %t1411 = load %Point, %Point* %t1410
  br label %find_eq_check_313
find_eq_check_313:
  %t1412 = call i1 @eq_s_Point(%Point %t1411, %Point %t1396)
  br i1 %t1412, label %find_end_315, label %find_next_314
find_next_314:
  %t1413 = add i64 %t1408, 1
  store i64 %t1413, i64* %t1406
  br label %find_cond_311
find_end_315:
  %t1414 = load i64, i64* %t1406
  %t1415 = icmp slt i64 %t1414, %t1405
  %t1416 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1417 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1418 = select i1 %t1415, i8* %t1416, i8* %t1417
  %t1419 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1419, i8* %t1418)
  %t1420 = load i8*, i8** %t1121
  call void @star_rc_release(i8* %t1420)
  %t1421 = load i8*, i8** %t705
  call void @star_rc_release(i8* %t1421)
  %t1422 = load i8*, i8** %t521
  call void @star_rc_release(i8* %t1422)
  %t1423 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t1423)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_3_stri32(i8* %objp) {
entry:
  %t15 = alloca i64
  %t8 = bitcast i8* %objp to { i8**, i32*, i64, i64 }*
  %t9 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t8, i32 0, i32 0
  %t10 = load i8**, i8*** %t9
  %t11 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t8, i32 0, i32 1
  %t12 = load i32*, i32** %t11
  %t13 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t8, i32 0, i32 2
  %t14 = load i64, i64* %t13
  store i64 0, i64* %t15
  br label %map_release_cond_3
map_release_cond_3:
  %t16 = load i64, i64* %t15
  %t17 = icmp slt i64 %t16, %t14
  br i1 %t17, label %map_release_body_4, label %map_release_end_5
map_release_body_4:
  %t18 = getelementptr inbounds i8*, i8** %t10, i64 %t16
  %t19 = load i8*, i8** %t18
  call void @star_rc_release(i8* %t19)
  %t20 = add i64 %t16, 1
  store i64 %t20, i64* %t15
  br label %map_release_cond_3
map_release_end_5:
  %t21 = bitcast i8** %t10 to i8*
  call void @free(i8* %t21)
  %t22 = bitcast i32* %t12 to i8*
  call void @free(i8* %t22)
  ret void
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t79 = call i32 @strcmp(i8* %a, i8* %b)
  %t80 = icmp eq i32 %t79, 0
  ret i1 %t80
}


define void @set_release_i32(i8* %objp) {
entry:
  %t710 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t711 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t710, i32 0, i32 0
  %t712 = load i32*, i32** %t711
  %t713 = bitcast i32* %t712 to i8*
  call void @free(i8* %t713)
  ret void
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t752 = icmp eq i32 %a, %b
  ret i1 %t752
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1126 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t1127 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1126, i32 0, i32 0
  %t1128 = load %Point*, %Point** %t1127
  %t1129 = bitcast %Point* %t1128 to i8*
  call void @free(i8* %t1129)
  ret void
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t1172 = extractvalue %Point %a, 0
  %t1173 = extractvalue %Point %b, 0
  %t1174 = icmp eq i32 %t1172, %t1173
  %t1175 = extractvalue %Point %a, 1
  %t1176 = extractvalue %Point %b, 1
  %t1177 = icmp eq i32 %t1175, %t1176
  %t1178 = and i1 %t1174, %t1177
  ret i1 %t1178
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.2 = private unnamed_addr constant [25 x i8] c"len after 2 inserts: %d\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.4 = private unnamed_addr constant [11 x i8] c"alice: %d\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.6 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"carol\00" }
@.str.8 = private unnamed_addr constant [11 x i8] c"carol: %d\0A\00"
@.str.9 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"carol: missing\00" }
@.str.10 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.12 = private unnamed_addr constant [25 x i8] c"len after overwrite: %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.14 = private unnamed_addr constant [27 x i8] c"alice after overwrite: %d\0A\00"
@.str.15 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.16 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [18 x i8] c"contains bob: %s\0A\00"
@.str.21 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.22 = private unnamed_addr constant [17 x i8] c"removed bob: %d\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"bob: missing\00" }
@.str.24 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.25 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.26 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.27 = private unnamed_addr constant [31 x i8] c"contains bob after remove: %s\0A\00"
@.str.28 = private unnamed_addr constant [22 x i8] c"len after remove: %d\0A\00"
@.str.29 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.30 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.31 = private unnamed_addr constant [20 x i8] c"insert 1 (new): %s\0A\00"
@.str.32 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.33 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.34 = private unnamed_addr constant [20 x i8] c"insert 2 (new): %s\0A\00"
@.str.35 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.36 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.37 = private unnamed_addr constant [20 x i8] c"insert 1 (dup): %s\0A\00"
@.str.38 = private unnamed_addr constant [13 x i8] c"set len: %d\0A\00"
@.str.39 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.40 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.41 = private unnamed_addr constant [16 x i8] c"contains 2: %s\0A\00"
@.str.42 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.43 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.44 = private unnamed_addr constant [14 x i8] c"remove 2: %s\0A\00"
@.str.45 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.46 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.47 = private unnamed_addr constant [29 x i8] c"contains 2 after remove: %s\0A\00"
@.str.48 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.49 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.50 = private unnamed_addr constant [20 x i8] c"remove 2 again: %s\0A\00"
@.str.51 = private unnamed_addr constant [27 x i8] c"set len after removes: %d\0A\00"
@.str.52 = private unnamed_addr constant [20 x i8] c"struct set len: %d\0A\00"
@.str.53 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.54 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.55 = private unnamed_addr constant [20 x i8] c"contains (1,2): %s\0A\00"
@.str.56 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.57 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.58 = private unnamed_addr constant [20 x i8] c"contains (9,9): %s\0A\00"
