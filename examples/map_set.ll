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
  %t0 = alloca i8*
  %t56 = alloca i64
  %t80 = alloca i64
  %t158 = alloca i64
  %t180 = alloca i64
  %t245 = alloca i64
  %t256 = alloca %Option__i32
  %t262 = alloca %Option__i32
  %t266 = alloca %Option__i32
  %t299 = alloca i64
  %t310 = alloca %Option__i32
  %t316 = alloca %Option__i32
  %t320 = alloca %Option__i32
  %t380 = alloca i64
  %t402 = alloca i64
  %t467 = alloca i64
  %t478 = alloca %Option__i32
  %t484 = alloca %Option__i32
  %t488 = alloca %Option__i32
  %t508 = alloca i8*
  %t524 = alloca i64
  %t533 = alloca i8*
  %t580 = alloca i64
  %t599 = alloca i64
  %t617 = alloca %Option__i32
  %t623 = alloca %Option__i32
  %t627 = alloca %Option__i32
  %t661 = alloca i64
  %t670 = alloca i8*
  %t690 = alloca i8*
  %t738 = alloca i64
  %t739 = alloca i1
  %t812 = alloca i64
  %t813 = alloca i1
  %t886 = alloca i64
  %t887 = alloca i1
  %t938 = alloca i64
  %t939 = alloca i1
  %t994 = alloca i64
  %t995 = alloca i1
  %t1021 = alloca i64
  %t1022 = alloca i1
  %t1077 = alloca i64
  %t1078 = alloca i1
  %t1106 = alloca i8*
  %t1151 = alloca %Point
  %t1164 = alloca i64
  %t1165 = alloca i1
  %t1232 = alloca %Point
  %t1238 = alloca i64
  %t1239 = alloca i1
  %t1306 = alloca %Point
  %t1312 = alloca i64
  %t1313 = alloca i1
  %t1351 = alloca %Point
  %t1364 = alloca i64
  %t1365 = alloca i1
  %t1378 = alloca %Point
  %t1391 = alloca i64
  %t1392 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store i8* null, i8** %t0
  %t1 = getelementptr i8*, i8** null, i32 1
  %t2 = ptrtoint i8** %t1 to i64
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = load i8*, i8** %t0
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t22 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t23 = call i8* @star_rc_alloc(i64 32, i8* %t22)
  %t24 = bitcast i8* %t23 to { i8**, i32*, i64, i64 }*
  %t25 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 0
  store i8** null, i8*** %t25
  %t26 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 1
  store i32* null, i32** %t26
  %t27 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 2
  store i64 0, i64* %t27
  %t28 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 3
  store i64 0, i64* %t28
  store i8* %t23, i8** %t0
  br label %map_cow_done_2
map_cow_check_1:
  %t29 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t30 = bitcast i8* %t29 to i64*
  %t31 = load atomic i64, i64* %t30 seq_cst, align 8
  %t32 = icmp eq i64 %t31, 1
  br i1 %t32, label %map_cow_done_2, label %map_cow_clone_6
map_cow_clone_6:
  %t33 = bitcast i8* %t5 to { i8**, i32*, i64, i64 }*
  %t34 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 0
  %t35 = load i8**, i8*** %t34
  %t36 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 1
  %t37 = load i32*, i32** %t36
  %t38 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 2
  %t39 = load i64, i64* %t38
  %t40 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 3
  %t41 = load i64, i64* %t40
  %t42 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t43 = call i8* @star_rc_alloc(i64 32, i8* %t42)
  %t44 = bitcast i8* %t43 to { i8**, i32*, i64, i64 }*
  %t45 = mul i64 %t41, %t2
  %t46 = call i8* @malloc(i64 %t45)
  %t47 = bitcast i8* %t46 to i8**
  %t48 = mul i64 %t41, %t4
  %t49 = call i8* @malloc(i64 %t48)
  %t50 = bitcast i8* %t49 to i32*
  %t51 = icmp sgt i64 %t39, 0
  br i1 %t51, label %map_cow_copy_7, label %map_cow_after_copy_8
map_cow_copy_7:
  %t52 = mul i64 %t39, %t2
  %t53 = bitcast i8** %t35 to i8*
  call i8* @memcpy(i8* %t46, i8* %t53, i64 %t52)
  %t54 = mul i64 %t39, %t4
  %t55 = bitcast i32* %t37 to i8*
  call i8* @memcpy(i8* %t49, i8* %t55, i64 %t54)
  store i64 0, i64* %t56
  br label %map_cow_retain_cond_9
map_cow_retain_cond_9:
  %t57 = load i64, i64* %t56
  %t58 = icmp slt i64 %t57, %t39
  br i1 %t58, label %map_cow_retain_body_10, label %map_cow_retain_end_11
map_cow_retain_body_10:
  %t59 = getelementptr inbounds i8*, i8** %t47, i64 %t57
  %t60 = load i8*, i8** %t59
  call void @star_rc_retain(i8* %t60)
  %t61 = add i64 %t57, 1
  store i64 %t61, i64* %t56
  br label %map_cow_retain_cond_9
map_cow_retain_end_11:
  br label %map_cow_after_copy_8
map_cow_after_copy_8:
  %t62 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 0
  store i8** %t47, i8*** %t62
  %t63 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 1
  store i32* %t50, i32** %t63
  %t64 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 2
  store i64 %t39, i64* %t64
  %t65 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 3
  store i64 %t41, i64* %t65
  call void @star_rc_release(i8* %t5)
  store i8* %t43, i8** %t0
  br label %map_cow_done_2
map_cow_done_2:
  %t66 = load i8*, i8** %t0
  %t67 = bitcast i8* %t66 to { i8**, i32*, i64, i64 }*
  %t68 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 0
  %t69 = load i8**, i8*** %t68
  %t70 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 1
  %t71 = load i32*, i32** %t70
  %t72 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 2
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 3
  %t75 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t76 = load i64, i64* %t72
  %t77 = load i8**, i8*** %t68
  store i64 0, i64* %t80
  br label %map_find_cond_12
map_find_cond_12:
  %t81 = load i64, i64* %t80
  %t82 = icmp slt i64 %t81, %t76
  br i1 %t82, label %map_find_body_13, label %map_find_end_16
map_find_body_13:
  %t83 = getelementptr inbounds i8*, i8** %t77, i64 %t81
  %t84 = load i8*, i8** %t83
  br label %map_find_eq_check_14
map_find_eq_check_14:
  %t85 = call i1 @eq_str(i8* %t84, i8* %t75)
  br i1 %t85, label %map_find_end_16, label %map_find_next_15
map_find_next_15:
  %t86 = add i64 %t81, 1
  store i64 %t86, i64* %t80
  br label %map_find_cond_12
map_find_end_16:
  %t87 = load i64, i64* %t80
  %t88 = icmp slt i64 %t87, %t76
  br i1 %t88, label %map_insert_overwrite_17, label %map_insert_new_18
map_insert_overwrite_17:
  %t89 = load i32*, i32** %t70
  %t90 = getelementptr inbounds i32, i32* %t89, i64 %t87
  store i32 30, i32* %t90
  br label %map_insert_after_19
map_insert_new_18:
  %t91 = load i64, i64* %t74
  %t92 = icmp sge i64 %t76, %t91
  br i1 %t92, label %map_insert_grow_20, label %map_insert_store_21
map_insert_grow_20:
  %t93 = mul i64 %t91, 2
  %t94 = icmp sgt i64 %t93, 0
  %t95 = select i1 %t94, i64 %t93, i64 1
  %t96 = getelementptr i8*, i8** null, i32 1
  %t97 = ptrtoint i8** %t96 to i64
  %t98 = mul i64 %t95, %t97
  %t99 = call i8* @malloc(i64 %t98)
  %t100 = bitcast i8* %t99 to i8**
  %t101 = getelementptr i32, i32* null, i32 1
  %t102 = ptrtoint i32* %t101 to i64
  %t103 = mul i64 %t95, %t102
  %t104 = call i8* @malloc(i64 %t103)
  %t105 = bitcast i8* %t104 to i32*
  %t106 = icmp sgt i64 %t91, 0
  br i1 %t106, label %map_insert_copy_22, label %map_insert_after_copy_23
map_insert_copy_22:
  %t107 = load i8**, i8*** %t68
  %t108 = mul i64 %t76, %t97
  %t109 = bitcast i8** %t107 to i8*
  call i8* @memcpy(i8* %t99, i8* %t109, i64 %t108)
  call void @free(i8* %t109)
  %t110 = load i32*, i32** %t70
  %t111 = mul i64 %t76, %t102
  %t112 = bitcast i32* %t110 to i8*
  call i8* @memcpy(i8* %t104, i8* %t112, i64 %t111)
  call void @free(i8* %t112)
  br label %map_insert_after_copy_23
map_insert_after_copy_23:
  store i8** %t100, i8*** %t68
  store i32* %t105, i32** %t70
  store i64 %t95, i64* %t74
  br label %map_insert_store_21
map_insert_store_21:
  %t113 = load i8**, i8*** %t68
  %t114 = load i32*, i32** %t70
  %t115 = getelementptr inbounds i8*, i8** %t113, i64 %t76
  store i8* %t75, i8** %t115
  %t116 = getelementptr inbounds i32, i32* %t114, i64 %t76
  store i32 30, i32* %t116
  %t117 = add i64 %t76, 1
  store i64 %t117, i64* %t72
  br label %map_insert_after_19
map_insert_after_19:
  %t118 = getelementptr i8*, i8** null, i32 1
  %t119 = ptrtoint i8** %t118 to i64
  %t120 = getelementptr i32, i32* null, i32 1
  %t121 = ptrtoint i32* %t120 to i64
  %t122 = load i8*, i8** %t0
  %t123 = icmp eq i8* %t122, null
  br i1 %t123, label %map_cow_alloc_24, label %map_cow_check_25
map_cow_alloc_24:
  %t124 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t125 = call i8* @star_rc_alloc(i64 32, i8* %t124)
  %t126 = bitcast i8* %t125 to { i8**, i32*, i64, i64 }*
  %t127 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t126, i32 0, i32 0
  store i8** null, i8*** %t127
  %t128 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t126, i32 0, i32 1
  store i32* null, i32** %t128
  %t129 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t126, i32 0, i32 2
  store i64 0, i64* %t129
  %t130 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t126, i32 0, i32 3
  store i64 0, i64* %t130
  store i8* %t125, i8** %t0
  br label %map_cow_done_26
map_cow_check_25:
  %t131 = getelementptr inbounds i8, i8* %t122, i64 -16
  %t132 = bitcast i8* %t131 to i64*
  %t133 = load atomic i64, i64* %t132 seq_cst, align 8
  %t134 = icmp eq i64 %t133, 1
  br i1 %t134, label %map_cow_done_26, label %map_cow_clone_27
map_cow_clone_27:
  %t135 = bitcast i8* %t122 to { i8**, i32*, i64, i64 }*
  %t136 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load i8**, i8*** %t136
  %t138 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t135, i32 0, i32 1
  %t139 = load i32*, i32** %t138
  %t140 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t135, i32 0, i32 2
  %t141 = load i64, i64* %t140
  %t142 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t135, i32 0, i32 3
  %t143 = load i64, i64* %t142
  %t144 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t145 = call i8* @star_rc_alloc(i64 32, i8* %t144)
  %t146 = bitcast i8* %t145 to { i8**, i32*, i64, i64 }*
  %t147 = mul i64 %t143, %t119
  %t148 = call i8* @malloc(i64 %t147)
  %t149 = bitcast i8* %t148 to i8**
  %t150 = mul i64 %t143, %t121
  %t151 = call i8* @malloc(i64 %t150)
  %t152 = bitcast i8* %t151 to i32*
  %t153 = icmp sgt i64 %t141, 0
  br i1 %t153, label %map_cow_copy_28, label %map_cow_after_copy_29
map_cow_copy_28:
  %t154 = mul i64 %t141, %t119
  %t155 = bitcast i8** %t137 to i8*
  call i8* @memcpy(i8* %t148, i8* %t155, i64 %t154)
  %t156 = mul i64 %t141, %t121
  %t157 = bitcast i32* %t139 to i8*
  call i8* @memcpy(i8* %t151, i8* %t157, i64 %t156)
  store i64 0, i64* %t158
  br label %map_cow_retain_cond_30
map_cow_retain_cond_30:
  %t159 = load i64, i64* %t158
  %t160 = icmp slt i64 %t159, %t141
  br i1 %t160, label %map_cow_retain_body_31, label %map_cow_retain_end_32
map_cow_retain_body_31:
  %t161 = getelementptr inbounds i8*, i8** %t149, i64 %t159
  %t162 = load i8*, i8** %t161
  call void @star_rc_retain(i8* %t162)
  %t163 = add i64 %t159, 1
  store i64 %t163, i64* %t158
  br label %map_cow_retain_cond_30
map_cow_retain_end_32:
  br label %map_cow_after_copy_29
map_cow_after_copy_29:
  %t164 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t146, i32 0, i32 0
  store i8** %t149, i8*** %t164
  %t165 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t146, i32 0, i32 1
  store i32* %t152, i32** %t165
  %t166 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t146, i32 0, i32 2
  store i64 %t141, i64* %t166
  %t167 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t146, i32 0, i32 3
  store i64 %t143, i64* %t167
  call void @star_rc_release(i8* %t122)
  store i8* %t145, i8** %t0
  br label %map_cow_done_26
map_cow_done_26:
  %t168 = load i8*, i8** %t0
  %t169 = bitcast i8* %t168 to { i8**, i32*, i64, i64 }*
  %t170 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t169, i32 0, i32 0
  %t171 = load i8**, i8*** %t170
  %t172 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t169, i32 0, i32 1
  %t173 = load i32*, i32** %t172
  %t174 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t169, i32 0, i32 2
  %t175 = load i64, i64* %t174
  %t176 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t169, i32 0, i32 3
  %t177 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t178 = load i64, i64* %t174
  %t179 = load i8**, i8*** %t170
  store i64 0, i64* %t180
  br label %map_find_cond_33
map_find_cond_33:
  %t181 = load i64, i64* %t180
  %t182 = icmp slt i64 %t181, %t178
  br i1 %t182, label %map_find_body_34, label %map_find_end_37
map_find_body_34:
  %t183 = getelementptr inbounds i8*, i8** %t179, i64 %t181
  %t184 = load i8*, i8** %t183
  br label %map_find_eq_check_35
