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

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

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
  %t2 = alloca i8*
  %t58 = alloca i64
  %t82 = alloca i64
  %t91 = alloca i8*
  %t162 = alloca i64
  %t184 = alloca i64
  %t193 = alloca i8*
  %t251 = alloca i64
  %t260 = alloca i8*
  %t264 = alloca %Option__i32
  %t270 = alloca %Option__i32
  %t274 = alloca %Option__i32
  %t307 = alloca i64
  %t316 = alloca i8*
  %t320 = alloca %Option__i32
  %t326 = alloca %Option__i32
  %t330 = alloca %Option__i32
  %t390 = alloca i64
  %t412 = alloca i64
  %t421 = alloca i8*
  %t479 = alloca i64
  %t488 = alloca i8*
  %t492 = alloca %Option__i32
  %t498 = alloca %Option__i32
  %t502 = alloca %Option__i32
  %t522 = alloca i8*
  %t538 = alloca i64
  %t547 = alloca i8*
  %t594 = alloca i64
  %t613 = alloca i64
  %t622 = alloca i8*
  %t633 = alloca %Option__i32
  %t639 = alloca %Option__i32
  %t643 = alloca %Option__i32
  %t677 = alloca i64
  %t686 = alloca i8*
  %t706 = alloca i8*
  %t754 = alloca i64
  %t755 = alloca i1
  %t828 = alloca i64
  %t829 = alloca i1
  %t902 = alloca i64
  %t903 = alloca i1
  %t954 = alloca i64
  %t955 = alloca i1
  %t1010 = alloca i64
  %t1011 = alloca i1
  %t1037 = alloca i64
  %t1038 = alloca i1
  %t1093 = alloca i64
  %t1094 = alloca i1
  %t1122 = alloca i8*
  %t1167 = alloca %Point
  %t1180 = alloca i64
  %t1181 = alloca i1
  %t1248 = alloca %Point
  %t1254 = alloca i64
  %t1255 = alloca i1
  %t1322 = alloca %Point
  %t1328 = alloca i64
  %t1329 = alloca i1
  %t1367 = alloca %Point
  %t1380 = alloca i64
  %t1381 = alloca i1
  %t1394 = alloca %Point
  %t1407 = alloca i64
  %t1408 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  %t3 = getelementptr i8*, i8** null, i32 1
  %t4 = ptrtoint i8** %t3 to i64
  %t5 = getelementptr i32, i32* null, i32 1
  %t6 = ptrtoint i32* %t5 to i64
  %t7 = load i8*, i8** %t2
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t24 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t25 = call i8* @star_rc_alloc(i64 32, i8* %t24)
  %t26 = bitcast i8* %t25 to { i8**, i32*, i64, i64 }*
  %t27 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t26, i32 0, i32 0
  store i8** null, i8*** %t27
  %t28 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t26, i32 0, i32 1
  store i32* null, i32** %t28
  %t29 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t26, i32 0, i32 2
  store i64 0, i64* %t29
  %t30 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t26, i32 0, i32 3
  store i64 0, i64* %t30
  store i8* %t25, i8** %t2
  br label %map_cow_done_2
map_cow_check_1:
  %t31 = getelementptr inbounds i8, i8* %t7, i64 -16
  %t32 = bitcast i8* %t31 to i64*
  %t33 = load atomic i64, i64* %t32 seq_cst, align 8
  %t34 = icmp eq i64 %t33, 1
  br i1 %t34, label %map_cow_done_2, label %map_cow_clone_6
map_cow_clone_6:
  %t35 = bitcast i8* %t7 to { i8**, i32*, i64, i64 }*
  %t36 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t35, i32 0, i32 0
  %t37 = load i8**, i8*** %t36
  %t38 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t35, i32 0, i32 1
  %t39 = load i32*, i32** %t38
  %t40 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t35, i32 0, i32 2
  %t41 = load i64, i64* %t40
  %t42 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t35, i32 0, i32 3
  %t43 = load i64, i64* %t42
  %t44 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t45 = call i8* @star_rc_alloc(i64 32, i8* %t44)
  %t46 = bitcast i8* %t45 to { i8**, i32*, i64, i64 }*
  %t47 = mul i64 %t43, %t4
  %t48 = call i8* @malloc(i64 %t47)
  %t49 = bitcast i8* %t48 to i8**
  %t50 = mul i64 %t43, %t6
  %t51 = call i8* @malloc(i64 %t50)
  %t52 = bitcast i8* %t51 to i32*
  %t53 = icmp sgt i64 %t41, 0
  br i1 %t53, label %map_cow_copy_7, label %map_cow_after_copy_8
map_cow_copy_7:
  %t54 = mul i64 %t41, %t4
  %t55 = bitcast i8** %t37 to i8*
  call i8* @memcpy(i8* %t48, i8* %t55, i64 %t54)
  %t56 = mul i64 %t41, %t6
  %t57 = bitcast i32* %t39 to i8*
  call i8* @memcpy(i8* %t51, i8* %t57, i64 %t56)
  store i64 0, i64* %t58
  br label %map_cow_retain_cond_9
map_cow_retain_cond_9:
  %t59 = load i64, i64* %t58
  %t60 = icmp slt i64 %t59, %t41
  br i1 %t60, label %map_cow_retain_body_10, label %map_cow_retain_end_11
map_cow_retain_body_10:
  %t61 = getelementptr inbounds i8*, i8** %t49, i64 %t59
  %t62 = load i8*, i8** %t61
  call void @star_rc_retain(i8* %t62)
  %t63 = add i64 %t59, 1
  store i64 %t63, i64* %t58
  br label %map_cow_retain_cond_9
map_cow_retain_end_11:
  br label %map_cow_after_copy_8
map_cow_after_copy_8:
  %t64 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t46, i32 0, i32 0
  store i8** %t49, i8*** %t64
  %t65 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t46, i32 0, i32 1
  store i32* %t52, i32** %t65
  %t66 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t46, i32 0, i32 2
  store i64 %t41, i64* %t66
  %t67 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t46, i32 0, i32 3
  store i64 %t43, i64* %t67
  call void @star_rc_release(i8* %t7)
  store i8* %t45, i8** %t2
  br label %map_cow_done_2
map_cow_done_2:
  %t68 = load i8*, i8** %t2
  %t69 = bitcast i8* %t68 to { i8**, i32*, i64, i64 }*
  %t70 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t69, i32 0, i32 0
  %t71 = load i8**, i8*** %t70
  %t72 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t69, i32 0, i32 1
  %t73 = load i32*, i32** %t72
  %t74 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t69, i32 0, i32 2
  %t75 = load i64, i64* %t74
  %t76 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t69, i32 0, i32 3
  %t77 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t78 = load i64, i64* %t74
  %t79 = load i8**, i8*** %t70
  store i64 0, i64* %t82
  br label %map_find_cond_12
map_find_cond_12:
  %t83 = load i64, i64* %t82
  %t84 = icmp slt i64 %t83, %t78
  br i1 %t84, label %map_find_body_13, label %map_find_end_16
map_find_body_13:
  %t85 = getelementptr inbounds i8*, i8** %t79, i64 %t83
  %t86 = load i8*, i8** %t85
  br label %map_find_eq_check_14
map_find_eq_check_14:
  %t87 = call i1 @eq_str(i8* %t86, i8* %t77)
  br i1 %t87, label %map_find_end_16, label %map_find_next_15
map_find_next_15:
  %t88 = add i64 %t83, 1
  store i64 %t88, i64* %t82
  br label %map_find_cond_12
map_find_end_16:
  %t89 = load i64, i64* %t82
  %t90 = icmp slt i64 %t89, %t78
  br i1 %t90, label %map_insert_overwrite_17, label %map_insert_new_18
map_insert_overwrite_17:
  store i8* %t77, i8** %t91
  %t92 = load i8*, i8** %t91
  call void @star_rc_release(i8* %t92)
  %t93 = load i32*, i32** %t72
  %t94 = getelementptr inbounds i32, i32* %t93, i64 %t89
  store i32 30, i32* %t94
  br label %map_insert_after_19
map_insert_new_18:
  %t95 = load i64, i64* %t76
  %t96 = icmp sge i64 %t78, %t95
  br i1 %t96, label %map_insert_grow_20, label %map_insert_store_21
map_insert_grow_20:
  %t97 = mul i64 %t95, 2
  %t98 = icmp sgt i64 %t97, 0
  %t99 = select i1 %t98, i64 %t97, i64 1
  %t100 = getelementptr i8*, i8** null, i32 1
  %t101 = ptrtoint i8** %t100 to i64
  %t102 = mul i64 %t99, %t101
  %t103 = call i8* @malloc(i64 %t102)
  %t104 = bitcast i8* %t103 to i8**
  %t105 = getelementptr i32, i32* null, i32 1
  %t106 = ptrtoint i32* %t105 to i64
  %t107 = mul i64 %t99, %t106
  %t108 = call i8* @malloc(i64 %t107)
  %t109 = bitcast i8* %t108 to i32*
  %t110 = icmp sgt i64 %t95, 0
  br i1 %t110, label %map_insert_copy_22, label %map_insert_after_copy_23
map_insert_copy_22:
  %t111 = load i8**, i8*** %t70
  %t112 = mul i64 %t78, %t101
  %t113 = bitcast i8** %t111 to i8*
  call i8* @memcpy(i8* %t103, i8* %t113, i64 %t112)
  call void @free(i8* %t113)
  %t114 = load i32*, i32** %t72
  %t115 = mul i64 %t78, %t106
  %t116 = bitcast i32* %t114 to i8*
  call i8* @memcpy(i8* %t108, i8* %t116, i64 %t115)
  call void @free(i8* %t116)
  br label %map_insert_after_copy_23
map_insert_after_copy_23:
  store i8** %t104, i8*** %t70
  store i32* %t109, i32** %t72
  store i64 %t99, i64* %t76
  br label %map_insert_store_21
map_insert_store_21:
  %t117 = load i8**, i8*** %t70
  %t118 = load i32*, i32** %t72
  %t119 = getelementptr inbounds i8*, i8** %t117, i64 %t78
  store i8* %t77, i8** %t119
  %t120 = getelementptr inbounds i32, i32* %t118, i64 %t78
  store i32 30, i32* %t120
  %t121 = add i64 %t78, 1
  store i64 %t121, i64* %t74
  br label %map_insert_after_19
map_insert_after_19:
  %t122 = getelementptr i8*, i8** null, i32 1
  %t123 = ptrtoint i8** %t122 to i64
  %t124 = getelementptr i32, i32* null, i32 1
  %t125 = ptrtoint i32* %t124 to i64
  %t126 = load i8*, i8** %t2
  %t127 = icmp eq i8* %t126, null
  br i1 %t127, label %map_cow_alloc_24, label %map_cow_check_25
map_cow_alloc_24:
  %t128 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t129 = call i8* @star_rc_alloc(i64 32, i8* %t128)
  %t130 = bitcast i8* %t129 to { i8**, i32*, i64, i64 }*
  %t131 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t130, i32 0, i32 0
  store i8** null, i8*** %t131
  %t132 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t130, i32 0, i32 1
  store i32* null, i32** %t132
  %t133 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t130, i32 0, i32 2
  store i64 0, i64* %t133
  %t134 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t130, i32 0, i32 3
  store i64 0, i64* %t134
  store i8* %t129, i8** %t2
  br label %map_cow_done_26
map_cow_check_25:
  %t135 = getelementptr inbounds i8, i8* %t126, i64 -16
  %t136 = bitcast i8* %t135 to i64*
  %t137 = load atomic i64, i64* %t136 seq_cst, align 8
  %t138 = icmp eq i64 %t137, 1
  br i1 %t138, label %map_cow_done_26, label %map_cow_clone_27
map_cow_clone_27:
  %t139 = bitcast i8* %t126 to { i8**, i32*, i64, i64 }*
  %t140 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t139, i32 0, i32 0
  %t141 = load i8**, i8*** %t140
  %t142 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t139, i32 0, i32 1
  %t143 = load i32*, i32** %t142
  %t144 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t139, i32 0, i32 2
  %t145 = load i64, i64* %t144
  %t146 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t139, i32 0, i32 3
  %t147 = load i64, i64* %t146
  %t148 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t149 = call i8* @star_rc_alloc(i64 32, i8* %t148)
  %t150 = bitcast i8* %t149 to { i8**, i32*, i64, i64 }*
  %t151 = mul i64 %t147, %t123
  %t152 = call i8* @malloc(i64 %t151)
  %t153 = bitcast i8* %t152 to i8**
  %t154 = mul i64 %t147, %t125
  %t155 = call i8* @malloc(i64 %t154)
  %t156 = bitcast i8* %t155 to i32*
  %t157 = icmp sgt i64 %t145, 0
  br i1 %t157, label %map_cow_copy_28, label %map_cow_after_copy_29
map_cow_copy_28:
  %t158 = mul i64 %t145, %t123
  %t159 = bitcast i8** %t141 to i8*
  call i8* @memcpy(i8* %t152, i8* %t159, i64 %t158)
  %t160 = mul i64 %t145, %t125
  %t161 = bitcast i32* %t143 to i8*
  call i8* @memcpy(i8* %t155, i8* %t161, i64 %t160)
  store i64 0, i64* %t162
  br label %map_cow_retain_cond_30
map_cow_retain_cond_30:
  %t163 = load i64, i64* %t162
  %t164 = icmp slt i64 %t163, %t145
  br i1 %t164, label %map_cow_retain_body_31, label %map_cow_retain_end_32
map_cow_retain_body_31:
  %t165 = getelementptr inbounds i8*, i8** %t153, i64 %t163
  %t166 = load i8*, i8** %t165
  call void @star_rc_retain(i8* %t166)
  %t167 = add i64 %t163, 1
  store i64 %t167, i64* %t162
  br label %map_cow_retain_cond_30
map_cow_retain_end_32:
  br label %map_cow_after_copy_29
map_cow_after_copy_29:
  %t168 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t150, i32 0, i32 0
  store i8** %t153, i8*** %t168
  %t169 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t150, i32 0, i32 1
  store i32* %t156, i32** %t169
  %t170 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t150, i32 0, i32 2
  store i64 %t145, i64* %t170
  %t171 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t150, i32 0, i32 3
  store i64 %t147, i64* %t171
  call void @star_rc_release(i8* %t126)
  store i8* %t149, i8** %t2
  br label %map_cow_done_26
map_cow_done_26:
  %t172 = load i8*, i8** %t2
  %t173 = bitcast i8* %t172 to { i8**, i32*, i64, i64 }*
  %t174 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load i8**, i8*** %t174
  %t176 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i32*, i32** %t176
  %t178 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t173, i32 0, i32 2
  %t179 = load i64, i64* %t178
  %t180 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t173, i32 0, i32 3
  %t181 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t182 = load i64, i64* %t178
  %t183 = load i8**, i8*** %t174
  store i64 0, i64* %t184
  br label %map_find_cond_33
