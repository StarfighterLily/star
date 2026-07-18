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

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t222 = alloca i8
  %t224 = alloca i32
  %t245 = alloca i8
  %t250 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = load i8*, i8** %t2
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %list_cow_alloc_0, label %list_cow_check_1
list_cow_alloc_0:
  %t11 = bitcast void (i8*)* @list_release_color32 to i8*
  %t12 = call i8* @star_rc_alloc(i64 24, i8* %t11)
  %t13 = bitcast i8* %t12 to { i32*, i64, i64 }*
  %t14 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t13, i32 0, i32 0
  store i32* null, i32** %t14
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t13, i32 0, i32 1
  store i64 0, i64* %t15
  %t16 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t13, i32 0, i32 2
  store i64 0, i64* %t16
  store i8* %t12, i8** %t2
  br label %list_cow_done_2
list_cow_check_1:
  %t17 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t18 = bitcast i8* %t17 to i64*
  %t19 = load atomic i64, i64* %t18 seq_cst, align 8
  %t20 = icmp eq i64 %t19, 1
  br i1 %t20, label %list_cow_done_2, label %list_cow_clone_3
list_cow_clone_3:
  %t21 = bitcast i8* %t5 to { i32*, i64, i64 }*
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 0
  %t23 = load i32*, i32** %t22
  %t24 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 1
  %t25 = load i64, i64* %t24
  %t26 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 2
  %t27 = load i64, i64* %t26
  %t28 = bitcast void (i8*)* @list_release_color32 to i8*
  %t29 = call i8* @star_rc_alloc(i64 24, i8* %t28)
  %t30 = bitcast i8* %t29 to { i32*, i64, i64 }*
  %t31 = mul i64 %t27, %t4
  %t32 = call i8* @malloc(i64 %t31)
  %t33 = bitcast i8* %t32 to i32*
  %t34 = icmp sgt i64 %t25, 0
  br i1 %t34, label %list_cow_copy_4, label %list_cow_after_copy_5
list_cow_copy_4:
  %t35 = mul i64 %t25, %t4
  %t36 = bitcast i32* %t23 to i8*
  call i8* @memcpy(i8* %t32, i8* %t36, i64 %t35)
  br label %list_cow_after_copy_5
list_cow_after_copy_5:
  %t37 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 0
  store i32* %t33, i32** %t37
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 1
  store i64 %t25, i64* %t38
  %t39 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 2
  store i64 %t27, i64* %t39
  call void @star_rc_release(i8* %t5)
  store i8* %t29, i8** %t2
  br label %list_cow_done_2
list_cow_done_2:
  %t40 = load i8*, i8** %t2
  %t41 = bitcast i8* %t40 to { i32*, i64, i64 }*
  %t42 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t41, i32 0, i32 0
  %t43 = load i32*, i32** %t42
  %t44 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t41, i32 0, i32 1
  %t45 = load i64, i64* %t44
  %t46 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t41, i32 0, i32 2
  %t47 = and i32 255, 255
  %t48 = and i32 0, 255
  %t49 = shl i32 %t48, 8
  %t50 = or i32 %t47, %t49
  %t51 = and i32 0, 255
  %t52 = shl i32 %t51, 16
  %t53 = or i32 %t50, %t52
  %t54 = and i32 255, 255
  %t55 = shl i32 %t54, 24
  %t56 = or i32 %t53, %t55
  %t57 = load i64, i64* %t46
  %t58 = load i32*, i32** %t42
  %t59 = load i64, i64* %t44
  %t60 = icmp sge i64 %t59, %t57
  br i1 %t60, label %list_push_grow_6, label %list_push_store_7
list_push_grow_6:
  %t61 = mul i64 %t57, 2
  %t62 = icmp sgt i64 %t61, 0
  %t63 = select i1 %t62, i64 %t61, i64 1
  %t64 = getelementptr i32, i32* null, i32 1
  %t65 = ptrtoint i32* %t64 to i64
  %t66 = mul i64 %t63, %t65
  %t67 = call i8* @malloc(i64 %t66)
  %t68 = bitcast i8* %t67 to i32*
  %t69 = icmp sgt i64 %t57, 0
  br i1 %t69, label %list_push_copy_8, label %list_push_after_copy_9
list_push_copy_8:
  %t70 = mul i64 %t59, %t65
  %t71 = bitcast i32* %t58 to i8*
  call i8* @memcpy(i8* %t67, i8* %t71, i64 %t70)
  call void @free(i8* %t71)
  br label %list_push_after_copy_9
list_push_after_copy_9:
  store i32* %t68, i32** %t42
  store i64 %t63, i64* %t46
  br label %list_push_store_7