map_find_eq_check_35:
  %t185 = call i1 @eq_str(i8* %t184, i8* %t177)
  br i1 %t185, label %map_find_end_37, label %map_find_next_36
map_find_next_36:
  %t186 = add i64 %t181, 1
  store i64 %t186, i64* %t180
  br label %map_find_cond_33
map_find_end_37:
  %t187 = load i64, i64* %t180
  %t188 = icmp slt i64 %t187, %t178
  br i1 %t188, label %map_insert_overwrite_38, label %map_insert_new_39
map_insert_overwrite_38:
  %t189 = load i32*, i32** %t172
  %t190 = getelementptr inbounds i32, i32* %t189, i64 %t187
  store i32 25, i32* %t190
  br label %map_insert_after_40
map_insert_new_39:
  %t191 = load i64, i64* %t176
  %t192 = icmp sge i64 %t178, %t191
  br i1 %t192, label %map_insert_grow_41, label %map_insert_store_42
map_insert_grow_41:
  %t193 = mul i64 %t191, 2
  %t194 = icmp sgt i64 %t193, 0
  %t195 = select i1 %t194, i64 %t193, i64 1
  %t196 = getelementptr i8*, i8** null, i32 1
  %t197 = ptrtoint i8** %t196 to i64
  %t198 = mul i64 %t195, %t197
  %t199 = call i8* @malloc(i64 %t198)
  %t200 = bitcast i8* %t199 to i8**
  %t201 = getelementptr i32, i32* null, i32 1
  %t202 = ptrtoint i32* %t201 to i64
  %t203 = mul i64 %t195, %t202
  %t204 = call i8* @malloc(i64 %t203)
  %t205 = bitcast i8* %t204 to i32*
  %t206 = icmp sgt i64 %t191, 0
  br i1 %t206, label %map_insert_copy_43, label %map_insert_after_copy_44
map_insert_copy_43:
  %t207 = load i8**, i8*** %t170
  %t208 = mul i64 %t178, %t197
  %t209 = bitcast i8** %t207 to i8*
  call i8* @memcpy(i8* %t199, i8* %t209, i64 %t208)
  call void @free(i8* %t209)
  %t210 = load i32*, i32** %t172
  %t211 = mul i64 %t178, %t202
  %t212 = bitcast i32* %t210 to i8*
  call i8* @memcpy(i8* %t204, i8* %t212, i64 %t211)
  call void @free(i8* %t212)
  br label %map_insert_after_copy_44
map_insert_after_copy_44:
  store i8** %t200, i8*** %t170
  store i32* %t205, i32** %t172
  store i64 %t195, i64* %t176
  br label %map_insert_store_42
map_insert_store_42:
  %t213 = load i8**, i8*** %t170
  %t214 = load i32*, i32** %t172
  %t215 = getelementptr inbounds i8*, i8** %t213, i64 %t178
  store i8* %t177, i8** %t215
  %t216 = getelementptr inbounds i32, i32* %t214, i64 %t178
  store i32 25, i32* %t216
  %t217 = add i64 %t178, 1
  store i64 %t217, i64* %t174
  br label %map_insert_after_40
map_insert_after_40:
  %t218 = load i8*, i8** %t0
  %t219 = icmp eq i8* %t218, null
  br i1 %t219, label %map_read_null_45, label %map_read_real_46
map_read_null_45:
  br label %map_read_end_47
map_read_real_46:
  %t220 = bitcast i8* %t218 to { i8**, i32*, i64, i64 }*
  %t221 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t220, i32 0, i32 0
  %t222 = load i8**, i8*** %t221
  %t223 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t220, i32 0, i32 1
  %t224 = load i32*, i32** %t223
  %t225 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t220, i32 0, i32 2
  %t226 = load i64, i64* %t225
  br label %map_read_end_47
map_read_end_47:
  %t227 = phi i8** [ null, %map_read_null_45 ], [ %t222, %map_read_real_46 ]
  %t228 = phi i32* [ null, %map_read_null_45 ], [ %t224, %map_read_real_46 ]
  %t229 = phi i64 [ 0, %map_read_null_45 ], [ %t226, %map_read_real_46 ]
  %t230 = trunc i64 %t229 to i32
  %t231 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t231, i32 %t230)
  %t232 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t233 = load i8*, i8** %t0
  %t234 = icmp eq i8* %t233, null
  br i1 %t234, label %map_read_null_48, label %map_read_real_49
map_read_null_48:
  br label %map_read_end_50
map_read_real_49:
  %t235 = bitcast i8* %t233 to { i8**, i32*, i64, i64 }*
  %t236 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t235, i32 0, i32 0
  %t237 = load i8**, i8*** %t236
  %t238 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t235, i32 0, i32 1
  %t239 = load i32*, i32** %t238
  %t240 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t235, i32 0, i32 2
  %t241 = load i64, i64* %t240
  br label %map_read_end_50
map_read_end_50:
  %t242 = phi i8** [ null, %map_read_null_48 ], [ %t237, %map_read_real_49 ]
  %t243 = phi i32* [ null, %map_read_null_48 ], [ %t239, %map_read_real_49 ]
  %t244 = phi i64 [ 0, %map_read_null_48 ], [ %t241, %map_read_real_49 ]
  store i64 0, i64* %t245
  br label %map_find_cond_51
map_find_cond_51:
  %t246 = load i64, i64* %t245
  %t247 = icmp slt i64 %t246, %t244
  br i1 %t247, label %map_find_body_52, label %map_find_end_55
map_find_body_52:
  %t248 = getelementptr inbounds i8*, i8** %t242, i64 %t246
  %t249 = load i8*, i8** %t248
  br label %map_find_eq_check_53
map_find_eq_check_53:
  %t250 = call i1 @eq_str(i8* %t249, i8* %t232)
  br i1 %t250, label %map_find_end_55, label %map_find_next_54
map_find_next_54:
  %t251 = add i64 %t246, 1
  store i64 %t251, i64* %t245
  br label %map_find_cond_51
map_find_end_55:
  %t252 = load i64, i64* %t245
  %t253 = icmp slt i64 %t252, %t244
  br i1 %t253, label %map_get_some_56, label %map_get_none_57
map_get_some_56:
  %t254 = getelementptr inbounds i32, i32* %t243, i64 %t252
  %t255 = load i32, i32* %t254
  %t257 = getelementptr inbounds %Option__i32, %Option__i32* %t256, i32 0, i32 0
  store i32 1, i32* %t257
  %t258 = getelementptr inbounds %Option__i32, %Option__i32* %t256, i32 0, i32 1
  %t259 = bitcast [1 x i64]* %t258 to { i32 }*
  %t260 = getelementptr inbounds { i32 }, { i32 }* %t259, i32 0, i32 0
  store i32 %t255, i32* %t260
  %t261 = load %Option__i32, %Option__i32* %t256
  br label %map_get_end_58
map_get_none_57:
  %t263 = getelementptr inbounds %Option__i32, %Option__i32* %t262, i32 0, i32 0
  store i32 0, i32* %t263
  %t264 = load %Option__i32, %Option__i32* %t262
  br label %map_get_end_58
map_get_end_58:
  %t265 = phi %Option__i32 [ %t261, %map_get_some_56 ], [ %t264, %map_get_none_57 ]
  store %Option__i32 %t265, %Option__i32* %t266
  br label %match_scrutinee_268
match_scrutinee_268:
  %t272 = getelementptr inbounds %Option__i32, %Option__i32* %t266, i32 0, i32 0
  %t273 = load i32, i32* %t272
  %t271 = icmp eq i32 %t273, 1
  br i1 %t271, label %match_then_0_269, label %match_next_0_270
match_then_0_269:
  %t274 = getelementptr inbounds %Option__i32, %Option__i32* %t266, i32 0, i32 1
  %t275 = bitcast [1 x i64]* %t274 to { i32 }*
  %t276 = getelementptr inbounds { i32 }, { i32 }* %t275, i32 0, i32 0
  %t277 = load i32, i32* %t276
  %t278 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t278, i32 %t277)
  br label %match_end_267
match_next_0_270:
  %t282 = getelementptr inbounds %Option__i32, %Option__i32* %t266, i32 0, i32 0
  %t283 = load i32, i32* %t282
  %t281 = icmp eq i32 %t283, 0
  br i1 %t281, label %match_then_1_279, label %match_next_1_280
match_then_1_279:
  %t284 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t284)
  %t285 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t285)
  br label %match_end_267
match_next_1_280:
  br label %match_end_267
match_end_267:
  %t286 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t287 = load i8*, i8** %t0
  %t288 = icmp eq i8* %t287, null
  br i1 %t288, label %map_read_null_59, label %map_read_real_60
map_read_null_59:
  br label %map_read_end_61
map_read_real_60:
  %t289 = bitcast i8* %t287 to { i8**, i32*, i64, i64 }*
  %t290 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t289, i32 0, i32 0
  %t291 = load i8**, i8*** %t290
  %t292 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t289, i32 0, i32 1
  %t293 = load i32*, i32** %t292
  %t294 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t289, i32 0, i32 2
  %t295 = load i64, i64* %t294
  br label %map_read_end_61
map_read_end_61:
  %t296 = phi i8** [ null, %map_read_null_59 ], [ %t291, %map_read_real_60 ]
  %t297 = phi i32* [ null, %map_read_null_59 ], [ %t293, %map_read_real_60 ]
  %t298 = phi i64 [ 0, %map_read_null_59 ], [ %t295, %map_read_real_60 ]
  store i64 0, i64* %t299
  br label %map_find_cond_62
map_find_cond_62:
  %t300 = load i64, i64* %t299
  %t301 = icmp slt i64 %t300, %t298
  br i1 %t301, label %map_find_body_63, label %map_find_end_66
map_find_body_63:
  %t302 = getelementptr inbounds i8*, i8** %t296, i64 %t300
  %t303 = load i8*, i8** %t302
  br label %map_find_eq_check_64
map_find_eq_check_64:
  %t304 = call i1 @eq_str(i8* %t303, i8* %t286)
  br i1 %t304, label %map_find_end_66, label %map_find_next_65
map_find_next_65:
  %t305 = add i64 %t300, 1
  store i64 %t305, i64* %t299
  br label %map_find_cond_62
map_find_end_66:
  %t306 = load i64, i64* %t299
  %t307 = icmp slt i64 %t306, %t298
  br i1 %t307, label %map_get_some_67, label %map_get_none_68
map_get_some_67:
  %t308 = getelementptr inbounds i32, i32* %t297, i64 %t306
  %t309 = load i32, i32* %t308
  %t311 = getelementptr inbounds %Option__i32, %Option__i32* %t310, i32 0, i32 0
  store i32 1, i32* %t311
  %t312 = getelementptr inbounds %Option__i32, %Option__i32* %t310, i32 0, i32 1
  %t313 = bitcast [1 x i64]* %t312 to { i32 }*
  %t314 = getelementptr inbounds { i32 }, { i32 }* %t313, i32 0, i32 0
  store i32 %t309, i32* %t314
  %t315 = load %Option__i32, %Option__i32* %t310
  br label %map_get_end_69
map_get_none_68:
  %t317 = getelementptr inbounds %Option__i32, %Option__i32* %t316, i32 0, i32 0
  store i32 0, i32* %t317
  %t318 = load %Option__i32, %Option__i32* %t316
  br label %map_get_end_69
map_get_end_69:
  %t319 = phi %Option__i32 [ %t315, %map_get_some_67 ], [ %t318, %map_get_none_68 ]
  store %Option__i32 %t319, %Option__i32* %t320
  br label %match_scrutinee_322
match_scrutinee_322:
  %t326 = getelementptr inbounds %Option__i32, %Option__i32* %t320, i32 0, i32 0
  %t327 = load i32, i32* %t326
  %t325 = icmp eq i32 %t327, 1
  br i1 %t325, label %match_then_0_323, label %match_next_0_324
match_then_0_323:
  %t328 = getelementptr inbounds %Option__i32, %Option__i32* %t320, i32 0, i32 1
  %t329 = bitcast [1 x i64]* %t328 to { i32 }*
  %t330 = getelementptr inbounds { i32 }, { i32 }* %t329, i32 0, i32 0
  %t331 = load i32, i32* %t330
  %t332 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t332, i32 %t331)
  br label %match_end_321
match_next_0_324:
  %t336 = getelementptr inbounds %Option__i32, %Option__i32* %t320, i32 0, i32 0
  %t337 = load i32, i32* %t336
  %t335 = icmp eq i32 %t337, 0
  br i1 %t335, label %match_then_1_333, label %match_next_1_334
match_then_1_333:
  %t338 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t338)
  %t339 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t339)
  br label %match_end_321
match_next_1_334:
  br label %match_end_321
match_end_321:
  %t340 = getelementptr i8*, i8** null, i32 1
  %t341 = ptrtoint i8** %t340 to i64
  %t342 = getelementptr i32, i32* null, i32 1
  %t343 = ptrtoint i32* %t342 to i64
  %t344 = load i8*, i8** %t0
  %t345 = icmp eq i8* %t344, null
  br i1 %t345, label %map_cow_alloc_70, label %map_cow_check_71
map_cow_alloc_70:
  %t346 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t347 = call i8* @star_rc_alloc(i64 32, i8* %t346)
  %t348 = bitcast i8* %t347 to { i8**, i32*, i64, i64 }*
  %t349 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t348, i32 0, i32 0
  store i8** null, i8*** %t349
  %t350 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t348, i32 0, i32 1
  store i32* null, i32** %t350
  %t351 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t348, i32 0, i32 2
  store i64 0, i64* %t351
  %t352 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t348, i32 0, i32 3
  store i64 0, i64* %t352
  store i8* %t347, i8** %t0
  br label %map_cow_done_72
map_cow_check_71:
  %t353 = getelementptr inbounds i8, i8* %t344, i64 -16
  %t354 = bitcast i8* %t353 to i64*
  %t355 = load atomic i64, i64* %t354 seq_cst, align 8
  %t356 = icmp eq i64 %t355, 1
  br i1 %t356, label %map_cow_done_72, label %map_cow_clone_73
