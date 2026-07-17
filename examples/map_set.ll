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
  %t89 = alloca i8*
  %t160 = alloca i64
  %t182 = alloca i64
  %t191 = alloca i8*
  %t249 = alloca i64
  %t258 = alloca i8*
  %t262 = alloca %Option__i32
  %t268 = alloca %Option__i32
  %t272 = alloca %Option__i32
  %t305 = alloca i64
  %t314 = alloca i8*
  %t318 = alloca %Option__i32
  %t324 = alloca %Option__i32
  %t328 = alloca %Option__i32
  %t388 = alloca i64
  %t410 = alloca i64
  %t419 = alloca i8*
  %t477 = alloca i64
  %t486 = alloca i8*
  %t490 = alloca %Option__i32
  %t496 = alloca %Option__i32
  %t500 = alloca %Option__i32
  %t520 = alloca i8*
  %t536 = alloca i64
  %t545 = alloca i8*
  %t592 = alloca i64
  %t611 = alloca i64
  %t620 = alloca i8*
  %t631 = alloca %Option__i32
  %t637 = alloca %Option__i32
  %t641 = alloca %Option__i32
  %t675 = alloca i64
  %t684 = alloca i8*
  %t704 = alloca i8*
  %t752 = alloca i64
  %t753 = alloca i1
  %t826 = alloca i64
  %t827 = alloca i1
  %t900 = alloca i64
  %t901 = alloca i1
  %t952 = alloca i64
  %t953 = alloca i1
  %t1008 = alloca i64
  %t1009 = alloca i1
  %t1035 = alloca i64
  %t1036 = alloca i1
  %t1091 = alloca i64
  %t1092 = alloca i1
  %t1120 = alloca i8*
  %t1165 = alloca %Point
  %t1178 = alloca i64
  %t1179 = alloca i1
  %t1246 = alloca %Point
  %t1252 = alloca i64
  %t1253 = alloca i1
  %t1320 = alloca %Point
  %t1326 = alloca i64
  %t1327 = alloca i1
  %t1365 = alloca %Point
  %t1378 = alloca i64
  %t1379 = alloca i1
  %t1392 = alloca %Point
  %t1405 = alloca i64
  %t1406 = alloca i1
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
  store i8* %t75, i8** %t89
  %t90 = load i8*, i8** %t89
  call void @star_rc_release(i8* %t90)
  %t91 = load i32*, i32** %t70
  %t92 = getelementptr inbounds i32, i32* %t91, i64 %t87
  store i32 30, i32* %t92
  br label %map_insert_after_19
map_insert_new_18:
  %t93 = load i64, i64* %t74
  %t94 = icmp sge i64 %t76, %t93
  br i1 %t94, label %map_insert_grow_20, label %map_insert_store_21
map_insert_grow_20:
  %t95 = mul i64 %t93, 2
  %t96 = icmp sgt i64 %t95, 0
  %t97 = select i1 %t96, i64 %t95, i64 1
  %t98 = getelementptr i8*, i8** null, i32 1
  %t99 = ptrtoint i8** %t98 to i64
  %t100 = mul i64 %t97, %t99
  %t101 = call i8* @malloc(i64 %t100)
  %t102 = bitcast i8* %t101 to i8**
  %t103 = getelementptr i32, i32* null, i32 1
  %t104 = ptrtoint i32* %t103 to i64
  %t105 = mul i64 %t97, %t104
  %t106 = call i8* @malloc(i64 %t105)
  %t107 = bitcast i8* %t106 to i32*
  %t108 = icmp sgt i64 %t93, 0
  br i1 %t108, label %map_insert_copy_22, label %map_insert_after_copy_23
map_insert_copy_22:
  %t109 = load i8**, i8*** %t68
  %t110 = mul i64 %t76, %t99
  %t111 = bitcast i8** %t109 to i8*
  call i8* @memcpy(i8* %t101, i8* %t111, i64 %t110)
  call void @free(i8* %t111)
  %t112 = load i32*, i32** %t70
  %t113 = mul i64 %t76, %t104
  %t114 = bitcast i32* %t112 to i8*
  call i8* @memcpy(i8* %t106, i8* %t114, i64 %t113)
  call void @free(i8* %t114)
  br label %map_insert_after_copy_23
map_insert_after_copy_23:
  store i8** %t102, i8*** %t68
  store i32* %t107, i32** %t70
  store i64 %t97, i64* %t74
  br label %map_insert_store_21
map_insert_store_21:
  %t115 = load i8**, i8*** %t68
  %t116 = load i32*, i32** %t70
  %t117 = getelementptr inbounds i8*, i8** %t115, i64 %t76
  store i8* %t75, i8** %t117
  %t118 = getelementptr inbounds i32, i32* %t116, i64 %t76
  store i32 30, i32* %t118
  %t119 = add i64 %t76, 1
  store i64 %t119, i64* %t72
  br label %map_insert_after_19
map_insert_after_19:
  %t120 = getelementptr i8*, i8** null, i32 1
  %t121 = ptrtoint i8** %t120 to i64
  %t122 = getelementptr i32, i32* null, i32 1
  %t123 = ptrtoint i32* %t122 to i64
  %t124 = load i8*, i8** %t0
  %t125 = icmp eq i8* %t124, null
  br i1 %t125, label %map_cow_alloc_24, label %map_cow_check_25
map_cow_alloc_24:
  %t126 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t127 = call i8* @star_rc_alloc(i64 32, i8* %t126)
  %t128 = bitcast i8* %t127 to { i8**, i32*, i64, i64 }*
  %t129 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t128, i32 0, i32 0
  store i8** null, i8*** %t129
  %t130 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t128, i32 0, i32 1
  store i32* null, i32** %t130
  %t131 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t128, i32 0, i32 2
  store i64 0, i64* %t131
  %t132 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t128, i32 0, i32 3
  store i64 0, i64* %t132
  store i8* %t127, i8** %t0
  br label %map_cow_done_26
map_cow_check_25:
  %t133 = getelementptr inbounds i8, i8* %t124, i64 -16
  %t134 = bitcast i8* %t133 to i64*
  %t135 = load atomic i64, i64* %t134 seq_cst, align 8
  %t136 = icmp eq i64 %t135, 1
  br i1 %t136, label %map_cow_done_26, label %map_cow_clone_27
map_cow_clone_27:
  %t137 = bitcast i8* %t124 to { i8**, i32*, i64, i64 }*
  %t138 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t137, i32 0, i32 0
  %t139 = load i8**, i8*** %t138
  %t140 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t137, i32 0, i32 1
  %t141 = load i32*, i32** %t140
  %t142 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t137, i32 0, i32 2
  %t143 = load i64, i64* %t142
  %t144 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t137, i32 0, i32 3
  %t145 = load i64, i64* %t144
  %t146 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t147 = call i8* @star_rc_alloc(i64 32, i8* %t146)
  %t148 = bitcast i8* %t147 to { i8**, i32*, i64, i64 }*
  %t149 = mul i64 %t145, %t121
  %t150 = call i8* @malloc(i64 %t149)
  %t151 = bitcast i8* %t150 to i8**
  %t152 = mul i64 %t145, %t123
  %t153 = call i8* @malloc(i64 %t152)
  %t154 = bitcast i8* %t153 to i32*
  %t155 = icmp sgt i64 %t143, 0
  br i1 %t155, label %map_cow_copy_28, label %map_cow_after_copy_29
map_cow_copy_28:
  %t156 = mul i64 %t143, %t121
  %t157 = bitcast i8** %t139 to i8*
  call i8* @memcpy(i8* %t150, i8* %t157, i64 %t156)
  %t158 = mul i64 %t143, %t123
  %t159 = bitcast i32* %t141 to i8*
  call i8* @memcpy(i8* %t153, i8* %t159, i64 %t158)
  store i64 0, i64* %t160
  br label %map_cow_retain_cond_30
map_cow_retain_cond_30:
  %t161 = load i64, i64* %t160
  %t162 = icmp slt i64 %t161, %t143
  br i1 %t162, label %map_cow_retain_body_31, label %map_cow_retain_end_32
map_cow_retain_body_31:
  %t163 = getelementptr inbounds i8*, i8** %t151, i64 %t161
  %t164 = load i8*, i8** %t163
  call void @star_rc_retain(i8* %t164)
  %t165 = add i64 %t161, 1
  store i64 %t165, i64* %t160
  br label %map_cow_retain_cond_30
map_cow_retain_end_32:
  br label %map_cow_after_copy_29
map_cow_after_copy_29:
  %t166 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t148, i32 0, i32 0
  store i8** %t151, i8*** %t166
  %t167 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t148, i32 0, i32 1
  store i32* %t154, i32** %t167
  %t168 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t148, i32 0, i32 2
  store i64 %t143, i64* %t168
  %t169 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t148, i32 0, i32 3
  store i64 %t145, i64* %t169
  call void @star_rc_release(i8* %t124)
  store i8* %t147, i8** %t0
  br label %map_cow_done_26
map_cow_done_26:
  %t170 = load i8*, i8** %t0
  %t171 = bitcast i8* %t170 to { i8**, i32*, i64, i64 }*
  %t172 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t171, i32 0, i32 0
  %t173 = load i8**, i8*** %t172
  %t174 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t171, i32 0, i32 1
  %t175 = load i32*, i32** %t174
  %t176 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t171, i32 0, i32 2
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t171, i32 0, i32 3
  %t179 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t180 = load i64, i64* %t176
  %t181 = load i8**, i8*** %t172
  store i64 0, i64* %t182
  br label %map_find_cond_33
map_find_cond_33:
  %t183 = load i64, i64* %t182
  %t184 = icmp slt i64 %t183, %t180
  br i1 %t184, label %map_find_body_34, label %map_find_end_37
map_find_body_34:
  %t185 = getelementptr inbounds i8*, i8** %t181, i64 %t183
  %t186 = load i8*, i8** %t185
  br label %map_find_eq_check_35
map_find_eq_check_35:
  %t187 = call i1 @eq_str(i8* %t186, i8* %t179)
  br i1 %t187, label %map_find_end_37, label %map_find_next_36
map_find_next_36:
  %t188 = add i64 %t183, 1
  store i64 %t188, i64* %t182
  br label %map_find_cond_33
map_find_end_37:
  %t189 = load i64, i64* %t182
  %t190 = icmp slt i64 %t189, %t180
  br i1 %t190, label %map_insert_overwrite_38, label %map_insert_new_39
map_insert_overwrite_38:
  store i8* %t179, i8** %t191
  %t192 = load i8*, i8** %t191
  call void @star_rc_release(i8* %t192)
  %t193 = load i32*, i32** %t174
  %t194 = getelementptr inbounds i32, i32* %t193, i64 %t189
  store i32 25, i32* %t194
  br label %map_insert_after_40
map_insert_new_39:
  %t195 = load i64, i64* %t178
  %t196 = icmp sge i64 %t180, %t195
  br i1 %t196, label %map_insert_grow_41, label %map_insert_store_42
map_insert_grow_41:
  %t197 = mul i64 %t195, 2
  %t198 = icmp sgt i64 %t197, 0
  %t199 = select i1 %t198, i64 %t197, i64 1
  %t200 = getelementptr i8*, i8** null, i32 1
  %t201 = ptrtoint i8** %t200 to i64
  %t202 = mul i64 %t199, %t201
  %t203 = call i8* @malloc(i64 %t202)
  %t204 = bitcast i8* %t203 to i8**
  %t205 = getelementptr i32, i32* null, i32 1
  %t206 = ptrtoint i32* %t205 to i64
  %t207 = mul i64 %t199, %t206
  %t208 = call i8* @malloc(i64 %t207)
  %t209 = bitcast i8* %t208 to i32*
  %t210 = icmp sgt i64 %t195, 0
  br i1 %t210, label %map_insert_copy_43, label %map_insert_after_copy_44
map_insert_copy_43:
  %t211 = load i8**, i8*** %t172
  %t212 = mul i64 %t180, %t201
  %t213 = bitcast i8** %t211 to i8*
  call i8* @memcpy(i8* %t203, i8* %t213, i64 %t212)
  call void @free(i8* %t213)
  %t214 = load i32*, i32** %t174
  %t215 = mul i64 %t180, %t206
  %t216 = bitcast i32* %t214 to i8*
  call i8* @memcpy(i8* %t208, i8* %t216, i64 %t215)
  call void @free(i8* %t216)
  br label %map_insert_after_copy_44
map_insert_after_copy_44:
  store i8** %t204, i8*** %t172
  store i32* %t209, i32** %t174
  store i64 %t199, i64* %t178
  br label %map_insert_store_42
map_insert_store_42:
  %t217 = load i8**, i8*** %t172
  %t218 = load i32*, i32** %t174
  %t219 = getelementptr inbounds i8*, i8** %t217, i64 %t180
  store i8* %t179, i8** %t219
  %t220 = getelementptr inbounds i32, i32* %t218, i64 %t180
  store i32 25, i32* %t220
  %t221 = add i64 %t180, 1
  store i64 %t221, i64* %t176
  br label %map_insert_after_40
map_insert_after_40:
  %t222 = load i8*, i8** %t0
  %t223 = icmp eq i8* %t222, null
  br i1 %t223, label %map_read_null_45, label %map_read_real_46
map_read_null_45:
  br label %map_read_end_47
map_read_real_46:
  %t224 = bitcast i8* %t222 to { i8**, i32*, i64, i64 }*
  %t225 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t224, i32 0, i32 0
  %t226 = load i8**, i8*** %t225
  %t227 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t224, i32 0, i32 1
  %t228 = load i32*, i32** %t227
  %t229 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t224, i32 0, i32 2
  %t230 = load i64, i64* %t229
  br label %map_read_end_47
