"==============================================================================
"  Description: conding_macros
"  Authors: Dmitry Ignatovich
"==============================================================================

command! ExpandHashMacro call coding_macros#expand_hash_macro()
command! MakeConstHashRef call coding_macros#make_const_hash_ref()
command! MakeRangeIter call coding_macros#make_range_iters()
command! MakeBrackets call coding_macros#make_brackets()
command! MakeCommentParam call coding_macros#make_comment_param()
command! MakeSizeTCast call coding_macros#make_size_t_cast()
command! MakeDbgPrintBefore call coding_macros#make_dbg_print_before()
command! MakeDbgPrintAfter call coding_macros#make_dbg_print_after()
command! MakeDbgInclude call coding_macros#add_dbg_include()
command! MakeDbgMarker call coding_macros#add_dbg_marker()
command! MakeCppCtor call coding_macros#gen_cpp_ctor()