map_cow_clone_73:
  %t357 = bitcast i8* %t344 to { i8**, i32*, i64, i64 }*
  %t358 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 0
  %t359 = load i8**, i8*** %t358
  %t360 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 1
  %t361 = load i32*, i32** %t360
  %t362 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 2
  %t363 = load i64, i64* %t362
  %t364 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t357, i32 0, i32 3
  %t365 = load i64, i64* %t364
  %t366 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t367 = call i8* @star_rc_alloc(i64 32, i8* %t366)
  %t368 = bitcast i8* %t367 to { i8**, i32*, i64, i64 }*
  %t369 = mul i64 %t365, %t341
  %t370 = call i8* @malloc(i64 %t369)
  %t371 = bitcast i8* %t370 to i8**
  %t372 = mul i64 %t365, %t343
  %t373 = call i8* @malloc(i64 %t372)
  %t374 = bitcast i8* %t373 to i32*
  %t375 = icmp sgt i64 %t363, 0
  br i1 %t375, label %map_cow_copy_74, label %map_cow_after_copy_75
map_cow_copy_74:
  %t376 = mul i64 %t363, %t341
  %t377 = bitcast i8** %t359 to i8*
  call i8* @memcpy(i8* %t370, i8* %t377, i64 %t376)
  %t378 = mul i64 %t363, %t343
  %t379 = bitcast i32* %t361 to i8*
  call i8* @memcpy(i8* %t373, i8* %t379, i64 %t378)
  store i64 0, i64* %t380
  br label %map_cow_retain_cond_76
map_cow_retain_cond_76:
  %t381 = load i64, i64* %t380
  %t382 = icmp slt i64 %t381, %t363
  br i1 %t382, label %map_cow_retain_body_77, label %map_cow_retain_end_78
map_cow_retain_body_77:
  %t383 = getelementptr inbounds i8*, i8** %t371, i64 %t381
  %t384 = load i8*, i8** %t383
  call void @star_rc_retain(i8* %t384)
  %t385 = add i64 %t381, 1
  store i64 %t385, i64* %t380
  br label %map_cow_retain_cond_76
map_cow_retain_end_78:
  br label %map_cow_after_copy_75
map_cow_after_copy_75:
  %t386 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t368, i32 0, i32 0
  store i8** %t371, i8*** %t386
  %t387 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t368, i32 0, i32 1
  store i32* %t374, i32** %t387
  %t388 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t368, i32 0, i32 2
  store i64 %t363, i64* %t388
  %t389 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t368, i32 0, i32 3
  store i64 %t365, i64* %t389
  call void @star_rc_release(i8* %t344)
  store i8* %t367, i8** %t0
  br label %map_cow_done_72
map_cow_done_72:
  %t390 = load i8*, i8** %t0
  %t391 = bitcast i8* %t390 to { i8**, i32*, i64, i64 }*
  %t392 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t391, i32 0, i32 0
  %t393 = load i8**, i8*** %t392
  %t394 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t391, i32 0, i32 1
  %t395 = load i32*, i32** %t394
  %t396 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t391, i32 0, i32 2
  %t397 = load i64, i64* %t396
  %t398 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t391, i32 0, i32 3
  %t399 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t400 = load i64, i64* %t396
  %t401 = load i8**, i8*** %t392
  store i64 0, i64* %t402
  br label %map_find_cond_79
map_find_cond_79:
  %t403 = load i64, i64* %t402
  %t404 = icmp slt i64 %t403, %t400
  br i1 %t404, label %map_find_body_80, label %map_find_end_83
map_find_body_80:
  %t405 = getelementptr inbounds i8*, i8** %t401, i64 %t403
  %t406 = load i8*, i8** %t405
  br label %map_find_eq_check_81
map_find_eq_check_81:
  %t407 = call i1 @eq_str(i8* %t406, i8* %t399)
  br i1 %t407, label %map_find_end_83, label %map_find_next_82
map_find_next_82:
  %t408 = add i64 %t403, 1
  store i64 %t408, i64* %t402
  br label %map_find_cond_79
map_find_end_83:
  %t409 = load i64, i64* %t402
  %t410 = icmp slt i64 %t409, %t400
  br i1 %t410, label %map_insert_overwrite_84, label %map_insert_new_85
map_insert_overwrite_84:
  %t411 = load i32*, i32** %t394
  %t412 = getelementptr inbounds i32, i32* %t411, i64 %t409
  store i32 31, i32* %t412
  br label %map_insert_after_86
map_insert_new_85:
  %t413 = load i64, i64* %t398
  %t414 = icmp sge i64 %t400, %t413
  br i1 %t414, label %map_insert_grow_87, label %map_insert_store_88
map_insert_grow_87:
  %t415 = mul i64 %t413, 2
  %t416 = icmp sgt i64 %t415, 0
  %t417 = select i1 %t416, i64 %t415, i64 1
  %t418 = getelementptr i8*, i8** null, i32 1
  %t419 = ptrtoint i8** %t418 to i64
  %t420 = mul i64 %t417, %t419
  %t421 = call i8* @malloc(i64 %t420)
  %t422 = bitcast i8* %t421 to i8**
  %t423 = getelementptr i32, i32* null, i32 1
  %t424 = ptrtoint i32* %t423 to i64
  %t425 = mul i64 %t417, %t424
  %t426 = call i8* @malloc(i64 %t425)
  %t427 = bitcast i8* %t426 to i32*
  %t428 = icmp sgt i64 %t413, 0
  br i1 %t428, label %map_insert_copy_89, label %map_insert_after_copy_90
map_insert_copy_89:
  %t429 = load i8**, i8*** %t392
  %t430 = mul i64 %t400, %t419
  %t431 = bitcast i8** %t429 to i8*
  call i8* @memcpy(i8* %t421, i8* %t431, i64 %t430)
  call void @free(i8* %t431)
  %t432 = load i32*, i32** %t394
  %t433 = mul i64 %t400, %t424
  %t434 = bitcast i32* %t432 to i8*
  call i8* @memcpy(i8* %t426, i8* %t434, i64 %t433)
  call void @free(i8* %t434)
  br label %map_insert_after_copy_90
map_insert_after_copy_90:
  store i8** %t422, i8*** %t392
  store i32* %t427, i32** %t394
  store i64 %t417, i64* %t398
  br label %map_insert_store_88
map_insert_store_88:
  %t435 = load i8**, i8*** %t392
  %t436 = load i32*, i32** %t394
  %t437 = getelementptr inbounds i8*, i8** %t435, i64 %t400
  store i8* %t399, i8** %t437
  %t438 = getelementptr inbounds i32, i32* %t436, i64 %t400
  store i32 31, i32* %t438
  %t439 = add i64 %t400, 1
  store i64 %t439, i64* %t396
  br label %map_insert_after_86
map_insert_after_86:
  %t440 = load i8*, i8** %t0
  %t441 = icmp eq i8* %t440, null
  br i1 %t441, label %map_read_null_91, label %map_read_real_92
map_read_null_91:
  br label %map_read_end_93
map_read_real_92:
  %t442 = bitcast i8* %t440 to { i8**, i32*, i64, i64 }*
  %t443 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t442, i32 0, i32 0
  %t444 = load i8**, i8*** %t443
  %t445 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t442, i32 0, i32 1
  %t446 = load i32*, i32** %t445
  %t447 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t442, i32 0, i32 2
  %t448 = load i64, i64* %t447
  br label %map_read_end_93
map_read_end_93:
  %t449 = phi i8** [ null, %map_read_null_91 ], [ %t444, %map_read_real_92 ]
  %t450 = phi i32* [ null, %map_read_null_91 ], [ %t446, %map_read_real_92 ]
  %t451 = phi i64 [ 0, %map_read_null_91 ], [ %t448, %map_read_real_92 ]
  %t452 = trunc i64 %t451 to i32
  %t453 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t453, i32 %t452)
  %t454 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t455 = load i8*, i8** %t0
  %t456 = icmp eq i8* %t455, null
  br i1 %t456, label %map_read_null_94, label %map_read_real_95
map_read_null_94:
  br label %map_read_end_96
map_read_real_95:
  %t457 = bitcast i8* %t455 to { i8**, i32*, i64, i64 }*
  %t458 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t457, i32 0, i32 0
  %t459 = load i8**, i8*** %t458
  %t460 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t457, i32 0, i32 1
  %t461 = load i32*, i32** %t460
  %t462 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t457, i32 0, i32 2
  %t463 = load i64, i64* %t462
  br label %map_read_end_96
map_read_end_96:
  %t464 = phi i8** [ null, %map_read_null_94 ], [ %t459, %map_read_real_95 ]
  %t465 = phi i32* [ null, %map_read_null_94 ], [ %t461, %map_read_real_95 ]
  %t466 = phi i64 [ 0, %map_read_null_94 ], [ %t463, %map_read_real_95 ]
  store i64 0, i64* %t467
  br label %map_find_cond_97
map_find_cond_97:
  %t468 = load i64, i64* %t467
  %t469 = icmp slt i64 %t468, %t466
  br i1 %t469, label %map_find_body_98, label %map_find_end_101
map_find_body_98:
  %t470 = getelementptr inbounds i8*, i8** %t464, i64 %t468
  %t471 = load i8*, i8** %t470
  br label %map_find_eq_check_99
map_find_eq_check_99:
  %t472 = call i1 @eq_str(i8* %t471, i8* %t454)
  br i1 %t472, label %map_find_end_101, label %map_find_next_100
map_find_next_100:
  %t473 = add i64 %t468, 1
  store i64 %t473, i64* %t467
  br label %map_find_cond_97
map_find_end_101:
  %t474 = load i64, i64* %t467
  %t475 = icmp slt i64 %t474, %t466
  br i1 %t475, label %map_get_some_102, label %map_get_none_103
map_get_some_102:
  %t476 = getelementptr inbounds i32, i32* %t465, i64 %t474
  %t477 = load i32, i32* %t476
  %t479 = getelementptr inbounds %Option__i32, %Option__i32* %t478, i32 0, i32 0
  store i32 1, i32* %t479
  %t480 = getelementptr inbounds %Option__i32, %Option__i32* %t478, i32 0, i32 1
  %t481 = bitcast [1 x i64]* %t480 to { i32 }*
  %t482 = getelementptr inbounds { i32 }, { i32 }* %t481, i32 0, i32 0
  store i32 %t477, i32* %t482
  %t483 = load %Option__i32, %Option__i32* %t478
  br label %map_get_end_104
map_get_none_103:
  %t485 = getelementptr inbounds %Option__i32, %Option__i32* %t484, i32 0, i32 0
  store i32 0, i32* %t485
  %t486 = load %Option__i32, %Option__i32* %t484
  br label %map_get_end_104
map_get_end_104:
  %t487 = phi %Option__i32 [ %t483, %map_get_some_102 ], [ %t486, %map_get_none_103 ]
  store %Option__i32 %t487, %Option__i32* %t488
  br label %match_scrutinee_490
match_scrutinee_490:
  %t494 = getelementptr inbounds %Option__i32, %Option__i32* %t488, i32 0, i32 0
  %t495 = load i32, i32* %t494
  %t493 = icmp eq i32 %t495, 1
  br i1 %t493, label %match_then_0_491, label %match_next_0_492
match_then_0_491:
  %t496 = getelementptr inbounds %Option__i32, %Option__i32* %t488, i32 0, i32 1
  %t497 = bitcast [1 x i64]* %t496 to { i32 }*
  %t498 = getelementptr inbounds { i32 }, { i32 }* %t497, i32 0, i32 0
  %t499 = load i32, i32* %t498
  %t500 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t500, i32 %t499)
  br label %match_end_489
match_next_0_492:
  %t504 = getelementptr inbounds %Option__i32, %Option__i32* %t488, i32 0, i32 0
  %t505 = load i32, i32* %t504
  %t503 = icmp eq i32 %t505, 0
  br i1 %t503, label %match_then_1_501, label %match_next_1_502
match_then_1_501:
  %t506 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t506)
  %t507 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t507)
  br label %match_end_489
match_next_1_502:
  br label %match_end_489
match_end_489:
  %t509 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t509, i8** %t508
  %t510 = load i8*, i8** %t508
  %t511 = load i8*, i8** %t508
  call void @star_rc_retain(i8* %t511)
  %t512 = load i8*, i8** %t0
  %t513 = icmp eq i8* %t512, null
  br i1 %t513, label %map_read_null_105, label %map_read_real_106
map_read_null_105:
  br label %map_read_end_107
map_read_real_106:
  %t514 = bitcast i8* %t512 to { i8**, i32*, i64, i64 }*
  %t515 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t514, i32 0, i32 0
  %t516 = load i8**, i8*** %t515
  %t517 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t514, i32 0, i32 1
  %t518 = load i32*, i32** %t517
  %t519 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t514, i32 0, i32 2
  %t520 = load i64, i64* %t519
  br label %map_read_end_107
map_read_end_107:
  %t521 = phi i8** [ null, %map_read_null_105 ], [ %t516, %map_read_real_106 ]
  %t522 = phi i32* [ null, %map_read_null_105 ], [ %t518, %map_read_real_106 ]
  %t523 = phi i64 [ 0, %map_read_null_105 ], [ %t520, %map_read_real_106 ]
  store i64 0, i64* %t524
  br label %map_find_cond_108
map_find_cond_108:
  %t525 = load i64, i64* %t524
  %t526 = icmp slt i64 %t525, %t523
  br i1 %t526, label %map_find_body_109, label %map_find_end_112
map_find_body_109:
  %t527 = getelementptr inbounds i8*, i8** %t521, i64 %t525
  %t528 = load i8*, i8** %t527
  br label %map_find_eq_check_110
map_find_eq_check_110:
  %t529 = call i1 @eq_str(i8* %t528, i8* %t510)
  br i1 %t529, label %map_find_end_112, label %map_find_next_111
map_find_next_111:
  %t530 = add i64 %t525, 1
  store i64 %t530, i64* %t524
  br label %map_find_cond_108
map_find_end_112:
  %t531 = load i64, i64* %t524
  %t532 = icmp slt i64 %t531, %t523
  store i8* %t510, i8** %t533
  %t534 = load i8*, i8** %t533
  call void @star_rc_release(i8* %t534)
  %t535 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t536 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t537 = select i1 %t532, i8* %t535, i8* %t536
  %t538 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t538, i8* %t537)
  %t539 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t540 = getelementptr i8*, i8** null, i32 1
  %t541 = ptrtoint i8** %t540 to i64
  %t542 = getelementptr i32, i32* null, i32 1
  %t543 = ptrtoint i32* %t542 to i64
  %t544 = load i8*, i8** %t0
  %t545 = icmp eq i8* %t544, null
  br i1 %t545, label %map_cow_alloc_113, label %map_cow_check_114