map_read_end_47:
  %t231 = phi i8** [ null, %map_read_null_45 ], [ %t226, %map_read_real_46 ]
  %t232 = phi i32* [ null, %map_read_null_45 ], [ %t228, %map_read_real_46 ]
  %t233 = phi i64 [ 0, %map_read_null_45 ], [ %t230, %map_read_real_46 ]
  %t234 = trunc i64 %t233 to i32
  %t235 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t235, i32 %t234)
  %t236 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t237 = load i8*, i8** %t0
  %t238 = icmp eq i8* %t237, null
  br i1 %t238, label %map_read_null_48, label %map_read_real_49
map_read_null_48:
  br label %map_read_end_50
map_read_real_49:
  %t239 = bitcast i8* %t237 to { i8**, i32*, i64, i64 }*
  %t240 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t239, i32 0, i32 0
  %t241 = load i8**, i8*** %t240
  %t242 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t239, i32 0, i32 1
  %t243 = load i32*, i32** %t242
  %t244 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t239, i32 0, i32 2
  %t245 = load i64, i64* %t244
  br label %map_read_end_50
map_read_end_50:
  %t246 = phi i8** [ null, %map_read_null_48 ], [ %t241, %map_read_real_49 ]
  %t247 = phi i32* [ null, %map_read_null_48 ], [ %t243, %map_read_real_49 ]
  %t248 = phi i64 [ 0, %map_read_null_48 ], [ %t245, %map_read_real_49 ]
  store i64 0, i64* %t249
  br label %map_find_cond_51
map_find_cond_51:
  %t250 = load i64, i64* %t249
  %t251 = icmp slt i64 %t250, %t248
  br i1 %t251, label %map_find_body_52, label %map_find_end_55
map_find_body_52:
  %t252 = getelementptr inbounds i8*, i8** %t246, i64 %t250
  %t253 = load i8*, i8** %t252
  br label %map_find_eq_check_53
map_find_eq_check_53:
  %t254 = call i1 @eq_str(i8* %t253, i8* %t236)
  br i1 %t254, label %map_find_end_55, label %map_find_next_54
map_find_next_54:
  %t255 = add i64 %t250, 1
  store i64 %t255, i64* %t249
  br label %map_find_cond_51
map_find_end_55:
  %t256 = load i64, i64* %t249
  %t257 = icmp slt i64 %t256, %t248
  store i8* %t236, i8** %t258
  %t259 = load i8*, i8** %t258
  call void @star_rc_release(i8* %t259)
  br i1 %t257, label %map_get_some_56, label %map_get_none_57
map_get_some_56:
  %t260 = getelementptr inbounds i32, i32* %t247, i64 %t256
  %t261 = load i32, i32* %t260
  %t263 = getelementptr inbounds %Option__i32, %Option__i32* %t262, i32 0, i32 0
  store i32 1, i32* %t263
  %t264 = getelementptr inbounds %Option__i32, %Option__i32* %t262, i32 0, i32 1
  %t265 = bitcast [1 x i64]* %t264 to { i32 }*
  %t266 = getelementptr inbounds { i32 }, { i32 }* %t265, i32 0, i32 0
  store i32 %t261, i32* %t266
  %t267 = load %Option__i32, %Option__i32* %t262
  br label %map_get_end_58
map_get_none_57:
  %t269 = getelementptr inbounds %Option__i32, %Option__i32* %t268, i32 0, i32 0
  store i32 0, i32* %t269
  %t270 = load %Option__i32, %Option__i32* %t268
  br label %map_get_end_58
map_get_end_58:
  %t271 = phi %Option__i32 [ %t267, %map_get_some_56 ], [ %t270, %map_get_none_57 ]
  store %Option__i32 %t271, %Option__i32* %t272
  br label %match_scrutinee_274
match_scrutinee_274:
  %t278 = getelementptr inbounds %Option__i32, %Option__i32* %t272, i32 0, i32 0
  %t279 = load i32, i32* %t278
  %t277 = icmp eq i32 %t279, 1
  br i1 %t277, label %match_then_0_275, label %match_next_0_276
match_then_0_275:
  %t280 = getelementptr inbounds %Option__i32, %Option__i32* %t272, i32 0, i32 1
  %t281 = bitcast [1 x i64]* %t280 to { i32 }*
  %t282 = getelementptr inbounds { i32 }, { i32 }* %t281, i32 0, i32 0
  %t283 = load i32, i32* %t282
  %t284 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t284, i32 %t283)
  br label %match_end_273
match_next_0_276:
  %t288 = getelementptr inbounds %Option__i32, %Option__i32* %t272, i32 0, i32 0
  %t289 = load i32, i32* %t288
  %t287 = icmp eq i32 %t289, 0
  br i1 %t287, label %match_then_1_285, label %match_next_1_286
match_then_1_285:
  %t290 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t290)
  call i32 (i8*, ...) @printf(i8* %t290)
  %t291 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t291)
  br label %match_end_273
match_next_1_286:
  br label %match_end_273
match_end_273:
  %t292 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t293 = load i8*, i8** %t0
  %t294 = icmp eq i8* %t293, null
  br i1 %t294, label %map_read_null_59, label %map_read_real_60
map_read_null_59:
  br label %map_read_end_61
map_read_real_60:
  %t295 = bitcast i8* %t293 to { i8**, i32*, i64, i64 }*
  %t296 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t295, i32 0, i32 0
  %t297 = load i8**, i8*** %t296
  %t298 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t295, i32 0, i32 1
  %t299 = load i32*, i32** %t298
  %t300 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t295, i32 0, i32 2
  %t301 = load i64, i64* %t300
  br label %map_read_end_61
map_read_end_61:
  %t302 = phi i8** [ null, %map_read_null_59 ], [ %t297, %map_read_real_60 ]
  %t303 = phi i32* [ null, %map_read_null_59 ], [ %t299, %map_read_real_60 ]
  %t304 = phi i64 [ 0, %map_read_null_59 ], [ %t301, %map_read_real_60 ]
  store i64 0, i64* %t305
  br label %map_find_cond_62
map_find_cond_62:
  %t306 = load i64, i64* %t305
  %t307 = icmp slt i64 %t306, %t304
  br i1 %t307, label %map_find_body_63, label %map_find_end_66
map_find_body_63:
  %t308 = getelementptr inbounds i8*, i8** %t302, i64 %t306
  %t309 = load i8*, i8** %t308
  br label %map_find_eq_check_64
map_find_eq_check_64:
  %t310 = call i1 @eq_str(i8* %t309, i8* %t292)
  br i1 %t310, label %map_find_end_66, label %map_find_next_65
map_find_next_65:
  %t311 = add i64 %t306, 1
  store i64 %t311, i64* %t305
  br label %map_find_cond_62
map_find_end_66:
  %t312 = load i64, i64* %t305
  %t313 = icmp slt i64 %t312, %t304
  store i8* %t292, i8** %t314
  %t315 = load i8*, i8** %t314
  call void @star_rc_release(i8* %t315)
  br i1 %t313, label %map_get_some_67, label %map_get_none_68
map_get_some_67:
  %t316 = getelementptr inbounds i32, i32* %t303, i64 %t312
  %t317 = load i32, i32* %t316
  %t319 = getelementptr inbounds %Option__i32, %Option__i32* %t318, i32 0, i32 0
  store i32 1, i32* %t319
  %t320 = getelementptr inbounds %Option__i32, %Option__i32* %t318, i32 0, i32 1
  %t321 = bitcast [1 x i64]* %t320 to { i32 }*
  %t322 = getelementptr inbounds { i32 }, { i32 }* %t321, i32 0, i32 0
  store i32 %t317, i32* %t322
  %t323 = load %Option__i32, %Option__i32* %t318
  br label %map_get_end_69
map_get_none_68:
  %t325 = getelementptr inbounds %Option__i32, %Option__i32* %t324, i32 0, i32 0
  store i32 0, i32* %t325
  %t326 = load %Option__i32, %Option__i32* %t324
  br label %map_get_end_69
map_get_end_69:
  %t327 = phi %Option__i32 [ %t323, %map_get_some_67 ], [ %t326, %map_get_none_68 ]
  store %Option__i32 %t327, %Option__i32* %t328
  br label %match_scrutinee_330
match_scrutinee_330:
  %t334 = getelementptr inbounds %Option__i32, %Option__i32* %t328, i32 0, i32 0
  %t335 = load i32, i32* %t334
  %t333 = icmp eq i32 %t335, 1
  br i1 %t333, label %match_then_0_331, label %match_next_0_332
match_then_0_331:
  %t336 = getelementptr inbounds %Option__i32, %Option__i32* %t328, i32 0, i32 1
  %t337 = bitcast [1 x i64]* %t336 to { i32 }*
  %t338 = getelementptr inbounds { i32 }, { i32 }* %t337, i32 0, i32 0
  %t339 = load i32, i32* %t338
  %t340 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t340, i32 %t339)
  br label %match_end_329
match_next_0_332:
  %t344 = getelementptr inbounds %Option__i32, %Option__i32* %t328, i32 0, i32 0
  %t345 = load i32, i32* %t344
  %t343 = icmp eq i32 %t345, 0
  br i1 %t343, label %match_then_1_341, label %match_next_1_342
match_then_1_341:
  %t346 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t346)
  call i32 (i8*, ...) @printf(i8* %t346)
  %t347 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t347)
  br label %match_end_329
match_next_1_342:
  br label %match_end_329
match_end_329:
  %t348 = getelementptr i8*, i8** null, i32 1
  %t349 = ptrtoint i8** %t348 to i64
  %t350 = getelementptr i32, i32* null, i32 1
  %t351 = ptrtoint i32* %t350 to i64
  %t352 = load i8*, i8** %t0
  %t353 = icmp eq i8* %t352, null
  br i1 %t353, label %map_cow_alloc_70, label %map_cow_check_71
map_cow_alloc_70:
  %t354 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t355 = call i8* @star_rc_alloc(i64 32, i8* %t354)
  %t356 = bitcast i8* %t355 to { i8**, i32*, i64, i64 }*
  %t357 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t356, i32 0, i32 0
  store i8** null, i8*** %t357
  %t358 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t356, i32 0, i32 1
  store i32* null, i32** %t358
  %t359 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t356, i32 0, i32 2
  store i64 0, i64* %t359
  %t360 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t356, i32 0, i32 3
  store i64 0, i64* %t360
  store i8* %t355, i8** %t0
  br label %map_cow_done_72
map_cow_check_71:
  %t361 = getelementptr inbounds i8, i8* %t352, i64 -16
  %t362 = bitcast i8* %t361 to i64*
  %t363 = load atomic i64, i64* %t362 seq_cst, align 8
  %t364 = icmp eq i64 %t363, 1
  br i1 %t364, label %map_cow_done_72, label %map_cow_clone_73
map_cow_clone_73:
  %t365 = bitcast i8* %t352 to { i8**, i32*, i64, i64 }*
  %t366 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t365, i32 0, i32 0
  %t367 = load i8**, i8*** %t366
  %t368 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t365, i32 0, i32 1
  %t369 = load i32*, i32** %t368
  %t370 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t365, i32 0, i32 2
  %t371 = load i64, i64* %t370
  %t372 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t365, i32 0, i32 3
  %t373 = load i64, i64* %t372
  %t374 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t375 = call i8* @star_rc_alloc(i64 32, i8* %t374)
  %t376 = bitcast i8* %t375 to { i8**, i32*, i64, i64 }*
  %t377 = mul i64 %t373, %t349
  %t378 = call i8* @malloc(i64 %t377)
  %t379 = bitcast i8* %t378 to i8**
  %t380 = mul i64 %t373, %t351
  %t381 = call i8* @malloc(i64 %t380)
  %t382 = bitcast i8* %t381 to i32*
  %t383 = icmp sgt i64 %t371, 0
  br i1 %t383, label %map_cow_copy_74, label %map_cow_after_copy_75
map_cow_copy_74:
  %t384 = mul i64 %t371, %t349
  %t385 = bitcast i8** %t367 to i8*
  call i8* @memcpy(i8* %t378, i8* %t385, i64 %t384)
  %t386 = mul i64 %t371, %t351
  %t387 = bitcast i32* %t369 to i8*
  call i8* @memcpy(i8* %t381, i8* %t387, i64 %t386)
  store i64 0, i64* %t388
  br label %map_cow_retain_cond_76
map_cow_retain_cond_76:
  %t389 = load i64, i64* %t388
  %t390 = icmp slt i64 %t389, %t371
  br i1 %t390, label %map_cow_retain_body_77, label %map_cow_retain_end_78
map_cow_retain_body_77:
  %t391 = getelementptr inbounds i8*, i8** %t379, i64 %t389
  %t392 = load i8*, i8** %t391
  call void @star_rc_retain(i8* %t392)
  %t393 = add i64 %t389, 1
  store i64 %t393, i64* %t388
  br label %map_cow_retain_cond_76
map_cow_retain_end_78:
  br label %map_cow_after_copy_75
map_cow_after_copy_75:
  %t394 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t376, i32 0, i32 0
  store i8** %t379, i8*** %t394
  %t395 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t376, i32 0, i32 1
  store i32* %t382, i32** %t395
  %t396 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t376, i32 0, i32 2
  store i64 %t371, i64* %t396
  %t397 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t376, i32 0, i32 3
  store i64 %t373, i64* %t397
  call void @star_rc_release(i8* %t352)
  store i8* %t375, i8** %t0
  br label %map_cow_done_72
map_cow_done_72:
  %t398 = load i8*, i8** %t0
  %t399 = bitcast i8* %t398 to { i8**, i32*, i64, i64 }*
  %t400 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t399, i32 0, i32 0
  %t401 = load i8**, i8*** %t400
  %t402 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t399, i32 0, i32 1
  %t403 = load i32*, i32** %t402
  %t404 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t399, i32 0, i32 2
  %t405 = load i64, i64* %t404
  %t406 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t399, i32 0, i32 3
  %t407 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t408 = load i64, i64* %t404
  %t409 = load i8**, i8*** %t400
  store i64 0, i64* %t410
  br label %map_find_cond_79
