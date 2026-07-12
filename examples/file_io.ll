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
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  %t1 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t1, i8** %t0
  %t2 = alloca i8*
  %t3 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.1, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t4 = alloca i8*
  %t5 = load i8*, i8** %t0
  %t6 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t6)
  call void @star_rc_release(i8* %t5)
  %t7 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t8 = call i8* @fopen(i8* %t5, i8* %t7)
  store i8* %t8, i8** %t4
  %t9 = load i8*, i8** %t4
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %if_then_0, label %if_else_1
if_then_0:
  %t11 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.3, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t11)
  %t12 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t12)
  %t13 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t13)
  ret i32 0
if_else_1:
  br label %if_end_2
if_end_2:
  %t14 = load i8*, i8** %t4
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %file_null_handle_3, label %file_handle_ok_4
file_null_handle_3:
  %t16 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t16)
  call void @exit(i32 1)
  unreachable
file_handle_ok_4:
  %t17 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t18 = call i32 @strlen(i8* %t17)
  %t19 = sext i32 %t18 to i64
  %t20 = call i64 @fwrite(i8* %t17, i64 1, i64 %t19, i8* %t14)
  %t21 = icmp eq i64 %t20, %t19
  %t22 = load i8*, i8** %t4
  %t23 = icmp eq i8* %t22, null
  br i1 %t23, label %file_null_handle_5, label %file_handle_ok_6
file_null_handle_5:
  %t24 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t24)
  call void @exit(i32 1)
  unreachable
file_handle_ok_6:
  %t25 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t26 = call i32 @strlen(i8* %t25)
  %t27 = sext i32 %t26 to i64
  %t28 = call i64 @fwrite(i8* %t25, i64 1, i64 %t27, i8* %t22)
  %t29 = icmp eq i64 %t28, %t27
  %t30 = load i8*, i8** %t4
  %t31 = icmp eq i8* %t30, null
  br i1 %t31, label %file_null_handle_7, label %file_handle_ok_8
file_null_handle_7:
  %t32 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.8, i64 0, i64 0
  call i32 @puts(i8* %t32)
  call void @exit(i32 1)
  unreachable
file_handle_ok_8:
  call i32 @fclose(i8* %t30)
  %t33 = alloca i1
  %t34 = load i8*, i8** %t0
  %t35 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t35)
  call void @star_rc_release(i8* %t34)
  %t36 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  %t37 = call i8* @fopen(i8* %t34, i8* %t36)
  %t38 = icmp ne i8* %t37, null
  br i1 %t38, label %file_exists_close_9, label %file_exists_end_10
file_exists_close_9:
  call i32 @fclose(i8* %t37)
  br label %file_exists_end_10
file_exists_end_10:
  store i1 %t38, i1* %t33
  %t39 = alloca i1
  %t40 = load i8*, i8** %t2
  %t41 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t41)
  call void @star_rc_release(i8* %t40)
  %t42 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  %t43 = call i8* @fopen(i8* %t40, i8* %t42)
  %t44 = icmp ne i8* %t43, null
  br i1 %t44, label %file_exists_close_11, label %file_exists_end_12
file_exists_close_11:
  call i32 @fclose(i8* %t43)
  br label %file_exists_end_12
file_exists_end_12:
  store i1 %t44, i1* %t39
  %t45 = load i1, i1* %t33
  %t46 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t47 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t48 = select i1 %t45, i8* %t46, i8* %t47
  %t49 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, i8* %t48)
  %t50 = load i1, i1* %t39
  %t51 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t52 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t53 = select i1 %t50, i8* %t51, i8* %t52
  %t54 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i8* %t53)
  %t55 = alloca i8*
  %t56 = load i8*, i8** %t0
  %t57 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t57)
  call void @star_rc_release(i8* %t56)
  %t58 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.17, i64 0, i32 2, i64 0
  %t59 = call i8* @fopen(i8* %t56, i8* %t58)
  store i8* %t59, i8** %t55
  %t60 = load i8*, i8** %t55
  %t61 = icmp eq i8* %t60, null
  br i1 %t61, label %if_then_13, label %if_else_14
if_then_13:
  %t62 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.18, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t62)
  %t63 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t63)
  %t64 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t64)
  ret i32 0
if_else_14:
  br label %if_end_15
if_end_15:
  %t65 = alloca i8*
  %t66 = load i8*, i8** %t55
  %t67 = icmp eq i8* %t66, null
  br i1 %t67, label %file_null_handle_16, label %file_handle_ok_17