map_find_cond_33:
  %t185 = load i64, i64* %t184
  %t186 = icmp slt i64 %t185, %t182
  br i1 %t186, label %map_find_body_34, label %map_find_end_37
map_find_body_34:
  %t187 = getelementptr inbounds i8*, i8** %t183, i64 %t185
  %t188 = load i8*, i8** %t187
  br label %map_find_eq_check_35
map_find_eq_check_35:
  %t189 = call i1 @eq_str(i8* %t188, i8* %t181)
  br i1 %t189, label %map_find_end_37, label %map_find_next_36
map_find_next_36:
  %t190 = add i64 %t185, 1
  store i64 %t190, i64* %t184
  br label %map_find_cond_33
map_find_end_37:
  %t191 = load i64, i64* %t184
  %t192 = icmp slt i64 %t191, %t182
  br i1 %t192, label %map_insert_overwrite_38, label %map_insert_new_39
map_insert_overwrite_38:
  store i8* %t181, i8** %t193
  %t194 = load i8*, i8** %t193
  call void @star_rc_release(i8* %t194)
  %t195 = load i32*, i32** %t176
  %t196 = getelementptr inbounds i32, i32* %t195, i64 %t191
  store i32 25, i32* %t196
  br label %map_insert_after_40
map_insert_new_39:
  %t197 = load i64, i64* %t180
  %t198 = icmp sge i64 %t182, %t197
  br i1 %t198, label %map_insert_grow_41, label %map_insert_store_42
map_insert_grow_41:
  %t199 = mul i64 %t197, 2
  %t200 = icmp sgt i64 %t199, 0
  %t201 = select i1 %t200, i64 %t199, i64 1
  %t202 = getelementptr i8*, i8** null, i32 1
  %t203 = ptrtoint i8** %t202 to i64
  %t204 = mul i64 %t201, %t203
  %t205 = call i8* @malloc(i64 %t204)
  %t206 = bitcast i8* %t205 to i8**
  %t207 = getelementptr i32, i32* null, i32 1
  %t208 = ptrtoint i32* %t207 to i64
  %t209 = mul i64 %t201, %t208
  %t210 = call i8* @malloc(i64 %t209)
  %t211 = bitcast i8* %t210 to i32*
  %t212 = icmp sgt i64 %t197, 0
  br i1 %t212, label %map_insert_copy_43, label %map_insert_after_copy_44
map_insert_copy_43:
  %t213 = load i8**, i8*** %t174
  %t214 = mul i64 %t182, %t203
  %t215 = bitcast i8** %t213 to i8*
  call i8* @memcpy(i8* %t205, i8* %t215, i64 %t214)
  call void @free(i8* %t215)
  %t216 = load i32*, i32** %t176
  %t217 = mul i64 %t182, %t208
  %t218 = bitcast i32* %t216 to i8*
  call i8* @memcpy(i8* %t210, i8* %t218, i64 %t217)
  call void @free(i8* %t218)
  br label %map_insert_after_copy_44
map_insert_after_copy_44:
  store i8** %t206, i8*** %t174
  store i32* %t211, i32** %t176
  store i64 %t201, i64* %t180
  br label %map_insert_store_42
map_insert_store_42:
  %t219 = load i8**, i8*** %t174
  %t220 = load i32*, i32** %t176
  %t221 = getelementptr inbounds i8*, i8** %t219, i64 %t182
  store i8* %t181, i8** %t221
  %t222 = getelementptr inbounds i32, i32* %t220, i64 %t182
  store i32 25, i32* %t222
  %t223 = add i64 %t182, 1
  store i64 %t223, i64* %t178
  br label %map_insert_after_40
map_insert_after_40:
  %t224 = load i8*, i8** %t2
  %t225 = icmp eq i8* %t224, null
  br i1 %t225, label %map_read_null_45, label %map_read_real_46
map_read_null_45:
  br label %map_read_end_47
map_read_real_46:
  %t226 = bitcast i8* %t224 to { i8**, i32*, i64, i64 }*
  %t227 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t226, i32 0, i32 0
  %t228 = load i8**, i8*** %t227
  %t229 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t226, i32 0, i32 1
  %t230 = load i32*, i32** %t229
  %t231 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t226, i32 0, i32 2
  %t232 = load i64, i64* %t231
  br label %map_read_end_47
map_read_end_47:
  %t233 = phi i8** [ null, %map_read_null_45 ], [ %t228, %map_read_real_46 ]
  %t234 = phi i32* [ null, %map_read_null_45 ], [ %t230, %map_read_real_46 ]
  %t235 = phi i64 [ 0, %map_read_null_45 ], [ %t232, %map_read_real_46 ]
  %t236 = trunc i64 %t235 to i32
  %t237 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t237, i32 %t236)
  %t238 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t239 = load i8*, i8** %t2
  %t240 = icmp eq i8* %t239, null
  br i1 %t240, label %map_read_null_48, label %map_read_real_49
map_read_null_48:
  br label %map_read_end_50
map_read_real_49:
  %t241 = bitcast i8* %t239 to { i8**, i32*, i64, i64 }*
  %t242 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t241, i32 0, i32 0
  %t243 = load i8**, i8*** %t242
  %t244 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t241, i32 0, i32 1
  %t245 = load i32*, i32** %t244
  %t246 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t241, i32 0, i32 2
  %t247 = load i64, i64* %t246
  br label %map_read_end_50
map_read_end_50:
  %t248 = phi i8** [ null, %map_read_null_48 ], [ %t243, %map_read_real_49 ]
  %t249 = phi i32* [ null, %map_read_null_48 ], [ %t245, %map_read_real_49 ]
  %t250 = phi i64 [ 0, %map_read_null_48 ], [ %t247, %map_read_real_49 ]
  store i64 0, i64* %t251
  br label %map_find_cond_51
map_find_cond_51:
  %t252 = load i64, i64* %t251
  %t253 = icmp slt i64 %t252, %t250
  br i1 %t253, label %map_find_body_52, label %map_find_end_55
map_find_body_52:
  %t254 = getelementptr inbounds i8*, i8** %t248, i64 %t252
  %t255 = load i8*, i8** %t254
  br label %map_find_eq_check_53
map_find_eq_check_53:
  %t256 = call i1 @eq_str(i8* %t255, i8* %t238)
  br i1 %t256, label %map_find_end_55, label %map_find_next_54
map_find_next_54:
  %t257 = add i64 %t252, 1
  store i64 %t257, i64* %t251
  br label %map_find_cond_51
map_find_end_55:
  %t258 = load i64, i64* %t251
  %t259 = icmp slt i64 %t258, %t250
  store i8* %t238, i8** %t260
  %t261 = load i8*, i8** %t260
  call void @star_rc_release(i8* %t261)
  br i1 %t259, label %map_get_some_56, label %map_get_none_57
map_get_some_56:
  %t262 = getelementptr inbounds i32, i32* %t249, i64 %t258
  %t263 = load i32, i32* %t262
  %t265 = getelementptr inbounds %Option__i32, %Option__i32* %t264, i32 0, i32 0
  store i32 1, i32* %t265
  %t266 = getelementptr inbounds %Option__i32, %Option__i32* %t264, i32 0, i32 1
  %t267 = bitcast [1 x i64]* %t266 to { i32 }*
  %t268 = getelementptr inbounds { i32 }, { i32 }* %t267, i32 0, i32 0
  store i32 %t263, i32* %t268
  %t269 = load %Option__i32, %Option__i32* %t264
  br label %map_get_end_58
map_get_none_57:
  %t271 = getelementptr inbounds %Option__i32, %Option__i32* %t270, i32 0, i32 0
  store i32 0, i32* %t271
  %t272 = load %Option__i32, %Option__i32* %t270
  br label %map_get_end_58
map_get_end_58:
  %t273 = phi %Option__i32 [ %t269, %map_get_some_56 ], [ %t272, %map_get_none_57 ]
  store %Option__i32 %t273, %Option__i32* %t274
  br label %match_scrutinee_276
match_scrutinee_276:
  %t280 = getelementptr inbounds %Option__i32, %Option__i32* %t274, i32 0, i32 0
  %t281 = load i32, i32* %t280
  %t279 = icmp eq i32 %t281, 1
  br i1 %t279, label %match_then_0_277, label %match_next_0_278
match_then_0_277:
  %t282 = getelementptr inbounds %Option__i32, %Option__i32* %t274, i32 0, i32 1
  %t283 = bitcast [1 x i64]* %t282 to { i32 }*
  %t284 = getelementptr inbounds { i32 }, { i32 }* %t283, i32 0, i32 0
  %t285 = load i32, i32* %t284
  %t286 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t286, i32 %t285)
  br label %match_end_275
match_next_0_278:
  %t290 = getelementptr inbounds %Option__i32, %Option__i32* %t274, i32 0, i32 0
  %t291 = load i32, i32* %t290
  %t289 = icmp eq i32 %t291, 0
  br i1 %t289, label %match_then_1_287, label %match_next_1_288
match_then_1_287:
  %t292 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t292)
  call i32 (i8*, ...) @printf(i8* %t292)
  %t293 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t293)
  br label %match_end_275
match_next_1_288:
  br label %match_end_275
match_end_275:
  %t294 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t295 = load i8*, i8** %t2
  %t296 = icmp eq i8* %t295, null
  br i1 %t296, label %map_read_null_59, label %map_read_real_60
map_read_null_59:
  br label %map_read_end_61
map_read_real_60:
  %t297 = bitcast i8* %t295 to { i8**, i32*, i64, i64 }*
  %t298 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t297, i32 0, i32 0
  %t299 = load i8**, i8*** %t298
  %t300 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t297, i32 0, i32 1
  %t301 = load i32*, i32** %t300
  %t302 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t297, i32 0, i32 2
  %t303 = load i64, i64* %t302
  br label %map_read_end_61
map_read_end_61:
  %t304 = phi i8** [ null, %map_read_null_59 ], [ %t299, %map_read_real_60 ]
  %t305 = phi i32* [ null, %map_read_null_59 ], [ %t301, %map_read_real_60 ]
  %t306 = phi i64 [ 0, %map_read_null_59 ], [ %t303, %map_read_real_60 ]
  store i64 0, i64* %t307
  br label %map_find_cond_62
map_find_cond_62:
  %t308 = load i64, i64* %t307
  %t309 = icmp slt i64 %t308, %t306
  br i1 %t309, label %map_find_body_63, label %map_find_end_66
map_find_body_63:
  %t310 = getelementptr inbounds i8*, i8** %t304, i64 %t308
  %t311 = load i8*, i8** %t310
  br label %map_find_eq_check_64
map_find_eq_check_64:
  %t312 = call i1 @eq_str(i8* %t311, i8* %t294)
  br i1 %t312, label %map_find_end_66, label %map_find_next_65
map_find_next_65:
  %t313 = add i64 %t308, 1
  store i64 %t313, i64* %t307
  br label %map_find_cond_62
map_find_end_66:
  %t314 = load i64, i64* %t307
  %t315 = icmp slt i64 %t314, %t306
  store i8* %t294, i8** %t316
  %t317 = load i8*, i8** %t316
  call void @star_rc_release(i8* %t317)
  br i1 %t315, label %map_get_some_67, label %map_get_none_68
map_get_some_67:
  %t318 = getelementptr inbounds i32, i32* %t305, i64 %t314
  %t319 = load i32, i32* %t318
  %t321 = getelementptr inbounds %Option__i32, %Option__i32* %t320, i32 0, i32 0
  store i32 1, i32* %t321
  %t322 = getelementptr inbounds %Option__i32, %Option__i32* %t320, i32 0, i32 1
  %t323 = bitcast [1 x i64]* %t322 to { i32 }*
  %t324 = getelementptr inbounds { i32 }, { i32 }* %t323, i32 0, i32 0
  store i32 %t319, i32* %t324
  %t325 = load %Option__i32, %Option__i32* %t320
  br label %map_get_end_69
map_get_none_68:
  %t327 = getelementptr inbounds %Option__i32, %Option__i32* %t326, i32 0, i32 0
  store i32 0, i32* %t327
  %t328 = load %Option__i32, %Option__i32* %t326
  br label %map_get_end_69
map_get_end_69:
  %t329 = phi %Option__i32 [ %t325, %map_get_some_67 ], [ %t328, %map_get_none_68 ]
  store %Option__i32 %t329, %Option__i32* %t330
  br label %match_scrutinee_332
match_scrutinee_332:
  %t336 = getelementptr inbounds %Option__i32, %Option__i32* %t330, i32 0, i32 0
  %t337 = load i32, i32* %t336
  %t335 = icmp eq i32 %t337, 1
  br i1 %t335, label %match_then_0_333, label %match_next_0_334
match_then_0_333:
  %t338 = getelementptr inbounds %Option__i32, %Option__i32* %t330, i32 0, i32 1
  %t339 = bitcast [1 x i64]* %t338 to { i32 }*
  %t340 = getelementptr inbounds { i32 }, { i32 }* %t339, i32 0, i32 0
  %t341 = load i32, i32* %t340
  %t342 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t342, i32 %t341)
  br label %match_end_331
match_next_0_334:
  %t346 = getelementptr inbounds %Option__i32, %Option__i32* %t330, i32 0, i32 0
  %t347 = load i32, i32* %t346
  %t345 = icmp eq i32 %t347, 0
  br i1 %t345, label %match_then_1_343, label %match_next_1_344
match_then_1_343:
  %t348 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t348)
  call i32 (i8*, ...) @printf(i8* %t348)
  %t349 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t349)
  br label %match_end_331
match_next_1_344:
  br label %match_end_331
match_end_331:
  %t350 = getelementptr i8*, i8** null, i32 1
  %t351 = ptrtoint i8** %t350 to i64
  %t352 = getelementptr i32, i32* null, i32 1
  %t353 = ptrtoint i32* %t352 to i64
  %t354 = load i8*, i8** %t2
  %t355 = icmp eq i8* %t354, null
  br i1 %t355, label %map_cow_alloc_70, label %map_cow_check_71
map_cow_alloc_70:
  %t356 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t357 = call i8* @star_rc_alloc(i64 32, i8* %t356)
  %t358 = bitcast i8* %t357 to { i8**, i32*, i64, i64 }*
  %t359 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t358, i32 0, i32 0
  store i8** null, i8*** %t359
  %t360 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t358, i32 0, i32 1
  store i32* null, i32** %t360
  %t361 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t358, i32 0, i32 2
  store i64 0, i64* %t361
  %t362 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t358, i32 0, i32 3
  store i64 0, i64* %t362
  store i8* %t357, i8** %t2
  br label %map_cow_done_72