list_push_store_7:
  %t72 = load i32*, i32** %t42
  %t73 = getelementptr inbounds i32, i32* %t72, i64 %t59
  store i32 %t56, i32* %t73
  %t74 = add i64 %t59, 1
  store i64 %t74, i64* %t44
  %t75 = getelementptr i32, i32* null, i32 1
  %t76 = ptrtoint i32* %t75 to i64
  %t77 = load i8*, i8** %t2
  %t78 = icmp eq i8* %t77, null
  br i1 %t78, label %list_cow_alloc_10, label %list_cow_check_11
list_cow_alloc_10:
  %t79 = bitcast void (i8*)* @list_release_color32 to i8*
  %t80 = call i8* @star_rc_alloc(i64 24, i8* %t79)
  %t81 = bitcast i8* %t80 to { i32*, i64, i64 }*
  %t82 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t81, i32 0, i32 0
  store i32* null, i32** %t82
  %t83 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t81, i32 0, i32 1
  store i64 0, i64* %t83
  %t84 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t81, i32 0, i32 2
  store i64 0, i64* %t84
  store i8* %t80, i8** %t2
  br label %list_cow_done_12
list_cow_check_11:
  %t85 = getelementptr inbounds i8, i8* %t77, i64 -16
  %t86 = bitcast i8* %t85 to i64*
  %t87 = load atomic i64, i64* %t86 seq_cst, align 8
  %t88 = icmp eq i64 %t87, 1
  br i1 %t88, label %list_cow_done_12, label %list_cow_clone_13
list_cow_clone_13:
  %t89 = bitcast i8* %t77 to { i32*, i64, i64 }*
  %t90 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t89, i32 0, i32 0
  %t91 = load i32*, i32** %t90
  %t92 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t89, i32 0, i32 1
  %t93 = load i64, i64* %t92
  %t94 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t89, i32 0, i32 2
  %t95 = load i64, i64* %t94
  %t96 = bitcast void (i8*)* @list_release_color32 to i8*
  %t97 = call i8* @star_rc_alloc(i64 24, i8* %t96)
  %t98 = bitcast i8* %t97 to { i32*, i64, i64 }*
  %t99 = mul i64 %t95, %t76
  %t100 = call i8* @malloc(i64 %t99)
  %t101 = bitcast i8* %t100 to i32*
  %t102 = icmp sgt i64 %t93, 0
  br i1 %t102, label %list_cow_copy_14, label %list_cow_after_copy_15
list_cow_copy_14:
  %t103 = mul i64 %t93, %t76
  %t104 = bitcast i32* %t91 to i8*
  call i8* @memcpy(i8* %t100, i8* %t104, i64 %t103)
  br label %list_cow_after_copy_15
list_cow_after_copy_15:
  %t105 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t98, i32 0, i32 0
  store i32* %t101, i32** %t105
  %t106 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t98, i32 0, i32 1
  store i64 %t93, i64* %t106
  %t107 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t98, i32 0, i32 2
  store i64 %t95, i64* %t107
  call void @star_rc_release(i8* %t77)
  store i8* %t97, i8** %t2
  br label %list_cow_done_12
list_cow_done_12:
  %t108 = load i8*, i8** %t2
  %t109 = bitcast i8* %t108 to { i32*, i64, i64 }*
  %t110 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t109, i32 0, i32 0
  %t111 = load i32*, i32** %t110
  %t112 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t109, i32 0, i32 1
  %t113 = load i64, i64* %t112
  %t114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t109, i32 0, i32 2
  %t115 = and i32 0, 255
  %t116 = and i32 255, 255
  %t117 = shl i32 %t116, 8
  %t118 = or i32 %t115, %t117
  %t119 = and i32 0, 255
  %t120 = shl i32 %t119, 16
  %t121 = or i32 %t118, %t120
  %t122 = and i32 255, 255
  %t123 = shl i32 %t122, 24
  %t124 = or i32 %t121, %t123
  %t125 = load i64, i64* %t114
  %t126 = load i32*, i32** %t110
  %t127 = load i64, i64* %t112
  %t128 = icmp sge i64 %t127, %t125
  br i1 %t128, label %list_push_grow_16, label %list_push_store_17
list_push_grow_16:
  %t129 = mul i64 %t125, 2
  %t130 = icmp sgt i64 %t129, 0
  %t131 = select i1 %t130, i64 %t129, i64 1
  %t132 = getelementptr i32, i32* null, i32 1
  %t133 = ptrtoint i32* %t132 to i64
  %t134 = mul i64 %t131, %t133
  %t135 = call i8* @malloc(i64 %t134)
  %t136 = bitcast i8* %t135 to i32*
  %t137 = icmp sgt i64 %t125, 0
  br i1 %t137, label %list_push_copy_18, label %list_push_after_copy_19