file_null_handle_16:
  %t68 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.19, i64 0, i64 0
  call i32 @puts(i8* %t68)
  call void @exit(i32 1)
  unreachable
file_handle_ok_17:
  %t69 = call i8* @star_rc_alloc(i64 1024, i8* null)
  %t70 = alloca i64
  store i64 0, i64* %t70
  br label %file_read_line_cond_18
file_read_line_cond_18:
  %t71 = load i64, i64* %t70
  %t72 = icmp ult i64 %t71, 1023
  br i1 %t72, label %file_read_line_body_19, label %file_read_line_end_21
file_read_line_body_19:
  %t73 = call i32 @fgetc(i8* %t66)
  %t74 = icmp eq i32 %t73, -1
  %t75 = icmp eq i32 %t73, 10
  %t76 = or i1 %t74, %t75
  br i1 %t76, label %file_read_line_end_21, label %file_read_line_store_20
file_read_line_store_20:
  %t77 = getelementptr inbounds i8, i8* %t69, i64 %t71
  %t78 = trunc i32 %t73 to i8
  store i8 %t78, i8* %t77
  %t79 = add i64 %t71, 1
  store i64 %t79, i64* %t70
  br label %file_read_line_cond_18
file_read_line_end_21:
  %t80 = load i64, i64* %t70
  %t81 = getelementptr inbounds i8, i8* %t69, i64 %t80
  store i8 0, i8* %t81
  store i8* %t69, i8** %t65
  %t82 = load i8*, i8** %t65
  %t83 = load i8*, i8** %t65
  call void @star_rc_retain(i8* %t83)
  call void @star_rc_release(i8* %t82)
  %t84 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t84, i8* %t82)
  %t85 = alloca i8*
  %t86 = load i8*, i8** %t55
  %t87 = icmp eq i8* %t86, null
  br i1 %t87, label %file_null_handle_22, label %file_handle_ok_23
file_null_handle_22:
  %t88 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t88)
  call void @exit(i32 1)
  unreachable
file_handle_ok_23:
  %t89 = call i32 @ftell(i8* %t86)
  call i32 @fseek(i8* %t86, i32 0, i32 2)
  %t90 = call i32 @ftell(i8* %t86)
  call i32 @fseek(i8* %t86, i32 %t89, i32 0)
  %t91 = sub i32 %t90, %t89
  %t92 = sext i32 %t91 to i64
  %t93 = add i64 %t92, 1
  %t94 = call i8* @star_rc_alloc(i64 %t93, i8* null)
  %t95 = call i64 @fread(i8* %t94, i64 1, i64 %t92, i8* %t86)
  %t96 = getelementptr inbounds i8, i8* %t94, i64 %t95
  store i8 0, i8* %t96
  store i8* %t94, i8** %t85
  %t97 = load i8*, i8** %t85
  %t98 = load i8*, i8** %t85
  call void @star_rc_retain(i8* %t98)
  call void @star_rc_release(i8* %t97)
  %t99 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t99, i8* %t97)
  %t100 = load i8*, i8** %t55
  %t101 = icmp eq i8* %t100, null
  br i1 %t101, label %file_null_handle_24, label %file_handle_ok_25
file_null_handle_24:
  %t102 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t102)
  call void @exit(i32 1)
  unreachable
file_handle_ok_25:
  call i32 @fclose(i8* %t100)
  %t103 = load i8*, i8** %t85
  call void @star_rc_release(i8* %t103)
  %t104 = load i8*, i8** %t65
  call void @star_rc_release(i8* %t104)
  %t105 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t105)
  %t106 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t106)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"star_file_io_example_scratch.txt\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"star_file_io_example_missing.txt\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"w\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"failed to open for writing\00" }
@.str.4 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"hello from star\0A\00" }
@.str.6 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"second line\0A\00" }
@.str.8 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.9 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.10 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.11 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.12 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.13 = private unnamed_addr constant [31 x i8] c"file_exists(written file): %s\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [31 x i8] c"file_exists(missing file): %s\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.18 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"failed to open for reading\00" }
@.str.19 = private unnamed_addr constant [78 x i8] c"star runtime error: file_read_line(..) called with a null/closed file handle\0A\00"
@.str.20 = private unnamed_addr constant [11 x i8] c"line1: %s\0A\00"
@.str.21 = private unnamed_addr constant [73 x i8] c"star runtime error: file_read(..) called with a null/closed file handle\0A\00"
@.str.22 = private unnamed_addr constant [10 x i8] c"rest: %s\0A\00"
@.str.23 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