map_find_cond_79:
  %t411 = load i64, i64* %t410
  %t412 = icmp slt i64 %t411, %t408
  br i1 %t412, label %map_find_body_80, label %map_find_end_83
map_find_body_80:
  %t413 = getelementptr inbounds i8*, i8** %t409, i64 %t411
  %t414 = load i8*, i8** %t413
  br label %map_find_eq_check_81
map_find_eq_check_81:
  %t415 = call i1 @eq_str(i8* %t414, i8* %t407)
  br i1 %t415, label %map_find_end_83, label %map_find_next_82
map_find_next_82:
  %t416 = add i64 %t411, 1
  store i64 %t416, i64* %t410
  br label %map_find_cond_79
map_find_end_83:
  %t417 = load i64, i64* %t410
  %t418 = icmp slt i64 %t417, %t408
  br i1 %t418, label %map_insert_overwrite_84, label %map_insert_new_85
map_insert_overwrite_84:
  store i8* %t407, i8** %t419
  %t420 = load i8*, i8** %t419
  call void @star_rc_release(i8* %t420)
  %t421 = load i32*, i32** %t402
  %t422 = getelementptr inbounds i32, i32* %t421, i64 %t417
  store i32 31, i32* %t422
  br label %map_insert_after_86
map_insert_new_85:
  %t423 = load i64, i64* %t406
  %t424 = icmp sge i64 %t408, %t423
  br i1 %t424, label %map_insert_grow_87, label %map_insert_store_88
map_insert_grow_87:
  %t425 = mul i64 %t423, 2
  %t426 = icmp sgt i64 %t425, 0
  %t427 = select i1 %t426, i64 %t425, i64 1
  %t428 = getelementptr i8*, i8** null, i32 1
  %t429 = ptrtoint i8** %t428 to i64
  %t430 = mul i64 %t427, %t429
  %t431 = call i8* @malloc(i64 %t430)
  %t432 = bitcast i8* %t431 to i8**
  %t433 = getelementptr i32, i32* null, i32 1
  %t434 = ptrtoint i32* %t433 to i64
  %t435 = mul i64 %t427, %t434
  %t436 = call i8* @malloc(i64 %t435)
  %t437 = bitcast i8* %t436 to i32*
  %t438 = icmp sgt i64 %t423, 0
  br i1 %t438, label %map_insert_copy_89, label %map_insert_after_copy_90
map_insert_copy_89:
  %t439 = load i8**, i8*** %t400
  %t440 = mul i64 %t408, %t429
  %t441 = bitcast i8** %t439 to i8*
  call i8* @memcpy(i8* %t431, i8* %t441, i64 %t440)
  call void @free(i8* %t441)
  %t442 = load i32*, i32** %t402
  %t443 = mul i64 %t408, %t434
  %t444 = bitcast i32* %t442 to i8*
  call i8* @memcpy(i8* %t436, i8* %t444, i64 %t443)
  call void @free(i8* %t444)
  br label %map_insert_after_copy_90
map_insert_after_copy_90:
  store i8** %t432, i8*** %t400
  store i32* %t437, i32** %t402
  store i64 %t427, i64* %t406
  br label %map_insert_store_88
map_insert_store_88:
  %t445 = load i8**, i8*** %t400
  %t446 = load i32*, i32** %t402
  %t447 = getelementptr inbounds i8*, i8** %t445, i64 %t408
  store i8* %t407, i8** %t447
  %t448 = getelementptr inbounds i32, i32* %t446, i64 %t408
  store i32 31, i32* %t448
  %t449 = add i64 %t408, 1
  store i64 %t449, i64* %t404
  br label %map_insert_after_86
map_insert_after_86:
  %t450 = load i8*, i8** %t0
  %t451 = icmp eq i8* %t450, null
  br i1 %t451, label %map_read_null_91, label %map_read_real_92
map_read_null_91:
  br label %map_read_end_93
map_read_real_92:
  %t452 = bitcast i8* %t450 to { i8**, i32*, i64, i64 }*
  %t453 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t452, i32 0, i32 0
  %t454 = load i8**, i8*** %t453
  %t455 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t452, i32 0, i32 1
  %t456 = load i32*, i32** %t455
  %t457 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t452, i32 0, i32 2
  %t458 = load i64, i64* %t457
  br label %map_read_end_93
map_read_end_93:
  %t459 = phi i8** [ null, %map_read_null_91 ], [ %t454, %map_read_real_92 ]
  %t460 = phi i32* [ null, %map_read_null_91 ], [ %t456, %map_read_real_92 ]
  %t461 = phi i64 [ 0, %map_read_null_91 ], [ %t458, %map_read_real_92 ]
  %t462 = trunc i64 %t461 to i32
  %t463 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t463, i32 %t462)
  %t464 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t465 = load i8*, i8** %t0
  %t466 = icmp eq i8* %t465, null
  br i1 %t466, label %map_read_null_94, label %map_read_real_95
map_read_null_94:
  br label %map_read_end_96
map_read_real_95:
  %t467 = bitcast i8* %t465 to { i8**, i32*, i64, i64 }*
  %t468 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t467, i32 0, i32 0
  %t469 = load i8**, i8*** %t468
  %t470 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t467, i32 0, i32 1
  %t471 = load i32*, i32** %t470
  %t472 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t467, i32 0, i32 2
  %t473 = load i64, i64* %t472
  br label %map_read_end_96
map_read_end_96:
  %t474 = phi i8** [ null, %map_read_null_94 ], [ %t469, %map_read_real_95 ]
  %t475 = phi i32* [ null, %map_read_null_94 ], [ %t471, %map_read_real_95 ]
  %t476 = phi i64 [ 0, %map_read_null_94 ], [ %t473, %map_read_real_95 ]
  store i64 0, i64* %t477
  br label %map_find_cond_97
map_find_cond_97:
  %t478 = load i64, i64* %t477
  %t479 = icmp slt i64 %t478, %t476
  br i1 %t479, label %map_find_body_98, label %map_find_end_101
map_find_body_98:
  %t480 = getelementptr inbounds i8*, i8** %t474, i64 %t478
  %t481 = load i8*, i8** %t480
  br label %map_find_eq_check_99
map_find_eq_check_99:
  %t482 = call i1 @eq_str(i8* %t481, i8* %t464)
  br i1 %t482, label %map_find_end_101, label %map_find_next_100
map_find_next_100:
  %t483 = add i64 %t478, 1
  store i64 %t483, i64* %t477
  br label %map_find_cond_97
map_find_end_101:
  %t484 = load i64, i64* %t477
  %t485 = icmp slt i64 %t484, %t476
  store i8* %t464, i8** %t486
  %t487 = load i8*, i8** %t486
  call void @star_rc_release(i8* %t487)
  br i1 %t485, label %map_get_some_102, label %map_get_none_103
map_get_some_102:
  %t488 = getelementptr inbounds i32, i32* %t475, i64 %t484
  %t489 = load i32, i32* %t488
  %t491 = getelementptr inbounds %Option__i32, %Option__i32* %t490, i32 0, i32 0
  store i32 1, i32* %t491
  %t492 = getelementptr inbounds %Option__i32, %Option__i32* %t490, i32 0, i32 1
  %t493 = bitcast [1 x i64]* %t492 to { i32 }*
  %t494 = getelementptr inbounds { i32 }, { i32 }* %t493, i32 0, i32 0
  store i32 %t489, i32* %t494
  %t495 = load %Option__i32, %Option__i32* %t490
  br label %map_get_end_104
map_get_none_103:
  %t497 = getelementptr inbounds %Option__i32, %Option__i32* %t496, i32 0, i32 0
  store i32 0, i32* %t497
  %t498 = load %Option__i32, %Option__i32* %t496
  br label %map_get_end_104
map_get_end_104:
  %t499 = phi %Option__i32 [ %t495, %map_get_some_102 ], [ %t498, %map_get_none_103 ]
  store %Option__i32 %t499, %Option__i32* %t500
  br label %match_scrutinee_502
match_scrutinee_502:
  %t506 = getelementptr inbounds %Option__i32, %Option__i32* %t500, i32 0, i32 0
  %t507 = load i32, i32* %t506
  %t505 = icmp eq i32 %t507, 1
  br i1 %t505, label %match_then_0_503, label %match_next_0_504
match_then_0_503:
  %t508 = getelementptr inbounds %Option__i32, %Option__i32* %t500, i32 0, i32 1
  %t509 = bitcast [1 x i64]* %t508 to { i32 }*
  %t510 = getelementptr inbounds { i32 }, { i32 }* %t509, i32 0, i32 0
  %t511 = load i32, i32* %t510
  %t512 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t512, i32 %t511)
  br label %match_end_501
match_next_0_504:
  %t516 = getelementptr inbounds %Option__i32, %Option__i32* %t500, i32 0, i32 0
  %t517 = load i32, i32* %t516
  %t515 = icmp eq i32 %t517, 0
  br i1 %t515, label %match_then_1_513, label %match_next_1_514
match_then_1_513:
  %t518 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t518)
  call i32 (i8*, ...) @printf(i8* %t518)
  %t519 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t519)
  br label %match_end_501
match_next_1_514:
  br label %match_end_501
match_end_501:
  %t521 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t521, i8** %t520
  %t522 = load i8*, i8** %t520
  %t523 = load i8*, i8** %t520
  call void @star_rc_retain(i8* %t523)
  %t524 = load i8*, i8** %t0
  %t525 = icmp eq i8* %t524, null
  br i1 %t525, label %map_read_null_105, label %map_read_real_106
map_read_null_105:
  br label %map_read_end_107
map_read_real_106:
  %t526 = bitcast i8* %t524 to { i8**, i32*, i64, i64 }*
  %t527 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t526, i32 0, i32 0
  %t528 = load i8**, i8*** %t527
  %t529 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t526, i32 0, i32 1
  %t530 = load i32*, i32** %t529
  %t531 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t526, i32 0, i32 2
  %t532 = load i64, i64* %t531
  br label %map_read_end_107
map_read_end_107:
  %t533 = phi i8** [ null, %map_read_null_105 ], [ %t528, %map_read_real_106 ]
  %t534 = phi i32* [ null, %map_read_null_105 ], [ %t530, %map_read_real_106 ]
  %t535 = phi i64 [ 0, %map_read_null_105 ], [ %t532, %map_read_real_106 ]
  store i64 0, i64* %t536
  br label %map_find_cond_108
map_find_cond_108:
  %t537 = load i64, i64* %t536
  %t538 = icmp slt i64 %t537, %t535
  br i1 %t538, label %map_find_body_109, label %map_find_end_112
map_find_body_109:
  %t539 = getelementptr inbounds i8*, i8** %t533, i64 %t537
  %t540 = load i8*, i8** %t539
  br label %map_find_eq_check_110
map_find_eq_check_110:
  %t541 = call i1 @eq_str(i8* %t540, i8* %t522)
  br i1 %t541, label %map_find_end_112, label %map_find_next_111
map_find_next_111:
  %t542 = add i64 %t537, 1
  store i64 %t542, i64* %t536
  br label %map_find_cond_108
map_find_end_112:
  %t543 = load i64, i64* %t536
  %t544 = icmp slt i64 %t543, %t535
  store i8* %t522, i8** %t545
  %t546 = load i8*, i8** %t545
  call void @star_rc_release(i8* %t546)
  %t547 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t548 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t549 = select i1 %t544, i8* %t547, i8* %t548
  %t550 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t550, i8* %t549)
  %t551 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t552 = getelementptr i8*, i8** null, i32 1
  %t553 = ptrtoint i8** %t552 to i64
  %t554 = getelementptr i32, i32* null, i32 1
  %t555 = ptrtoint i32* %t554 to i64
  %t556 = load i8*, i8** %t0
  %t557 = icmp eq i8* %t556, null
  br i1 %t557, label %map_cow_alloc_113, label %map_cow_check_114
map_cow_alloc_113:
  %t558 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t559 = call i8* @star_rc_alloc(i64 32, i8* %t558)
  %t560 = bitcast i8* %t559 to { i8**, i32*, i64, i64 }*
  %t561 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t560, i32 0, i32 0
  store i8** null, i8*** %t561
  %t562 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t560, i32 0, i32 1
  store i32* null, i32** %t562
  %t563 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t560, i32 0, i32 2
  store i64 0, i64* %t563
  %t564 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t560, i32 0, i32 3
  store i64 0, i64* %t564
  store i8* %t559, i8** %t0
  br label %map_cow_done_115
map_cow_check_114:
  %t565 = getelementptr inbounds i8, i8* %t556, i64 -16
  %t566 = bitcast i8* %t565 to i64*
  %t567 = load atomic i64, i64* %t566 seq_cst, align 8
  %t568 = icmp eq i64 %t567, 1
  br i1 %t568, label %map_cow_done_115, label %map_cow_clone_116
map_cow_clone_116:
  %t569 = bitcast i8* %t556 to { i8**, i32*, i64, i64 }*
  %t570 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t569, i32 0, i32 0
  %t571 = load i8**, i8*** %t570
  %t572 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t569, i32 0, i32 1
  %t573 = load i32*, i32** %t572
  %t574 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t569, i32 0, i32 2
  %t575 = load i64, i64* %t574
  %t576 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t569, i32 0, i32 3
  %t577 = load i64, i64* %t576
  %t578 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t579 = call i8* @star_rc_alloc(i64 32, i8* %t578)
  %t580 = bitcast i8* %t579 to { i8**, i32*, i64, i64 }*
  %t581 = mul i64 %t577, %t553
  %t582 = call i8* @malloc(i64 %t581)
  %t583 = bitcast i8* %t582 to i8**
  %t584 = mul i64 %t577, %t555
  %t585 = call i8* @malloc(i64 %t584)
  %t586 = bitcast i8* %t585 to i32*
  %t587 = icmp sgt i64 %t575, 0
  br i1 %t587, label %map_cow_copy_117, label %map_cow_after_copy_118