map_cow_check_71:
  %t363 = getelementptr inbounds i8, i8* %t354, i64 -16
  %t364 = bitcast i8* %t363 to i64*
  %t365 = load atomic i64, i64* %t364 seq_cst, align 8
  %t366 = icmp eq i64 %t365, 1
  br i1 %t366, label %map_cow_done_72, label %map_cow_clone_73
map_cow_clone_73:
  %t367 = bitcast i8* %t354 to { i8**, i32*, i64, i64 }*
  %t368 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t367, i32 0, i32 0
  %t369 = load i8**, i8*** %t368
  %t370 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t367, i32 0, i32 1
  %t371 = load i32*, i32** %t370
  %t372 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t367, i32 0, i32 2
  %t373 = load i64, i64* %t372
  %t374 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t367, i32 0, i32 3
  %t375 = load i64, i64* %t374
  %t376 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t377 = call i8* @star_rc_alloc(i64 32, i8* %t376)
  %t378 = bitcast i8* %t377 to { i8**, i32*, i64, i64 }*
  %t379 = mul i64 %t375, %t351
  %t380 = call i8* @malloc(i64 %t379)
  %t381 = bitcast i8* %t380 to i8**
  %t382 = mul i64 %t375, %t353
  %t383 = call i8* @malloc(i64 %t382)
  %t384 = bitcast i8* %t383 to i32*
  %t385 = icmp sgt i64 %t373, 0
  br i1 %t385, label %map_cow_copy_74, label %map_cow_after_copy_75
map_cow_copy_74:
  %t386 = mul i64 %t373, %t351
  %t387 = bitcast i8** %t369 to i8*
  call i8* @memcpy(i8* %t380, i8* %t387, i64 %t386)
  %t388 = mul i64 %t373, %t353
  %t389 = bitcast i32* %t371 to i8*
  call i8* @memcpy(i8* %t383, i8* %t389, i64 %t388)
  store i64 0, i64* %t390
  br label %map_cow_retain_cond_76
map_cow_retain_cond_76:
  %t391 = load i64, i64* %t390
  %t392 = icmp slt i64 %t391, %t373
  br i1 %t392, label %map_cow_retain_body_77, label %map_cow_retain_end_78
map_cow_retain_body_77:
  %t393 = getelementptr inbounds i8*, i8** %t381, i64 %t391
  %t394 = load i8*, i8** %t393
  call void @star_rc_retain(i8* %t394)
  %t395 = add i64 %t391, 1
  store i64 %t395, i64* %t390
  br label %map_cow_retain_cond_76
map_cow_retain_end_78:
  br label %map_cow_after_copy_75
map_cow_after_copy_75:
  %t396 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t378, i32 0, i32 0
  store i8** %t381, i8*** %t396
  %t397 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t378, i32 0, i32 1
  store i32* %t384, i32** %t397
  %t398 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t378, i32 0, i32 2
  store i64 %t373, i64* %t398
  %t399 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t378, i32 0, i32 3
  store i64 %t375, i64* %t399
  call void @star_rc_release(i8* %t354)
  store i8* %t377, i8** %t2
  br label %map_cow_done_72
map_cow_done_72:
  %t400 = load i8*, i8** %t2
  %t401 = bitcast i8* %t400 to { i8**, i32*, i64, i64 }*
  %t402 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t401, i32 0, i32 0
  %t403 = load i8**, i8*** %t402
  %t404 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t401, i32 0, i32 1
  %t405 = load i32*, i32** %t404
  %t406 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t401, i32 0, i32 2
  %t407 = load i64, i64* %t406
  %t408 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t401, i32 0, i32 3
  %t409 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t410 = load i64, i64* %t406
  %t411 = load i8**, i8*** %t402
  store i64 0, i64* %t412
  br label %map_find_cond_79
map_find_cond_79:
  %t413 = load i64, i64* %t412
  %t414 = icmp slt i64 %t413, %t410
  br i1 %t414, label %map_find_body_80, label %map_find_end_83
map_find_body_80:
  %t415 = getelementptr inbounds i8*, i8** %t411, i64 %t413
  %t416 = load i8*, i8** %t415
  br label %map_find_eq_check_81
map_find_eq_check_81:
  %t417 = call i1 @eq_str(i8* %t416, i8* %t409)
  br i1 %t417, label %map_find_end_83, label %map_find_next_82
map_find_next_82:
  %t418 = add i64 %t413, 1
  store i64 %t418, i64* %t412
  br label %map_find_cond_79
map_find_end_83:
  %t419 = load i64, i64* %t412
  %t420 = icmp slt i64 %t419, %t410
  br i1 %t420, label %map_insert_overwrite_84, label %map_insert_new_85
map_insert_overwrite_84:
  store i8* %t409, i8** %t421
  %t422 = load i8*, i8** %t421
  call void @star_rc_release(i8* %t422)
  %t423 = load i32*, i32** %t404
  %t424 = getelementptr inbounds i32, i32* %t423, i64 %t419
  store i32 31, i32* %t424
  br label %map_insert_after_86
map_insert_new_85:
  %t425 = load i64, i64* %t408
  %t426 = icmp sge i64 %t410, %t425
  br i1 %t426, label %map_insert_grow_87, label %map_insert_store_88
map_insert_grow_87:
  %t427 = mul i64 %t425, 2
  %t428 = icmp sgt i64 %t427, 0
  %t429 = select i1 %t428, i64 %t427, i64 1
  %t430 = getelementptr i8*, i8** null, i32 1
  %t431 = ptrtoint i8** %t430 to i64
  %t432 = mul i64 %t429, %t431
  %t433 = call i8* @malloc(i64 %t432)
  %t434 = bitcast i8* %t433 to i8**
  %t435 = getelementptr i32, i32* null, i32 1
  %t436 = ptrtoint i32* %t435 to i64
  %t437 = mul i64 %t429, %t436
  %t438 = call i8* @malloc(i64 %t437)
  %t439 = bitcast i8* %t438 to i32*
  %t440 = icmp sgt i64 %t425, 0
  br i1 %t440, label %map_insert_copy_89, label %map_insert_after_copy_90
map_insert_copy_89:
  %t441 = load i8**, i8*** %t402
  %t442 = mul i64 %t410, %t431
  %t443 = bitcast i8** %t441 to i8*
  call i8* @memcpy(i8* %t433, i8* %t443, i64 %t442)
  call void @free(i8* %t443)
  %t444 = load i32*, i32** %t404
  %t445 = mul i64 %t410, %t436
  %t446 = bitcast i32* %t444 to i8*
  call i8* @memcpy(i8* %t438, i8* %t446, i64 %t445)
  call void @free(i8* %t446)
  br label %map_insert_after_copy_90
map_insert_after_copy_90:
  store i8** %t434, i8*** %t402
  store i32* %t439, i32** %t404
  store i64 %t429, i64* %t408
  br label %map_insert_store_88
map_insert_store_88:
  %t447 = load i8**, i8*** %t402
  %t448 = load i32*, i32** %t404
  %t449 = getelementptr inbounds i8*, i8** %t447, i64 %t410
  store i8* %t409, i8** %t449
  %t450 = getelementptr inbounds i32, i32* %t448, i64 %t410
  store i32 31, i32* %t450
  %t451 = add i64 %t410, 1
  store i64 %t451, i64* %t406
  br label %map_insert_after_86
map_insert_after_86:
  %t452 = load i8*, i8** %t2
  %t453 = icmp eq i8* %t452, null
  br i1 %t453, label %map_read_null_91, label %map_read_real_92
map_read_null_91:
  br label %map_read_end_93
map_read_real_92:
  %t454 = bitcast i8* %t452 to { i8**, i32*, i64, i64 }*
  %t455 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t454, i32 0, i32 0
  %t456 = load i8**, i8*** %t455
  %t457 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t454, i32 0, i32 1
  %t458 = load i32*, i32** %t457
  %t459 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t454, i32 0, i32 2
  %t460 = load i64, i64* %t459
  br label %map_read_end_93
map_read_end_93:
  %t461 = phi i8** [ null, %map_read_null_91 ], [ %t456, %map_read_real_92 ]
  %t462 = phi i32* [ null, %map_read_null_91 ], [ %t458, %map_read_real_92 ]
  %t463 = phi i64 [ 0, %map_read_null_91 ], [ %t460, %map_read_real_92 ]
  %t464 = trunc i64 %t463 to i32
  %t465 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t465, i32 %t464)
  %t466 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t467 = load i8*, i8** %t2
  %t468 = icmp eq i8* %t467, null
  br i1 %t468, label %map_read_null_94, label %map_read_real_95
map_read_null_94:
  br label %map_read_end_96
map_read_real_95:
  %t469 = bitcast i8* %t467 to { i8**, i32*, i64, i64 }*
  %t470 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t469, i32 0, i32 0
  %t471 = load i8**, i8*** %t470
  %t472 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t469, i32 0, i32 1
  %t473 = load i32*, i32** %t472
  %t474 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t469, i32 0, i32 2
  %t475 = load i64, i64* %t474
  br label %map_read_end_96
map_read_end_96:
  %t476 = phi i8** [ null, %map_read_null_94 ], [ %t471, %map_read_real_95 ]
  %t477 = phi i32* [ null, %map_read_null_94 ], [ %t473, %map_read_real_95 ]
  %t478 = phi i64 [ 0, %map_read_null_94 ], [ %t475, %map_read_real_95 ]
  store i64 0, i64* %t479
  br label %map_find_cond_97
map_find_cond_97:
  %t480 = load i64, i64* %t479
  %t481 = icmp slt i64 %t480, %t478
  br i1 %t481, label %map_find_body_98, label %map_find_end_101
map_find_body_98:
  %t482 = getelementptr inbounds i8*, i8** %t476, i64 %t480
  %t483 = load i8*, i8** %t482
  br label %map_find_eq_check_99
map_find_eq_check_99:
  %t484 = call i1 @eq_str(i8* %t483, i8* %t466)
  br i1 %t484, label %map_find_end_101, label %map_find_next_100
map_find_next_100:
  %t485 = add i64 %t480, 1
  store i64 %t485, i64* %t479
  br label %map_find_cond_97
map_find_end_101:
  %t486 = load i64, i64* %t479
  %t487 = icmp slt i64 %t486, %t478
  store i8* %t466, i8** %t488
  %t489 = load i8*, i8** %t488
  call void @star_rc_release(i8* %t489)
  br i1 %t487, label %map_get_some_102, label %map_get_none_103
map_get_some_102:
  %t490 = getelementptr inbounds i32, i32* %t477, i64 %t486
  %t491 = load i32, i32* %t490
  %t493 = getelementptr inbounds %Option__i32, %Option__i32* %t492, i32 0, i32 0
  store i32 1, i32* %t493
  %t494 = getelementptr inbounds %Option__i32, %Option__i32* %t492, i32 0, i32 1
  %t495 = bitcast [1 x i64]* %t494 to { i32 }*
  %t496 = getelementptr inbounds { i32 }, { i32 }* %t495, i32 0, i32 0
  store i32 %t491, i32* %t496
  %t497 = load %Option__i32, %Option__i32* %t492
  br label %map_get_end_104
map_get_none_103:
  %t499 = getelementptr inbounds %Option__i32, %Option__i32* %t498, i32 0, i32 0
  store i32 0, i32* %t499
  %t500 = load %Option__i32, %Option__i32* %t498
  br label %map_get_end_104
map_get_end_104:
  %t501 = phi %Option__i32 [ %t497, %map_get_some_102 ], [ %t500, %map_get_none_103 ]
  store %Option__i32 %t501, %Option__i32* %t502
  br label %match_scrutinee_504
match_scrutinee_504:
  %t508 = getelementptr inbounds %Option__i32, %Option__i32* %t502, i32 0, i32 0
  %t509 = load i32, i32* %t508
  %t507 = icmp eq i32 %t509, 1
  br i1 %t507, label %match_then_0_505, label %match_next_0_506
match_then_0_505:
  %t510 = getelementptr inbounds %Option__i32, %Option__i32* %t502, i32 0, i32 1
  %t511 = bitcast [1 x i64]* %t510 to { i32 }*
  %t512 = getelementptr inbounds { i32 }, { i32 }* %t511, i32 0, i32 0
  %t513 = load i32, i32* %t512
  %t514 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t514, i32 %t513)
  br label %match_end_503
match_next_0_506:
  %t518 = getelementptr inbounds %Option__i32, %Option__i32* %t502, i32 0, i32 0
  %t519 = load i32, i32* %t518
  %t517 = icmp eq i32 %t519, 0
  br i1 %t517, label %match_then_1_515, label %match_next_1_516
match_then_1_515:
  %t520 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t520)
  call i32 (i8*, ...) @printf(i8* %t520)
  %t521 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t521)
  br label %match_end_503
match_next_1_516:
  br label %match_end_503
match_end_503:
  %t523 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t523, i8** %t522
  %t524 = load i8*, i8** %t522
  %t525 = load i8*, i8** %t522
  call void @star_rc_retain(i8* %t525)
  %t526 = load i8*, i8** %t2
  %t527 = icmp eq i8* %t526, null
  br i1 %t527, label %map_read_null_105, label %map_read_real_106
map_read_null_105:
  br label %map_read_end_107
map_read_real_106:
  %t528 = bitcast i8* %t526 to { i8**, i32*, i64, i64 }*
  %t529 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t528, i32 0, i32 0
  %t530 = load i8**, i8*** %t529
  %t531 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t528, i32 0, i32 1
  %t532 = load i32*, i32** %t531
  %t533 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t528, i32 0, i32 2
  %t534 = load i64, i64* %t533
  br label %map_read_end_107
map_read_end_107:
  %t535 = phi i8** [ null, %map_read_null_105 ], [ %t530, %map_read_real_106 ]
  %t536 = phi i32* [ null, %map_read_null_105 ], [ %t532, %map_read_real_106 ]
  %t537 = phi i64 [ 0, %map_read_null_105 ], [ %t534, %map_read_real_106 ]
  store i64 0, i64* %t538
  br label %map_find_cond_108
map_find_cond_108:
  %t539 = load i64, i64* %t538
  %t540 = icmp slt i64 %t539, %t537
  br i1 %t540, label %map_find_body_109, label %map_find_end_112
map_find_body_109:
  %t541 = getelementptr inbounds i8*, i8** %t535, i64 %t539
  %t542 = load i8*, i8** %t541
  br label %map_find_eq_check_110
map_find_eq_check_110:
  %t543 = call i1 @eq_str(i8* %t542, i8* %t524)
  br i1 %t543, label %map_find_end_112, label %map_find_next_111