map_cow_alloc_113:
  %t546 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t547 = call i8* @star_rc_alloc(i64 32, i8* %t546)
  %t548 = bitcast i8* %t547 to { i8**, i32*, i64, i64 }*
  %t549 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t548, i32 0, i32 0
  store i8** null, i8*** %t549
  %t550 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t548, i32 0, i32 1
  store i32* null, i32** %t550
  %t551 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t548, i32 0, i32 2
  store i64 0, i64* %t551
  %t552 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t548, i32 0, i32 3
  store i64 0, i64* %t552
  store i8* %t547, i8** %t0
  br label %map_cow_done_115
map_cow_check_114:
  %t553 = getelementptr inbounds i8, i8* %t544, i64 -16
  %t554 = bitcast i8* %t553 to i64*
  %t555 = load atomic i64, i64* %t554 seq_cst, align 8
  %t556 = icmp eq i64 %t555, 1
  br i1 %t556, label %map_cow_done_115, label %map_cow_clone_116
map_cow_clone_116:
  %t557 = bitcast i8* %t544 to { i8**, i32*, i64, i64 }*
  %t558 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t557, i32 0, i32 0
  %t559 = load i8**, i8*** %t558
  %t560 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t557, i32 0, i32 1
  %t561 = load i32*, i32** %t560
  %t562 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t557, i32 0, i32 2
  %t563 = load i64, i64* %t562
  %t564 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t557, i32 0, i32 3
  %t565 = load i64, i64* %t564
  %t566 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t567 = call i8* @star_rc_alloc(i64 32, i8* %t566)
  %t568 = bitcast i8* %t567 to { i8**, i32*, i64, i64 }*
  %t569 = mul i64 %t565, %t541
  %t570 = call i8* @malloc(i64 %t569)
  %t571 = bitcast i8* %t570 to i8**
  %t572 = mul i64 %t565, %t543
  %t573 = call i8* @malloc(i64 %t572)
  %t574 = bitcast i8* %t573 to i32*
  %t575 = icmp sgt i64 %t563, 0
  br i1 %t575, label %map_cow_copy_117, label %map_cow_after_copy_118
map_cow_copy_117:
  %t576 = mul i64 %t563, %t541
  %t577 = bitcast i8** %t559 to i8*
  call i8* @memcpy(i8* %t570, i8* %t577, i64 %t576)
  %t578 = mul i64 %t563, %t543
  %t579 = bitcast i32* %t561 to i8*
  call i8* @memcpy(i8* %t573, i8* %t579, i64 %t578)
  store i64 0, i64* %t580
  br label %map_cow_retain_cond_119
map_cow_retain_cond_119:
  %t581 = load i64, i64* %t580
  %t582 = icmp slt i64 %t581, %t563
  br i1 %t582, label %map_cow_retain_body_120, label %map_cow_retain_end_121
map_cow_retain_body_120:
  %t583 = getelementptr inbounds i8*, i8** %t571, i64 %t581
  %t584 = load i8*, i8** %t583
  call void @star_rc_retain(i8* %t584)
  %t585 = add i64 %t581, 1
  store i64 %t585, i64* %t580
  br label %map_cow_retain_cond_119
map_cow_retain_end_121:
  br label %map_cow_after_copy_118
map_cow_after_copy_118:
  %t586 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t568, i32 0, i32 0
  store i8** %t571, i8*** %t586
  %t587 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t568, i32 0, i32 1
  store i32* %t574, i32** %t587
  %t588 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t568, i32 0, i32 2
  store i64 %t563, i64* %t588
  %t589 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t568, i32 0, i32 3
  store i64 %t565, i64* %t589
  call void @star_rc_release(i8* %t544)
  store i8* %t567, i8** %t0
  br label %map_cow_done_115
map_cow_done_115:
  %t590 = load i8*, i8** %t0
  %t591 = bitcast i8* %t590 to { i8**, i32*, i64, i64 }*
  %t592 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t591, i32 0, i32 0
  %t593 = load i8**, i8*** %t592
  %t594 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t591, i32 0, i32 1
  %t595 = load i32*, i32** %t594
  %t596 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t591, i32 0, i32 2
  %t597 = load i64, i64* %t596
  %t598 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t591, i32 0, i32 3
  store i64 0, i64* %t599
  br label %map_find_cond_122
map_find_cond_122:
  %t600 = load i64, i64* %t599
  %t601 = icmp slt i64 %t600, %t597
  br i1 %t601, label %map_find_body_123, label %map_find_end_126
map_find_body_123:
  %t602 = getelementptr inbounds i8*, i8** %t593, i64 %t600
  %t603 = load i8*, i8** %t602
  br label %map_find_eq_check_124
map_find_eq_check_124:
  %t604 = call i1 @eq_str(i8* %t603, i8* %t539)
  br i1 %t604, label %map_find_end_126, label %map_find_next_125
map_find_next_125:
  %t605 = add i64 %t600, 1
  store i64 %t605, i64* %t599
  br label %map_find_cond_122
map_find_end_126:
  %t606 = load i64, i64* %t599
  %t607 = icmp slt i64 %t606, %t597
  br i1 %t607, label %map_remove_some_127, label %map_remove_none_128
map_remove_some_127:
  %t608 = getelementptr inbounds i8*, i8** %t593, i64 %t606
  %t609 = getelementptr inbounds i32, i32* %t595, i64 %t606
  %t610 = load i32, i32* %t609
  %t611 = load i8*, i8** %t608
  call void @star_rc_release(i8* %t611)
  %t612 = sub i64 %t597, 1
  %t613 = getelementptr inbounds i8*, i8** %t593, i64 %t612
  %t614 = load i8*, i8** %t613
  %t615 = getelementptr inbounds i32, i32* %t595, i64 %t612
  %t616 = load i32, i32* %t615
  store i8* %t614, i8** %t608
  store i32 %t616, i32* %t609
  store i64 %t612, i64* %t596
  %t618 = getelementptr inbounds %Option__i32, %Option__i32* %t617, i32 0, i32 0
  store i32 1, i32* %t618
  %t619 = getelementptr inbounds %Option__i32, %Option__i32* %t617, i32 0, i32 1
  %t620 = bitcast [1 x i64]* %t619 to { i32 }*
  %t621 = getelementptr inbounds { i32 }, { i32 }* %t620, i32 0, i32 0
  store i32 %t610, i32* %t621
  %t622 = load %Option__i32, %Option__i32* %t617
  br label %map_remove_end_129
map_remove_none_128:
  %t624 = getelementptr inbounds %Option__i32, %Option__i32* %t623, i32 0, i32 0
  store i32 0, i32* %t624
  %t625 = load %Option__i32, %Option__i32* %t623
  br label %map_remove_end_129
map_remove_end_129:
  %t626 = phi %Option__i32 [ %t622, %map_remove_some_127 ], [ %t625, %map_remove_none_128 ]
  store %Option__i32 %t626, %Option__i32* %t627
  br label %match_scrutinee_629
match_scrutinee_629:
  %t633 = getelementptr inbounds %Option__i32, %Option__i32* %t627, i32 0, i32 0
  %t634 = load i32, i32* %t633
  %t632 = icmp eq i32 %t634, 1
  br i1 %t632, label %match_then_0_630, label %match_next_0_631
match_then_0_630:
  %t635 = getelementptr inbounds %Option__i32, %Option__i32* %t627, i32 0, i32 1
  %t636 = bitcast [1 x i64]* %t635 to { i32 }*
  %t637 = getelementptr inbounds { i32 }, { i32 }* %t636, i32 0, i32 0
  %t638 = load i32, i32* %t637
  %t639 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t639, i32 %t638)
  br label %match_end_628
match_next_0_631:
  %t643 = getelementptr inbounds %Option__i32, %Option__i32* %t627, i32 0, i32 0
  %t644 = load i32, i32* %t643
  %t642 = icmp eq i32 %t644, 0
  br i1 %t642, label %match_then_1_640, label %match_next_1_641
match_then_1_640:
  %t645 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t645)
  %t646 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t646)
  br label %match_end_628
match_next_1_641:
  br label %match_end_628
match_end_628:
  %t647 = load i8*, i8** %t508
  %t648 = load i8*, i8** %t508
  call void @star_rc_retain(i8* %t648)
  %t649 = load i8*, i8** %t0
  %t650 = icmp eq i8* %t649, null
  br i1 %t650, label %map_read_null_130, label %map_read_real_131
map_read_null_130:
  br label %map_read_end_132
map_read_real_131:
  %t651 = bitcast i8* %t649 to { i8**, i32*, i64, i64 }*
  %t652 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t651, i32 0, i32 0
  %t653 = load i8**, i8*** %t652
  %t654 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t651, i32 0, i32 1
  %t655 = load i32*, i32** %t654
  %t656 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t651, i32 0, i32 2
  %t657 = load i64, i64* %t656
  br label %map_read_end_132
map_read_end_132:
  %t658 = phi i8** [ null, %map_read_null_130 ], [ %t653, %map_read_real_131 ]
  %t659 = phi i32* [ null, %map_read_null_130 ], [ %t655, %map_read_real_131 ]
  %t660 = phi i64 [ 0, %map_read_null_130 ], [ %t657, %map_read_real_131 ]
  store i64 0, i64* %t661
  br label %map_find_cond_133
map_find_cond_133:
  %t662 = load i64, i64* %t661
  %t663 = icmp slt i64 %t662, %t660
  br i1 %t663, label %map_find_body_134, label %map_find_end_137
map_find_body_134:
  %t664 = getelementptr inbounds i8*, i8** %t658, i64 %t662
  %t665 = load i8*, i8** %t664
  br label %map_find_eq_check_135
map_find_eq_check_135:
  %t666 = call i1 @eq_str(i8* %t665, i8* %t647)
  br i1 %t666, label %map_find_end_137, label %map_find_next_136
map_find_next_136:
  %t667 = add i64 %t662, 1
  store i64 %t667, i64* %t661
  br label %map_find_cond_133
map_find_end_137:
  %t668 = load i64, i64* %t661
  %t669 = icmp slt i64 %t668, %t660
  store i8* %t647, i8** %t670
  %t671 = load i8*, i8** %t670
  call void @star_rc_release(i8* %t671)
  %t672 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t673 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t674 = select i1 %t669, i8* %t672, i8* %t673
  %t675 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t675, i8* %t674)
  %t676 = load i8*, i8** %t0
  %t677 = icmp eq i8* %t676, null
  br i1 %t677, label %map_read_null_138, label %map_read_real_139
map_read_null_138:
  br label %map_read_end_140
map_read_real_139:
  %t678 = bitcast i8* %t676 to { i8**, i32*, i64, i64 }*
  %t679 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t678, i32 0, i32 0
  %t680 = load i8**, i8*** %t679
  %t681 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t678, i32 0, i32 1
  %t682 = load i32*, i32** %t681
  %t683 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t678, i32 0, i32 2
  %t684 = load i64, i64* %t683
  br label %map_read_end_140
map_read_end_140:
  %t685 = phi i8** [ null, %map_read_null_138 ], [ %t680, %map_read_real_139 ]
  %t686 = phi i32* [ null, %map_read_null_138 ], [ %t682, %map_read_real_139 ]
  %t687 = phi i64 [ 0, %map_read_null_138 ], [ %t684, %map_read_real_139 ]
  %t688 = trunc i64 %t687 to i32
  %t689 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t689, i32 %t688)
  store i8* null, i8** %t690
  %t691 = getelementptr i32, i32* null, i32 1
  %t692 = ptrtoint i32* %t691 to i64
  %t693 = load i8*, i8** %t690
  %t694 = icmp eq i8* %t693, null
  br i1 %t694, label %set_cow_alloc_141, label %set_cow_check_142
set_cow_alloc_141:
  %t699 = bitcast void (i8*)* @set_release_i32 to i8*
  %t700 = call i8* @star_rc_alloc(i64 24, i8* %t699)
  %t701 = bitcast i8* %t700 to { i32*, i64, i64 }*
  %t702 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t701, i32 0, i32 0
  store i32* null, i32** %t702
  %t703 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t701, i32 0, i32 1
  store i64 0, i64* %t703
  %t704 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t701, i32 0, i32 2
  store i64 0, i64* %t704
  store i8* %t700, i8** %t690
  br label %set_cow_done_143
set_cow_check_142:
  %t705 = getelementptr inbounds i8, i8* %t693, i64 -16
  %t706 = bitcast i8* %t705 to i64*
  %t707 = load atomic i64, i64* %t706 seq_cst, align 8
  %t708 = icmp eq i64 %t707, 1
  br i1 %t708, label %set_cow_done_143, label %set_cow_clone_144
set_cow_clone_144:
  %t709 = bitcast i8* %t693 to { i32*, i64, i64 }*
  %t710 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t709, i32 0, i32 0
  %t711 = load i32*, i32** %t710
  %t712 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t709, i32 0, i32 1
  %t713 = load i64, i64* %t712
  %t714 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t709, i32 0, i32 2
  %t715 = load i64, i64* %t714
  %t716 = bitcast void (i8*)* @set_release_i32 to i8*
  %t717 = call i8* @star_rc_alloc(i64 24, i8* %t716)
  %t718 = bitcast i8* %t717 to { i32*, i64, i64 }*
  %t719 = mul i64 %t715, %t692
  %t720 = call i8* @malloc(i64 %t719)
  %t721 = bitcast i8* %t720 to i32*
  %t722 = icmp sgt i64 %t713, 0
  br i1 %t722, label %set_cow_copy_145, label %set_cow_after_copy_146
set_cow_copy_145:
  %t723 = mul i64 %t713, %t692
  %t724 = bitcast i32* %t711 to i8*
  call i8* @memcpy(i8* %t720, i8* %t724, i64 %t723)
  br label %set_cow_after_copy_146
set_cow_after_copy_146:
  %t725 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t718, i32 0, i32 0
  store i32* %t721, i32** %t725
  %t726 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t718, i32 0, i32 1
  store i64 %t713, i64* %t726
  %t727 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t718, i32 0, i32 2
  store i64 %t715, i64* %t727
  call void @star_rc_release(i8* %t693)
  store i8* %t717, i8** %t690
  br label %set_cow_done_143