map_cow_copy_117:
  %t588 = mul i64 %t575, %t553
  %t589 = bitcast i8** %t571 to i8*
  call i8* @memcpy(i8* %t582, i8* %t589, i64 %t588)
  %t590 = mul i64 %t575, %t555
  %t591 = bitcast i32* %t573 to i8*
  call i8* @memcpy(i8* %t585, i8* %t591, i64 %t590)
  store i64 0, i64* %t592
  br label %map_cow_retain_cond_119
map_cow_retain_cond_119:
  %t593 = load i64, i64* %t592
  %t594 = icmp slt i64 %t593, %t575
  br i1 %t594, label %map_cow_retain_body_120, label %map_cow_retain_end_121
map_cow_retain_body_120:
  %t595 = getelementptr inbounds i8*, i8** %t583, i64 %t593
  %t596 = load i8*, i8** %t595
  call void @star_rc_retain(i8* %t596)
  %t597 = add i64 %t593, 1
  store i64 %t597, i64* %t592
  br label %map_cow_retain_cond_119
map_cow_retain_end_121:
  br label %map_cow_after_copy_118
map_cow_after_copy_118:
  %t598 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t580, i32 0, i32 0
  store i8** %t583, i8*** %t598
  %t599 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t580, i32 0, i32 1
  store i32* %t586, i32** %t599
  %t600 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t580, i32 0, i32 2
  store i64 %t575, i64* %t600
  %t601 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t580, i32 0, i32 3
  store i64 %t577, i64* %t601
  call void @star_rc_release(i8* %t556)
  store i8* %t579, i8** %t0
  br label %map_cow_done_115
map_cow_done_115:
  %t602 = load i8*, i8** %t0
  %t603 = bitcast i8* %t602 to { i8**, i32*, i64, i64 }*
  %t604 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t603, i32 0, i32 0
  %t605 = load i8**, i8*** %t604
  %t606 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t603, i32 0, i32 1
  %t607 = load i32*, i32** %t606
  %t608 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t603, i32 0, i32 2
  %t609 = load i64, i64* %t608
  %t610 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t603, i32 0, i32 3
  store i64 0, i64* %t611
  br label %map_find_cond_122
map_find_cond_122:
  %t612 = load i64, i64* %t611
  %t613 = icmp slt i64 %t612, %t609
  br i1 %t613, label %map_find_body_123, label %map_find_end_126
map_find_body_123:
  %t614 = getelementptr inbounds i8*, i8** %t605, i64 %t612
  %t615 = load i8*, i8** %t614
  br label %map_find_eq_check_124
map_find_eq_check_124:
  %t616 = call i1 @eq_str(i8* %t615, i8* %t551)
  br i1 %t616, label %map_find_end_126, label %map_find_next_125
map_find_next_125:
  %t617 = add i64 %t612, 1
  store i64 %t617, i64* %t611
  br label %map_find_cond_122
map_find_end_126:
  %t618 = load i64, i64* %t611
  %t619 = icmp slt i64 %t618, %t609
  store i8* %t551, i8** %t620
  %t621 = load i8*, i8** %t620
  call void @star_rc_release(i8* %t621)
  br i1 %t619, label %map_remove_some_127, label %map_remove_none_128
map_remove_some_127:
  %t622 = getelementptr inbounds i8*, i8** %t605, i64 %t618
  %t623 = getelementptr inbounds i32, i32* %t607, i64 %t618
  %t624 = load i32, i32* %t623
  %t625 = load i8*, i8** %t622
  call void @star_rc_release(i8* %t625)
  %t626 = sub i64 %t609, 1
  %t627 = getelementptr inbounds i8*, i8** %t605, i64 %t626
  %t628 = load i8*, i8** %t627
  %t629 = getelementptr inbounds i32, i32* %t607, i64 %t626
  %t630 = load i32, i32* %t629
  store i8* %t628, i8** %t622
  store i32 %t630, i32* %t623
  store i64 %t626, i64* %t608
  %t632 = getelementptr inbounds %Option__i32, %Option__i32* %t631, i32 0, i32 0
  store i32 1, i32* %t632
  %t633 = getelementptr inbounds %Option__i32, %Option__i32* %t631, i32 0, i32 1
  %t634 = bitcast [1 x i64]* %t633 to { i32 }*
  %t635 = getelementptr inbounds { i32 }, { i32 }* %t634, i32 0, i32 0
  store i32 %t624, i32* %t635
  %t636 = load %Option__i32, %Option__i32* %t631
  br label %map_remove_end_129
map_remove_none_128:
  %t638 = getelementptr inbounds %Option__i32, %Option__i32* %t637, i32 0, i32 0
  store i32 0, i32* %t638
  %t639 = load %Option__i32, %Option__i32* %t637
  br label %map_remove_end_129
map_remove_end_129:
  %t640 = phi %Option__i32 [ %t636, %map_remove_some_127 ], [ %t639, %map_remove_none_128 ]
  store %Option__i32 %t640, %Option__i32* %t641
  br label %match_scrutinee_643
match_scrutinee_643:
  %t647 = getelementptr inbounds %Option__i32, %Option__i32* %t641, i32 0, i32 0
  %t648 = load i32, i32* %t647
  %t646 = icmp eq i32 %t648, 1
  br i1 %t646, label %match_then_0_644, label %match_next_0_645
match_then_0_644:
  %t649 = getelementptr inbounds %Option__i32, %Option__i32* %t641, i32 0, i32 1
  %t650 = bitcast [1 x i64]* %t649 to { i32 }*
  %t651 = getelementptr inbounds { i32 }, { i32 }* %t650, i32 0, i32 0
  %t652 = load i32, i32* %t651
  %t653 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t653, i32 %t652)
  br label %match_end_642
match_next_0_645:
  %t657 = getelementptr inbounds %Option__i32, %Option__i32* %t641, i32 0, i32 0
  %t658 = load i32, i32* %t657
  %t656 = icmp eq i32 %t658, 0
  br i1 %t656, label %match_then_1_654, label %match_next_1_655
match_then_1_654:
  %t659 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t659)
  call i32 (i8*, ...) @printf(i8* %t659)
  %t660 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t660)
  br label %match_end_642
match_next_1_655:
  br label %match_end_642
match_end_642:
  %t661 = load i8*, i8** %t520
  %t662 = load i8*, i8** %t520
  call void @star_rc_retain(i8* %t662)
  %t663 = load i8*, i8** %t0
  %t664 = icmp eq i8* %t663, null
  br i1 %t664, label %map_read_null_130, label %map_read_real_131
map_read_null_130:
  br label %map_read_end_132
map_read_real_131:
  %t665 = bitcast i8* %t663 to { i8**, i32*, i64, i64 }*
  %t666 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t665, i32 0, i32 0
  %t667 = load i8**, i8*** %t666
  %t668 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t665, i32 0, i32 1
  %t669 = load i32*, i32** %t668
  %t670 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t665, i32 0, i32 2
  %t671 = load i64, i64* %t670
  br label %map_read_end_132
map_read_end_132:
  %t672 = phi i8** [ null, %map_read_null_130 ], [ %t667, %map_read_real_131 ]
  %t673 = phi i32* [ null, %map_read_null_130 ], [ %t669, %map_read_real_131 ]
  %t674 = phi i64 [ 0, %map_read_null_130 ], [ %t671, %map_read_real_131 ]
  store i64 0, i64* %t675
  br label %map_find_cond_133
map_find_cond_133:
  %t676 = load i64, i64* %t675
  %t677 = icmp slt i64 %t676, %t674
  br i1 %t677, label %map_find_body_134, label %map_find_end_137
map_find_body_134:
  %t678 = getelementptr inbounds i8*, i8** %t672, i64 %t676
  %t679 = load i8*, i8** %t678
  br label %map_find_eq_check_135
map_find_eq_check_135:
  %t680 = call i1 @eq_str(i8* %t679, i8* %t661)
  br i1 %t680, label %map_find_end_137, label %map_find_next_136
map_find_next_136:
  %t681 = add i64 %t676, 1
  store i64 %t681, i64* %t675
  br label %map_find_cond_133
map_find_end_137:
  %t682 = load i64, i64* %t675
  %t683 = icmp slt i64 %t682, %t674
  store i8* %t661, i8** %t684
  %t685 = load i8*, i8** %t684
  call void @star_rc_release(i8* %t685)
  %t686 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t687 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t688 = select i1 %t683, i8* %t686, i8* %t687
  %t689 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t689, i8* %t688)
  %t690 = load i8*, i8** %t0
  %t691 = icmp eq i8* %t690, null
  br i1 %t691, label %map_read_null_138, label %map_read_real_139
map_read_null_138:
  br label %map_read_end_140
map_read_real_139:
  %t692 = bitcast i8* %t690 to { i8**, i32*, i64, i64 }*
  %t693 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t692, i32 0, i32 0
  %t694 = load i8**, i8*** %t693
  %t695 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t692, i32 0, i32 1
  %t696 = load i32*, i32** %t695
  %t697 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t692, i32 0, i32 2
  %t698 = load i64, i64* %t697
  br label %map_read_end_140
map_read_end_140:
  %t699 = phi i8** [ null, %map_read_null_138 ], [ %t694, %map_read_real_139 ]
  %t700 = phi i32* [ null, %map_read_null_138 ], [ %t696, %map_read_real_139 ]
  %t701 = phi i64 [ 0, %map_read_null_138 ], [ %t698, %map_read_real_139 ]
  %t702 = trunc i64 %t701 to i32
  %t703 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t703, i32 %t702)
  store i8* null, i8** %t704
  %t705 = getelementptr i32, i32* null, i32 1
  %t706 = ptrtoint i32* %t705 to i64
  %t707 = load i8*, i8** %t704
  %t708 = icmp eq i8* %t707, null
  br i1 %t708, label %set_cow_alloc_141, label %set_cow_check_142
set_cow_alloc_141:
  %t713 = bitcast void (i8*)* @set_release_i32 to i8*
  %t714 = call i8* @star_rc_alloc(i64 24, i8* %t713)
  %t715 = bitcast i8* %t714 to { i32*, i64, i64 }*
  %t716 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t715, i32 0, i32 0
  store i32* null, i32** %t716
  %t717 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t715, i32 0, i32 1
  store i64 0, i64* %t717
  %t718 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t715, i32 0, i32 2
  store i64 0, i64* %t718
  store i8* %t714, i8** %t704
  br label %set_cow_done_143
set_cow_check_142:
  %t719 = getelementptr inbounds i8, i8* %t707, i64 -16
  %t720 = bitcast i8* %t719 to i64*
  %t721 = load atomic i64, i64* %t720 seq_cst, align 8
  %t722 = icmp eq i64 %t721, 1
  br i1 %t722, label %set_cow_done_143, label %set_cow_clone_144
set_cow_clone_144:
  %t723 = bitcast i8* %t707 to { i32*, i64, i64 }*
  %t724 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t723, i32 0, i32 0
  %t725 = load i32*, i32** %t724
  %t726 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t723, i32 0, i32 1
  %t727 = load i64, i64* %t726
  %t728 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t723, i32 0, i32 2
  %t729 = load i64, i64* %t728
  %t730 = bitcast void (i8*)* @set_release_i32 to i8*
  %t731 = call i8* @star_rc_alloc(i64 24, i8* %t730)
  %t732 = bitcast i8* %t731 to { i32*, i64, i64 }*
  %t733 = mul i64 %t729, %t706
  %t734 = call i8* @malloc(i64 %t733)
  %t735 = bitcast i8* %t734 to i32*
  %t736 = icmp sgt i64 %t727, 0
  br i1 %t736, label %set_cow_copy_145, label %set_cow_after_copy_146
set_cow_copy_145:
  %t737 = mul i64 %t727, %t706
  %t738 = bitcast i32* %t725 to i8*
  call i8* @memcpy(i8* %t734, i8* %t738, i64 %t737)
  br label %set_cow_after_copy_146
set_cow_after_copy_146:
  %t739 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t732, i32 0, i32 0
  store i32* %t735, i32** %t739
  %t740 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t732, i32 0, i32 1
  store i64 %t727, i64* %t740
  %t741 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t732, i32 0, i32 2
  store i64 %t729, i64* %t741
  call void @star_rc_release(i8* %t707)
  store i8* %t731, i8** %t704
  br label %set_cow_done_143
set_cow_done_143:
  %t742 = load i8*, i8** %t704
  %t743 = bitcast i8* %t742 to { i32*, i64, i64 }*
  %t744 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t743, i32 0, i32 0
  %t745 = load i32*, i32** %t744
  %t746 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t743, i32 0, i32 1
  %t747 = load i64, i64* %t746
  %t748 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t743, i32 0, i32 2
  %t749 = load i64, i64* %t746
  %t750 = load i32*, i32** %t744
  store i64 0, i64* %t752
  store i1 false, i1* %t753
  br label %find_cond_147
find_cond_147:
  %t754 = load i64, i64* %t752
  %t755 = icmp slt i64 %t754, %t749
  br i1 %t755, label %find_body_148, label %find_end_151
find_body_148:
  %t756 = getelementptr inbounds i32, i32* %t750, i64 %t754
  %t757 = load i32, i32* %t756
  br label %find_eq_check_149
find_eq_check_149:
  %t758 = call i1 @eq_i32(i32 %t757, i32 1)
  br i1 %t758, label %find_end_151, label %find_next_150
find_next_150:
  %t759 = add i64 %t754, 1
  store i64 %t759, i64* %t752
  br label %find_cond_147
find_end_151:
  %t760 = load i64, i64* %t752
  %t761 = icmp slt i64 %t760, %t749
  br i1 %t761, label %set_insert_already_present_152, label %set_insert_do_153