map_find_next_111:
  %t544 = add i64 %t539, 1
  store i64 %t544, i64* %t538
  br label %map_find_cond_108
map_find_end_112:
  %t545 = load i64, i64* %t538
  %t546 = icmp slt i64 %t545, %t537
  store i8* %t524, i8** %t547
  %t548 = load i8*, i8** %t547
  call void @star_rc_release(i8* %t548)
  %t549 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t550 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t551 = select i1 %t546, i8* %t549, i8* %t550
  %t552 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t552, i8* %t551)
  %t553 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t554 = getelementptr i8*, i8** null, i32 1
  %t555 = ptrtoint i8** %t554 to i64
  %t556 = getelementptr i32, i32* null, i32 1
  %t557 = ptrtoint i32* %t556 to i64
  %t558 = load i8*, i8** %t2
  %t559 = icmp eq i8* %t558, null
  br i1 %t559, label %map_cow_alloc_113, label %map_cow_check_114
map_cow_alloc_113:
  %t560 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t561 = call i8* @star_rc_alloc(i64 32, i8* %t560)
  %t562 = bitcast i8* %t561 to { i8**, i32*, i64, i64 }*
  %t563 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 0
  store i8** null, i8*** %t563
  %t564 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 1
  store i32* null, i32** %t564
  %t565 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 2
  store i64 0, i64* %t565
  %t566 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 3
  store i64 0, i64* %t566
  store i8* %t561, i8** %t2
  br label %map_cow_done_115
map_cow_check_114:
  %t567 = getelementptr inbounds i8, i8* %t558, i64 -16
  %t568 = bitcast i8* %t567 to i64*
  %t569 = load atomic i64, i64* %t568 seq_cst, align 8
  %t570 = icmp eq i64 %t569, 1
  br i1 %t570, label %map_cow_done_115, label %map_cow_clone_116
map_cow_clone_116:
  %t571 = bitcast i8* %t558 to { i8**, i32*, i64, i64 }*
  %t572 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t571, i32 0, i32 0
  %t573 = load i8**, i8*** %t572
  %t574 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t571, i32 0, i32 1
  %t575 = load i32*, i32** %t574
  %t576 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t571, i32 0, i32 2
  %t577 = load i64, i64* %t576
  %t578 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t571, i32 0, i32 3
  %t579 = load i64, i64* %t578
  %t580 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t581 = call i8* @star_rc_alloc(i64 32, i8* %t580)
  %t582 = bitcast i8* %t581 to { i8**, i32*, i64, i64 }*
  %t583 = mul i64 %t579, %t555
  %t584 = call i8* @malloc(i64 %t583)
  %t585 = bitcast i8* %t584 to i8**
  %t586 = mul i64 %t579, %t557
  %t587 = call i8* @malloc(i64 %t586)
  %t588 = bitcast i8* %t587 to i32*
  %t589 = icmp sgt i64 %t577, 0
  br i1 %t589, label %map_cow_copy_117, label %map_cow_after_copy_118
map_cow_copy_117:
  %t590 = mul i64 %t577, %t555
  %t591 = bitcast i8** %t573 to i8*
  call i8* @memcpy(i8* %t584, i8* %t591, i64 %t590)
  %t592 = mul i64 %t577, %t557
  %t593 = bitcast i32* %t575 to i8*
  call i8* @memcpy(i8* %t587, i8* %t593, i64 %t592)
  store i64 0, i64* %t594
  br label %map_cow_retain_cond_119
map_cow_retain_cond_119:
  %t595 = load i64, i64* %t594
  %t596 = icmp slt i64 %t595, %t577
  br i1 %t596, label %map_cow_retain_body_120, label %map_cow_retain_end_121
map_cow_retain_body_120:
  %t597 = getelementptr inbounds i8*, i8** %t585, i64 %t595
  %t598 = load i8*, i8** %t597
  call void @star_rc_retain(i8* %t598)
  %t599 = add i64 %t595, 1
  store i64 %t599, i64* %t594
  br label %map_cow_retain_cond_119
map_cow_retain_end_121:
  br label %map_cow_after_copy_118
map_cow_after_copy_118:
  %t600 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t582, i32 0, i32 0
  store i8** %t585, i8*** %t600
  %t601 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t582, i32 0, i32 1
  store i32* %t588, i32** %t601
  %t602 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t582, i32 0, i32 2
  store i64 %t577, i64* %t602
  %t603 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t582, i32 0, i32 3
  store i64 %t579, i64* %t603
  call void @star_rc_release(i8* %t558)
  store i8* %t581, i8** %t2
  br label %map_cow_done_115
map_cow_done_115:
  %t604 = load i8*, i8** %t2
  %t605 = bitcast i8* %t604 to { i8**, i32*, i64, i64 }*
  %t606 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t605, i32 0, i32 0
  %t607 = load i8**, i8*** %t606
  %t608 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t605, i32 0, i32 1
  %t609 = load i32*, i32** %t608
  %t610 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t605, i32 0, i32 2
  %t611 = load i64, i64* %t610
  %t612 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t605, i32 0, i32 3
  store i64 0, i64* %t613
  br label %map_find_cond_122
map_find_cond_122:
  %t614 = load i64, i64* %t613
  %t615 = icmp slt i64 %t614, %t611
  br i1 %t615, label %map_find_body_123, label %map_find_end_126
map_find_body_123:
  %t616 = getelementptr inbounds i8*, i8** %t607, i64 %t614
  %t617 = load i8*, i8** %t616
  br label %map_find_eq_check_124
map_find_eq_check_124:
  %t618 = call i1 @eq_str(i8* %t617, i8* %t553)
  br i1 %t618, label %map_find_end_126, label %map_find_next_125
map_find_next_125:
  %t619 = add i64 %t614, 1
  store i64 %t619, i64* %t613
  br label %map_find_cond_122
map_find_end_126:
  %t620 = load i64, i64* %t613
  %t621 = icmp slt i64 %t620, %t611
  store i8* %t553, i8** %t622
  %t623 = load i8*, i8** %t622
  call void @star_rc_release(i8* %t623)
  br i1 %t621, label %map_remove_some_127, label %map_remove_none_128
map_remove_some_127:
  %t624 = getelementptr inbounds i8*, i8** %t607, i64 %t620
  %t625 = getelementptr inbounds i32, i32* %t609, i64 %t620
  %t626 = load i32, i32* %t625
  %t627 = load i8*, i8** %t624
  call void @star_rc_release(i8* %t627)
  %t628 = sub i64 %t611, 1
  %t629 = getelementptr inbounds i8*, i8** %t607, i64 %t628
  %t630 = load i8*, i8** %t629
  %t631 = getelementptr inbounds i32, i32* %t609, i64 %t628
  %t632 = load i32, i32* %t631
  store i8* %t630, i8** %t624
  store i32 %t632, i32* %t625
  store i64 %t628, i64* %t610
  %t634 = getelementptr inbounds %Option__i32, %Option__i32* %t633, i32 0, i32 0
  store i32 1, i32* %t634
  %t635 = getelementptr inbounds %Option__i32, %Option__i32* %t633, i32 0, i32 1
  %t636 = bitcast [1 x i64]* %t635 to { i32 }*
  %t637 = getelementptr inbounds { i32 }, { i32 }* %t636, i32 0, i32 0
  store i32 %t626, i32* %t637
  %t638 = load %Option__i32, %Option__i32* %t633
  br label %map_remove_end_129
map_remove_none_128:
  %t640 = getelementptr inbounds %Option__i32, %Option__i32* %t639, i32 0, i32 0
  store i32 0, i32* %t640
  %t641 = load %Option__i32, %Option__i32* %t639
  br label %map_remove_end_129
map_remove_end_129:
  %t642 = phi %Option__i32 [ %t638, %map_remove_some_127 ], [ %t641, %map_remove_none_128 ]
  store %Option__i32 %t642, %Option__i32* %t643
  br label %match_scrutinee_645
match_scrutinee_645:
  %t649 = getelementptr inbounds %Option__i32, %Option__i32* %t643, i32 0, i32 0
  %t650 = load i32, i32* %t649
  %t648 = icmp eq i32 %t650, 1
  br i1 %t648, label %match_then_0_646, label %match_next_0_647
match_then_0_646:
  %t651 = getelementptr inbounds %Option__i32, %Option__i32* %t643, i32 0, i32 1
  %t652 = bitcast [1 x i64]* %t651 to { i32 }*
  %t653 = getelementptr inbounds { i32 }, { i32 }* %t652, i32 0, i32 0
  %t654 = load i32, i32* %t653
  %t655 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t655, i32 %t654)
  br label %match_end_644
match_next_0_647:
  %t659 = getelementptr inbounds %Option__i32, %Option__i32* %t643, i32 0, i32 0
  %t660 = load i32, i32* %t659
  %t658 = icmp eq i32 %t660, 0
  br i1 %t658, label %match_then_1_656, label %match_next_1_657
match_then_1_656:
  %t661 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t661)
  call i32 (i8*, ...) @printf(i8* %t661)
  %t662 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t662)
  br label %match_end_644
match_next_1_657:
  br label %match_end_644
match_end_644:
  %t663 = load i8*, i8** %t522
  %t664 = load i8*, i8** %t522
  call void @star_rc_retain(i8* %t664)
  %t665 = load i8*, i8** %t2
  %t666 = icmp eq i8* %t665, null
  br i1 %t666, label %map_read_null_130, label %map_read_real_131
map_read_null_130:
  br label %map_read_end_132
map_read_real_131:
  %t667 = bitcast i8* %t665 to { i8**, i32*, i64, i64 }*
  %t668 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t667, i32 0, i32 0
  %t669 = load i8**, i8*** %t668
  %t670 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t667, i32 0, i32 1
  %t671 = load i32*, i32** %t670
  %t672 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t667, i32 0, i32 2
  %t673 = load i64, i64* %t672
  br label %map_read_end_132
map_read_end_132:
  %t674 = phi i8** [ null, %map_read_null_130 ], [ %t669, %map_read_real_131 ]
  %t675 = phi i32* [ null, %map_read_null_130 ], [ %t671, %map_read_real_131 ]
  %t676 = phi i64 [ 0, %map_read_null_130 ], [ %t673, %map_read_real_131 ]
  store i64 0, i64* %t677
  br label %map_find_cond_133
map_find_cond_133:
  %t678 = load i64, i64* %t677
  %t679 = icmp slt i64 %t678, %t676
  br i1 %t679, label %map_find_body_134, label %map_find_end_137
map_find_body_134:
  %t680 = getelementptr inbounds i8*, i8** %t674, i64 %t678
  %t681 = load i8*, i8** %t680
  br label %map_find_eq_check_135
map_find_eq_check_135:
  %t682 = call i1 @eq_str(i8* %t681, i8* %t663)
  br i1 %t682, label %map_find_end_137, label %map_find_next_136
map_find_next_136:
  %t683 = add i64 %t678, 1
  store i64 %t683, i64* %t677
  br label %map_find_cond_133
map_find_end_137:
  %t684 = load i64, i64* %t677
  %t685 = icmp slt i64 %t684, %t676
  store i8* %t663, i8** %t686
  %t687 = load i8*, i8** %t686
  call void @star_rc_release(i8* %t687)
  %t688 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t689 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t690 = select i1 %t685, i8* %t688, i8* %t689
  %t691 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t691, i8* %t690)
  %t692 = load i8*, i8** %t2
  %t693 = icmp eq i8* %t692, null
  br i1 %t693, label %map_read_null_138, label %map_read_real_139
map_read_null_138:
  br label %map_read_end_140
map_read_real_139:
  %t694 = bitcast i8* %t692 to { i8**, i32*, i64, i64 }*
  %t695 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t694, i32 0, i32 0
  %t696 = load i8**, i8*** %t695
  %t697 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t694, i32 0, i32 1
  %t698 = load i32*, i32** %t697
  %t699 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t694, i32 0, i32 2
  %t700 = load i64, i64* %t699
  br label %map_read_end_140
map_read_end_140:
  %t701 = phi i8** [ null, %map_read_null_138 ], [ %t696, %map_read_real_139 ]
  %t702 = phi i32* [ null, %map_read_null_138 ], [ %t698, %map_read_real_139 ]
  %t703 = phi i64 [ 0, %map_read_null_138 ], [ %t700, %map_read_real_139 ]
  %t704 = trunc i64 %t703 to i32
  %t705 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t705, i32 %t704)
  store i8* null, i8** %t706
  %t707 = getelementptr i32, i32* null, i32 1
  %t708 = ptrtoint i32* %t707 to i64
  %t709 = load i8*, i8** %t706
  %t710 = icmp eq i8* %t709, null
  br i1 %t710, label %set_cow_alloc_141, label %set_cow_check_142
set_cow_alloc_141:
  %t715 = bitcast void (i8*)* @set_release_i32 to i8*
  %t716 = call i8* @star_rc_alloc(i64 24, i8* %t715)
  %t717 = bitcast i8* %t716 to { i32*, i64, i64 }*
  %t718 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t717, i32 0, i32 0
  store i32* null, i32** %t718
  %t719 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t717, i32 0, i32 1
  store i64 0, i64* %t719
  %t720 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t717, i32 0, i32 2
  store i64 0, i64* %t720
  store i8* %t716, i8** %t706
  br label %set_cow_done_143
set_cow_check_142:
  %t721 = getelementptr inbounds i8, i8* %t709, i64 -16
  %t722 = bitcast i8* %t721 to i64*
  %t723 = load atomic i64, i64* %t722 seq_cst, align 8
  %t724 = icmp eq i64 %t723, 1
  br i1 %t724, label %set_cow_done_143, label %set_cow_clone_144
set_cow_clone_144:
  %t725 = bitcast i8* %t709 to { i32*, i64, i64 }*
  %t726 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t725, i32 0, i32 0
  %t727 = load i32*, i32** %t726
  %t728 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t725, i32 0, i32 1
  %t729 = load i64, i64* %t728
  %t730 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t725, i32 0, i32 2
  %t731 = load i64, i64* %t730
  %t732 = bitcast void (i8*)* @set_release_i32 to i8*
  %t733 = call i8* @star_rc_alloc(i64 24, i8* %t732)
  %t734 = bitcast i8* %t733 to { i32*, i64, i64 }*
  %t735 = mul i64 %t731, %t708
  %t736 = call i8* @malloc(i64 %t735)
  %t737 = bitcast i8* %t736 to i32*
  %t738 = icmp sgt i64 %t729, 0
  br i1 %t738, label %set_cow_copy_145, label %set_cow_after_copy_146