list_push_copy_18:
  %t138 = mul i64 %t127, %t133
  %t139 = bitcast i32* %t126 to i8*
  call i8* @memcpy(i8* %t135, i8* %t139, i64 %t138)
  call void @free(i8* %t139)
  br label %list_push_after_copy_19
list_push_after_copy_19:
  store i32* %t136, i32** %t110
  store i64 %t131, i64* %t114
  br label %list_push_store_17
list_push_store_17:
  %t140 = load i32*, i32** %t110
  %t141 = getelementptr inbounds i32, i32* %t140, i64 %t127
  store i32 %t124, i32* %t141
  %t142 = add i64 %t127, 1
  store i64 %t142, i64* %t112
  %t143 = getelementptr i32, i32* null, i32 1
  %t144 = ptrtoint i32* %t143 to i64
  %t145 = load i8*, i8** %t2
  %t146 = icmp eq i8* %t145, null
  br i1 %t146, label %list_cow_alloc_20, label %list_cow_check_21
list_cow_alloc_20:
  %t147 = bitcast void (i8*)* @list_release_color32 to i8*
  %t148 = call i8* @star_rc_alloc(i64 24, i8* %t147)
  %t149 = bitcast i8* %t148 to { i32*, i64, i64 }*
  %t150 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t149, i32 0, i32 0
  store i32* null, i32** %t150
  %t151 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t149, i32 0, i32 1
  store i64 0, i64* %t151
  %t152 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t149, i32 0, i32 2
  store i64 0, i64* %t152
  store i8* %t148, i8** %t2
  br label %list_cow_done_22
list_cow_check_21:
  %t153 = getelementptr inbounds i8, i8* %t145, i64 -16
  %t154 = bitcast i8* %t153 to i64*
  %t155 = load atomic i64, i64* %t154 seq_cst, align 8
  %t156 = icmp eq i64 %t155, 1
  br i1 %t156, label %list_cow_done_22, label %list_cow_clone_23
list_cow_clone_23:
  %t157 = bitcast i8* %t145 to { i32*, i64, i64 }*
  %t158 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 0
  %t159 = load i32*, i32** %t158
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 1
  %t161 = load i64, i64* %t160
  %t162 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 2
  %t163 = load i64, i64* %t162
  %t164 = bitcast void (i8*)* @list_release_color32 to i8*
  %t165 = call i8* @star_rc_alloc(i64 24, i8* %t164)
  %t166 = bitcast i8* %t165 to { i32*, i64, i64 }*
  %t167 = mul i64 %t163, %t144
  %t168 = call i8* @malloc(i64 %t167)
  %t169 = bitcast i8* %t168 to i32*
  %t170 = icmp sgt i64 %t161, 0
  br i1 %t170, label %list_cow_copy_24, label %list_cow_after_copy_25
list_cow_copy_24:
  %t171 = mul i64 %t161, %t144
  %t172 = bitcast i32* %t159 to i8*
  call i8* @memcpy(i8* %t168, i8* %t172, i64 %t171)
  br label %list_cow_after_copy_25
list_cow_after_copy_25:
  %t173 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t166, i32 0, i32 0
  store i32* %t169, i32** %t173
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t166, i32 0, i32 1
  store i64 %t161, i64* %t174
  %t175 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t166, i32 0, i32 2
  store i64 %t163, i64* %t175
  call void @star_rc_release(i8* %t145)
  store i8* %t165, i8** %t2
  br label %list_cow_done_22
list_cow_done_22:
  %t176 = load i8*, i8** %t2
  %t177 = bitcast i8* %t176 to { i32*, i64, i64 }*
  %t178 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t177, i32 0, i32 0
  %t179 = load i32*, i32** %t178
  %t180 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t177, i32 0, i32 1
  %t181 = load i64, i64* %t180
  %t182 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t177, i32 0, i32 2
  %t183 = and i32 0, 255
  %t184 = and i32 0, 255
  %t185 = shl i32 %t184, 8
  %t186 = or i32 %t183, %t185
  %t187 = and i32 255, 255
  %t188 = shl i32 %t187, 16
  %t189 = or i32 %t186, %t188
  %t190 = and i32 255, 255
  %t191 = shl i32 %t190, 24
  %t192 = or i32 %t189, %t191
  %t193 = load i64, i64* %t182
  %t194 = load i32*, i32** %t178
  %t195 = load i64, i64* %t180
  %t196 = icmp sge i64 %t195, %t193
  br i1 %t196, label %list_push_grow_26, label %list_push_store_27
list_push_grow_26:
  %t197 = mul i64 %t193, 2
  %t198 = icmp sgt i64 %t197, 0
  %t199 = select i1 %t198, i64 %t197, i64 1
  %t200 = getelementptr i32, i32* null, i32 1
  %t201 = ptrtoint i32* %t200 to i64
  %t202 = mul i64 %t199, %t201
  %t203 = call i8* @malloc(i64 %t202)
  %t204 = bitcast i8* %t203 to i32*
  %t205 = icmp sgt i64 %t193, 0
  br i1 %t205, label %list_push_copy_28, label %list_push_after_copy_29