set_insert_already_present_152:
  br label %set_insert_end_154
set_insert_do_153:
  %t762 = load i64, i64* %t748
  %t763 = load i32*, i32** %t744
  %t764 = icmp sge i64 %t749, %t762
  br i1 %t764, label %set_insert_grow_155, label %set_insert_store_156
set_insert_grow_155:
  %t765 = mul i64 %t762, 2
  %t766 = icmp sgt i64 %t765, 0
  %t767 = select i1 %t766, i64 %t765, i64 1
  %t768 = getelementptr i32, i32* null, i32 1
  %t769 = ptrtoint i32* %t768 to i64
  %t770 = mul i64 %t767, %t769
  %t771 = call i8* @malloc(i64 %t770)
  %t772 = bitcast i8* %t771 to i32*
  %t773 = icmp sgt i64 %t762, 0
  br i1 %t773, label %set_insert_copy_157, label %set_insert_after_copy_158
set_insert_copy_157:
  %t774 = mul i64 %t749, %t769
  %t775 = bitcast i32* %t763 to i8*
  call i8* @memcpy(i8* %t771, i8* %t775, i64 %t774)
  call void @free(i8* %t775)
  br label %set_insert_after_copy_158
set_insert_after_copy_158:
  store i32* %t772, i32** %t744
  store i64 %t767, i64* %t748
  br label %set_insert_store_156
set_insert_store_156:
  %t776 = load i32*, i32** %t744
  %t777 = getelementptr inbounds i32, i32* %t776, i64 %t749
  store i32 1, i32* %t777
  %t778 = add i64 %t749, 1
  store i64 %t778, i64* %t746
  br label %set_insert_end_154
set_insert_end_154:
  %t779 = phi i1 [ false, %set_insert_already_present_152 ], [ true, %set_insert_store_156 ]
  %t780 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t781 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t782 = select i1 %t779, i8* %t780, i8* %t781
  %t783 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t783, i8* %t782)
  %t784 = getelementptr i32, i32* null, i32 1
  %t785 = ptrtoint i32* %t784 to i64
  %t786 = load i8*, i8** %t704
  %t787 = icmp eq i8* %t786, null
  br i1 %t787, label %set_cow_alloc_159, label %set_cow_check_160
set_cow_alloc_159:
  %t788 = bitcast void (i8*)* @set_release_i32 to i8*
  %t789 = call i8* @star_rc_alloc(i64 24, i8* %t788)
  %t790 = bitcast i8* %t789 to { i32*, i64, i64 }*
  %t791 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t790, i32 0, i32 0
  store i32* null, i32** %t791
  %t792 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t790, i32 0, i32 1
  store i64 0, i64* %t792
  %t793 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t790, i32 0, i32 2
  store i64 0, i64* %t793
  store i8* %t789, i8** %t704
  br label %set_cow_done_161
set_cow_check_160:
  %t794 = getelementptr inbounds i8, i8* %t786, i64 -16
  %t795 = bitcast i8* %t794 to i64*
  %t796 = load atomic i64, i64* %t795 seq_cst, align 8
  %t797 = icmp eq i64 %t796, 1
  br i1 %t797, label %set_cow_done_161, label %set_cow_clone_162
set_cow_clone_162:
  %t798 = bitcast i8* %t786 to { i32*, i64, i64 }*
  %t799 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t798, i32 0, i32 0
  %t800 = load i32*, i32** %t799
  %t801 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t798, i32 0, i32 1
  %t802 = load i64, i64* %t801
  %t803 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t798, i32 0, i32 2
  %t804 = load i64, i64* %t803
  %t805 = bitcast void (i8*)* @set_release_i32 to i8*
  %t806 = call i8* @star_rc_alloc(i64 24, i8* %t805)
  %t807 = bitcast i8* %t806 to { i32*, i64, i64 }*
  %t808 = mul i64 %t804, %t785
  %t809 = call i8* @malloc(i64 %t808)
  %t810 = bitcast i8* %t809 to i32*
  %t811 = icmp sgt i64 %t802, 0
  br i1 %t811, label %set_cow_copy_163, label %set_cow_after_copy_164
set_cow_copy_163:
  %t812 = mul i64 %t802, %t785
  %t813 = bitcast i32* %t800 to i8*
  call i8* @memcpy(i8* %t809, i8* %t813, i64 %t812)
  br label %set_cow_after_copy_164
set_cow_after_copy_164:
  %t814 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 0
  store i32* %t810, i32** %t814
  %t815 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 1
  store i64 %t802, i64* %t815
  %t816 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 2
  store i64 %t804, i64* %t816
  call void @star_rc_release(i8* %t786)
  store i8* %t806, i8** %t704
  br label %set_cow_done_161
set_cow_done_161:
  %t817 = load i8*, i8** %t704
  %t818 = bitcast i8* %t817 to { i32*, i64, i64 }*
  %t819 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t818, i32 0, i32 0
  %t820 = load i32*, i32** %t819
  %t821 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t818, i32 0, i32 1
  %t822 = load i64, i64* %t821
  %t823 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t818, i32 0, i32 2
  %t824 = load i64, i64* %t821
  %t825 = load i32*, i32** %t819
  store i64 0, i64* %t826
  store i1 false, i1* %t827
  br label %find_cond_165
find_cond_165:
  %t828 = load i64, i64* %t826
  %t829 = icmp slt i64 %t828, %t824
  br i1 %t829, label %find_body_166, label %find_end_169
find_body_166:
  %t830 = getelementptr inbounds i32, i32* %t825, i64 %t828
  %t831 = load i32, i32* %t830
  br label %find_eq_check_167
find_eq_check_167:
  %t832 = call i1 @eq_i32(i32 %t831, i32 2)
  br i1 %t832, label %find_end_169, label %find_next_168
find_next_168:
  %t833 = add i64 %t828, 1
  store i64 %t833, i64* %t826
  br label %find_cond_165
find_end_169:
  %t834 = load i64, i64* %t826
  %t835 = icmp slt i64 %t834, %t824
  br i1 %t835, label %set_insert_already_present_170, label %set_insert_do_171
set_insert_already_present_170:
  br label %set_insert_end_172
set_insert_do_171:
  %t836 = load i64, i64* %t823
  %t837 = load i32*, i32** %t819
  %t838 = icmp sge i64 %t824, %t836
  br i1 %t838, label %set_insert_grow_173, label %set_insert_store_174
set_insert_grow_173:
  %t839 = mul i64 %t836, 2
  %t840 = icmp sgt i64 %t839, 0
  %t841 = select i1 %t840, i64 %t839, i64 1
  %t842 = getelementptr i32, i32* null, i32 1
  %t843 = ptrtoint i32* %t842 to i64
  %t844 = mul i64 %t841, %t843
  %t845 = call i8* @malloc(i64 %t844)
  %t846 = bitcast i8* %t845 to i32*
  %t847 = icmp sgt i64 %t836, 0
  br i1 %t847, label %set_insert_copy_175, label %set_insert_after_copy_176
set_insert_copy_175:
  %t848 = mul i64 %t824, %t843
  %t849 = bitcast i32* %t837 to i8*
  call i8* @memcpy(i8* %t845, i8* %t849, i64 %t848)
  call void @free(i8* %t849)
  br label %set_insert_after_copy_176
set_insert_after_copy_176:
  store i32* %t846, i32** %t819
  store i64 %t841, i64* %t823
  br label %set_insert_store_174
set_insert_store_174:
  %t850 = load i32*, i32** %t819
  %t851 = getelementptr inbounds i32, i32* %t850, i64 %t824
  store i32 2, i32* %t851
  %t852 = add i64 %t824, 1
  store i64 %t852, i64* %t821
  br label %set_insert_end_172
set_insert_end_172:
  %t853 = phi i1 [ false, %set_insert_already_present_170 ], [ true, %set_insert_store_174 ]
  %t854 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t855 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t856 = select i1 %t853, i8* %t854, i8* %t855
  %t857 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t857, i8* %t856)
  %t858 = getelementptr i32, i32* null, i32 1
  %t859 = ptrtoint i32* %t858 to i64
  %t860 = load i8*, i8** %t704
  %t861 = icmp eq i8* %t860, null
  br i1 %t861, label %set_cow_alloc_177, label %set_cow_check_178
set_cow_alloc_177:
  %t862 = bitcast void (i8*)* @set_release_i32 to i8*
  %t863 = call i8* @star_rc_alloc(i64 24, i8* %t862)
  %t864 = bitcast i8* %t863 to { i32*, i64, i64 }*
  %t865 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t864, i32 0, i32 0
  store i32* null, i32** %t865
  %t866 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t864, i32 0, i32 1
  store i64 0, i64* %t866
  %t867 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t864, i32 0, i32 2
  store i64 0, i64* %t867
  store i8* %t863, i8** %t704
  br label %set_cow_done_179
set_cow_check_178:
  %t868 = getelementptr inbounds i8, i8* %t860, i64 -16
  %t869 = bitcast i8* %t868 to i64*
  %t870 = load atomic i64, i64* %t869 seq_cst, align 8
  %t871 = icmp eq i64 %t870, 1
  br i1 %t871, label %set_cow_done_179, label %set_cow_clone_180
set_cow_clone_180:
  %t872 = bitcast i8* %t860 to { i32*, i64, i64 }*
  %t873 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t872, i32 0, i32 0
  %t874 = load i32*, i32** %t873
  %t875 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t872, i32 0, i32 1
  %t876 = load i64, i64* %t875
  %t877 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t872, i32 0, i32 2
  %t878 = load i64, i64* %t877
  %t879 = bitcast void (i8*)* @set_release_i32 to i8*
  %t880 = call i8* @star_rc_alloc(i64 24, i8* %t879)
  %t881 = bitcast i8* %t880 to { i32*, i64, i64 }*
  %t882 = mul i64 %t878, %t859
  %t883 = call i8* @malloc(i64 %t882)
  %t884 = bitcast i8* %t883 to i32*
  %t885 = icmp sgt i64 %t876, 0
  br i1 %t885, label %set_cow_copy_181, label %set_cow_after_copy_182
set_cow_copy_181:
  %t886 = mul i64 %t876, %t859
  %t887 = bitcast i32* %t874 to i8*
  call i8* @memcpy(i8* %t883, i8* %t887, i64 %t886)
  br label %set_cow_after_copy_182
set_cow_after_copy_182:
  %t888 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t881, i32 0, i32 0
  store i32* %t884, i32** %t888
  %t889 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t881, i32 0, i32 1
  store i64 %t876, i64* %t889
  %t890 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t881, i32 0, i32 2
  store i64 %t878, i64* %t890
  call void @star_rc_release(i8* %t860)
  store i8* %t880, i8** %t704
  br label %set_cow_done_179
set_cow_done_179:
  %t891 = load i8*, i8** %t704
  %t892 = bitcast i8* %t891 to { i32*, i64, i64 }*
  %t893 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t892, i32 0, i32 0
  %t894 = load i32*, i32** %t893
  %t895 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t892, i32 0, i32 1
  %t896 = load i64, i64* %t895
  %t897 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t892, i32 0, i32 2
  %t898 = load i64, i64* %t895
  %t899 = load i32*, i32** %t893
  store i64 0, i64* %t900
  store i1 false, i1* %t901
  br label %find_cond_183
find_cond_183:
  %t902 = load i64, i64* %t900
  %t903 = icmp slt i64 %t902, %t898
  br i1 %t903, label %find_body_184, label %find_end_187
find_body_184:
  %t904 = getelementptr inbounds i32, i32* %t899, i64 %t902
  %t905 = load i32, i32* %t904
  br label %find_eq_check_185
find_eq_check_185:
  %t906 = call i1 @eq_i32(i32 %t905, i32 1)
  br i1 %t906, label %find_end_187, label %find_next_186
find_next_186:
  %t907 = add i64 %t902, 1
  store i64 %t907, i64* %t900
  br label %find_cond_183
find_end_187:
  %t908 = load i64, i64* %t900
  %t909 = icmp slt i64 %t908, %t898
  br i1 %t909, label %set_insert_already_present_188, label %set_insert_do_189
set_insert_already_present_188:
  br label %set_insert_end_190
set_insert_do_189:
  %t910 = load i64, i64* %t897
  %t911 = load i32*, i32** %t893
  %t912 = icmp sge i64 %t898, %t910
  br i1 %t912, label %set_insert_grow_191, label %set_insert_store_192
set_insert_grow_191:
  %t913 = mul i64 %t910, 2
  %t914 = icmp sgt i64 %t913, 0
  %t915 = select i1 %t914, i64 %t913, i64 1
  %t916 = getelementptr i32, i32* null, i32 1
  %t917 = ptrtoint i32* %t916 to i64
  %t918 = mul i64 %t915, %t917
  %t919 = call i8* @malloc(i64 %t918)
  %t920 = bitcast i8* %t919 to i32*
  %t921 = icmp sgt i64 %t910, 0
  br i1 %t921, label %set_insert_copy_193, label %set_insert_after_copy_194
set_insert_copy_193:
  %t922 = mul i64 %t898, %t917
  %t923 = bitcast i32* %t911 to i8*
  call i8* @memcpy(i8* %t919, i8* %t923, i64 %t922)
  call void @free(i8* %t923)
  br label %set_insert_after_copy_194
set_insert_after_copy_194:
  store i32* %t920, i32** %t893
  store i64 %t915, i64* %t897
  br label %set_insert_store_192
set_insert_store_192:
  %t924 = load i32*, i32** %t893
  %t925 = getelementptr inbounds i32, i32* %t924, i64 %t898
  store i32 1, i32* %t925
  %t926 = add i64 %t898, 1
  store i64 %t926, i64* %t895
  br label %set_insert_end_190