set_cow_copy_145:
  %t739 = mul i64 %t729, %t708
  %t740 = bitcast i32* %t727 to i8*
  call i8* @memcpy(i8* %t736, i8* %t740, i64 %t739)
  br label %set_cow_after_copy_146
set_cow_after_copy_146:
  %t741 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t734, i32 0, i32 0
  store i32* %t737, i32** %t741
  %t742 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t734, i32 0, i32 1
  store i64 %t729, i64* %t742
  %t743 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t734, i32 0, i32 2
  store i64 %t731, i64* %t743
  call void @star_rc_release(i8* %t709)
  store i8* %t733, i8** %t706
  br label %set_cow_done_143
set_cow_done_143:
  %t744 = load i8*, i8** %t706
  %t745 = bitcast i8* %t744 to { i32*, i64, i64 }*
  %t746 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t745, i32 0, i32 0
  %t747 = load i32*, i32** %t746
  %t748 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t745, i32 0, i32 1
  %t749 = load i64, i64* %t748
  %t750 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t745, i32 0, i32 2
  %t751 = load i64, i64* %t748
  %t752 = load i32*, i32** %t746
  store i64 0, i64* %t754
  store i1 false, i1* %t755
  br label %find_cond_147
find_cond_147:
  %t756 = load i64, i64* %t754
  %t757 = icmp slt i64 %t756, %t751
  br i1 %t757, label %find_body_148, label %find_end_151
find_body_148:
  %t758 = getelementptr inbounds i32, i32* %t752, i64 %t756
  %t759 = load i32, i32* %t758
  br label %find_eq_check_149
find_eq_check_149:
  %t760 = call i1 @eq_i32(i32 %t759, i32 1)
  br i1 %t760, label %find_end_151, label %find_next_150
find_next_150:
  %t761 = add i64 %t756, 1
  store i64 %t761, i64* %t754
  br label %find_cond_147
find_end_151:
  %t762 = load i64, i64* %t754
  %t763 = icmp slt i64 %t762, %t751
  br i1 %t763, label %set_insert_already_present_152, label %set_insert_do_153
set_insert_already_present_152:
  br label %set_insert_end_154
set_insert_do_153:
  %t764 = load i64, i64* %t750
  %t765 = load i32*, i32** %t746
  %t766 = icmp sge i64 %t751, %t764
  br i1 %t766, label %set_insert_grow_155, label %set_insert_store_156
set_insert_grow_155:
  %t767 = mul i64 %t764, 2
  %t768 = icmp sgt i64 %t767, 0
  %t769 = select i1 %t768, i64 %t767, i64 1
  %t770 = getelementptr i32, i32* null, i32 1
  %t771 = ptrtoint i32* %t770 to i64
  %t772 = mul i64 %t769, %t771
  %t773 = call i8* @malloc(i64 %t772)
  %t774 = bitcast i8* %t773 to i32*
  %t775 = icmp sgt i64 %t764, 0
  br i1 %t775, label %set_insert_copy_157, label %set_insert_after_copy_158
set_insert_copy_157:
  %t776 = mul i64 %t751, %t771
  %t777 = bitcast i32* %t765 to i8*
  call i8* @memcpy(i8* %t773, i8* %t777, i64 %t776)
  call void @free(i8* %t777)
  br label %set_insert_after_copy_158
set_insert_after_copy_158:
  store i32* %t774, i32** %t746
  store i64 %t769, i64* %t750
  br label %set_insert_store_156
set_insert_store_156:
  %t778 = load i32*, i32** %t746
  %t779 = getelementptr inbounds i32, i32* %t778, i64 %t751
  store i32 1, i32* %t779
  %t780 = add i64 %t751, 1
  store i64 %t780, i64* %t748
  br label %set_insert_end_154
set_insert_end_154:
  %t781 = phi i1 [ false, %set_insert_already_present_152 ], [ true, %set_insert_store_156 ]
  %t782 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t783 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t784 = select i1 %t781, i8* %t782, i8* %t783
  %t785 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t785, i8* %t784)
  %t786 = getelementptr i32, i32* null, i32 1
  %t787 = ptrtoint i32* %t786 to i64
  %t788 = load i8*, i8** %t706
  %t789 = icmp eq i8* %t788, null
  br i1 %t789, label %set_cow_alloc_159, label %set_cow_check_160
set_cow_alloc_159:
  %t790 = bitcast void (i8*)* @set_release_i32 to i8*
  %t791 = call i8* @star_rc_alloc(i64 24, i8* %t790)
  %t792 = bitcast i8* %t791 to { i32*, i64, i64 }*
  %t793 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t792, i32 0, i32 0
  store i32* null, i32** %t793
  %t794 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t792, i32 0, i32 1
  store i64 0, i64* %t794
  %t795 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t792, i32 0, i32 2
  store i64 0, i64* %t795
  store i8* %t791, i8** %t706
  br label %set_cow_done_161
set_cow_check_160:
  %t796 = getelementptr inbounds i8, i8* %t788, i64 -16
  %t797 = bitcast i8* %t796 to i64*
  %t798 = load atomic i64, i64* %t797 seq_cst, align 8
  %t799 = icmp eq i64 %t798, 1
  br i1 %t799, label %set_cow_done_161, label %set_cow_clone_162
set_cow_clone_162:
  %t800 = bitcast i8* %t788 to { i32*, i64, i64 }*
  %t801 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t800, i32 0, i32 0
  %t802 = load i32*, i32** %t801
  %t803 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t800, i32 0, i32 1
  %t804 = load i64, i64* %t803
  %t805 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t800, i32 0, i32 2
  %t806 = load i64, i64* %t805
  %t807 = bitcast void (i8*)* @set_release_i32 to i8*
  %t808 = call i8* @star_rc_alloc(i64 24, i8* %t807)
  %t809 = bitcast i8* %t808 to { i32*, i64, i64 }*
  %t810 = mul i64 %t806, %t787
  %t811 = call i8* @malloc(i64 %t810)
  %t812 = bitcast i8* %t811 to i32*
  %t813 = icmp sgt i64 %t804, 0
  br i1 %t813, label %set_cow_copy_163, label %set_cow_after_copy_164
set_cow_copy_163:
  %t814 = mul i64 %t804, %t787
  %t815 = bitcast i32* %t802 to i8*
  call i8* @memcpy(i8* %t811, i8* %t815, i64 %t814)
  br label %set_cow_after_copy_164
set_cow_after_copy_164:
  %t816 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t809, i32 0, i32 0
  store i32* %t812, i32** %t816
  %t817 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t809, i32 0, i32 1
  store i64 %t804, i64* %t817
  %t818 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t809, i32 0, i32 2
  store i64 %t806, i64* %t818
  call void @star_rc_release(i8* %t788)
  store i8* %t808, i8** %t706
  br label %set_cow_done_161
set_cow_done_161:
  %t819 = load i8*, i8** %t706
  %t820 = bitcast i8* %t819 to { i32*, i64, i64 }*
  %t821 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t820, i32 0, i32 0
  %t822 = load i32*, i32** %t821
  %t823 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t820, i32 0, i32 1
  %t824 = load i64, i64* %t823
  %t825 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t820, i32 0, i32 2
  %t826 = load i64, i64* %t823
  %t827 = load i32*, i32** %t821
  store i64 0, i64* %t828
  store i1 false, i1* %t829
  br label %find_cond_165
find_cond_165:
  %t830 = load i64, i64* %t828
  %t831 = icmp slt i64 %t830, %t826
  br i1 %t831, label %find_body_166, label %find_end_169
find_body_166:
  %t832 = getelementptr inbounds i32, i32* %t827, i64 %t830
  %t833 = load i32, i32* %t832
  br label %find_eq_check_167
find_eq_check_167:
  %t834 = call i1 @eq_i32(i32 %t833, i32 2)
  br i1 %t834, label %find_end_169, label %find_next_168
find_next_168:
  %t835 = add i64 %t830, 1
  store i64 %t835, i64* %t828
  br label %find_cond_165
find_end_169:
  %t836 = load i64, i64* %t828
  %t837 = icmp slt i64 %t836, %t826
  br i1 %t837, label %set_insert_already_present_170, label %set_insert_do_171
set_insert_already_present_170:
  br label %set_insert_end_172
set_insert_do_171:
  %t838 = load i64, i64* %t825
  %t839 = load i32*, i32** %t821
  %t840 = icmp sge i64 %t826, %t838
  br i1 %t840, label %set_insert_grow_173, label %set_insert_store_174
set_insert_grow_173:
  %t841 = mul i64 %t838, 2
  %t842 = icmp sgt i64 %t841, 0
  %t843 = select i1 %t842, i64 %t841, i64 1
  %t844 = getelementptr i32, i32* null, i32 1
  %t845 = ptrtoint i32* %t844 to i64
  %t846 = mul i64 %t843, %t845
  %t847 = call i8* @malloc(i64 %t846)
  %t848 = bitcast i8* %t847 to i32*
  %t849 = icmp sgt i64 %t838, 0
  br i1 %t849, label %set_insert_copy_175, label %set_insert_after_copy_176
set_insert_copy_175:
  %t850 = mul i64 %t826, %t845
  %t851 = bitcast i32* %t839 to i8*
  call i8* @memcpy(i8* %t847, i8* %t851, i64 %t850)
  call void @free(i8* %t851)
  br label %set_insert_after_copy_176
set_insert_after_copy_176:
  store i32* %t848, i32** %t821
  store i64 %t843, i64* %t825
  br label %set_insert_store_174
set_insert_store_174:
  %t852 = load i32*, i32** %t821
  %t853 = getelementptr inbounds i32, i32* %t852, i64 %t826
  store i32 2, i32* %t853
  %t854 = add i64 %t826, 1
  store i64 %t854, i64* %t823
  br label %set_insert_end_172
set_insert_end_172:
  %t855 = phi i1 [ false, %set_insert_already_present_170 ], [ true, %set_insert_store_174 ]
  %t856 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t857 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t858 = select i1 %t855, i8* %t856, i8* %t857
  %t859 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t859, i8* %t858)
  %t860 = getelementptr i32, i32* null, i32 1
  %t861 = ptrtoint i32* %t860 to i64
  %t862 = load i8*, i8** %t706
  %t863 = icmp eq i8* %t862, null
  br i1 %t863, label %set_cow_alloc_177, label %set_cow_check_178
set_cow_alloc_177:
  %t864 = bitcast void (i8*)* @set_release_i32 to i8*
  %t865 = call i8* @star_rc_alloc(i64 24, i8* %t864)
  %t866 = bitcast i8* %t865 to { i32*, i64, i64 }*
  %t867 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t866, i32 0, i32 0
  store i32* null, i32** %t867
  %t868 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t866, i32 0, i32 1
  store i64 0, i64* %t868
  %t869 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t866, i32 0, i32 2
  store i64 0, i64* %t869
  store i8* %t865, i8** %t706
  br label %set_cow_done_179
set_cow_check_178:
  %t870 = getelementptr inbounds i8, i8* %t862, i64 -16
  %t871 = bitcast i8* %t870 to i64*
  %t872 = load atomic i64, i64* %t871 seq_cst, align 8
  %t873 = icmp eq i64 %t872, 1
  br i1 %t873, label %set_cow_done_179, label %set_cow_clone_180
set_cow_clone_180:
  %t874 = bitcast i8* %t862 to { i32*, i64, i64 }*
  %t875 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t874, i32 0, i32 0
  %t876 = load i32*, i32** %t875
  %t877 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t874, i32 0, i32 1
  %t878 = load i64, i64* %t877
  %t879 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t874, i32 0, i32 2
  %t880 = load i64, i64* %t879
  %t881 = bitcast void (i8*)* @set_release_i32 to i8*
  %t882 = call i8* @star_rc_alloc(i64 24, i8* %t881)
  %t883 = bitcast i8* %t882 to { i32*, i64, i64 }*
  %t884 = mul i64 %t880, %t861
  %t885 = call i8* @malloc(i64 %t884)
  %t886 = bitcast i8* %t885 to i32*
  %t887 = icmp sgt i64 %t878, 0
  br i1 %t887, label %set_cow_copy_181, label %set_cow_after_copy_182
set_cow_copy_181:
  %t888 = mul i64 %t878, %t861
  %t889 = bitcast i32* %t876 to i8*
  call i8* @memcpy(i8* %t885, i8* %t889, i64 %t888)
  br label %set_cow_after_copy_182
set_cow_after_copy_182:
  %t890 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t883, i32 0, i32 0
  store i32* %t886, i32** %t890
  %t891 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t883, i32 0, i32 1
  store i64 %t878, i64* %t891
  %t892 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t883, i32 0, i32 2
  store i64 %t880, i64* %t892
  call void @star_rc_release(i8* %t862)
  store i8* %t882, i8** %t706
  br label %set_cow_done_179
set_cow_done_179:
  %t893 = load i8*, i8** %t706
  %t894 = bitcast i8* %t893 to { i32*, i64, i64 }*
  %t895 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t894, i32 0, i32 0
  %t896 = load i32*, i32** %t895
  %t897 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t894, i32 0, i32 1
  %t898 = load i64, i64* %t897
  %t899 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t894, i32 0, i32 2
  %t900 = load i64, i64* %t897
  %t901 = load i32*, i32** %t895
  store i64 0, i64* %t902
  store i1 false, i1* %t903
  br label %find_cond_183
find_cond_183:
  %t904 = load i64, i64* %t902
  %t905 = icmp slt i64 %t904, %t900
  br i1 %t905, label %find_body_184, label %find_end_187
find_body_184:
  %t906 = getelementptr inbounds i32, i32* %t901, i64 %t904
  %t907 = load i32, i32* %t906
  br label %find_eq_check_185
find_eq_check_185:
  %t908 = call i1 @eq_i32(i32 %t907, i32 1)
  br i1 %t908, label %find_end_187, label %find_next_186
find_next_186:
  %t909 = add i64 %t904, 1
  store i64 %t909, i64* %t902
  br label %find_cond_183
find_end_187:
  %t910 = load i64, i64* %t902
  %t911 = icmp slt i64 %t910, %t900
  br i1 %t911, label %set_insert_already_present_188, label %set_insert_do_189
set_insert_already_present_188:
  br label %set_insert_end_190
set_insert_do_189:
  %t912 = load i64, i64* %t899
  %t913 = load i32*, i32** %t895
  %t914 = icmp sge i64 %t900, %t912
  br i1 %t914, label %set_insert_grow_191, label %set_insert_store_192
set_insert_grow_191:
  %t915 = mul i64 %t912, 2
  %t916 = icmp sgt i64 %t915, 0
  %t917 = select i1 %t916, i64 %t915, i64 1
  %t918 = getelementptr i32, i32* null, i32 1
  %t919 = ptrtoint i32* %t918 to i64
  %t920 = mul i64 %t917, %t919
  %t921 = call i8* @malloc(i64 %t920)
  %t922 = bitcast i8* %t921 to i32*
  %t923 = icmp sgt i64 %t912, 0
  br i1 %t923, label %set_insert_copy_193, label %set_insert_after_copy_194