set_cow_done_143:
  %t728 = load i8*, i8** %t690
  %t729 = bitcast i8* %t728 to { i32*, i64, i64 }*
  %t730 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t729, i32 0, i32 0
  %t731 = load i32*, i32** %t730
  %t732 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t729, i32 0, i32 1
  %t733 = load i64, i64* %t732
  %t734 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t729, i32 0, i32 2
  %t735 = load i64, i64* %t732
  %t736 = load i32*, i32** %t730
  store i64 0, i64* %t738
  store i1 false, i1* %t739
  br label %find_cond_147
find_cond_147:
  %t740 = load i64, i64* %t738
  %t741 = icmp slt i64 %t740, %t735
  br i1 %t741, label %find_body_148, label %find_end_151
find_body_148:
  %t742 = getelementptr inbounds i32, i32* %t736, i64 %t740
  %t743 = load i32, i32* %t742
  br label %find_eq_check_149
find_eq_check_149:
  %t744 = call i1 @eq_i32(i32 %t743, i32 1)
  br i1 %t744, label %find_end_151, label %find_next_150
find_next_150:
  %t745 = add i64 %t740, 1
  store i64 %t745, i64* %t738
  br label %find_cond_147
find_end_151:
  %t746 = load i64, i64* %t738
  %t747 = icmp slt i64 %t746, %t735
  br i1 %t747, label %set_insert_already_present_152, label %set_insert_do_153
set_insert_already_present_152:
  br label %set_insert_end_154
set_insert_do_153:
  %t748 = load i64, i64* %t734
  %t749 = load i32*, i32** %t730
  %t750 = icmp sge i64 %t735, %t748
  br i1 %t750, label %set_insert_grow_155, label %set_insert_store_156
set_insert_grow_155:
  %t751 = mul i64 %t748, 2
  %t752 = icmp sgt i64 %t751, 0
  %t753 = select i1 %t752, i64 %t751, i64 1
  %t754 = getelementptr i32, i32* null, i32 1
  %t755 = ptrtoint i32* %t754 to i64
  %t756 = mul i64 %t753, %t755
  %t757 = call i8* @malloc(i64 %t756)
  %t758 = bitcast i8* %t757 to i32*
  %t759 = icmp sgt i64 %t748, 0
  br i1 %t759, label %set_insert_copy_157, label %set_insert_after_copy_158
set_insert_copy_157:
  %t760 = mul i64 %t735, %t755
  %t761 = bitcast i32* %t749 to i8*
  call i8* @memcpy(i8* %t757, i8* %t761, i64 %t760)
  call void @free(i8* %t761)
  br label %set_insert_after_copy_158
set_insert_after_copy_158:
  store i32* %t758, i32** %t730
  store i64 %t753, i64* %t734
  br label %set_insert_store_156
set_insert_store_156:
  %t762 = load i32*, i32** %t730
  %t763 = getelementptr inbounds i32, i32* %t762, i64 %t735
  store i32 1, i32* %t763
  %t764 = add i64 %t735, 1
  store i64 %t764, i64* %t732
  br label %set_insert_end_154
set_insert_end_154:
  %t765 = phi i1 [ false, %set_insert_already_present_152 ], [ true, %set_insert_store_156 ]
  %t766 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t767 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t768 = select i1 %t765, i8* %t766, i8* %t767
  %t769 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t769, i8* %t768)
  %t770 = getelementptr i32, i32* null, i32 1
  %t771 = ptrtoint i32* %t770 to i64
  %t772 = load i8*, i8** %t690
  %t773 = icmp eq i8* %t772, null
  br i1 %t773, label %set_cow_alloc_159, label %set_cow_check_160
set_cow_alloc_159:
  %t774 = bitcast void (i8*)* @set_release_i32 to i8*
  %t775 = call i8* @star_rc_alloc(i64 24, i8* %t774)
  %t776 = bitcast i8* %t775 to { i32*, i64, i64 }*
  %t777 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 0
  store i32* null, i32** %t777
  %t778 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 1
  store i64 0, i64* %t778
  %t779 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 2
  store i64 0, i64* %t779
  store i8* %t775, i8** %t690
  br label %set_cow_done_161
set_cow_check_160:
  %t780 = getelementptr inbounds i8, i8* %t772, i64 -16
  %t781 = bitcast i8* %t780 to i64*
  %t782 = load atomic i64, i64* %t781 seq_cst, align 8
  %t783 = icmp eq i64 %t782, 1
  br i1 %t783, label %set_cow_done_161, label %set_cow_clone_162
set_cow_clone_162:
  %t784 = bitcast i8* %t772 to { i32*, i64, i64 }*
  %t785 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t784, i32 0, i32 0
  %t786 = load i32*, i32** %t785
  %t787 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t784, i32 0, i32 1
  %t788 = load i64, i64* %t787
  %t789 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t784, i32 0, i32 2
  %t790 = load i64, i64* %t789
  %t791 = bitcast void (i8*)* @set_release_i32 to i8*
  %t792 = call i8* @star_rc_alloc(i64 24, i8* %t791)
  %t793 = bitcast i8* %t792 to { i32*, i64, i64 }*
  %t794 = mul i64 %t790, %t771
  %t795 = call i8* @malloc(i64 %t794)
  %t796 = bitcast i8* %t795 to i32*
  %t797 = icmp sgt i64 %t788, 0
  br i1 %t797, label %set_cow_copy_163, label %set_cow_after_copy_164
set_cow_copy_163:
  %t798 = mul i64 %t788, %t771
  %t799 = bitcast i32* %t786 to i8*
  call i8* @memcpy(i8* %t795, i8* %t799, i64 %t798)
  br label %set_cow_after_copy_164
set_cow_after_copy_164:
  %t800 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t793, i32 0, i32 0
  store i32* %t796, i32** %t800
  %t801 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t793, i32 0, i32 1
  store i64 %t788, i64* %t801
  %t802 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t793, i32 0, i32 2
  store i64 %t790, i64* %t802
  call void @star_rc_release(i8* %t772)
  store i8* %t792, i8** %t690
  br label %set_cow_done_161
set_cow_done_161:
  %t803 = load i8*, i8** %t690
  %t804 = bitcast i8* %t803 to { i32*, i64, i64 }*
  %t805 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t804, i32 0, i32 0
  %t806 = load i32*, i32** %t805
  %t807 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t804, i32 0, i32 1
  %t808 = load i64, i64* %t807
  %t809 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t804, i32 0, i32 2
  %t810 = load i64, i64* %t807
  %t811 = load i32*, i32** %t805
  store i64 0, i64* %t812
  store i1 false, i1* %t813
  br label %find_cond_165
find_cond_165:
  %t814 = load i64, i64* %t812
  %t815 = icmp slt i64 %t814, %t810
  br i1 %t815, label %find_body_166, label %find_end_169
find_body_166:
  %t816 = getelementptr inbounds i32, i32* %t811, i64 %t814
  %t817 = load i32, i32* %t816
  br label %find_eq_check_167
find_eq_check_167:
  %t818 = call i1 @eq_i32(i32 %t817, i32 2)
  br i1 %t818, label %find_end_169, label %find_next_168
find_next_168:
  %t819 = add i64 %t814, 1
  store i64 %t819, i64* %t812
  br label %find_cond_165
find_end_169:
  %t820 = load i64, i64* %t812
  %t821 = icmp slt i64 %t820, %t810
  br i1 %t821, label %set_insert_already_present_170, label %set_insert_do_171
set_insert_already_present_170:
  br label %set_insert_end_172
set_insert_do_171:
  %t822 = load i64, i64* %t809
  %t823 = load i32*, i32** %t805
  %t824 = icmp sge i64 %t810, %t822
  br i1 %t824, label %set_insert_grow_173, label %set_insert_store_174
set_insert_grow_173:
  %t825 = mul i64 %t822, 2
  %t826 = icmp sgt i64 %t825, 0
  %t827 = select i1 %t826, i64 %t825, i64 1
  %t828 = getelementptr i32, i32* null, i32 1
  %t829 = ptrtoint i32* %t828 to i64
  %t830 = mul i64 %t827, %t829
  %t831 = call i8* @malloc(i64 %t830)
  %t832 = bitcast i8* %t831 to i32*
  %t833 = icmp sgt i64 %t822, 0
  br i1 %t833, label %set_insert_copy_175, label %set_insert_after_copy_176
set_insert_copy_175:
  %t834 = mul i64 %t810, %t829
  %t835 = bitcast i32* %t823 to i8*
  call i8* @memcpy(i8* %t831, i8* %t835, i64 %t834)
  call void @free(i8* %t835)
  br label %set_insert_after_copy_176
set_insert_after_copy_176:
  store i32* %t832, i32** %t805
  store i64 %t827, i64* %t809
  br label %set_insert_store_174
set_insert_store_174:
  %t836 = load i32*, i32** %t805
  %t837 = getelementptr inbounds i32, i32* %t836, i64 %t810
  store i32 2, i32* %t837
  %t838 = add i64 %t810, 1
  store i64 %t838, i64* %t807
  br label %set_insert_end_172
set_insert_end_172:
  %t839 = phi i1 [ false, %set_insert_already_present_170 ], [ true, %set_insert_store_174 ]
  %t840 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t841 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t842 = select i1 %t839, i8* %t840, i8* %t841
  %t843 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t843, i8* %t842)
  %t844 = getelementptr i32, i32* null, i32 1
  %t845 = ptrtoint i32* %t844 to i64
  %t846 = load i8*, i8** %t690
  %t847 = icmp eq i8* %t846, null
  br i1 %t847, label %set_cow_alloc_177, label %set_cow_check_178
set_cow_alloc_177:
  %t848 = bitcast void (i8*)* @set_release_i32 to i8*
  %t849 = call i8* @star_rc_alloc(i64 24, i8* %t848)
  %t850 = bitcast i8* %t849 to { i32*, i64, i64 }*
  %t851 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t850, i32 0, i32 0
  store i32* null, i32** %t851
  %t852 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t850, i32 0, i32 1
  store i64 0, i64* %t852
  %t853 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t850, i32 0, i32 2
  store i64 0, i64* %t853
  store i8* %t849, i8** %t690
  br label %set_cow_done_179
set_cow_check_178:
  %t854 = getelementptr inbounds i8, i8* %t846, i64 -16
  %t855 = bitcast i8* %t854 to i64*
  %t856 = load atomic i64, i64* %t855 seq_cst, align 8
  %t857 = icmp eq i64 %t856, 1
  br i1 %t857, label %set_cow_done_179, label %set_cow_clone_180
set_cow_clone_180:
  %t858 = bitcast i8* %t846 to { i32*, i64, i64 }*
  %t859 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 0
  %t860 = load i32*, i32** %t859
  %t861 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 1
  %t862 = load i64, i64* %t861
  %t863 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 2
  %t864 = load i64, i64* %t863
  %t865 = bitcast void (i8*)* @set_release_i32 to i8*
  %t866 = call i8* @star_rc_alloc(i64 24, i8* %t865)
  %t867 = bitcast i8* %t866 to { i32*, i64, i64 }*
  %t868 = mul i64 %t864, %t845
  %t869 = call i8* @malloc(i64 %t868)
  %t870 = bitcast i8* %t869 to i32*
  %t871 = icmp sgt i64 %t862, 0
  br i1 %t871, label %set_cow_copy_181, label %set_cow_after_copy_182
set_cow_copy_181:
  %t872 = mul i64 %t862, %t845
  %t873 = bitcast i32* %t860 to i8*
  call i8* @memcpy(i8* %t869, i8* %t873, i64 %t872)
  br label %set_cow_after_copy_182
set_cow_after_copy_182:
  %t874 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t867, i32 0, i32 0
  store i32* %t870, i32** %t874
  %t875 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t867, i32 0, i32 1
  store i64 %t862, i64* %t875
  %t876 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t867, i32 0, i32 2
  store i64 %t864, i64* %t876
  call void @star_rc_release(i8* %t846)
  store i8* %t866, i8** %t690
  br label %set_cow_done_179
set_cow_done_179:
  %t877 = load i8*, i8** %t690
  %t878 = bitcast i8* %t877 to { i32*, i64, i64 }*
  %t879 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t878, i32 0, i32 0
  %t880 = load i32*, i32** %t879
  %t881 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t878, i32 0, i32 1
  %t882 = load i64, i64* %t881
  %t883 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t878, i32 0, i32 2
  %t884 = load i64, i64* %t881
  %t885 = load i32*, i32** %t879
  store i64 0, i64* %t886
  store i1 false, i1* %t887
  br label %find_cond_183
find_cond_183:
  %t888 = load i64, i64* %t886
  %t889 = icmp slt i64 %t888, %t884
  br i1 %t889, label %find_body_184, label %find_end_187
find_body_184:
  %t890 = getelementptr inbounds i32, i32* %t885, i64 %t888
  %t891 = load i32, i32* %t890
  br label %find_eq_check_185
find_eq_check_185:
  %t892 = call i1 @eq_i32(i32 %t891, i32 1)
  br i1 %t892, label %find_end_187, label %find_next_186
find_next_186:
  %t893 = add i64 %t888, 1
  store i64 %t893, i64* %t886
  br label %find_cond_183
find_end_187:
  %t894 = load i64, i64* %t886
  %t895 = icmp slt i64 %t894, %t884
  br i1 %t895, label %set_insert_already_present_188, label %set_insert_do_189
set_insert_already_present_188:
  br label %set_insert_end_190
set_insert_do_189:
  %t896 = load i64, i64* %t883
  %t897 = load i32*, i32** %t879
  %t898 = icmp sge i64 %t884, %t896
  br i1 %t898, label %set_insert_grow_191, label %set_insert_store_192
set_insert_grow_191:
  %t899 = mul i64 %t896, 2
  %t900 = icmp sgt i64 %t899, 0
  %t901 = select i1 %t900, i64 %t899, i64 1
  %t902 = getelementptr i32, i32* null, i32 1
  %t903 = ptrtoint i32* %t902 to i64
  %t904 = mul i64 %t901, %t903
  %t905 = call i8* @malloc(i64 %t904)
  %t906 = bitcast i8* %t905 to i32*
  %t907 = icmp sgt i64 %t896, 0
  br i1 %t907, label %set_insert_copy_193, label %set_insert_after_copy_194
set_insert_copy_193:
  %t908 = mul i64 %t884, %t903
  %t909 = bitcast i32* %t897 to i8*
  call i8* @memcpy(i8* %t905, i8* %t909, i64 %t908)
  call void @free(i8* %t909)
  br label %set_insert_after_copy_194