set_insert_end_190:
  %t927 = phi i1 [ false, %set_insert_already_present_188 ], [ true, %set_insert_store_192 ]
  %t928 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t929 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t930 = select i1 %t927, i8* %t928, i8* %t929
  %t931 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t931, i8* %t930)
  %t932 = load i8*, i8** %t704
  %t933 = icmp eq i8* %t932, null
  br i1 %t933, label %set_read_null_195, label %set_read_real_196
set_read_null_195:
  br label %set_read_end_197
set_read_real_196:
  %t934 = bitcast i8* %t932 to { i32*, i64, i64 }*
  %t935 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t934, i32 0, i32 0
  %t936 = load i32*, i32** %t935
  %t937 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t934, i32 0, i32 1
  %t938 = load i64, i64* %t937
  br label %set_read_end_197
set_read_end_197:
  %t939 = phi i32* [ null, %set_read_null_195 ], [ %t936, %set_read_real_196 ]
  %t940 = phi i64 [ 0, %set_read_null_195 ], [ %t938, %set_read_real_196 ]
  %t941 = trunc i64 %t940 to i32
  %t942 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t942, i32 %t941)
  %t943 = load i8*, i8** %t704
  %t944 = icmp eq i8* %t943, null
  br i1 %t944, label %set_read_null_198, label %set_read_real_199
set_read_null_198:
  br label %set_read_end_200
set_read_real_199:
  %t945 = bitcast i8* %t943 to { i32*, i64, i64 }*
  %t946 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t945, i32 0, i32 0
  %t947 = load i32*, i32** %t946
  %t948 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t945, i32 0, i32 1
  %t949 = load i64, i64* %t948
  br label %set_read_end_200
set_read_end_200:
  %t950 = phi i32* [ null, %set_read_null_198 ], [ %t947, %set_read_real_199 ]
  %t951 = phi i64 [ 0, %set_read_null_198 ], [ %t949, %set_read_real_199 ]
  store i64 0, i64* %t952
  store i1 false, i1* %t953
  br label %find_cond_201
find_cond_201:
  %t954 = load i64, i64* %t952
  %t955 = icmp slt i64 %t954, %t951
  br i1 %t955, label %find_body_202, label %find_end_205
find_body_202:
  %t956 = getelementptr inbounds i32, i32* %t950, i64 %t954
  %t957 = load i32, i32* %t956
  br label %find_eq_check_203
find_eq_check_203:
  %t958 = call i1 @eq_i32(i32 %t957, i32 2)
  br i1 %t958, label %find_end_205, label %find_next_204
find_next_204:
  %t959 = add i64 %t954, 1
  store i64 %t959, i64* %t952
  br label %find_cond_201
find_end_205:
  %t960 = load i64, i64* %t952
  %t961 = icmp slt i64 %t960, %t951
  %t962 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t963 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t964 = select i1 %t961, i8* %t962, i8* %t963
  %t965 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t965, i8* %t964)
  %t966 = getelementptr i32, i32* null, i32 1
  %t967 = ptrtoint i32* %t966 to i64
  %t968 = load i8*, i8** %t704
  %t969 = icmp eq i8* %t968, null
  br i1 %t969, label %set_cow_alloc_206, label %set_cow_check_207
set_cow_alloc_206:
  %t970 = bitcast void (i8*)* @set_release_i32 to i8*
  %t971 = call i8* @star_rc_alloc(i64 24, i8* %t970)
  %t972 = bitcast i8* %t971 to { i32*, i64, i64 }*
  %t973 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t972, i32 0, i32 0
  store i32* null, i32** %t973
  %t974 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t972, i32 0, i32 1
  store i64 0, i64* %t974
  %t975 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t972, i32 0, i32 2
  store i64 0, i64* %t975
  store i8* %t971, i8** %t704
  br label %set_cow_done_208
set_cow_check_207:
  %t976 = getelementptr inbounds i8, i8* %t968, i64 -16
  %t977 = bitcast i8* %t976 to i64*
  %t978 = load atomic i64, i64* %t977 seq_cst, align 8
  %t979 = icmp eq i64 %t978, 1
  br i1 %t979, label %set_cow_done_208, label %set_cow_clone_209
set_cow_clone_209:
  %t980 = bitcast i8* %t968 to { i32*, i64, i64 }*
  %t981 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t980, i32 0, i32 0
  %t982 = load i32*, i32** %t981
  %t983 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t980, i32 0, i32 1
  %t984 = load i64, i64* %t983
  %t985 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t980, i32 0, i32 2
  %t986 = load i64, i64* %t985
  %t987 = bitcast void (i8*)* @set_release_i32 to i8*
  %t988 = call i8* @star_rc_alloc(i64 24, i8* %t987)
  %t989 = bitcast i8* %t988 to { i32*, i64, i64 }*
  %t990 = mul i64 %t986, %t967
  %t991 = call i8* @malloc(i64 %t990)
  %t992 = bitcast i8* %t991 to i32*
  %t993 = icmp sgt i64 %t984, 0
  br i1 %t993, label %set_cow_copy_210, label %set_cow_after_copy_211
set_cow_copy_210:
  %t994 = mul i64 %t984, %t967
  %t995 = bitcast i32* %t982 to i8*
  call i8* @memcpy(i8* %t991, i8* %t995, i64 %t994)
  br label %set_cow_after_copy_211
set_cow_after_copy_211:
  %t996 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t989, i32 0, i32 0
  store i32* %t992, i32** %t996
  %t997 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t989, i32 0, i32 1
  store i64 %t984, i64* %t997
  %t998 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t989, i32 0, i32 2
  store i64 %t986, i64* %t998
  call void @star_rc_release(i8* %t968)
  store i8* %t988, i8** %t704
  br label %set_cow_done_208
set_cow_done_208:
  %t999 = load i8*, i8** %t704
  %t1000 = bitcast i8* %t999 to { i32*, i64, i64 }*
  %t1001 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1000, i32 0, i32 0
  %t1002 = load i32*, i32** %t1001
  %t1003 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1000, i32 0, i32 1
  %t1004 = load i64, i64* %t1003
  %t1005 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1000, i32 0, i32 2
  %t1006 = load i64, i64* %t1003
  %t1007 = load i32*, i32** %t1001
  store i64 0, i64* %t1008
  store i1 false, i1* %t1009
  br label %find_cond_212
find_cond_212:
  %t1010 = load i64, i64* %t1008
  %t1011 = icmp slt i64 %t1010, %t1006
  br i1 %t1011, label %find_body_213, label %find_end_216
find_body_213:
  %t1012 = getelementptr inbounds i32, i32* %t1007, i64 %t1010
  %t1013 = load i32, i32* %t1012
  br label %find_eq_check_214
find_eq_check_214:
  %t1014 = call i1 @eq_i32(i32 %t1013, i32 2)
  br i1 %t1014, label %find_end_216, label %find_next_215
find_next_215:
  %t1015 = add i64 %t1010, 1
  store i64 %t1015, i64* %t1008
  br label %find_cond_212
find_end_216:
  %t1016 = load i64, i64* %t1008
  %t1017 = icmp slt i64 %t1016, %t1006
  br i1 %t1017, label %set_remove_do_217, label %set_remove_end_218
set_remove_do_217:
  %t1018 = getelementptr inbounds i32, i32* %t1007, i64 %t1016
  %t1019 = sub i64 %t1006, 1
  %t1020 = getelementptr inbounds i32, i32* %t1007, i64 %t1019
  %t1021 = load i32, i32* %t1020
  store i32 %t1021, i32* %t1018
  store i64 %t1019, i64* %t1003
  br label %set_remove_end_218
set_remove_end_218:
  %t1022 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t1023 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t1024 = select i1 %t1017, i8* %t1022, i8* %t1023
  %t1025 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1025, i8* %t1024)
  %t1026 = load i8*, i8** %t704
  %t1027 = icmp eq i8* %t1026, null
  br i1 %t1027, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t1028 = bitcast i8* %t1026 to { i32*, i64, i64 }*
  %t1029 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1028, i32 0, i32 0
  %t1030 = load i32*, i32** %t1029
  %t1031 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1028, i32 0, i32 1
  %t1032 = load i64, i64* %t1031
  br label %set_read_end_221
set_read_end_221:
  %t1033 = phi i32* [ null, %set_read_null_219 ], [ %t1030, %set_read_real_220 ]
  %t1034 = phi i64 [ 0, %set_read_null_219 ], [ %t1032, %set_read_real_220 ]
  store i64 0, i64* %t1035
  store i1 false, i1* %t1036
  br label %find_cond_222
find_cond_222:
  %t1037 = load i64, i64* %t1035
  %t1038 = icmp slt i64 %t1037, %t1034
  br i1 %t1038, label %find_body_223, label %find_end_226
find_body_223:
  %t1039 = getelementptr inbounds i32, i32* %t1033, i64 %t1037
  %t1040 = load i32, i32* %t1039
  br label %find_eq_check_224
find_eq_check_224:
  %t1041 = call i1 @eq_i32(i32 %t1040, i32 2)
  br i1 %t1041, label %find_end_226, label %find_next_225
find_next_225:
  %t1042 = add i64 %t1037, 1
  store i64 %t1042, i64* %t1035
  br label %find_cond_222
find_end_226:
  %t1043 = load i64, i64* %t1035
  %t1044 = icmp slt i64 %t1043, %t1034
  %t1045 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1046 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1047 = select i1 %t1044, i8* %t1045, i8* %t1046
  %t1048 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1048, i8* %t1047)
  %t1049 = getelementptr i32, i32* null, i32 1
  %t1050 = ptrtoint i32* %t1049 to i64
  %t1051 = load i8*, i8** %t704
  %t1052 = icmp eq i8* %t1051, null
  br i1 %t1052, label %set_cow_alloc_227, label %set_cow_check_228
set_cow_alloc_227:
  %t1053 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1054 = call i8* @star_rc_alloc(i64 24, i8* %t1053)
  %t1055 = bitcast i8* %t1054 to { i32*, i64, i64 }*
  %t1056 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1055, i32 0, i32 0
  store i32* null, i32** %t1056
  %t1057 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1055, i32 0, i32 1
  store i64 0, i64* %t1057
  %t1058 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1055, i32 0, i32 2
  store i64 0, i64* %t1058
  store i8* %t1054, i8** %t704
  br label %set_cow_done_229
set_cow_check_228:
  %t1059 = getelementptr inbounds i8, i8* %t1051, i64 -16
  %t1060 = bitcast i8* %t1059 to i64*
  %t1061 = load atomic i64, i64* %t1060 seq_cst, align 8
  %t1062 = icmp eq i64 %t1061, 1
  br i1 %t1062, label %set_cow_done_229, label %set_cow_clone_230
set_cow_clone_230:
  %t1063 = bitcast i8* %t1051 to { i32*, i64, i64 }*
  %t1064 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1063, i32 0, i32 0
  %t1065 = load i32*, i32** %t1064
  %t1066 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1063, i32 0, i32 1
  %t1067 = load i64, i64* %t1066
  %t1068 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1063, i32 0, i32 2
  %t1069 = load i64, i64* %t1068
  %t1070 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1071 = call i8* @star_rc_alloc(i64 24, i8* %t1070)
  %t1072 = bitcast i8* %t1071 to { i32*, i64, i64 }*
  %t1073 = mul i64 %t1069, %t1050
  %t1074 = call i8* @malloc(i64 %t1073)
  %t1075 = bitcast i8* %t1074 to i32*
  %t1076 = icmp sgt i64 %t1067, 0
  br i1 %t1076, label %set_cow_copy_231, label %set_cow_after_copy_232
set_cow_copy_231:
  %t1077 = mul i64 %t1067, %t1050
  %t1078 = bitcast i32* %t1065 to i8*
  call i8* @memcpy(i8* %t1074, i8* %t1078, i64 %t1077)
  br label %set_cow_after_copy_232
set_cow_after_copy_232:
  %t1079 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1072, i32 0, i32 0
  store i32* %t1075, i32** %t1079
  %t1080 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1072, i32 0, i32 1
  store i64 %t1067, i64* %t1080
  %t1081 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1072, i32 0, i32 2
  store i64 %t1069, i64* %t1081
  call void @star_rc_release(i8* %t1051)
  store i8* %t1071, i8** %t704
  br label %set_cow_done_229
set_cow_done_229:
  %t1082 = load i8*, i8** %t704
  %t1083 = bitcast i8* %t1082 to { i32*, i64, i64 }*
  %t1084 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1083, i32 0, i32 0
  %t1085 = load i32*, i32** %t1084
  %t1086 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1083, i32 0, i32 1
  %t1087 = load i64, i64* %t1086
  %t1088 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1083, i32 0, i32 2
  %t1089 = load i64, i64* %t1086
  %t1090 = load i32*, i32** %t1084
  store i64 0, i64* %t1091
  store i1 false, i1* %t1092
  br label %find_cond_233
find_cond_233:
  %t1093 = load i64, i64* %t1091
  %t1094 = icmp slt i64 %t1093, %t1089
  br i1 %t1094, label %find_body_234, label %find_end_237
find_body_234:
  %t1095 = getelementptr inbounds i32, i32* %t1090, i64 %t1093
  %t1096 = load i32, i32* %t1095
  br label %find_eq_check_235
find_eq_check_235:
  %t1097 = call i1 @eq_i32(i32 %t1096, i32 2)
  br i1 %t1097, label %find_end_237, label %find_next_236
find_next_236:
  %t1098 = add i64 %t1093, 1
  store i64 %t1098, i64* %t1091
  br label %find_cond_233
find_end_237:
  %t1099 = load i64, i64* %t1091
  %t1100 = icmp slt i64 %t1099, %t1089
  br i1 %t1100, label %set_remove_do_238, label %set_remove_end_239
set_remove_do_238:
  %t1101 = getelementptr inbounds i32, i32* %t1090, i64 %t1099
  %t1102 = sub i64 %t1089, 1
  %t1103 = getelementptr inbounds i32, i32* %t1090, i64 %t1102
  %t1104 = load i32, i32* %t1103
  store i32 %t1104, i32* %t1101
  store i64 %t1102, i64* %t1086
  br label %set_remove_end_239