set_insert_copy_193:
  %t924 = mul i64 %t900, %t919
  %t925 = bitcast i32* %t913 to i8*
  call i8* @memcpy(i8* %t921, i8* %t925, i64 %t924)
  call void @free(i8* %t925)
  br label %set_insert_after_copy_194
set_insert_after_copy_194:
  store i32* %t922, i32** %t895
  store i64 %t917, i64* %t899
  br label %set_insert_store_192
set_insert_store_192:
  %t926 = load i32*, i32** %t895
  %t927 = getelementptr inbounds i32, i32* %t926, i64 %t900
  store i32 1, i32* %t927
  %t928 = add i64 %t900, 1
  store i64 %t928, i64* %t897
  br label %set_insert_end_190
set_insert_end_190:
  %t929 = phi i1 [ false, %set_insert_already_present_188 ], [ true, %set_insert_store_192 ]
  %t930 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t931 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t932 = select i1 %t929, i8* %t930, i8* %t931
  %t933 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t933, i8* %t932)
  %t934 = load i8*, i8** %t706
  %t935 = icmp eq i8* %t934, null
  br i1 %t935, label %set_read_null_195, label %set_read_real_196
set_read_null_195:
  br label %set_read_end_197
set_read_real_196:
  %t936 = bitcast i8* %t934 to { i32*, i64, i64 }*
  %t937 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t936, i32 0, i32 0
  %t938 = load i32*, i32** %t937
  %t939 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t936, i32 0, i32 1
  %t940 = load i64, i64* %t939
  br label %set_read_end_197
set_read_end_197:
  %t941 = phi i32* [ null, %set_read_null_195 ], [ %t938, %set_read_real_196 ]
  %t942 = phi i64 [ 0, %set_read_null_195 ], [ %t940, %set_read_real_196 ]
  %t943 = trunc i64 %t942 to i32
  %t944 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t944, i32 %t943)
  %t945 = load i8*, i8** %t706
  %t946 = icmp eq i8* %t945, null
  br i1 %t946, label %set_read_null_198, label %set_read_real_199
set_read_null_198:
  br label %set_read_end_200
set_read_real_199:
  %t947 = bitcast i8* %t945 to { i32*, i64, i64 }*
  %t948 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t947, i32 0, i32 0
  %t949 = load i32*, i32** %t948
  %t950 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t947, i32 0, i32 1
  %t951 = load i64, i64* %t950
  br label %set_read_end_200
set_read_end_200:
  %t952 = phi i32* [ null, %set_read_null_198 ], [ %t949, %set_read_real_199 ]
  %t953 = phi i64 [ 0, %set_read_null_198 ], [ %t951, %set_read_real_199 ]
  store i64 0, i64* %t954
  store i1 false, i1* %t955
  br label %find_cond_201
find_cond_201:
  %t956 = load i64, i64* %t954
  %t957 = icmp slt i64 %t956, %t953
  br i1 %t957, label %find_body_202, label %find_end_205
find_body_202:
  %t958 = getelementptr inbounds i32, i32* %t952, i64 %t956
  %t959 = load i32, i32* %t958
  br label %find_eq_check_203
find_eq_check_203:
  %t960 = call i1 @eq_i32(i32 %t959, i32 2)
  br i1 %t960, label %find_end_205, label %find_next_204
find_next_204:
  %t961 = add i64 %t956, 1
  store i64 %t961, i64* %t954
  br label %find_cond_201
find_end_205:
  %t962 = load i64, i64* %t954
  %t963 = icmp slt i64 %t962, %t953
  %t964 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t965 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t966 = select i1 %t963, i8* %t964, i8* %t965
  %t967 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t967, i8* %t966)
  %t968 = getelementptr i32, i32* null, i32 1
  %t969 = ptrtoint i32* %t968 to i64
  %t970 = load i8*, i8** %t706
  %t971 = icmp eq i8* %t970, null
  br i1 %t971, label %set_cow_alloc_206, label %set_cow_check_207
set_cow_alloc_206:
  %t972 = bitcast void (i8*)* @set_release_i32 to i8*
  %t973 = call i8* @star_rc_alloc(i64 24, i8* %t972)
  %t974 = bitcast i8* %t973 to { i32*, i64, i64 }*
  %t975 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t974, i32 0, i32 0
  store i32* null, i32** %t975
  %t976 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t974, i32 0, i32 1
  store i64 0, i64* %t976
  %t977 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t974, i32 0, i32 2
  store i64 0, i64* %t977
  store i8* %t973, i8** %t706
  br label %set_cow_done_208
set_cow_check_207:
  %t978 = getelementptr inbounds i8, i8* %t970, i64 -16
  %t979 = bitcast i8* %t978 to i64*
  %t980 = load atomic i64, i64* %t979 seq_cst, align 8
  %t981 = icmp eq i64 %t980, 1
  br i1 %t981, label %set_cow_done_208, label %set_cow_clone_209
set_cow_clone_209:
  %t982 = bitcast i8* %t970 to { i32*, i64, i64 }*
  %t983 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t982, i32 0, i32 0
  %t984 = load i32*, i32** %t983
  %t985 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t982, i32 0, i32 1
  %t986 = load i64, i64* %t985
  %t987 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t982, i32 0, i32 2
  %t988 = load i64, i64* %t987
  %t989 = bitcast void (i8*)* @set_release_i32 to i8*
  %t990 = call i8* @star_rc_alloc(i64 24, i8* %t989)
  %t991 = bitcast i8* %t990 to { i32*, i64, i64 }*
  %t992 = mul i64 %t988, %t969
  %t993 = call i8* @malloc(i64 %t992)
  %t994 = bitcast i8* %t993 to i32*
  %t995 = icmp sgt i64 %t986, 0
  br i1 %t995, label %set_cow_copy_210, label %set_cow_after_copy_211
set_cow_copy_210:
  %t996 = mul i64 %t986, %t969
  %t997 = bitcast i32* %t984 to i8*
  call i8* @memcpy(i8* %t993, i8* %t997, i64 %t996)
  br label %set_cow_after_copy_211
set_cow_after_copy_211:
  %t998 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t991, i32 0, i32 0
  store i32* %t994, i32** %t998
  %t999 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t991, i32 0, i32 1
  store i64 %t986, i64* %t999
  %t1000 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t991, i32 0, i32 2
  store i64 %t988, i64* %t1000
  call void @star_rc_release(i8* %t970)
  store i8* %t990, i8** %t706
  br label %set_cow_done_208
set_cow_done_208:
  %t1001 = load i8*, i8** %t706
  %t1002 = bitcast i8* %t1001 to { i32*, i64, i64 }*
  %t1003 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1002, i32 0, i32 0
  %t1004 = load i32*, i32** %t1003
  %t1005 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1002, i32 0, i32 1
  %t1006 = load i64, i64* %t1005
  %t1007 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1002, i32 0, i32 2
  %t1008 = load i64, i64* %t1005
  %t1009 = load i32*, i32** %t1003
  store i64 0, i64* %t1010
  store i1 false, i1* %t1011
  br label %find_cond_212
find_cond_212:
  %t1012 = load i64, i64* %t1010
  %t1013 = icmp slt i64 %t1012, %t1008
  br i1 %t1013, label %find_body_213, label %find_end_216
find_body_213:
  %t1014 = getelementptr inbounds i32, i32* %t1009, i64 %t1012
  %t1015 = load i32, i32* %t1014
  br label %find_eq_check_214
find_eq_check_214:
  %t1016 = call i1 @eq_i32(i32 %t1015, i32 2)
  br i1 %t1016, label %find_end_216, label %find_next_215
find_next_215:
  %t1017 = add i64 %t1012, 1
  store i64 %t1017, i64* %t1010
  br label %find_cond_212
find_end_216:
  %t1018 = load i64, i64* %t1010
  %t1019 = icmp slt i64 %t1018, %t1008
  br i1 %t1019, label %set_remove_do_217, label %set_remove_end_218
set_remove_do_217:
  %t1020 = getelementptr inbounds i32, i32* %t1009, i64 %t1018
  %t1021 = sub i64 %t1008, 1
  %t1022 = getelementptr inbounds i32, i32* %t1009, i64 %t1021
  %t1023 = load i32, i32* %t1022
  store i32 %t1023, i32* %t1020
  store i64 %t1021, i64* %t1005
  br label %set_remove_end_218
set_remove_end_218:
  %t1024 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t1025 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t1026 = select i1 %t1019, i8* %t1024, i8* %t1025
  %t1027 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1027, i8* %t1026)
  %t1028 = load i8*, i8** %t706
  %t1029 = icmp eq i8* %t1028, null
  br i1 %t1029, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t1030 = bitcast i8* %t1028 to { i32*, i64, i64 }*
  %t1031 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 0
  %t1032 = load i32*, i32** %t1031
  %t1033 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 1
  %t1034 = load i64, i64* %t1033
  br label %set_read_end_221
set_read_end_221:
  %t1035 = phi i32* [ null, %set_read_null_219 ], [ %t1032, %set_read_real_220 ]
  %t1036 = phi i64 [ 0, %set_read_null_219 ], [ %t1034, %set_read_real_220 ]
  store i64 0, i64* %t1037
  store i1 false, i1* %t1038
  br label %find_cond_222
find_cond_222:
  %t1039 = load i64, i64* %t1037
  %t1040 = icmp slt i64 %t1039, %t1036
  br i1 %t1040, label %find_body_223, label %find_end_226
find_body_223:
  %t1041 = getelementptr inbounds i32, i32* %t1035, i64 %t1039
  %t1042 = load i32, i32* %t1041
  br label %find_eq_check_224
find_eq_check_224:
  %t1043 = call i1 @eq_i32(i32 %t1042, i32 2)
  br i1 %t1043, label %find_end_226, label %find_next_225
find_next_225:
  %t1044 = add i64 %t1039, 1
  store i64 %t1044, i64* %t1037
  br label %find_cond_222
find_end_226:
  %t1045 = load i64, i64* %t1037
  %t1046 = icmp slt i64 %t1045, %t1036
  %t1047 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1048 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1049 = select i1 %t1046, i8* %t1047, i8* %t1048
  %t1050 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1050, i8* %t1049)
  %t1051 = getelementptr i32, i32* null, i32 1
  %t1052 = ptrtoint i32* %t1051 to i64
  %t1053 = load i8*, i8** %t706
  %t1054 = icmp eq i8* %t1053, null
  br i1 %t1054, label %set_cow_alloc_227, label %set_cow_check_228
set_cow_alloc_227:
  %t1055 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1056 = call i8* @star_rc_alloc(i64 24, i8* %t1055)
  %t1057 = bitcast i8* %t1056 to { i32*, i64, i64 }*
  %t1058 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1057, i32 0, i32 0
  store i32* null, i32** %t1058
  %t1059 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1057, i32 0, i32 1
  store i64 0, i64* %t1059
  %t1060 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1057, i32 0, i32 2
  store i64 0, i64* %t1060
  store i8* %t1056, i8** %t706
  br label %set_cow_done_229
set_cow_check_228:
  %t1061 = getelementptr inbounds i8, i8* %t1053, i64 -16
  %t1062 = bitcast i8* %t1061 to i64*
  %t1063 = load atomic i64, i64* %t1062 seq_cst, align 8
  %t1064 = icmp eq i64 %t1063, 1
  br i1 %t1064, label %set_cow_done_229, label %set_cow_clone_230
set_cow_clone_230:
  %t1065 = bitcast i8* %t1053 to { i32*, i64, i64 }*
  %t1066 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1065, i32 0, i32 0
  %t1067 = load i32*, i32** %t1066
  %t1068 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1065, i32 0, i32 1
  %t1069 = load i64, i64* %t1068
  %t1070 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1065, i32 0, i32 2
  %t1071 = load i64, i64* %t1070
  %t1072 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1073 = call i8* @star_rc_alloc(i64 24, i8* %t1072)
  %t1074 = bitcast i8* %t1073 to { i32*, i64, i64 }*
  %t1075 = mul i64 %t1071, %t1052
  %t1076 = call i8* @malloc(i64 %t1075)
  %t1077 = bitcast i8* %t1076 to i32*
  %t1078 = icmp sgt i64 %t1069, 0
  br i1 %t1078, label %set_cow_copy_231, label %set_cow_after_copy_232
set_cow_copy_231:
  %t1079 = mul i64 %t1069, %t1052
  %t1080 = bitcast i32* %t1067 to i8*
  call i8* @memcpy(i8* %t1076, i8* %t1080, i64 %t1079)
  br label %set_cow_after_copy_232
set_cow_after_copy_232:
  %t1081 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1074, i32 0, i32 0
  store i32* %t1077, i32** %t1081
  %t1082 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1074, i32 0, i32 1
  store i64 %t1069, i64* %t1082
  %t1083 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1074, i32 0, i32 2
  store i64 %t1071, i64* %t1083
  call void @star_rc_release(i8* %t1053)
  store i8* %t1073, i8** %t706
  br label %set_cow_done_229
set_cow_done_229:
  %t1084 = load i8*, i8** %t706
  %t1085 = bitcast i8* %t1084 to { i32*, i64, i64 }*
  %t1086 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1085, i32 0, i32 0
  %t1087 = load i32*, i32** %t1086
  %t1088 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1085, i32 0, i32 1
  %t1089 = load i64, i64* %t1088
  %t1090 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1085, i32 0, i32 2
  %t1091 = load i64, i64* %t1088
  %t1092 = load i32*, i32** %t1086
  store i64 0, i64* %t1093
  store i1 false, i1* %t1094
  br label %find_cond_233
find_cond_233:
  %t1095 = load i64, i64* %t1093
  %t1096 = icmp slt i64 %t1095, %t1091
  br i1 %t1096, label %find_body_234, label %find_end_237
find_body_234:
  %t1097 = getelementptr inbounds i32, i32* %t1092, i64 %t1095
  %t1098 = load i32, i32* %t1097
  br label %find_eq_check_235
find_eq_check_235:
  %t1099 = call i1 @eq_i32(i32 %t1098, i32 2)
  br i1 %t1099, label %find_end_237, label %find_next_236
find_next_236:
  %t1100 = add i64 %t1095, 1
  store i64 %t1100, i64* %t1093
  br label %find_cond_233
find_end_237:
  %t1101 = load i64, i64* %t1093
  %t1102 = icmp slt i64 %t1101, %t1091
  br i1 %t1102, label %set_remove_do_238, label %set_remove_end_239