set_insert_after_copy_194:
  store i32* %t906, i32** %t879
  store i64 %t901, i64* %t883
  br label %set_insert_store_192
set_insert_store_192:
  %t910 = load i32*, i32** %t879
  %t911 = getelementptr inbounds i32, i32* %t910, i64 %t884
  store i32 1, i32* %t911
  %t912 = add i64 %t884, 1
  store i64 %t912, i64* %t881
  br label %set_insert_end_190
set_insert_end_190:
  %t913 = phi i1 [ false, %set_insert_already_present_188 ], [ true, %set_insert_store_192 ]
  %t914 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t915 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t916 = select i1 %t913, i8* %t914, i8* %t915
  %t917 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t917, i8* %t916)
  %t918 = load i8*, i8** %t690
  %t919 = icmp eq i8* %t918, null
  br i1 %t919, label %set_read_null_195, label %set_read_real_196
set_read_null_195:
  br label %set_read_end_197
set_read_real_196:
  %t920 = bitcast i8* %t918 to { i32*, i64, i64 }*
  %t921 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t920, i32 0, i32 0
  %t922 = load i32*, i32** %t921
  %t923 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t920, i32 0, i32 1
  %t924 = load i64, i64* %t923
  br label %set_read_end_197
set_read_end_197:
  %t925 = phi i32* [ null, %set_read_null_195 ], [ %t922, %set_read_real_196 ]
  %t926 = phi i64 [ 0, %set_read_null_195 ], [ %t924, %set_read_real_196 ]
  %t927 = trunc i64 %t926 to i32
  %t928 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t928, i32 %t927)
  %t929 = load i8*, i8** %t690
  %t930 = icmp eq i8* %t929, null
  br i1 %t930, label %set_read_null_198, label %set_read_real_199
set_read_null_198:
  br label %set_read_end_200
set_read_real_199:
  %t931 = bitcast i8* %t929 to { i32*, i64, i64 }*
  %t932 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t931, i32 0, i32 0
  %t933 = load i32*, i32** %t932
  %t934 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t931, i32 0, i32 1
  %t935 = load i64, i64* %t934
  br label %set_read_end_200
set_read_end_200:
  %t936 = phi i32* [ null, %set_read_null_198 ], [ %t933, %set_read_real_199 ]
  %t937 = phi i64 [ 0, %set_read_null_198 ], [ %t935, %set_read_real_199 ]
  store i64 0, i64* %t938
  store i1 false, i1* %t939
  br label %find_cond_201
find_cond_201:
  %t940 = load i64, i64* %t938
  %t941 = icmp slt i64 %t940, %t937
  br i1 %t941, label %find_body_202, label %find_end_205
find_body_202:
  %t942 = getelementptr inbounds i32, i32* %t936, i64 %t940
  %t943 = load i32, i32* %t942
  br label %find_eq_check_203
find_eq_check_203:
  %t944 = call i1 @eq_i32(i32 %t943, i32 2)
  br i1 %t944, label %find_end_205, label %find_next_204
find_next_204:
  %t945 = add i64 %t940, 1
  store i64 %t945, i64* %t938
  br label %find_cond_201
find_end_205:
  %t946 = load i64, i64* %t938
  %t947 = icmp slt i64 %t946, %t937
  %t948 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t949 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t950 = select i1 %t947, i8* %t948, i8* %t949
  %t951 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t951, i8* %t950)
  %t952 = getelementptr i32, i32* null, i32 1
  %t953 = ptrtoint i32* %t952 to i64
  %t954 = load i8*, i8** %t690
  %t955 = icmp eq i8* %t954, null
  br i1 %t955, label %set_cow_alloc_206, label %set_cow_check_207
set_cow_alloc_206:
  %t956 = bitcast void (i8*)* @set_release_i32 to i8*
  %t957 = call i8* @star_rc_alloc(i64 24, i8* %t956)
  %t958 = bitcast i8* %t957 to { i32*, i64, i64 }*
  %t959 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t958, i32 0, i32 0
  store i32* null, i32** %t959
  %t960 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t958, i32 0, i32 1
  store i64 0, i64* %t960
  %t961 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t958, i32 0, i32 2
  store i64 0, i64* %t961
  store i8* %t957, i8** %t690
  br label %set_cow_done_208
set_cow_check_207:
  %t962 = getelementptr inbounds i8, i8* %t954, i64 -16
  %t963 = bitcast i8* %t962 to i64*
  %t964 = load atomic i64, i64* %t963 seq_cst, align 8
  %t965 = icmp eq i64 %t964, 1
  br i1 %t965, label %set_cow_done_208, label %set_cow_clone_209
set_cow_clone_209:
  %t966 = bitcast i8* %t954 to { i32*, i64, i64 }*
  %t967 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t966, i32 0, i32 0
  %t968 = load i32*, i32** %t967
  %t969 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t966, i32 0, i32 1
  %t970 = load i64, i64* %t969
  %t971 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t966, i32 0, i32 2
  %t972 = load i64, i64* %t971
  %t973 = bitcast void (i8*)* @set_release_i32 to i8*
  %t974 = call i8* @star_rc_alloc(i64 24, i8* %t973)
  %t975 = bitcast i8* %t974 to { i32*, i64, i64 }*
  %t976 = mul i64 %t972, %t953
  %t977 = call i8* @malloc(i64 %t976)
  %t978 = bitcast i8* %t977 to i32*
  %t979 = icmp sgt i64 %t970, 0
  br i1 %t979, label %set_cow_copy_210, label %set_cow_after_copy_211
set_cow_copy_210:
  %t980 = mul i64 %t970, %t953
  %t981 = bitcast i32* %t968 to i8*
  call i8* @memcpy(i8* %t977, i8* %t981, i64 %t980)
  br label %set_cow_after_copy_211
set_cow_after_copy_211:
  %t982 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t975, i32 0, i32 0
  store i32* %t978, i32** %t982
  %t983 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t975, i32 0, i32 1
  store i64 %t970, i64* %t983
  %t984 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t975, i32 0, i32 2
  store i64 %t972, i64* %t984
  call void @star_rc_release(i8* %t954)
  store i8* %t974, i8** %t690
  br label %set_cow_done_208
set_cow_done_208:
  %t985 = load i8*, i8** %t690
  %t986 = bitcast i8* %t985 to { i32*, i64, i64 }*
  %t987 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t986, i32 0, i32 0
  %t988 = load i32*, i32** %t987
  %t989 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t986, i32 0, i32 1
  %t990 = load i64, i64* %t989
  %t991 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t986, i32 0, i32 2
  %t992 = load i64, i64* %t989
  %t993 = load i32*, i32** %t987
  store i64 0, i64* %t994
  store i1 false, i1* %t995
  br label %find_cond_212
find_cond_212:
  %t996 = load i64, i64* %t994
  %t997 = icmp slt i64 %t996, %t992
  br i1 %t997, label %find_body_213, label %find_end_216
find_body_213:
  %t998 = getelementptr inbounds i32, i32* %t993, i64 %t996
  %t999 = load i32, i32* %t998
  br label %find_eq_check_214
find_eq_check_214:
  %t1000 = call i1 @eq_i32(i32 %t999, i32 2)
  br i1 %t1000, label %find_end_216, label %find_next_215
find_next_215:
  %t1001 = add i64 %t996, 1
  store i64 %t1001, i64* %t994
  br label %find_cond_212
find_end_216:
  %t1002 = load i64, i64* %t994
  %t1003 = icmp slt i64 %t1002, %t992
  br i1 %t1003, label %set_remove_do_217, label %set_remove_end_218
set_remove_do_217:
  %t1004 = getelementptr inbounds i32, i32* %t993, i64 %t1002
  %t1005 = sub i64 %t992, 1
  %t1006 = getelementptr inbounds i32, i32* %t993, i64 %t1005
  %t1007 = load i32, i32* %t1006
  store i32 %t1007, i32* %t1004
  store i64 %t1005, i64* %t989
  br label %set_remove_end_218
set_remove_end_218:
  %t1008 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t1009 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t1010 = select i1 %t1003, i8* %t1008, i8* %t1009
  %t1011 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1011, i8* %t1010)
  %t1012 = load i8*, i8** %t690
  %t1013 = icmp eq i8* %t1012, null
  br i1 %t1013, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t1014 = bitcast i8* %t1012 to { i32*, i64, i64 }*
  %t1015 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1014, i32 0, i32 0
  %t1016 = load i32*, i32** %t1015
  %t1017 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1014, i32 0, i32 1
  %t1018 = load i64, i64* %t1017
  br label %set_read_end_221
set_read_end_221:
  %t1019 = phi i32* [ null, %set_read_null_219 ], [ %t1016, %set_read_real_220 ]
  %t1020 = phi i64 [ 0, %set_read_null_219 ], [ %t1018, %set_read_real_220 ]
  store i64 0, i64* %t1021
  store i1 false, i1* %t1022
  br label %find_cond_222
find_cond_222:
  %t1023 = load i64, i64* %t1021
  %t1024 = icmp slt i64 %t1023, %t1020
  br i1 %t1024, label %find_body_223, label %find_end_226
find_body_223:
  %t1025 = getelementptr inbounds i32, i32* %t1019, i64 %t1023
  %t1026 = load i32, i32* %t1025
  br label %find_eq_check_224
find_eq_check_224:
  %t1027 = call i1 @eq_i32(i32 %t1026, i32 2)
  br i1 %t1027, label %find_end_226, label %find_next_225
find_next_225:
  %t1028 = add i64 %t1023, 1
  store i64 %t1028, i64* %t1021
  br label %find_cond_222
find_end_226:
  %t1029 = load i64, i64* %t1021
  %t1030 = icmp slt i64 %t1029, %t1020
  %t1031 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1032 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1033 = select i1 %t1030, i8* %t1031, i8* %t1032
  %t1034 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1034, i8* %t1033)
  %t1035 = getelementptr i32, i32* null, i32 1
  %t1036 = ptrtoint i32* %t1035 to i64
  %t1037 = load i8*, i8** %t690
  %t1038 = icmp eq i8* %t1037, null
  br i1 %t1038, label %set_cow_alloc_227, label %set_cow_check_228
set_cow_alloc_227:
  %t1039 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1040 = call i8* @star_rc_alloc(i64 24, i8* %t1039)
  %t1041 = bitcast i8* %t1040 to { i32*, i64, i64 }*
  %t1042 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1041, i32 0, i32 0
  store i32* null, i32** %t1042
  %t1043 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1041, i32 0, i32 1
  store i64 0, i64* %t1043
  %t1044 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1041, i32 0, i32 2
  store i64 0, i64* %t1044
  store i8* %t1040, i8** %t690
  br label %set_cow_done_229
set_cow_check_228:
  %t1045 = getelementptr inbounds i8, i8* %t1037, i64 -16
  %t1046 = bitcast i8* %t1045 to i64*
  %t1047 = load atomic i64, i64* %t1046 seq_cst, align 8
  %t1048 = icmp eq i64 %t1047, 1
  br i1 %t1048, label %set_cow_done_229, label %set_cow_clone_230
set_cow_clone_230:
  %t1049 = bitcast i8* %t1037 to { i32*, i64, i64 }*
  %t1050 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1049, i32 0, i32 0
  %t1051 = load i32*, i32** %t1050
  %t1052 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1049, i32 0, i32 1
  %t1053 = load i64, i64* %t1052
  %t1054 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1049, i32 0, i32 2
  %t1055 = load i64, i64* %t1054
  %t1056 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1057 = call i8* @star_rc_alloc(i64 24, i8* %t1056)
  %t1058 = bitcast i8* %t1057 to { i32*, i64, i64 }*
  %t1059 = mul i64 %t1055, %t1036
  %t1060 = call i8* @malloc(i64 %t1059)
  %t1061 = bitcast i8* %t1060 to i32*
  %t1062 = icmp sgt i64 %t1053, 0
  br i1 %t1062, label %set_cow_copy_231, label %set_cow_after_copy_232
set_cow_copy_231:
  %t1063 = mul i64 %t1053, %t1036
  %t1064 = bitcast i32* %t1051 to i8*
  call i8* @memcpy(i8* %t1060, i8* %t1064, i64 %t1063)
  br label %set_cow_after_copy_232
set_cow_after_copy_232:
  %t1065 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 0
  store i32* %t1061, i32** %t1065
  %t1066 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 1
  store i64 %t1053, i64* %t1066
  %t1067 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 2
  store i64 %t1055, i64* %t1067
  call void @star_rc_release(i8* %t1037)
  store i8* %t1057, i8** %t690
  br label %set_cow_done_229
set_cow_done_229:
  %t1068 = load i8*, i8** %t690
  %t1069 = bitcast i8* %t1068 to { i32*, i64, i64 }*
  %t1070 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1069, i32 0, i32 0
  %t1071 = load i32*, i32** %t1070
  %t1072 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1069, i32 0, i32 1
  %t1073 = load i64, i64* %t1072
  %t1074 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1069, i32 0, i32 2
  %t1075 = load i64, i64* %t1072
  %t1076 = load i32*, i32** %t1070
  store i64 0, i64* %t1077
  store i1 false, i1* %t1078
  br label %find_cond_233
find_cond_233:
  %t1079 = load i64, i64* %t1077
  %t1080 = icmp slt i64 %t1079, %t1075
  br i1 %t1080, label %find_body_234, label %find_end_237
find_body_234:
  %t1081 = getelementptr inbounds i32, i32* %t1076, i64 %t1079
  %t1082 = load i32, i32* %t1081
  br label %find_eq_check_235
find_eq_check_235:
  %t1083 = call i1 @eq_i32(i32 %t1082, i32 2)
  br i1 %t1083, label %find_end_237, label %find_next_236
find_next_236:
  %t1084 = add i64 %t1079, 1
  store i64 %t1084, i64* %t1077
  br label %find_cond_233
find_end_237:
  %t1085 = load i64, i64* %t1077
  %t1086 = icmp slt i64 %t1085, %t1075
  br i1 %t1086, label %set_remove_do_238, label %set_remove_end_239
set_remove_do_238:
  %t1087 = getelementptr inbounds i32, i32* %t1076, i64 %t1085
  %t1088 = sub i64 %t1075, 1
  %t1089 = getelementptr inbounds i32, i32* %t1076, i64 %t1088
  %t1090 = load i32, i32* %t1089
  store i32 %t1090, i32* %t1087
  store i64 %t1088, i64* %t1072
  br label %set_remove_end_239