set_remove_end_239:
  %t1105 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1106 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1107 = select i1 %t1100, i8* %t1105, i8* %t1106
  %t1108 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1108, i8* %t1107)
  %t1109 = load i8*, i8** %t704
  %t1110 = icmp eq i8* %t1109, null
  br i1 %t1110, label %set_read_null_240, label %set_read_real_241
set_read_null_240:
  br label %set_read_end_242
set_read_real_241:
  %t1111 = bitcast i8* %t1109 to { i32*, i64, i64 }*
  %t1112 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1111, i32 0, i32 0
  %t1113 = load i32*, i32** %t1112
  %t1114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1111, i32 0, i32 1
  %t1115 = load i64, i64* %t1114
  br label %set_read_end_242
set_read_end_242:
  %t1116 = phi i32* [ null, %set_read_null_240 ], [ %t1113, %set_read_real_241 ]
  %t1117 = phi i64 [ 0, %set_read_null_240 ], [ %t1115, %set_read_real_241 ]
  %t1118 = trunc i64 %t1117 to i32
  %t1119 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1119, i32 %t1118)
  store i8* null, i8** %t1120
  %t1121 = getelementptr %Point, %Point* null, i32 1
  %t1122 = ptrtoint %Point* %t1121 to i64
  %t1123 = load i8*, i8** %t1120
  %t1124 = icmp eq i8* %t1123, null
  br i1 %t1124, label %set_cow_alloc_243, label %set_cow_check_244
set_cow_alloc_243:
  %t1129 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1130 = call i8* @star_rc_alloc(i64 24, i8* %t1129)
  %t1131 = bitcast i8* %t1130 to { %Point*, i64, i64 }*
  %t1132 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1131, i32 0, i32 0
  store %Point* null, %Point** %t1132
  %t1133 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1131, i32 0, i32 1
  store i64 0, i64* %t1133
  %t1134 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1131, i32 0, i32 2
  store i64 0, i64* %t1134
  store i8* %t1130, i8** %t1120
  br label %set_cow_done_245
set_cow_check_244:
  %t1135 = getelementptr inbounds i8, i8* %t1123, i64 -16
  %t1136 = bitcast i8* %t1135 to i64*
  %t1137 = load atomic i64, i64* %t1136 seq_cst, align 8
  %t1138 = icmp eq i64 %t1137, 1
  br i1 %t1138, label %set_cow_done_245, label %set_cow_clone_246
set_cow_clone_246:
  %t1139 = bitcast i8* %t1123 to { %Point*, i64, i64 }*
  %t1140 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1139, i32 0, i32 0
  %t1141 = load %Point*, %Point** %t1140
  %t1142 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1139, i32 0, i32 1
  %t1143 = load i64, i64* %t1142
  %t1144 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1139, i32 0, i32 2
  %t1145 = load i64, i64* %t1144
  %t1146 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1147 = call i8* @star_rc_alloc(i64 24, i8* %t1146)
  %t1148 = bitcast i8* %t1147 to { %Point*, i64, i64 }*
  %t1149 = mul i64 %t1145, %t1122
  %t1150 = call i8* @malloc(i64 %t1149)
  %t1151 = bitcast i8* %t1150 to %Point*
  %t1152 = icmp sgt i64 %t1143, 0
  br i1 %t1152, label %set_cow_copy_247, label %set_cow_after_copy_248
set_cow_copy_247:
  %t1153 = mul i64 %t1143, %t1122
  %t1154 = bitcast %Point* %t1141 to i8*
  call i8* @memcpy(i8* %t1150, i8* %t1154, i64 %t1153)
  br label %set_cow_after_copy_248
set_cow_after_copy_248:
  %t1155 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1148, i32 0, i32 0
  store %Point* %t1151, %Point** %t1155
  %t1156 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1148, i32 0, i32 1
  store i64 %t1143, i64* %t1156
  %t1157 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1148, i32 0, i32 2
  store i64 %t1145, i64* %t1157
  call void @star_rc_release(i8* %t1123)
  store i8* %t1147, i8** %t1120
  br label %set_cow_done_245
set_cow_done_245:
  %t1158 = load i8*, i8** %t1120
  %t1159 = bitcast i8* %t1158 to { %Point*, i64, i64 }*
  %t1160 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1159, i32 0, i32 0
  %t1161 = load %Point*, %Point** %t1160
  %t1162 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1159, i32 0, i32 1
  %t1163 = load i64, i64* %t1162
  %t1164 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1159, i32 0, i32 2
  %t1166 = getelementptr inbounds %Point, %Point* %t1165, i32 0, i32 0
  store i32 1, i32* %t1166
  %t1167 = getelementptr inbounds %Point, %Point* %t1165, i32 0, i32 1
  store i32 2, i32* %t1167
  %t1168 = load %Point, %Point* %t1165
  %t1169 = load i64, i64* %t1162
  %t1170 = load %Point*, %Point** %t1160
  store i64 0, i64* %t1178
  store i1 false, i1* %t1179
  br label %find_cond_249
find_cond_249:
  %t1180 = load i64, i64* %t1178
  %t1181 = icmp slt i64 %t1180, %t1169
  br i1 %t1181, label %find_body_250, label %find_end_253
find_body_250:
  %t1182 = getelementptr inbounds %Point, %Point* %t1170, i64 %t1180
  %t1183 = load %Point, %Point* %t1182
  br label %find_eq_check_251
find_eq_check_251:
  %t1184 = call i1 @eq_s_Point(%Point %t1183, %Point %t1168)
  br i1 %t1184, label %find_end_253, label %find_next_252
find_next_252:
  %t1185 = add i64 %t1180, 1
  store i64 %t1185, i64* %t1178
  br label %find_cond_249
find_end_253:
  %t1186 = load i64, i64* %t1178
  %t1187 = icmp slt i64 %t1186, %t1169
  br i1 %t1187, label %set_insert_already_present_254, label %set_insert_do_255
set_insert_already_present_254:
  br label %set_insert_end_256
set_insert_do_255:
  %t1188 = load i64, i64* %t1164
  %t1189 = load %Point*, %Point** %t1160
  %t1190 = icmp sge i64 %t1169, %t1188
  br i1 %t1190, label %set_insert_grow_257, label %set_insert_store_258
set_insert_grow_257:
  %t1191 = mul i64 %t1188, 2
  %t1192 = icmp sgt i64 %t1191, 0
  %t1193 = select i1 %t1192, i64 %t1191, i64 1
  %t1194 = getelementptr %Point, %Point* null, i32 1
  %t1195 = ptrtoint %Point* %t1194 to i64
  %t1196 = mul i64 %t1193, %t1195
  %t1197 = call i8* @malloc(i64 %t1196)
  %t1198 = bitcast i8* %t1197 to %Point*
  %t1199 = icmp sgt i64 %t1188, 0
  br i1 %t1199, label %set_insert_copy_259, label %set_insert_after_copy_260
set_insert_copy_259:
  %t1200 = mul i64 %t1169, %t1195
  %t1201 = bitcast %Point* %t1189 to i8*
  call i8* @memcpy(i8* %t1197, i8* %t1201, i64 %t1200)
  call void @free(i8* %t1201)
  br label %set_insert_after_copy_260
set_insert_after_copy_260:
  store %Point* %t1198, %Point** %t1160
  store i64 %t1193, i64* %t1164
  br label %set_insert_store_258
set_insert_store_258:
  %t1202 = load %Point*, %Point** %t1160
  %t1203 = getelementptr inbounds %Point, %Point* %t1202, i64 %t1169
  store %Point %t1168, %Point* %t1203
  %t1204 = add i64 %t1169, 1
  store i64 %t1204, i64* %t1162
  br label %set_insert_end_256
set_insert_end_256:
  %t1205 = phi i1 [ false, %set_insert_already_present_254 ], [ true, %set_insert_store_258 ]
  %t1206 = getelementptr %Point, %Point* null, i32 1
  %t1207 = ptrtoint %Point* %t1206 to i64
  %t1208 = load i8*, i8** %t1120
  %t1209 = icmp eq i8* %t1208, null
  br i1 %t1209, label %set_cow_alloc_261, label %set_cow_check_262
set_cow_alloc_261:
  %t1210 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1211 = call i8* @star_rc_alloc(i64 24, i8* %t1210)
  %t1212 = bitcast i8* %t1211 to { %Point*, i64, i64 }*
  %t1213 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1212, i32 0, i32 0
  store %Point* null, %Point** %t1213
  %t1214 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1212, i32 0, i32 1
  store i64 0, i64* %t1214
  %t1215 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1212, i32 0, i32 2
  store i64 0, i64* %t1215
  store i8* %t1211, i8** %t1120
  br label %set_cow_done_263
set_cow_check_262:
  %t1216 = getelementptr inbounds i8, i8* %t1208, i64 -16
  %t1217 = bitcast i8* %t1216 to i64*
  %t1218 = load atomic i64, i64* %t1217 seq_cst, align 8
  %t1219 = icmp eq i64 %t1218, 1
  br i1 %t1219, label %set_cow_done_263, label %set_cow_clone_264
set_cow_clone_264:
  %t1220 = bitcast i8* %t1208 to { %Point*, i64, i64 }*
  %t1221 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1220, i32 0, i32 0
  %t1222 = load %Point*, %Point** %t1221
  %t1223 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1220, i32 0, i32 1
  %t1224 = load i64, i64* %t1223
  %t1225 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1220, i32 0, i32 2
  %t1226 = load i64, i64* %t1225
  %t1227 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1228 = call i8* @star_rc_alloc(i64 24, i8* %t1227)
  %t1229 = bitcast i8* %t1228 to { %Point*, i64, i64 }*
  %t1230 = mul i64 %t1226, %t1207
  %t1231 = call i8* @malloc(i64 %t1230)
  %t1232 = bitcast i8* %t1231 to %Point*
  %t1233 = icmp sgt i64 %t1224, 0
  br i1 %t1233, label %set_cow_copy_265, label %set_cow_after_copy_266
set_cow_copy_265:
  %t1234 = mul i64 %t1224, %t1207
  %t1235 = bitcast %Point* %t1222 to i8*
  call i8* @memcpy(i8* %t1231, i8* %t1235, i64 %t1234)
  br label %set_cow_after_copy_266
set_cow_after_copy_266:
  %t1236 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1229, i32 0, i32 0
  store %Point* %t1232, %Point** %t1236
  %t1237 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1229, i32 0, i32 1
  store i64 %t1224, i64* %t1237
  %t1238 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1229, i32 0, i32 2
  store i64 %t1226, i64* %t1238
  call void @star_rc_release(i8* %t1208)
  store i8* %t1228, i8** %t1120
  br label %set_cow_done_263
set_cow_done_263:
  %t1239 = load i8*, i8** %t1120
  %t1240 = bitcast i8* %t1239 to { %Point*, i64, i64 }*
  %t1241 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1240, i32 0, i32 0
  %t1242 = load %Point*, %Point** %t1241
  %t1243 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1240, i32 0, i32 1
  %t1244 = load i64, i64* %t1243
  %t1245 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1240, i32 0, i32 2
  %t1247 = getelementptr inbounds %Point, %Point* %t1246, i32 0, i32 0
  store i32 1, i32* %t1247
  %t1248 = getelementptr inbounds %Point, %Point* %t1246, i32 0, i32 1
  store i32 2, i32* %t1248
  %t1249 = load %Point, %Point* %t1246
  %t1250 = load i64, i64* %t1243
  %t1251 = load %Point*, %Point** %t1241
  store i64 0, i64* %t1252
  store i1 false, i1* %t1253
  br label %find_cond_267
find_cond_267:
  %t1254 = load i64, i64* %t1252
  %t1255 = icmp slt i64 %t1254, %t1250
  br i1 %t1255, label %find_body_268, label %find_end_271
find_body_268:
  %t1256 = getelementptr inbounds %Point, %Point* %t1251, i64 %t1254
  %t1257 = load %Point, %Point* %t1256
  br label %find_eq_check_269
find_eq_check_269:
  %t1258 = call i1 @eq_s_Point(%Point %t1257, %Point %t1249)
  br i1 %t1258, label %find_end_271, label %find_next_270
find_next_270:
  %t1259 = add i64 %t1254, 1
  store i64 %t1259, i64* %t1252
  br label %find_cond_267
find_end_271:
  %t1260 = load i64, i64* %t1252
  %t1261 = icmp slt i64 %t1260, %t1250
  br i1 %t1261, label %set_insert_already_present_272, label %set_insert_do_273
set_insert_already_present_272:
  br label %set_insert_end_274
set_insert_do_273:
  %t1262 = load i64, i64* %t1245
  %t1263 = load %Point*, %Point** %t1241
  %t1264 = icmp sge i64 %t1250, %t1262
  br i1 %t1264, label %set_insert_grow_275, label %set_insert_store_276
set_insert_grow_275:
  %t1265 = mul i64 %t1262, 2
  %t1266 = icmp sgt i64 %t1265, 0
  %t1267 = select i1 %t1266, i64 %t1265, i64 1
  %t1268 = getelementptr %Point, %Point* null, i32 1
  %t1269 = ptrtoint %Point* %t1268 to i64
  %t1270 = mul i64 %t1267, %t1269
  %t1271 = call i8* @malloc(i64 %t1270)
  %t1272 = bitcast i8* %t1271 to %Point*
  %t1273 = icmp sgt i64 %t1262, 0
  br i1 %t1273, label %set_insert_copy_277, label %set_insert_after_copy_278
set_insert_copy_277:
  %t1274 = mul i64 %t1250, %t1269
  %t1275 = bitcast %Point* %t1263 to i8*
  call i8* @memcpy(i8* %t1271, i8* %t1275, i64 %t1274)
  call void @free(i8* %t1275)
  br label %set_insert_after_copy_278