set_remove_do_238:
  %t1103 = getelementptr inbounds i32, i32* %t1092, i64 %t1101
  %t1104 = sub i64 %t1091, 1
  %t1105 = getelementptr inbounds i32, i32* %t1092, i64 %t1104
  %t1106 = load i32, i32* %t1105
  store i32 %t1106, i32* %t1103
  store i64 %t1104, i64* %t1088
  br label %set_remove_end_239
set_remove_end_239:
  %t1107 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1108 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1109 = select i1 %t1102, i8* %t1107, i8* %t1108
  %t1110 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1110, i8* %t1109)
  %t1111 = load i8*, i8** %t706
  %t1112 = icmp eq i8* %t1111, null
  br i1 %t1112, label %set_read_null_240, label %set_read_real_241
set_read_null_240:
  br label %set_read_end_242
set_read_real_241:
  %t1113 = bitcast i8* %t1111 to { i32*, i64, i64 }*
  %t1114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1113, i32 0, i32 0
  %t1115 = load i32*, i32** %t1114
  %t1116 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1113, i32 0, i32 1
  %t1117 = load i64, i64* %t1116
  br label %set_read_end_242
set_read_end_242:
  %t1118 = phi i32* [ null, %set_read_null_240 ], [ %t1115, %set_read_real_241 ]
  %t1119 = phi i64 [ 0, %set_read_null_240 ], [ %t1117, %set_read_real_241 ]
  %t1120 = trunc i64 %t1119 to i32
  %t1121 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1121, i32 %t1120)
  store i8* null, i8** %t1122
  %t1123 = getelementptr %Point, %Point* null, i32 1
  %t1124 = ptrtoint %Point* %t1123 to i64
  %t1125 = load i8*, i8** %t1122
  %t1126 = icmp eq i8* %t1125, null
  br i1 %t1126, label %set_cow_alloc_243, label %set_cow_check_244
set_cow_alloc_243:
  %t1131 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1132 = call i8* @star_rc_alloc(i64 24, i8* %t1131)
  %t1133 = bitcast i8* %t1132 to { %Point*, i64, i64 }*
  %t1134 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 0
  store %Point* null, %Point** %t1134
  %t1135 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 1
  store i64 0, i64* %t1135
  %t1136 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 2
  store i64 0, i64* %t1136
  store i8* %t1132, i8** %t1122
  br label %set_cow_done_245
set_cow_check_244:
  %t1137 = getelementptr inbounds i8, i8* %t1125, i64 -16
  %t1138 = bitcast i8* %t1137 to i64*
  %t1139 = load atomic i64, i64* %t1138 seq_cst, align 8
  %t1140 = icmp eq i64 %t1139, 1
  br i1 %t1140, label %set_cow_done_245, label %set_cow_clone_246
set_cow_clone_246:
  %t1141 = bitcast i8* %t1125 to { %Point*, i64, i64 }*
  %t1142 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1141, i32 0, i32 0
  %t1143 = load %Point*, %Point** %t1142
  %t1144 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1141, i32 0, i32 1
  %t1145 = load i64, i64* %t1144
  %t1146 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1141, i32 0, i32 2
  %t1147 = load i64, i64* %t1146
  %t1148 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1149 = call i8* @star_rc_alloc(i64 24, i8* %t1148)
  %t1150 = bitcast i8* %t1149 to { %Point*, i64, i64 }*
  %t1151 = mul i64 %t1147, %t1124
  %t1152 = call i8* @malloc(i64 %t1151)
  %t1153 = bitcast i8* %t1152 to %Point*
  %t1154 = icmp sgt i64 %t1145, 0
  br i1 %t1154, label %set_cow_copy_247, label %set_cow_after_copy_248
set_cow_copy_247:
  %t1155 = mul i64 %t1145, %t1124
  %t1156 = bitcast %Point* %t1143 to i8*
  call i8* @memcpy(i8* %t1152, i8* %t1156, i64 %t1155)
  br label %set_cow_after_copy_248
set_cow_after_copy_248:
  %t1157 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1150, i32 0, i32 0
  store %Point* %t1153, %Point** %t1157
  %t1158 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1150, i32 0, i32 1
  store i64 %t1145, i64* %t1158
  %t1159 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1150, i32 0, i32 2
  store i64 %t1147, i64* %t1159
  call void @star_rc_release(i8* %t1125)
  store i8* %t1149, i8** %t1122
  br label %set_cow_done_245
set_cow_done_245:
  %t1160 = load i8*, i8** %t1122
  %t1161 = bitcast i8* %t1160 to { %Point*, i64, i64 }*
  %t1162 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1161, i32 0, i32 0
  %t1163 = load %Point*, %Point** %t1162
  %t1164 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1161, i32 0, i32 1
  %t1165 = load i64, i64* %t1164
  %t1166 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1161, i32 0, i32 2
  %t1168 = getelementptr inbounds %Point, %Point* %t1167, i32 0, i32 0
  store i32 1, i32* %t1168
  %t1169 = getelementptr inbounds %Point, %Point* %t1167, i32 0, i32 1
  store i32 2, i32* %t1169
  %t1170 = load %Point, %Point* %t1167
  %t1171 = load i64, i64* %t1164
  %t1172 = load %Point*, %Point** %t1162
  store i64 0, i64* %t1180
  store i1 false, i1* %t1181
  br label %find_cond_249
find_cond_249:
  %t1182 = load i64, i64* %t1180
  %t1183 = icmp slt i64 %t1182, %t1171
  br i1 %t1183, label %find_body_250, label %find_end_253
find_body_250:
  %t1184 = getelementptr inbounds %Point, %Point* %t1172, i64 %t1182
  %t1185 = load %Point, %Point* %t1184
  br label %find_eq_check_251
find_eq_check_251:
  %t1186 = call i1 @eq_s_Point(%Point %t1185, %Point %t1170)
  br i1 %t1186, label %find_end_253, label %find_next_252
find_next_252:
  %t1187 = add i64 %t1182, 1
  store i64 %t1187, i64* %t1180
  br label %find_cond_249
find_end_253:
  %t1188 = load i64, i64* %t1180
  %t1189 = icmp slt i64 %t1188, %t1171
  br i1 %t1189, label %set_insert_already_present_254, label %set_insert_do_255
set_insert_already_present_254:
  br label %set_insert_end_256
set_insert_do_255:
  %t1190 = load i64, i64* %t1166
  %t1191 = load %Point*, %Point** %t1162
  %t1192 = icmp sge i64 %t1171, %t1190
  br i1 %t1192, label %set_insert_grow_257, label %set_insert_store_258
set_insert_grow_257:
  %t1193 = mul i64 %t1190, 2
  %t1194 = icmp sgt i64 %t1193, 0
  %t1195 = select i1 %t1194, i64 %t1193, i64 1
  %t1196 = getelementptr %Point, %Point* null, i32 1
  %t1197 = ptrtoint %Point* %t1196 to i64
  %t1198 = mul i64 %t1195, %t1197
  %t1199 = call i8* @malloc(i64 %t1198)
  %t1200 = bitcast i8* %t1199 to %Point*
  %t1201 = icmp sgt i64 %t1190, 0
  br i1 %t1201, label %set_insert_copy_259, label %set_insert_after_copy_260
set_insert_copy_259:
  %t1202 = mul i64 %t1171, %t1197
  %t1203 = bitcast %Point* %t1191 to i8*
  call i8* @memcpy(i8* %t1199, i8* %t1203, i64 %t1202)
  call void @free(i8* %t1203)
  br label %set_insert_after_copy_260
set_insert_after_copy_260:
  store %Point* %t1200, %Point** %t1162
  store i64 %t1195, i64* %t1166
  br label %set_insert_store_258
set_insert_store_258:
  %t1204 = load %Point*, %Point** %t1162
  %t1205 = getelementptr inbounds %Point, %Point* %t1204, i64 %t1171
  store %Point %t1170, %Point* %t1205
  %t1206 = add i64 %t1171, 1
  store i64 %t1206, i64* %t1164
  br label %set_insert_end_256
set_insert_end_256:
  %t1207 = phi i1 [ false, %set_insert_already_present_254 ], [ true, %set_insert_store_258 ]
  %t1208 = getelementptr %Point, %Point* null, i32 1
  %t1209 = ptrtoint %Point* %t1208 to i64
  %t1210 = load i8*, i8** %t1122
  %t1211 = icmp eq i8* %t1210, null
  br i1 %t1211, label %set_cow_alloc_261, label %set_cow_check_262
set_cow_alloc_261:
  %t1212 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1213 = call i8* @star_rc_alloc(i64 24, i8* %t1212)
  %t1214 = bitcast i8* %t1213 to { %Point*, i64, i64 }*
  %t1215 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1214, i32 0, i32 0
  store %Point* null, %Point** %t1215
  %t1216 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1214, i32 0, i32 1
  store i64 0, i64* %t1216
  %t1217 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1214, i32 0, i32 2
  store i64 0, i64* %t1217
  store i8* %t1213, i8** %t1122
  br label %set_cow_done_263
set_cow_check_262:
  %t1218 = getelementptr inbounds i8, i8* %t1210, i64 -16
  %t1219 = bitcast i8* %t1218 to i64*
  %t1220 = load atomic i64, i64* %t1219 seq_cst, align 8
  %t1221 = icmp eq i64 %t1220, 1
  br i1 %t1221, label %set_cow_done_263, label %set_cow_clone_264
set_cow_clone_264:
  %t1222 = bitcast i8* %t1210 to { %Point*, i64, i64 }*
  %t1223 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1222, i32 0, i32 0
  %t1224 = load %Point*, %Point** %t1223
  %t1225 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1222, i32 0, i32 1
  %t1226 = load i64, i64* %t1225
  %t1227 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1222, i32 0, i32 2
  %t1228 = load i64, i64* %t1227
  %t1229 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1230 = call i8* @star_rc_alloc(i64 24, i8* %t1229)
  %t1231 = bitcast i8* %t1230 to { %Point*, i64, i64 }*
  %t1232 = mul i64 %t1228, %t1209
  %t1233 = call i8* @malloc(i64 %t1232)
  %t1234 = bitcast i8* %t1233 to %Point*
  %t1235 = icmp sgt i64 %t1226, 0
  br i1 %t1235, label %set_cow_copy_265, label %set_cow_after_copy_266
set_cow_copy_265:
  %t1236 = mul i64 %t1226, %t1209
  %t1237 = bitcast %Point* %t1224 to i8*
  call i8* @memcpy(i8* %t1233, i8* %t1237, i64 %t1236)
  br label %set_cow_after_copy_266
set_cow_after_copy_266:
  %t1238 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1231, i32 0, i32 0
  store %Point* %t1234, %Point** %t1238
  %t1239 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1231, i32 0, i32 1
  store i64 %t1226, i64* %t1239
  %t1240 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1231, i32 0, i32 2
  store i64 %t1228, i64* %t1240
  call void @star_rc_release(i8* %t1210)
  store i8* %t1230, i8** %t1122
  br label %set_cow_done_263
set_cow_done_263:
  %t1241 = load i8*, i8** %t1122
  %t1242 = bitcast i8* %t1241 to { %Point*, i64, i64 }*
  %t1243 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1242, i32 0, i32 0
  %t1244 = load %Point*, %Point** %t1243
  %t1245 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1242, i32 0, i32 1
  %t1246 = load i64, i64* %t1245
  %t1247 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1242, i32 0, i32 2
  %t1249 = getelementptr inbounds %Point, %Point* %t1248, i32 0, i32 0
  store i32 1, i32* %t1249
  %t1250 = getelementptr inbounds %Point, %Point* %t1248, i32 0, i32 1
  store i32 2, i32* %t1250
  %t1251 = load %Point, %Point* %t1248
  %t1252 = load i64, i64* %t1245
  %t1253 = load %Point*, %Point** %t1243
  store i64 0, i64* %t1254
  store i1 false, i1* %t1255
  br label %find_cond_267
find_cond_267:
  %t1256 = load i64, i64* %t1254
  %t1257 = icmp slt i64 %t1256, %t1252
  br i1 %t1257, label %find_body_268, label %find_end_271
find_body_268:
  %t1258 = getelementptr inbounds %Point, %Point* %t1253, i64 %t1256
  %t1259 = load %Point, %Point* %t1258
  br label %find_eq_check_269
find_eq_check_269:
  %t1260 = call i1 @eq_s_Point(%Point %t1259, %Point %t1251)
  br i1 %t1260, label %find_end_271, label %find_next_270
find_next_270:
  %t1261 = add i64 %t1256, 1
  store i64 %t1261, i64* %t1254
  br label %find_cond_267
find_end_271:
  %t1262 = load i64, i64* %t1254
  %t1263 = icmp slt i64 %t1262, %t1252
  br i1 %t1263, label %set_insert_already_present_272, label %set_insert_do_273
set_insert_already_present_272:
  br label %set_insert_end_274
set_insert_do_273:
  %t1264 = load i64, i64* %t1247
  %t1265 = load %Point*, %Point** %t1243
  %t1266 = icmp sge i64 %t1252, %t1264
  br i1 %t1266, label %set_insert_grow_275, label %set_insert_store_276
set_insert_grow_275:
  %t1267 = mul i64 %t1264, 2
  %t1268 = icmp sgt i64 %t1267, 0
  %t1269 = select i1 %t1268, i64 %t1267, i64 1
  %t1270 = getelementptr %Point, %Point* null, i32 1
  %t1271 = ptrtoint %Point* %t1270 to i64
  %t1272 = mul i64 %t1269, %t1271
  %t1273 = call i8* @malloc(i64 %t1272)
  %t1274 = bitcast i8* %t1273 to %Point*
  %t1275 = icmp sgt i64 %t1264, 0
  br i1 %t1275, label %set_insert_copy_277, label %set_insert_after_copy_278
set_insert_copy_277:
  %t1276 = mul i64 %t1252, %t1271
  %t1277 = bitcast %Point* %t1265 to i8*
  call i8* @memcpy(i8* %t1273, i8* %t1277, i64 %t1276)
  call void @free(i8* %t1277)
  br label %set_insert_after_copy_278
set_insert_after_copy_278:
  store %Point* %t1274, %Point** %t1243
  store i64 %t1269, i64* %t1247
  br label %set_insert_store_276
set_insert_store_276:
  %t1278 = load %Point*, %Point** %t1243
  %t1279 = getelementptr inbounds %Point, %Point* %t1278, i64 %t1252
  store %Point %t1251, %Point* %t1279
  %t1280 = add i64 %t1252, 1
  store i64 %t1280, i64* %t1245
  br label %set_insert_end_274