set_remove_end_239:
  %t1091 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1092 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1093 = select i1 %t1086, i8* %t1091, i8* %t1092
  %t1094 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1094, i8* %t1093)
  %t1095 = load i8*, i8** %t690
  %t1096 = icmp eq i8* %t1095, null
  br i1 %t1096, label %set_read_null_240, label %set_read_real_241
set_read_null_240:
  br label %set_read_end_242
set_read_real_241:
  %t1097 = bitcast i8* %t1095 to { i32*, i64, i64 }*
  %t1098 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1097, i32 0, i32 0
  %t1099 = load i32*, i32** %t1098
  %t1100 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1097, i32 0, i32 1
  %t1101 = load i64, i64* %t1100
  br label %set_read_end_242
set_read_end_242:
  %t1102 = phi i32* [ null, %set_read_null_240 ], [ %t1099, %set_read_real_241 ]
  %t1103 = phi i64 [ 0, %set_read_null_240 ], [ %t1101, %set_read_real_241 ]
  %t1104 = trunc i64 %t1103 to i32
  %t1105 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1105, i32 %t1104)
  store i8* null, i8** %t1106
  %t1107 = getelementptr %Point, %Point* null, i32 1
  %t1108 = ptrtoint %Point* %t1107 to i64
  %t1109 = load i8*, i8** %t1106
  %t1110 = icmp eq i8* %t1109, null
  br i1 %t1110, label %set_cow_alloc_243, label %set_cow_check_244
set_cow_alloc_243:
  %t1115 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1116 = call i8* @star_rc_alloc(i64 24, i8* %t1115)
  %t1117 = bitcast i8* %t1116 to { %Point*, i64, i64 }*
  %t1118 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1117, i32 0, i32 0
  store %Point* null, %Point** %t1118
  %t1119 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1117, i32 0, i32 1
  store i64 0, i64* %t1119
  %t1120 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1117, i32 0, i32 2
  store i64 0, i64* %t1120
  store i8* %t1116, i8** %t1106
  br label %set_cow_done_245
set_cow_check_244:
  %t1121 = getelementptr inbounds i8, i8* %t1109, i64 -16
  %t1122 = bitcast i8* %t1121 to i64*
  %t1123 = load atomic i64, i64* %t1122 seq_cst, align 8
  %t1124 = icmp eq i64 %t1123, 1
  br i1 %t1124, label %set_cow_done_245, label %set_cow_clone_246
set_cow_clone_246:
  %t1125 = bitcast i8* %t1109 to { %Point*, i64, i64 }*
  %t1126 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1125, i32 0, i32 0
  %t1127 = load %Point*, %Point** %t1126
  %t1128 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1125, i32 0, i32 1
  %t1129 = load i64, i64* %t1128
  %t1130 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1125, i32 0, i32 2
  %t1131 = load i64, i64* %t1130
  %t1132 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1133 = call i8* @star_rc_alloc(i64 24, i8* %t1132)
  %t1134 = bitcast i8* %t1133 to { %Point*, i64, i64 }*
  %t1135 = mul i64 %t1131, %t1108
  %t1136 = call i8* @malloc(i64 %t1135)
  %t1137 = bitcast i8* %t1136 to %Point*
  %t1138 = icmp sgt i64 %t1129, 0
  br i1 %t1138, label %set_cow_copy_247, label %set_cow_after_copy_248
set_cow_copy_247:
  %t1139 = mul i64 %t1129, %t1108
  %t1140 = bitcast %Point* %t1127 to i8*
  call i8* @memcpy(i8* %t1136, i8* %t1140, i64 %t1139)
  br label %set_cow_after_copy_248
set_cow_after_copy_248:
  %t1141 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1134, i32 0, i32 0
  store %Point* %t1137, %Point** %t1141
  %t1142 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1134, i32 0, i32 1
  store i64 %t1129, i64* %t1142
  %t1143 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1134, i32 0, i32 2
  store i64 %t1131, i64* %t1143
  call void @star_rc_release(i8* %t1109)
  store i8* %t1133, i8** %t1106
  br label %set_cow_done_245
set_cow_done_245:
  %t1144 = load i8*, i8** %t1106
  %t1145 = bitcast i8* %t1144 to { %Point*, i64, i64 }*
  %t1146 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1145, i32 0, i32 0
  %t1147 = load %Point*, %Point** %t1146
  %t1148 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1145, i32 0, i32 1
  %t1149 = load i64, i64* %t1148
  %t1150 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1145, i32 0, i32 2
  %t1152 = getelementptr inbounds %Point, %Point* %t1151, i32 0, i32 0
  store i32 1, i32* %t1152
  %t1153 = getelementptr inbounds %Point, %Point* %t1151, i32 0, i32 1
  store i32 2, i32* %t1153
  %t1154 = load %Point, %Point* %t1151
  %t1155 = load i64, i64* %t1148
  %t1156 = load %Point*, %Point** %t1146
  store i64 0, i64* %t1164
  store i1 false, i1* %t1165
  br label %find_cond_249
find_cond_249:
  %t1166 = load i64, i64* %t1164
  %t1167 = icmp slt i64 %t1166, %t1155
  br i1 %t1167, label %find_body_250, label %find_end_253
find_body_250:
  %t1168 = getelementptr inbounds %Point, %Point* %t1156, i64 %t1166
  %t1169 = load %Point, %Point* %t1168
  br label %find_eq_check_251
find_eq_check_251:
  %t1170 = call i1 @eq_s_Point(%Point %t1169, %Point %t1154)
  br i1 %t1170, label %find_end_253, label %find_next_252
find_next_252:
  %t1171 = add i64 %t1166, 1
  store i64 %t1171, i64* %t1164
  br label %find_cond_249
find_end_253:
  %t1172 = load i64, i64* %t1164
  %t1173 = icmp slt i64 %t1172, %t1155
  br i1 %t1173, label %set_insert_already_present_254, label %set_insert_do_255
set_insert_already_present_254:
  br label %set_insert_end_256
set_insert_do_255:
  %t1174 = load i64, i64* %t1150
  %t1175 = load %Point*, %Point** %t1146
  %t1176 = icmp sge i64 %t1155, %t1174
  br i1 %t1176, label %set_insert_grow_257, label %set_insert_store_258
set_insert_grow_257:
  %t1177 = mul i64 %t1174, 2
  %t1178 = icmp sgt i64 %t1177, 0
  %t1179 = select i1 %t1178, i64 %t1177, i64 1
  %t1180 = getelementptr %Point, %Point* null, i32 1
  %t1181 = ptrtoint %Point* %t1180 to i64
  %t1182 = mul i64 %t1179, %t1181
  %t1183 = call i8* @malloc(i64 %t1182)
  %t1184 = bitcast i8* %t1183 to %Point*
  %t1185 = icmp sgt i64 %t1174, 0
  br i1 %t1185, label %set_insert_copy_259, label %set_insert_after_copy_260
set_insert_copy_259:
  %t1186 = mul i64 %t1155, %t1181
  %t1187 = bitcast %Point* %t1175 to i8*
  call i8* @memcpy(i8* %t1183, i8* %t1187, i64 %t1186)
  call void @free(i8* %t1187)
  br label %set_insert_after_copy_260
set_insert_after_copy_260:
  store %Point* %t1184, %Point** %t1146
  store i64 %t1179, i64* %t1150
  br label %set_insert_store_258
set_insert_store_258:
  %t1188 = load %Point*, %Point** %t1146
  %t1189 = getelementptr inbounds %Point, %Point* %t1188, i64 %t1155
  store %Point %t1154, %Point* %t1189
  %t1190 = add i64 %t1155, 1
  store i64 %t1190, i64* %t1148
  br label %set_insert_end_256
set_insert_end_256:
  %t1191 = phi i1 [ false, %set_insert_already_present_254 ], [ true, %set_insert_store_258 ]
  %t1192 = getelementptr %Point, %Point* null, i32 1
  %t1193 = ptrtoint %Point* %t1192 to i64
  %t1194 = load i8*, i8** %t1106
  %t1195 = icmp eq i8* %t1194, null
  br i1 %t1195, label %set_cow_alloc_261, label %set_cow_check_262
set_cow_alloc_261:
  %t1196 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1197 = call i8* @star_rc_alloc(i64 24, i8* %t1196)
  %t1198 = bitcast i8* %t1197 to { %Point*, i64, i64 }*
  %t1199 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1198, i32 0, i32 0
  store %Point* null, %Point** %t1199
  %t1200 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1198, i32 0, i32 1
  store i64 0, i64* %t1200
  %t1201 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1198, i32 0, i32 2
  store i64 0, i64* %t1201
  store i8* %t1197, i8** %t1106
  br label %set_cow_done_263
set_cow_check_262:
  %t1202 = getelementptr inbounds i8, i8* %t1194, i64 -16
  %t1203 = bitcast i8* %t1202 to i64*
  %t1204 = load atomic i64, i64* %t1203 seq_cst, align 8
  %t1205 = icmp eq i64 %t1204, 1
  br i1 %t1205, label %set_cow_done_263, label %set_cow_clone_264
set_cow_clone_264:
  %t1206 = bitcast i8* %t1194 to { %Point*, i64, i64 }*
  %t1207 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1206, i32 0, i32 0
  %t1208 = load %Point*, %Point** %t1207
  %t1209 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1206, i32 0, i32 1
  %t1210 = load i64, i64* %t1209
  %t1211 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1206, i32 0, i32 2
  %t1212 = load i64, i64* %t1211
  %t1213 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1214 = call i8* @star_rc_alloc(i64 24, i8* %t1213)
  %t1215 = bitcast i8* %t1214 to { %Point*, i64, i64 }*
  %t1216 = mul i64 %t1212, %t1193
  %t1217 = call i8* @malloc(i64 %t1216)
  %t1218 = bitcast i8* %t1217 to %Point*
  %t1219 = icmp sgt i64 %t1210, 0
  br i1 %t1219, label %set_cow_copy_265, label %set_cow_after_copy_266
set_cow_copy_265:
  %t1220 = mul i64 %t1210, %t1193
  %t1221 = bitcast %Point* %t1208 to i8*
  call i8* @memcpy(i8* %t1217, i8* %t1221, i64 %t1220)
  br label %set_cow_after_copy_266
set_cow_after_copy_266:
  %t1222 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1215, i32 0, i32 0
  store %Point* %t1218, %Point** %t1222
  %t1223 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1215, i32 0, i32 1
  store i64 %t1210, i64* %t1223
  %t1224 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1215, i32 0, i32 2
  store i64 %t1212, i64* %t1224
  call void @star_rc_release(i8* %t1194)
  store i8* %t1214, i8** %t1106
  br label %set_cow_done_263
set_cow_done_263:
  %t1225 = load i8*, i8** %t1106
  %t1226 = bitcast i8* %t1225 to { %Point*, i64, i64 }*
  %t1227 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1226, i32 0, i32 0
  %t1228 = load %Point*, %Point** %t1227
  %t1229 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1226, i32 0, i32 1
  %t1230 = load i64, i64* %t1229
  %t1231 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1226, i32 0, i32 2
  %t1233 = getelementptr inbounds %Point, %Point* %t1232, i32 0, i32 0
  store i32 1, i32* %t1233
  %t1234 = getelementptr inbounds %Point, %Point* %t1232, i32 0, i32 1
  store i32 2, i32* %t1234
  %t1235 = load %Point, %Point* %t1232
  %t1236 = load i64, i64* %t1229
  %t1237 = load %Point*, %Point** %t1227
  store i64 0, i64* %t1238
  store i1 false, i1* %t1239
  br label %find_cond_267
find_cond_267:
  %t1240 = load i64, i64* %t1238
  %t1241 = icmp slt i64 %t1240, %t1236
  br i1 %t1241, label %find_body_268, label %find_end_271
find_body_268:
  %t1242 = getelementptr inbounds %Point, %Point* %t1237, i64 %t1240
  %t1243 = load %Point, %Point* %t1242
  br label %find_eq_check_269
find_eq_check_269:
  %t1244 = call i1 @eq_s_Point(%Point %t1243, %Point %t1235)
  br i1 %t1244, label %find_end_271, label %find_next_270
find_next_270:
  %t1245 = add i64 %t1240, 1
  store i64 %t1245, i64* %t1238
  br label %find_cond_267
find_end_271:
  %t1246 = load i64, i64* %t1238
  %t1247 = icmp slt i64 %t1246, %t1236
  br i1 %t1247, label %set_insert_already_present_272, label %set_insert_do_273
set_insert_already_present_272:
  br label %set_insert_end_274
set_insert_do_273:
  %t1248 = load i64, i64* %t1231
  %t1249 = load %Point*, %Point** %t1227
  %t1250 = icmp sge i64 %t1236, %t1248
  br i1 %t1250, label %set_insert_grow_275, label %set_insert_store_276
set_insert_grow_275:
  %t1251 = mul i64 %t1248, 2
  %t1252 = icmp sgt i64 %t1251, 0
  %t1253 = select i1 %t1252, i64 %t1251, i64 1
  %t1254 = getelementptr %Point, %Point* null, i32 1
  %t1255 = ptrtoint %Point* %t1254 to i64
  %t1256 = mul i64 %t1253, %t1255
  %t1257 = call i8* @malloc(i64 %t1256)
  %t1258 = bitcast i8* %t1257 to %Point*
  %t1259 = icmp sgt i64 %t1248, 0
  br i1 %t1259, label %set_insert_copy_277, label %set_insert_after_copy_278
set_insert_copy_277:
  %t1260 = mul i64 %t1236, %t1255
  %t1261 = bitcast %Point* %t1249 to i8*
  call i8* @memcpy(i8* %t1257, i8* %t1261, i64 %t1260)
  call void @free(i8* %t1261)
  br label %set_insert_after_copy_278
set_insert_after_copy_278:
  store %Point* %t1258, %Point** %t1227
  store i64 %t1253, i64* %t1231
  br label %set_insert_store_276
set_insert_store_276:
  %t1262 = load %Point*, %Point** %t1227
  %t1263 = getelementptr inbounds %Point, %Point* %t1262, i64 %t1236
  store %Point %t1235, %Point* %t1263
  %t1264 = add i64 %t1236, 1
  store i64 %t1264, i64* %t1229
  br label %set_insert_end_274