set_insert_after_copy_278:
  store %Point* %t1272, %Point** %t1241
  store i64 %t1267, i64* %t1245
  br label %set_insert_store_276
set_insert_store_276:
  %t1276 = load %Point*, %Point** %t1241
  %t1277 = getelementptr inbounds %Point, %Point* %t1276, i64 %t1250
  store %Point %t1249, %Point* %t1277
  %t1278 = add i64 %t1250, 1
  store i64 %t1278, i64* %t1243
  br label %set_insert_end_274
set_insert_end_274:
  %t1279 = phi i1 [ false, %set_insert_already_present_272 ], [ true, %set_insert_store_276 ]
  %t1280 = getelementptr %Point, %Point* null, i32 1
  %t1281 = ptrtoint %Point* %t1280 to i64
  %t1282 = load i8*, i8** %t1120
  %t1283 = icmp eq i8* %t1282, null
  br i1 %t1283, label %set_cow_alloc_279, label %set_cow_check_280
set_cow_alloc_279:
  %t1284 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1285 = call i8* @star_rc_alloc(i64 24, i8* %t1284)
  %t1286 = bitcast i8* %t1285 to { %Point*, i64, i64 }*
  %t1287 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 0
  store %Point* null, %Point** %t1287
  %t1288 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 1
  store i64 0, i64* %t1288
  %t1289 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 2
  store i64 0, i64* %t1289
  store i8* %t1285, i8** %t1120
  br label %set_cow_done_281
set_cow_check_280:
  %t1290 = getelementptr inbounds i8, i8* %t1282, i64 -16
  %t1291 = bitcast i8* %t1290 to i64*
  %t1292 = load atomic i64, i64* %t1291 seq_cst, align 8
  %t1293 = icmp eq i64 %t1292, 1
  br i1 %t1293, label %set_cow_done_281, label %set_cow_clone_282
set_cow_clone_282:
  %t1294 = bitcast i8* %t1282 to { %Point*, i64, i64 }*
  %t1295 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1294, i32 0, i32 0
  %t1296 = load %Point*, %Point** %t1295
  %t1297 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1294, i32 0, i32 1
  %t1298 = load i64, i64* %t1297
  %t1299 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1294, i32 0, i32 2
  %t1300 = load i64, i64* %t1299
  %t1301 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1302 = call i8* @star_rc_alloc(i64 24, i8* %t1301)
  %t1303 = bitcast i8* %t1302 to { %Point*, i64, i64 }*
  %t1304 = mul i64 %t1300, %t1281
  %t1305 = call i8* @malloc(i64 %t1304)
  %t1306 = bitcast i8* %t1305 to %Point*
  %t1307 = icmp sgt i64 %t1298, 0
  br i1 %t1307, label %set_cow_copy_283, label %set_cow_after_copy_284
set_cow_copy_283:
  %t1308 = mul i64 %t1298, %t1281
  %t1309 = bitcast %Point* %t1296 to i8*
  call i8* @memcpy(i8* %t1305, i8* %t1309, i64 %t1308)
  br label %set_cow_after_copy_284
set_cow_after_copy_284:
  %t1310 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1303, i32 0, i32 0
  store %Point* %t1306, %Point** %t1310
  %t1311 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1303, i32 0, i32 1
  store i64 %t1298, i64* %t1311
  %t1312 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1303, i32 0, i32 2
  store i64 %t1300, i64* %t1312
  call void @star_rc_release(i8* %t1282)
  store i8* %t1302, i8** %t1120
  br label %set_cow_done_281
set_cow_done_281:
  %t1313 = load i8*, i8** %t1120
  %t1314 = bitcast i8* %t1313 to { %Point*, i64, i64 }*
  %t1315 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1314, i32 0, i32 0
  %t1316 = load %Point*, %Point** %t1315
  %t1317 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1314, i32 0, i32 1
  %t1318 = load i64, i64* %t1317
  %t1319 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1314, i32 0, i32 2
  %t1321 = getelementptr inbounds %Point, %Point* %t1320, i32 0, i32 0
  store i32 3, i32* %t1321
  %t1322 = getelementptr inbounds %Point, %Point* %t1320, i32 0, i32 1
  store i32 4, i32* %t1322
  %t1323 = load %Point, %Point* %t1320
  %t1324 = load i64, i64* %t1317
  %t1325 = load %Point*, %Point** %t1315
  store i64 0, i64* %t1326
  store i1 false, i1* %t1327
  br label %find_cond_285
find_cond_285:
  %t1328 = load i64, i64* %t1326
  %t1329 = icmp slt i64 %t1328, %t1324
  br i1 %t1329, label %find_body_286, label %find_end_289
find_body_286:
  %t1330 = getelementptr inbounds %Point, %Point* %t1325, i64 %t1328
  %t1331 = load %Point, %Point* %t1330
  br label %find_eq_check_287
find_eq_check_287:
  %t1332 = call i1 @eq_s_Point(%Point %t1331, %Point %t1323)
  br i1 %t1332, label %find_end_289, label %find_next_288
find_next_288:
  %t1333 = add i64 %t1328, 1
  store i64 %t1333, i64* %t1326
  br label %find_cond_285
find_end_289:
  %t1334 = load i64, i64* %t1326
  %t1335 = icmp slt i64 %t1334, %t1324
  br i1 %t1335, label %set_insert_already_present_290, label %set_insert_do_291
set_insert_already_present_290:
  br label %set_insert_end_292
set_insert_do_291:
  %t1336 = load i64, i64* %t1319
  %t1337 = load %Point*, %Point** %t1315
  %t1338 = icmp sge i64 %t1324, %t1336
  br i1 %t1338, label %set_insert_grow_293, label %set_insert_store_294
set_insert_grow_293:
  %t1339 = mul i64 %t1336, 2
  %t1340 = icmp sgt i64 %t1339, 0
  %t1341 = select i1 %t1340, i64 %t1339, i64 1
  %t1342 = getelementptr %Point, %Point* null, i32 1
  %t1343 = ptrtoint %Point* %t1342 to i64
  %t1344 = mul i64 %t1341, %t1343
  %t1345 = call i8* @malloc(i64 %t1344)
  %t1346 = bitcast i8* %t1345 to %Point*
  %t1347 = icmp sgt i64 %t1336, 0
  br i1 %t1347, label %set_insert_copy_295, label %set_insert_after_copy_296
set_insert_copy_295:
  %t1348 = mul i64 %t1324, %t1343
  %t1349 = bitcast %Point* %t1337 to i8*
  call i8* @memcpy(i8* %t1345, i8* %t1349, i64 %t1348)
  call void @free(i8* %t1349)
  br label %set_insert_after_copy_296
set_insert_after_copy_296:
  store %Point* %t1346, %Point** %t1315
  store i64 %t1341, i64* %t1319
  br label %set_insert_store_294
set_insert_store_294:
  %t1350 = load %Point*, %Point** %t1315
  %t1351 = getelementptr inbounds %Point, %Point* %t1350, i64 %t1324
  store %Point %t1323, %Point* %t1351
  %t1352 = add i64 %t1324, 1
  store i64 %t1352, i64* %t1317
  br label %set_insert_end_292
set_insert_end_292:
  %t1353 = phi i1 [ false, %set_insert_already_present_290 ], [ true, %set_insert_store_294 ]
  %t1354 = load i8*, i8** %t1120
  %t1355 = icmp eq i8* %t1354, null
  br i1 %t1355, label %set_read_null_297, label %set_read_real_298
set_read_null_297:
  br label %set_read_end_299
set_read_real_298:
  %t1356 = bitcast i8* %t1354 to { %Point*, i64, i64 }*
  %t1357 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1356, i32 0, i32 0
  %t1358 = load %Point*, %Point** %t1357
  %t1359 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1356, i32 0, i32 1
  %t1360 = load i64, i64* %t1359
  br label %set_read_end_299
set_read_end_299:
  %t1361 = phi %Point* [ null, %set_read_null_297 ], [ %t1358, %set_read_real_298 ]
  %t1362 = phi i64 [ 0, %set_read_null_297 ], [ %t1360, %set_read_real_298 ]
  %t1363 = trunc i64 %t1362 to i32
  %t1364 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1364, i32 %t1363)
  %t1366 = getelementptr inbounds %Point, %Point* %t1365, i32 0, i32 0
  store i32 1, i32* %t1366
  %t1367 = getelementptr inbounds %Point, %Point* %t1365, i32 0, i32 1
  store i32 2, i32* %t1367
  %t1368 = load %Point, %Point* %t1365
  %t1369 = load i8*, i8** %t1120
  %t1370 = icmp eq i8* %t1369, null
  br i1 %t1370, label %set_read_null_300, label %set_read_real_301
set_read_null_300:
  br label %set_read_end_302
set_read_real_301:
  %t1371 = bitcast i8* %t1369 to { %Point*, i64, i64 }*
  %t1372 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1371, i32 0, i32 0
  %t1373 = load %Point*, %Point** %t1372
  %t1374 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1371, i32 0, i32 1
  %t1375 = load i64, i64* %t1374
  br label %set_read_end_302
set_read_end_302:
  %t1376 = phi %Point* [ null, %set_read_null_300 ], [ %t1373, %set_read_real_301 ]
  %t1377 = phi i64 [ 0, %set_read_null_300 ], [ %t1375, %set_read_real_301 ]
  store i64 0, i64* %t1378
  store i1 false, i1* %t1379
  br label %find_cond_303
find_cond_303:
  %t1380 = load i64, i64* %t1378
  %t1381 = icmp slt i64 %t1380, %t1377
  br i1 %t1381, label %find_body_304, label %find_end_307
find_body_304:
  %t1382 = getelementptr inbounds %Point, %Point* %t1376, i64 %t1380
  %t1383 = load %Point, %Point* %t1382
  br label %find_eq_check_305
find_eq_check_305:
  %t1384 = call i1 @eq_s_Point(%Point %t1383, %Point %t1368)
  br i1 %t1384, label %find_end_307, label %find_next_306
find_next_306:
  %t1385 = add i64 %t1380, 1
  store i64 %t1385, i64* %t1378
  br label %find_cond_303
find_end_307:
  %t1386 = load i64, i64* %t1378
  %t1387 = icmp slt i64 %t1386, %t1377
  %t1388 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t1389 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t1390 = select i1 %t1387, i8* %t1388, i8* %t1389
  %t1391 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1391, i8* %t1390)
  %t1393 = getelementptr inbounds %Point, %Point* %t1392, i32 0, i32 0
  store i32 9, i32* %t1393
  %t1394 = getelementptr inbounds %Point, %Point* %t1392, i32 0, i32 1
  store i32 9, i32* %t1394
  %t1395 = load %Point, %Point* %t1392
  %t1396 = load i8*, i8** %t1120
  %t1397 = icmp eq i8* %t1396, null
  br i1 %t1397, label %set_read_null_308, label %set_read_real_309
set_read_null_308:
  br label %set_read_end_310
set_read_real_309:
  %t1398 = bitcast i8* %t1396 to { %Point*, i64, i64 }*
  %t1399 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1398, i32 0, i32 0
  %t1400 = load %Point*, %Point** %t1399
  %t1401 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1398, i32 0, i32 1
  %t1402 = load i64, i64* %t1401
  br label %set_read_end_310
set_read_end_310:
  %t1403 = phi %Point* [ null, %set_read_null_308 ], [ %t1400, %set_read_real_309 ]
  %t1404 = phi i64 [ 0, %set_read_null_308 ], [ %t1402, %set_read_real_309 ]
  store i64 0, i64* %t1405
  store i1 false, i1* %t1406
  br label %find_cond_311
find_cond_311:
  %t1407 = load i64, i64* %t1405
  %t1408 = icmp slt i64 %t1407, %t1404
  br i1 %t1408, label %find_body_312, label %find_end_315
find_body_312:
  %t1409 = getelementptr inbounds %Point, %Point* %t1403, i64 %t1407
  %t1410 = load %Point, %Point* %t1409
  br label %find_eq_check_313
find_eq_check_313:
  %t1411 = call i1 @eq_s_Point(%Point %t1410, %Point %t1395)
  br i1 %t1411, label %find_end_315, label %find_next_314
find_next_314:
  %t1412 = add i64 %t1407, 1
  store i64 %t1412, i64* %t1405
  br label %find_cond_311
find_end_315:
  %t1413 = load i64, i64* %t1405
  %t1414 = icmp slt i64 %t1413, %t1404
  %t1415 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1416 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1417 = select i1 %t1414, i8* %t1415, i8* %t1416
  %t1418 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1418, i8* %t1417)
  %t1419 = load i8*, i8** %t1120
  call void @star_rc_release(i8* %t1419)
  %t1420 = load i8*, i8** %t704
  call void @star_rc_release(i8* %t1420)
  %t1421 = load i8*, i8** %t520
  call void @star_rc_release(i8* %t1421)
  %t1422 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1422)
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
  %t709 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t710 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t709, i32 0, i32 0
  %t711 = load i32*, i32** %t710
  %t712 = bitcast i32* %t711 to i8*
  call void @free(i8* %t712)
  ret void
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t751 = icmp eq i32 %a, %b
  ret i1 %t751
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1125 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t1126 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1125, i32 0, i32 0
  %t1127 = load %Point*, %Point** %t1126
  %t1128 = bitcast %Point* %t1127 to i8*
  call void @free(i8* %t1128)
  ret void
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t1171 = extractvalue %Point %a, 0
  %t1172 = extractvalue %Point %b, 0
  %t1173 = icmp eq i32 %t1171, %t1172
  %t1174 = extractvalue %Point %a, 1
  %t1175 = extractvalue %Point %b, 1
  %t1176 = icmp eq i32 %t1174, %t1175
  %t1177 = and i1 %t1173, %t1176
  ret i1 %t1177
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