set_insert_end_274:
  %t1281 = phi i1 [ false, %set_insert_already_present_272 ], [ true, %set_insert_store_276 ]
  %t1282 = getelementptr %Point, %Point* null, i32 1
  %t1283 = ptrtoint %Point* %t1282 to i64
  %t1284 = load i8*, i8** %t1122
  %t1285 = icmp eq i8* %t1284, null
  br i1 %t1285, label %set_cow_alloc_279, label %set_cow_check_280
set_cow_alloc_279:
  %t1286 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1287 = call i8* @star_rc_alloc(i64 24, i8* %t1286)
  %t1288 = bitcast i8* %t1287 to { %Point*, i64, i64 }*
  %t1289 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1288, i32 0, i32 0
  store %Point* null, %Point** %t1289
  %t1290 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1288, i32 0, i32 1
  store i64 0, i64* %t1290
  %t1291 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1288, i32 0, i32 2
  store i64 0, i64* %t1291
  store i8* %t1287, i8** %t1122
  br label %set_cow_done_281
set_cow_check_280:
  %t1292 = getelementptr inbounds i8, i8* %t1284, i64 -16
  %t1293 = bitcast i8* %t1292 to i64*
  %t1294 = load atomic i64, i64* %t1293 seq_cst, align 8
  %t1295 = icmp eq i64 %t1294, 1
  br i1 %t1295, label %set_cow_done_281, label %set_cow_clone_282
set_cow_clone_282:
  %t1296 = bitcast i8* %t1284 to { %Point*, i64, i64 }*
  %t1297 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1296, i32 0, i32 0
  %t1298 = load %Point*, %Point** %t1297
  %t1299 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1296, i32 0, i32 1
  %t1300 = load i64, i64* %t1299
  %t1301 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1296, i32 0, i32 2
  %t1302 = load i64, i64* %t1301
  %t1303 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1304 = call i8* @star_rc_alloc(i64 24, i8* %t1303)
  %t1305 = bitcast i8* %t1304 to { %Point*, i64, i64 }*
  %t1306 = mul i64 %t1302, %t1283
  %t1307 = call i8* @malloc(i64 %t1306)
  %t1308 = bitcast i8* %t1307 to %Point*
  %t1309 = icmp sgt i64 %t1300, 0
  br i1 %t1309, label %set_cow_copy_283, label %set_cow_after_copy_284
set_cow_copy_283:
  %t1310 = mul i64 %t1300, %t1283
  %t1311 = bitcast %Point* %t1298 to i8*
  call i8* @memcpy(i8* %t1307, i8* %t1311, i64 %t1310)
  br label %set_cow_after_copy_284
set_cow_after_copy_284:
  %t1312 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1305, i32 0, i32 0
  store %Point* %t1308, %Point** %t1312
  %t1313 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1305, i32 0, i32 1
  store i64 %t1300, i64* %t1313
  %t1314 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1305, i32 0, i32 2
  store i64 %t1302, i64* %t1314
  call void @star_rc_release(i8* %t1284)
  store i8* %t1304, i8** %t1122
  br label %set_cow_done_281
set_cow_done_281:
  %t1315 = load i8*, i8** %t1122
  %t1316 = bitcast i8* %t1315 to { %Point*, i64, i64 }*
  %t1317 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1316, i32 0, i32 0
  %t1318 = load %Point*, %Point** %t1317
  %t1319 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1316, i32 0, i32 1
  %t1320 = load i64, i64* %t1319
  %t1321 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1316, i32 0, i32 2
  %t1323 = getelementptr inbounds %Point, %Point* %t1322, i32 0, i32 0
  store i32 3, i32* %t1323
  %t1324 = getelementptr inbounds %Point, %Point* %t1322, i32 0, i32 1
  store i32 4, i32* %t1324
  %t1325 = load %Point, %Point* %t1322
  %t1326 = load i64, i64* %t1319
  %t1327 = load %Point*, %Point** %t1317
  store i64 0, i64* %t1328
  store i1 false, i1* %t1329
  br label %find_cond_285
find_cond_285:
  %t1330 = load i64, i64* %t1328
  %t1331 = icmp slt i64 %t1330, %t1326
  br i1 %t1331, label %find_body_286, label %find_end_289
find_body_286:
  %t1332 = getelementptr inbounds %Point, %Point* %t1327, i64 %t1330
  %t1333 = load %Point, %Point* %t1332
  br label %find_eq_check_287
find_eq_check_287:
  %t1334 = call i1 @eq_s_Point(%Point %t1333, %Point %t1325)
  br i1 %t1334, label %find_end_289, label %find_next_288
find_next_288:
  %t1335 = add i64 %t1330, 1
  store i64 %t1335, i64* %t1328
  br label %find_cond_285
find_end_289:
  %t1336 = load i64, i64* %t1328
  %t1337 = icmp slt i64 %t1336, %t1326
  br i1 %t1337, label %set_insert_already_present_290, label %set_insert_do_291
set_insert_already_present_290:
  br label %set_insert_end_292
set_insert_do_291:
  %t1338 = load i64, i64* %t1321
  %t1339 = load %Point*, %Point** %t1317
  %t1340 = icmp sge i64 %t1326, %t1338
  br i1 %t1340, label %set_insert_grow_293, label %set_insert_store_294
set_insert_grow_293:
  %t1341 = mul i64 %t1338, 2
  %t1342 = icmp sgt i64 %t1341, 0
  %t1343 = select i1 %t1342, i64 %t1341, i64 1
  %t1344 = getelementptr %Point, %Point* null, i32 1
  %t1345 = ptrtoint %Point* %t1344 to i64
  %t1346 = mul i64 %t1343, %t1345
  %t1347 = call i8* @malloc(i64 %t1346)
  %t1348 = bitcast i8* %t1347 to %Point*
  %t1349 = icmp sgt i64 %t1338, 0
  br i1 %t1349, label %set_insert_copy_295, label %set_insert_after_copy_296
set_insert_copy_295:
  %t1350 = mul i64 %t1326, %t1345
  %t1351 = bitcast %Point* %t1339 to i8*
  call i8* @memcpy(i8* %t1347, i8* %t1351, i64 %t1350)
  call void @free(i8* %t1351)
  br label %set_insert_after_copy_296
set_insert_after_copy_296:
  store %Point* %t1348, %Point** %t1317
  store i64 %t1343, i64* %t1321
  br label %set_insert_store_294
set_insert_store_294:
  %t1352 = load %Point*, %Point** %t1317
  %t1353 = getelementptr inbounds %Point, %Point* %t1352, i64 %t1326
  store %Point %t1325, %Point* %t1353
  %t1354 = add i64 %t1326, 1
  store i64 %t1354, i64* %t1319
  br label %set_insert_end_292
set_insert_end_292:
  %t1355 = phi i1 [ false, %set_insert_already_present_290 ], [ true, %set_insert_store_294 ]
  %t1356 = load i8*, i8** %t1122
  %t1357 = icmp eq i8* %t1356, null
  br i1 %t1357, label %set_read_null_297, label %set_read_real_298
set_read_null_297:
  br label %set_read_end_299
set_read_real_298:
  %t1358 = bitcast i8* %t1356 to { %Point*, i64, i64 }*
  %t1359 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1358, i32 0, i32 0
  %t1360 = load %Point*, %Point** %t1359
  %t1361 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1358, i32 0, i32 1
  %t1362 = load i64, i64* %t1361
  br label %set_read_end_299
set_read_end_299:
  %t1363 = phi %Point* [ null, %set_read_null_297 ], [ %t1360, %set_read_real_298 ]
  %t1364 = phi i64 [ 0, %set_read_null_297 ], [ %t1362, %set_read_real_298 ]
  %t1365 = trunc i64 %t1364 to i32
  %t1366 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1366, i32 %t1365)
  %t1368 = getelementptr inbounds %Point, %Point* %t1367, i32 0, i32 0
  store i32 1, i32* %t1368
  %t1369 = getelementptr inbounds %Point, %Point* %t1367, i32 0, i32 1
  store i32 2, i32* %t1369
  %t1370 = load %Point, %Point* %t1367
  %t1371 = load i8*, i8** %t1122
  %t1372 = icmp eq i8* %t1371, null
  br i1 %t1372, label %set_read_null_300, label %set_read_real_301
set_read_null_300:
  br label %set_read_end_302
set_read_real_301:
  %t1373 = bitcast i8* %t1371 to { %Point*, i64, i64 }*
  %t1374 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1373, i32 0, i32 0
  %t1375 = load %Point*, %Point** %t1374
  %t1376 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1373, i32 0, i32 1
  %t1377 = load i64, i64* %t1376
  br label %set_read_end_302
set_read_end_302:
  %t1378 = phi %Point* [ null, %set_read_null_300 ], [ %t1375, %set_read_real_301 ]
  %t1379 = phi i64 [ 0, %set_read_null_300 ], [ %t1377, %set_read_real_301 ]
  store i64 0, i64* %t1380
  store i1 false, i1* %t1381
  br label %find_cond_303
find_cond_303:
  %t1382 = load i64, i64* %t1380
  %t1383 = icmp slt i64 %t1382, %t1379
  br i1 %t1383, label %find_body_304, label %find_end_307
find_body_304:
  %t1384 = getelementptr inbounds %Point, %Point* %t1378, i64 %t1382
  %t1385 = load %Point, %Point* %t1384
  br label %find_eq_check_305
find_eq_check_305:
  %t1386 = call i1 @eq_s_Point(%Point %t1385, %Point %t1370)
  br i1 %t1386, label %find_end_307, label %find_next_306
find_next_306:
  %t1387 = add i64 %t1382, 1
  store i64 %t1387, i64* %t1380
  br label %find_cond_303
find_end_307:
  %t1388 = load i64, i64* %t1380
  %t1389 = icmp slt i64 %t1388, %t1379
  %t1390 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t1391 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t1392 = select i1 %t1389, i8* %t1390, i8* %t1391
  %t1393 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1393, i8* %t1392)
  %t1395 = getelementptr inbounds %Point, %Point* %t1394, i32 0, i32 0
  store i32 9, i32* %t1395
  %t1396 = getelementptr inbounds %Point, %Point* %t1394, i32 0, i32 1
  store i32 9, i32* %t1396
  %t1397 = load %Point, %Point* %t1394
  %t1398 = load i8*, i8** %t1122
  %t1399 = icmp eq i8* %t1398, null
  br i1 %t1399, label %set_read_null_308, label %set_read_real_309
set_read_null_308:
  br label %set_read_end_310
set_read_real_309:
  %t1400 = bitcast i8* %t1398 to { %Point*, i64, i64 }*
  %t1401 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1400, i32 0, i32 0
  %t1402 = load %Point*, %Point** %t1401
  %t1403 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1400, i32 0, i32 1
  %t1404 = load i64, i64* %t1403
  br label %set_read_end_310
set_read_end_310:
  %t1405 = phi %Point* [ null, %set_read_null_308 ], [ %t1402, %set_read_real_309 ]
  %t1406 = phi i64 [ 0, %set_read_null_308 ], [ %t1404, %set_read_real_309 ]
  store i64 0, i64* %t1407
  store i1 false, i1* %t1408
  br label %find_cond_311
find_cond_311:
  %t1409 = load i64, i64* %t1407
  %t1410 = icmp slt i64 %t1409, %t1406
  br i1 %t1410, label %find_body_312, label %find_end_315
find_body_312:
  %t1411 = getelementptr inbounds %Point, %Point* %t1405, i64 %t1409
  %t1412 = load %Point, %Point* %t1411
  br label %find_eq_check_313
find_eq_check_313:
  %t1413 = call i1 @eq_s_Point(%Point %t1412, %Point %t1397)
  br i1 %t1413, label %find_end_315, label %find_next_314
find_next_314:
  %t1414 = add i64 %t1409, 1
  store i64 %t1414, i64* %t1407
  br label %find_cond_311
find_end_315:
  %t1415 = load i64, i64* %t1407
  %t1416 = icmp slt i64 %t1415, %t1406
  %t1417 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1418 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1419 = select i1 %t1416, i8* %t1417, i8* %t1418
  %t1420 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1420, i8* %t1419)
  %t1421 = load i8*, i8** %t1122
  call void @star_rc_release(i8* %t1421)
  %t1422 = load i8*, i8** %t706
  call void @star_rc_release(i8* %t1422)
  %t1423 = load i8*, i8** %t522
  call void @star_rc_release(i8* %t1423)
  %t1424 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t1424)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_3_stri32(i8* %objp) {
entry:
  %t16 = alloca i64
  %t9 = bitcast i8* %objp to { i8**, i32*, i64, i64 }*
  %t10 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t9, i32 0, i32 0
  %t11 = load i8**, i8*** %t10
  %t12 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t9, i32 0, i32 1
  %t13 = load i32*, i32** %t12
  %t14 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t9, i32 0, i32 2
  %t15 = load i64, i64* %t14
  store i64 0, i64* %t16
  br label %map_release_cond_3
map_release_cond_3:
  %t17 = load i64, i64* %t16
  %t18 = icmp slt i64 %t17, %t15
  br i1 %t18, label %map_release_body_4, label %map_release_end_5
map_release_body_4:
  %t19 = getelementptr inbounds i8*, i8** %t11, i64 %t17
  %t20 = load i8*, i8** %t19
  call void @star_rc_release(i8* %t20)
  %t21 = add i64 %t17, 1
  store i64 %t21, i64* %t16
  br label %map_release_cond_3
map_release_end_5:
  %t22 = bitcast i8** %t11 to i8*
  call void @free(i8* %t22)
  %t23 = bitcast i32* %t13 to i8*
  call void @free(i8* %t23)
  ret void
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t80 = call i32 @strcmp(i8* %a, i8* %b)
  %t81 = icmp eq i32 %t80, 0
  ret i1 %t81
}


define void @set_release_i32(i8* %objp) {
entry:
  %t711 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t712 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t711, i32 0, i32 0
  %t713 = load i32*, i32** %t712
  %t714 = bitcast i32* %t713 to i8*
  call void @free(i8* %t714)
  ret void
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t753 = icmp eq i32 %a, %b
  ret i1 %t753
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1127 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t1128 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1127, i32 0, i32 0
  %t1129 = load %Point*, %Point** %t1128
  %t1130 = bitcast %Point* %t1129 to i8*
  call void @free(i8* %t1130)
  ret void
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t1173 = extractvalue %Point %a, 0
  %t1174 = extractvalue %Point %b, 0
  %t1175 = icmp eq i32 %t1173, %t1174
  %t1176 = extractvalue %Point %a, 1
  %t1177 = extractvalue %Point %b, 1
  %t1178 = icmp eq i32 %t1176, %t1177
  %t1179 = and i1 %t1175, %t1178
  ret i1 %t1179
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