set_insert_end_274:
  %t1265 = phi i1 [ false, %set_insert_already_present_272 ], [ true, %set_insert_store_276 ]
  %t1266 = getelementptr %Point, %Point* null, i32 1
  %t1267 = ptrtoint %Point* %t1266 to i64
  %t1268 = load i8*, i8** %t1106
  %t1269 = icmp eq i8* %t1268, null
  br i1 %t1269, label %set_cow_alloc_279, label %set_cow_check_280
set_cow_alloc_279:
  %t1270 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1271 = call i8* @star_rc_alloc(i64 24, i8* %t1270)
  %t1272 = bitcast i8* %t1271 to { %Point*, i64, i64 }*
  %t1273 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1272, i32 0, i32 0
  store %Point* null, %Point** %t1273
  %t1274 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1272, i32 0, i32 1
  store i64 0, i64* %t1274
  %t1275 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1272, i32 0, i32 2
  store i64 0, i64* %t1275
  store i8* %t1271, i8** %t1106
  br label %set_cow_done_281
set_cow_check_280:
  %t1276 = getelementptr inbounds i8, i8* %t1268, i64 -16
  %t1277 = bitcast i8* %t1276 to i64*
  %t1278 = load atomic i64, i64* %t1277 seq_cst, align 8
  %t1279 = icmp eq i64 %t1278, 1
  br i1 %t1279, label %set_cow_done_281, label %set_cow_clone_282
set_cow_clone_282:
  %t1280 = bitcast i8* %t1268 to { %Point*, i64, i64 }*
  %t1281 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1280, i32 0, i32 0
  %t1282 = load %Point*, %Point** %t1281
  %t1283 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1280, i32 0, i32 1
  %t1284 = load i64, i64* %t1283
  %t1285 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1280, i32 0, i32 2
  %t1286 = load i64, i64* %t1285
  %t1287 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1288 = call i8* @star_rc_alloc(i64 24, i8* %t1287)
  %t1289 = bitcast i8* %t1288 to { %Point*, i64, i64 }*
  %t1290 = mul i64 %t1286, %t1267
  %t1291 = call i8* @malloc(i64 %t1290)
  %t1292 = bitcast i8* %t1291 to %Point*
  %t1293 = icmp sgt i64 %t1284, 0
  br i1 %t1293, label %set_cow_copy_283, label %set_cow_after_copy_284
set_cow_copy_283:
  %t1294 = mul i64 %t1284, %t1267
  %t1295 = bitcast %Point* %t1282 to i8*
  call i8* @memcpy(i8* %t1291, i8* %t1295, i64 %t1294)
  br label %set_cow_after_copy_284
set_cow_after_copy_284:
  %t1296 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1289, i32 0, i32 0
  store %Point* %t1292, %Point** %t1296
  %t1297 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1289, i32 0, i32 1
  store i64 %t1284, i64* %t1297
  %t1298 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1289, i32 0, i32 2
  store i64 %t1286, i64* %t1298
  call void @star_rc_release(i8* %t1268)
  store i8* %t1288, i8** %t1106
  br label %set_cow_done_281
set_cow_done_281:
  %t1299 = load i8*, i8** %t1106
  %t1300 = bitcast i8* %t1299 to { %Point*, i64, i64 }*
  %t1301 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1300, i32 0, i32 0
  %t1302 = load %Point*, %Point** %t1301
  %t1303 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1300, i32 0, i32 1
  %t1304 = load i64, i64* %t1303
  %t1305 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1300, i32 0, i32 2
  %t1307 = getelementptr inbounds %Point, %Point* %t1306, i32 0, i32 0
  store i32 3, i32* %t1307
  %t1308 = getelementptr inbounds %Point, %Point* %t1306, i32 0, i32 1
  store i32 4, i32* %t1308
  %t1309 = load %Point, %Point* %t1306
  %t1310 = load i64, i64* %t1303
  %t1311 = load %Point*, %Point** %t1301
  store i64 0, i64* %t1312
  store i1 false, i1* %t1313
  br label %find_cond_285
find_cond_285:
  %t1314 = load i64, i64* %t1312
  %t1315 = icmp slt i64 %t1314, %t1310
  br i1 %t1315, label %find_body_286, label %find_end_289
find_body_286:
  %t1316 = getelementptr inbounds %Point, %Point* %t1311, i64 %t1314
  %t1317 = load %Point, %Point* %t1316
  br label %find_eq_check_287
find_eq_check_287:
  %t1318 = call i1 @eq_s_Point(%Point %t1317, %Point %t1309)
  br i1 %t1318, label %find_end_289, label %find_next_288
find_next_288:
  %t1319 = add i64 %t1314, 1
  store i64 %t1319, i64* %t1312
  br label %find_cond_285
find_end_289:
  %t1320 = load i64, i64* %t1312
  %t1321 = icmp slt i64 %t1320, %t1310
  br i1 %t1321, label %set_insert_already_present_290, label %set_insert_do_291
set_insert_already_present_290:
  br label %set_insert_end_292
set_insert_do_291:
  %t1322 = load i64, i64* %t1305
  %t1323 = load %Point*, %Point** %t1301
  %t1324 = icmp sge i64 %t1310, %t1322
  br i1 %t1324, label %set_insert_grow_293, label %set_insert_store_294
set_insert_grow_293:
  %t1325 = mul i64 %t1322, 2
  %t1326 = icmp sgt i64 %t1325, 0
  %t1327 = select i1 %t1326, i64 %t1325, i64 1
  %t1328 = getelementptr %Point, %Point* null, i32 1
  %t1329 = ptrtoint %Point* %t1328 to i64
  %t1330 = mul i64 %t1327, %t1329
  %t1331 = call i8* @malloc(i64 %t1330)
  %t1332 = bitcast i8* %t1331 to %Point*
  %t1333 = icmp sgt i64 %t1322, 0
  br i1 %t1333, label %set_insert_copy_295, label %set_insert_after_copy_296
set_insert_copy_295:
  %t1334 = mul i64 %t1310, %t1329
  %t1335 = bitcast %Point* %t1323 to i8*
  call i8* @memcpy(i8* %t1331, i8* %t1335, i64 %t1334)
  call void @free(i8* %t1335)
  br label %set_insert_after_copy_296
set_insert_after_copy_296:
  store %Point* %t1332, %Point** %t1301
  store i64 %t1327, i64* %t1305
  br label %set_insert_store_294
set_insert_store_294:
  %t1336 = load %Point*, %Point** %t1301
  %t1337 = getelementptr inbounds %Point, %Point* %t1336, i64 %t1310
  store %Point %t1309, %Point* %t1337
  %t1338 = add i64 %t1310, 1
  store i64 %t1338, i64* %t1303
  br label %set_insert_end_292
set_insert_end_292:
  %t1339 = phi i1 [ false, %set_insert_already_present_290 ], [ true, %set_insert_store_294 ]
  %t1340 = load i8*, i8** %t1106
  %t1341 = icmp eq i8* %t1340, null
  br i1 %t1341, label %set_read_null_297, label %set_read_real_298
set_read_null_297:
  br label %set_read_end_299
set_read_real_298:
  %t1342 = bitcast i8* %t1340 to { %Point*, i64, i64 }*
  %t1343 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1342, i32 0, i32 0
  %t1344 = load %Point*, %Point** %t1343
  %t1345 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1342, i32 0, i32 1
  %t1346 = load i64, i64* %t1345
  br label %set_read_end_299
set_read_end_299:
  %t1347 = phi %Point* [ null, %set_read_null_297 ], [ %t1344, %set_read_real_298 ]
  %t1348 = phi i64 [ 0, %set_read_null_297 ], [ %t1346, %set_read_real_298 ]
  %t1349 = trunc i64 %t1348 to i32
  %t1350 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1350, i32 %t1349)
  %t1352 = getelementptr inbounds %Point, %Point* %t1351, i32 0, i32 0
  store i32 1, i32* %t1352
  %t1353 = getelementptr inbounds %Point, %Point* %t1351, i32 0, i32 1
  store i32 2, i32* %t1353
  %t1354 = load %Point, %Point* %t1351
  %t1355 = load i8*, i8** %t1106
  %t1356 = icmp eq i8* %t1355, null
  br i1 %t1356, label %set_read_null_300, label %set_read_real_301
set_read_null_300:
  br label %set_read_end_302
set_read_real_301:
  %t1357 = bitcast i8* %t1355 to { %Point*, i64, i64 }*
  %t1358 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1357, i32 0, i32 0
  %t1359 = load %Point*, %Point** %t1358
  %t1360 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1357, i32 0, i32 1
  %t1361 = load i64, i64* %t1360
  br label %set_read_end_302
set_read_end_302:
  %t1362 = phi %Point* [ null, %set_read_null_300 ], [ %t1359, %set_read_real_301 ]
  %t1363 = phi i64 [ 0, %set_read_null_300 ], [ %t1361, %set_read_real_301 ]
  store i64 0, i64* %t1364
  store i1 false, i1* %t1365
  br label %find_cond_303
find_cond_303:
  %t1366 = load i64, i64* %t1364
  %t1367 = icmp slt i64 %t1366, %t1363
  br i1 %t1367, label %find_body_304, label %find_end_307
find_body_304:
  %t1368 = getelementptr inbounds %Point, %Point* %t1362, i64 %t1366
  %t1369 = load %Point, %Point* %t1368
  br label %find_eq_check_305
find_eq_check_305:
  %t1370 = call i1 @eq_s_Point(%Point %t1369, %Point %t1354)
  br i1 %t1370, label %find_end_307, label %find_next_306
find_next_306:
  %t1371 = add i64 %t1366, 1
  store i64 %t1371, i64* %t1364
  br label %find_cond_303
find_end_307:
  %t1372 = load i64, i64* %t1364
  %t1373 = icmp slt i64 %t1372, %t1363
  %t1374 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t1375 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t1376 = select i1 %t1373, i8* %t1374, i8* %t1375
  %t1377 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1377, i8* %t1376)
  %t1379 = getelementptr inbounds %Point, %Point* %t1378, i32 0, i32 0
  store i32 9, i32* %t1379
  %t1380 = getelementptr inbounds %Point, %Point* %t1378, i32 0, i32 1
  store i32 9, i32* %t1380
  %t1381 = load %Point, %Point* %t1378
  %t1382 = load i8*, i8** %t1106
  %t1383 = icmp eq i8* %t1382, null
  br i1 %t1383, label %set_read_null_308, label %set_read_real_309
set_read_null_308:
  br label %set_read_end_310
set_read_real_309:
  %t1384 = bitcast i8* %t1382 to { %Point*, i64, i64 }*
  %t1385 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1384, i32 0, i32 0
  %t1386 = load %Point*, %Point** %t1385
  %t1387 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1384, i32 0, i32 1
  %t1388 = load i64, i64* %t1387
  br label %set_read_end_310
set_read_end_310:
  %t1389 = phi %Point* [ null, %set_read_null_308 ], [ %t1386, %set_read_real_309 ]
  %t1390 = phi i64 [ 0, %set_read_null_308 ], [ %t1388, %set_read_real_309 ]
  store i64 0, i64* %t1391
  store i1 false, i1* %t1392
  br label %find_cond_311
find_cond_311:
  %t1393 = load i64, i64* %t1391
  %t1394 = icmp slt i64 %t1393, %t1390
  br i1 %t1394, label %find_body_312, label %find_end_315
find_body_312:
  %t1395 = getelementptr inbounds %Point, %Point* %t1389, i64 %t1393
  %t1396 = load %Point, %Point* %t1395
  br label %find_eq_check_313
find_eq_check_313:
  %t1397 = call i1 @eq_s_Point(%Point %t1396, %Point %t1381)
  br i1 %t1397, label %find_end_315, label %find_next_314
find_next_314:
  %t1398 = add i64 %t1393, 1
  store i64 %t1398, i64* %t1391
  br label %find_cond_311
find_end_315:
  %t1399 = load i64, i64* %t1391
  %t1400 = icmp slt i64 %t1399, %t1390
  %t1401 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1402 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1403 = select i1 %t1400, i8* %t1401, i8* %t1402
  %t1404 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1404, i8* %t1403)
  %t1405 = load i8*, i8** %t1106
  call void @star_rc_release(i8* %t1405)
  %t1406 = load i8*, i8** %t690
  call void @star_rc_release(i8* %t1406)
  %t1407 = load i8*, i8** %t508
  call void @star_rc_release(i8* %t1407)
  %t1408 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1408)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_3_stri32(i8* %objp) {
entry:
  %t14 = alloca i64
  %t7 = bitcast i8* %objp to { i8**, i32*, i64, i64 }*
  %t8 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i8**, i8*** %t8
  %t10 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 1
  %t11 = load i32*, i32** %t10
  %t12 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 2
  %t13 = load i64, i64* %t12
  store i64 0, i64* %t14
  br label %map_release_cond_3
map_release_cond_3:
  %t15 = load i64, i64* %t14
  %t16 = icmp slt i64 %t15, %t13
  br i1 %t16, label %map_release_body_4, label %map_release_end_5
map_release_body_4:
  %t17 = getelementptr inbounds i8*, i8** %t9, i64 %t15
  %t18 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t18)
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* %t14
  br label %map_release_cond_3
map_release_end_5:
  %t20 = bitcast i8** %t9 to i8*
  call void @free(i8* %t20)
  %t21 = bitcast i32* %t11 to i8*
  call void @free(i8* %t21)
  ret void
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t78 = call i32 @strcmp(i8* %a, i8* %b)
  %t79 = icmp eq i32 %t78, 0
  ret i1 %t79
}


define void @set_release_i32(i8* %objp) {
entry:
  %t695 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t696 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t695, i32 0, i32 0
  %t697 = load i32*, i32** %t696
  %t698 = bitcast i32* %t697 to i8*
  call void @free(i8* %t698)
  ret void
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t737 = icmp eq i32 %a, %b
  ret i1 %t737
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1111 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t1112 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1111, i32 0, i32 0
  %t1113 = load %Point*, %Point** %t1112
  %t1114 = bitcast %Point* %t1113 to i8*
  call void @free(i8* %t1114)
  ret void
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t1157 = extractvalue %Point %a, 0
  %t1158 = extractvalue %Point %b, 0
  %t1159 = icmp eq i32 %t1157, %t1158
  %t1160 = extractvalue %Point %a, 1
  %t1161 = extractvalue %Point %b, 1
  %t1162 = icmp eq i32 %t1160, %t1161
  %t1163 = and i1 %t1159, %t1162
  ret i1 %t1163
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