list_push_copy_28:
  %t206 = mul i64 %t195, %t201
  %t207 = bitcast i32* %t194 to i8*
  call i8* @memcpy(i8* %t203, i8* %t207, i64 %t206)
  call void @free(i8* %t207)
  br label %list_push_after_copy_29
list_push_after_copy_29:
  store i32* %t204, i32** %t178
  store i64 %t199, i64* %t182
  br label %list_push_store_27
list_push_store_27:
  %t208 = load i32*, i32** %t178
  %t209 = getelementptr inbounds i32, i32* %t208, i64 %t195
  store i32 %t192, i32* %t209
  %t210 = add i64 %t195, 1
  store i64 %t210, i64* %t180
  %t211 = load i8*, i8** %t2
  %t212 = icmp eq i8* %t211, null
  br i1 %t212, label %list_read_null_30, label %list_read_real_31
list_read_null_30:
  br label %list_read_end_32
list_read_real_31:
  %t213 = bitcast i8* %t211 to { i32*, i64, i64 }*
  %t214 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t213, i32 0, i32 0
  %t215 = load i32*, i32** %t214
  %t216 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t213, i32 0, i32 1
  %t217 = load i64, i64* %t216
  br label %list_read_end_32
list_read_end_32:
  %t218 = phi i32* [ null, %list_read_null_30 ], [ %t215, %list_read_real_31 ]
  %t219 = phi i64 [ 0, %list_read_null_30 ], [ %t217, %list_read_real_31 ]
  %t220 = trunc i64 %t219 to i32
  %t221 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t221, i32 %t220)
  %t223 = trunc i32 1 to i8
  store i8 %t223, i8* %t222
  %t225 = load i8*, i8** %t2
  %t226 = icmp eq i8* %t225, null
  br i1 %t226, label %list_read_null_33, label %list_read_real_34
list_read_null_33:
  br label %list_read_end_35
list_read_real_34:
  %t227 = bitcast i8* %t225 to { i32*, i64, i64 }*
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t227, i32 0, i32 0
  %t229 = load i32*, i32** %t228
  %t230 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t227, i32 0, i32 1
  %t231 = load i64, i64* %t230
  br label %list_read_end_35
list_read_end_35:
  %t232 = phi i32* [ null, %list_read_null_33 ], [ %t229, %list_read_real_34 ]
  %t233 = phi i64 [ 0, %list_read_null_33 ], [ %t231, %list_read_real_34 ]
  %t234 = load i8, i8* %t222
  %t235 = zext i8 %t234 to i32
  %t236 = sext i32 %t235 to i64
  %t237 = icmp ult i64 %t236, %t233
  br i1 %t237, label %list_idx_ok_36, label %list_idx_oob_37
list_idx_ok_36:
  %t238 = getelementptr inbounds i32, i32* %t232, i64 %t236
  %t239 = load i32, i32* %t238
  br label %list_idx_end_38
list_idx_oob_37:
  br label %list_idx_end_38
list_idx_end_38:
  %t240 = phi i32 [ %t239, %list_idx_ok_36 ], [ 0, %list_idx_oob_37 ]
  store i32 %t240, i32* %t224
  %t241 = load i32, i32* %t224
  %t242 = lshr i32 %t241, 8
  %t243 = and i32 %t242, 255
  %t244 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t244, i32 %t243)
  %t246 = load i8, i8* %t222
  store i8 %t246, i8* %t245
  %t247 = load i8, i8* %t245
  %t248 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  %t249 = zext i8 %t247 to i32
  call i32 (i8*, ...) @printf(i8* %t248, i32 %t249)
  %t251 = load i8, i8* %t245
  store i8 %t251, i8* %t250
  %t252 = load i8, i8* %t250
  %t253 = load i8, i8* %t222
  %t254 = icmp eq i8 %t252, %t253
  %t255 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t256 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t257 = select i1 %t254, i8* %t255, i8* %t256
  %t258 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t258, i8* %t257)
  %t259 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t259)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_color32(i8* %objp) {
entry:
  %t7 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i32*, i32** %t8
  %t10 = bitcast i32* %t9 to i8*
  call void @free(i8* %t10)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"palette len: %d\0A\00"
@.str.1 = private unnamed_addr constant [26 x i8] c"palette[1] g channel: %d\0A\00"
@.str.2 = private unnamed_addr constant [17 x i8] c"index as u8: %u\0A\00"
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [34 x i8] c"index round-trip == original: %s\0A\00"
