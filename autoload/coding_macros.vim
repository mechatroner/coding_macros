"==============================================================================
"  Description: conding_macros
"  Authors: Dmitry Ignatovich
"==============================================================================


function! coding_macros#add_dbg_include()
    let lineno = line(".")
    let cpos = col(".")
    call cursor(line('$'), 1)
	let lnum_and_col = searchpos('^#include', 'nw')
    if (lnum_and_col[0] == 0)
        return
    endif
    let dbg_path = expand('~/toolbox/includes/dbg_deleteme.h')
    let new_line = '#include "' . dbg_path . '" // FOR_DEBUG'
    call append(lnum_and_col[0] - 1, new_line)
    call cursor(lineno + 1, cpos)
endfunction


function! s:ChompMember(line)
    let result = substitute(a:line, '[ \t]*$', '', '')
    let result = substitute(result, '^[ \t]*', '', '')
    let result = substitute(result, ';$', '', '')
    return result
endfunction

function! s:RFind(line, target_char)
    if (!len(a:line))
        return -1
    endif
    for pos in range(len(a:line) - 1, 0, -1)
        if a:line[pos] == a:target_char
            return pos
        endif
    endfor
    return -1
endfunction


function! coding_macros#gen_cpp_ctor()
    let first_line = line("'<")
    let last_line = line("'>")
    let decl = 'explicit FIXME_CLASS_NAME(' 
    let res_lines = []
    call add(res_lines, decl)
    for lnno in range(first_line, last_line)
        let cur_line = getline(lnno)
        let cur_line = s:ChompMember(cur_line)
        let pos = s:RFind(cur_line, ' ')
        if pos == -1
            echohl ErrorMsg | echo "No whitespace found in member declaration" | echohl None
            return
        endif
        let var_type = cur_line[:pos - 1]
        let var_name = cur_line[pos + 1:]
        let small_var_name = tolower(var_name[0]) . var_name[1:]
        if lnno != first_line
            let res_lines[0] = res_lines[0] . ', '
        endif
        let res_lines[0] = res_lines[0] . var_type . ' ' . small_var_name

        if lnno == first_line
            call add(res_lines, '    : ' . var_name . '(' . small_var_name . ')')
        else
            call add(res_lines, '    , ' . var_name . '(' . small_var_name . ')')
        endif
    endfor
    let res_lines[0] = res_lines[0] . ')'
    call add(res_lines, '{')
    call add(res_lines, '}')
    for iln in range(0, len(res_lines) - 1)
        call append(first_line - 1 + iln, res_lines[iln])
    endfor
endfunction


function! s:MatchCppToken(pattern)
    let lineno = line(".")
    let cpos = col(".") - 1
    let line = getline(".")
    let tpend = len(line)
    let tpstart = 0
    for pos in range(len(line))
        let letter = line[pos]
        if (match(letter, a:pattern) == 0)
            continue
        else
            if (pos < cpos)
                let tpstart = pos
            elseif (pos > cpos)
                let tpend = pos
                break
            else
                echohl ErrorMsg | echo "No token found under the cursor" | echohl None
            endif
        endif
    endfor
    let before = line[0:tpstart]
    let after = line[tpend + 0:]
    let token = line[tpstart + 1:tpend - 1]
    return [lineno, cpos, before, after, token]
endfunction


function! coding_macros#make_comment_param()
    let matched = <SID>MatchCppToken("[a-zA-Z0-9_:<>]")
    let lineno = matched[0]
    let cpos = matched[1]
    let before = matched[2]
    let after = matched[3]
    let token = matched[4]
    if (match(before, '\*$') != -1)
        let before = before . ' '
    endif
    let result = before . "/*" . token . "*/" . after 
    delete
    call append(lineno - 1, result)
    call cursor(lineno, cpos + 7)
endfunction


function! coding_macros#make_const_hash_ref()
    let matched = <SID>MatchCppToken("[a-zA-Z0-9_:<>]")
    let lineno = matched[0]
    let cpos = matched[1]
    let before = matched[2]
    let after = matched[3]
    let token = matched[4]
    let result = before . "const " . token . "&" . after 
    delete
    call append(lineno - 1, result)
    call cursor(lineno, cpos + 7)
endfunction


function! coding_macros#make_size_t_cast()
    let matched = <SID>MatchCppToken("[a-zA-Z0-9_:<>]")
    let lineno = matched[0]
    let cpos = matched[1]
    let before = matched[2]
    let after = matched[3]
    let token = matched[4]
    let result = before . "static_cast<"
    let res_column = len(result) + 1
    let result = result . ">(" . token . ")" . after
    delete
    call append(lineno - 1, result)
    call cursor(lineno, res_column)
endfunction


function! coding_macros#add_dbg_marker()
    let lineno = line(".")
    let cpos = col(".")
    let line = getline(".")
    let result = line . "//FOR_DEBUG"
    delete
    call append(lineno - 1, result)
    call cursor(lineno, cpos)
endfunction


function! coding_macros#make_range_iters()
    let matched = <SID>MatchCppToken("[a-zA-Z0-9_:<>]")
    let lineno = matched[0]
    let cpos = matched[1]
    let before = matched[2]
    let after = matched[3]
    let token = matched[4]
    let result = before . token . ".begin(), " . token . ".end()" . after 
    delete
    call append(lineno - 1, result)
    call cursor(lineno, cpos + 7)
endfunction



function! coding_macros#make_dbg_print_after()
    "TODO fix indentation after function
    let lineno = line(".")
    let cpos = col(".")
    let line = getline(".")
    let indent = matchstr(line, '^[ \t]*')
    let result = substitute(line, '^[ \t]*', '', '')
    let result = substitute(result, '\', '\\\\', 'g')
    let result = substitute(result, '"', '\\"', 'g')
    let result = indent . 'cout << __FILE__ << ":" << __LINE__ << " [AFTER] ' . result . '" << endl;'
    call append(lineno, result)
    call cursor(lineno, cpos)
endfunction

function! coding_macros#make_dbg_print_before()
    let lineno = line(".")
    let cpos = col(".")
    let line = getline(".")
    let indent = matchstr(line, '^[ \t]*')
    let result = substitute(line, '^[ \t]*', '', '')
    let result = substitute(result, '\', '\\\\', 'g')
    let result = substitute(result, '"', '\\"', 'g')
    let result = indent . 'cout << __FILE__ << ":" << __LINE__ << " [BEFORE] ' . result . '" << endl;'
    call append(lineno - 1, result)
    call cursor(lineno + 1, cpos)
endfunction



function! coding_macros#make_brackets()
    let lineno = line(".")
    let cpos = col(".") - 1
    let curno = lineno
    let indentlen = -1
    while 1
        let line = getline(curno)
        let indentlen = match(line, '[^ \t]')
        if indentlen != -1 || curno <= 1
            break
        endif
        let curno = curno - 1
    endwhile
    let line = getline(".")
    if indentlen == -1
        let indentlen = 0
    endif
    let ilp = indentlen
    let indent = ""
    while ilp > 0
        let indent = indent . " "
        let ilp = ilp - 1
    endwhile
    let closeLine = indent . "}"
    if (match(line, '[^ \t]') != -1)
        let openLine = line . " {"
        delete
        call append(lineno - 1, openLine)
        call append(lineno, closeLine)
        call cursor(lineno, 10000)
    else
        let openLine = indent . "{"
        call append(lineno, openLine)
        call append(lineno + 1, closeLine)
        call cursor(lineno + 1, 10000)
    endif
endfunction

function! s:SelectPythonOutput(token)
    if (a:token ==# 'o')
        return ''
    elseif (a:token ==# 'e')
        return ', file=sys.stderr'
    else
        echoerr "Unknown stream token: " . a:token
    endif
endfunction

function! s:SelectStreams(token)
    if (a:token ==# 'o')
        return ['cout', 'endl']
    elseif (a:token ==# 'e')
        return ['cerr', 'endl']
    elseif (a:token ==# 'O')
        return ['Cout', 'Endl']
    elseif (a:token ==# 'E')
        return ['Cerr', 'Endl']
    else
        echoerr "Unknown stream token: " . a:token
    endif
endfunction

function! s:FormatVarsOutCpp(fields, indent, stream_token)
    let resout = ""
    let i = 0
    for field in a:fields
        if (i > 0)
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf(' << "\t" << %s', field)
            else
                let resout = resout . printf(' << "\t%s: " << %s', field, field)
            endif
        else
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf(' << %s', field)
            else
                let resout = resout . printf(' << "%s: " << %s', field, field)
            endif
        endif
        let i = i + 1
    endfor
    let stkns = <SID>SelectStreams(a:stream_token)
    let expanded = printf('%s%s%s << %s;//FOR_DEBUG', a:indent, stkns[0], resout, stkns[1])
    return expanded
endfunction


function! s:FormatVarsOutPython(fields, indent, stream_token)
    let resout = ""
    let i = 0
    for field in a:fields
        if (i > 0)
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf(', ",\t" + %s', field)
            else
                let resout = resout . printf(', ",\t%s:", str(%s)', field, field)
            endif
        else
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf(' %s', field)
            else
                let resout = resout . printf(' "%s:", str(%s)', field, field)
            endif
        endif
        let i = i + 1
    endfor
    let resout = "''.join([" . resout . "])"
    let stkns = <SID>SelectPythonOutput(a:stream_token)
    let expanded = printf('%sprint(%s%s) #FOR_DEBUG', a:indent, resout, stkns)
    return expanded
endfunction


function! s:FormatVarsOutJS(fields, indent, stream_token)
    let resout = ""
    let i = 0
    for field in a:fields
        if (i > 0)
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf(' + %s', field)
            else
                let resout = resout . printf(' + ", %s:" + %s', field, field)
            endif
        else
            if (field[0] == '"' && field[len(field) - 1] == '"')
                let resout = resout . printf('%s', field)
            else
                let resout = resout . printf('"%s:" + %s', field, field)
            endif
        endif
        let i = i + 1
    endfor
    let stkns = "console.log("
    let expanded = printf('%s%s%s); //FOR_DEBUG', a:indent, stkns, resout)
    return expanded
endfunction


function! s:FormatVarsOutBash(fields, indent, stream_token)
    let resout = ""
    let i = 0
    for field in a:fields
        if (field[0] == '"' && field[len(field) - 1] == '"')
            let resout = resout . printf('%s ', field[1:-2])
        else
            let resout = resout . printf('%s: $%s ', field, field)
        endif
        let i = i + 1
    endfor
    let out_err = (a:stream_token ==# 'e') ? " 1>&2" : ""
    let expanded = printf('%sprintf "%s\n"%s #FOR_DEBUG', a:indent, resout, out_err)
    return expanded
endfunction


function! s:FormatVarsOut(fields, indent, stream_token)
    if &filetype ==# "python"
        return <SID>FormatVarsOutPython(a:fields, a:indent, a:stream_token)
    elseif &filetype ==# "sh"
        return <SID>FormatVarsOutBash(a:fields, a:indent, a:stream_token)
    elseif &filetype ==# "javascript"
        return <SID>FormatVarsOutJS(a:fields, a:indent, a:stream_token)
    else
        return <SID>FormatVarsOutCpp(a:fields, a:indent, a:stream_token)
    endif
endfunction

function! s:FormatVarsTabOut(fields, indent, stream_token)
    let resout = ""
    let i = 0
    for field in a:fields
        if (i > 0)
            let resout = resout . printf(' << "\t" << %s', field)
        else
            let resout = resout . printf(' << %s', field)
        endif
        let i = i + 1
    endfor
    let stkns = <SID>SelectStreams(a:stream_token)
    let expanded = printf('%s%s%s << %s;', a:indent, stkns[0], resout, stkns[1])
    return expanded
endfunction


function! s:FormatMapOut(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s: [\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(auto i=%s.begin();i!=%s.end();++i)",a:vecname, a:vecname)
    let l3 = printf("%s<<'('<<i->first<<\": \"<<i->second<<\"), \";", stkns[0])
    let l4 = printf("%s<<\"]\"<<%s;", stkns[0], stkns[1])
    let l5 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5)
    return res
endfunction


function! s:FormatSetOut(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s: {\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(auto i=%s.begin();i!=%s.end();++i)",a:vecname, a:vecname)
    let l3 = printf("%s<<*i<<\", \";", stkns[0])
    let l4 = printf("%s<<\"}\"<<%s;", stkns[0], stkns[1])
    let l5 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5)
    return res
endfunction

function! s:FormatVectorOut(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s: [\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(size_t i=0;i<%s.size();++i)", a:vecname)
    let l3 = printf("%s<<%s[i]<<\", \";", stkns[0], a:vecname)
    let l4 = printf("%s<<\"]\"<<%s;", stkns[0], stkns[1])
    let l5 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5)
    return res
endfunction

function! s:FormatVectorOutIndexed(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s: [\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(size_t i=0;i<%s.size();++i)", a:vecname)
    let l3 = printf("%s<<i<<\": \"<<%s[i]<<\", \";", stkns[0], a:vecname)
    let l4 = printf("%s<<\"]\"<<%s;", stkns[0], stkns[1])
    let l5 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5)
    return res
endfunction


function! s:FormatDelimOut(indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let expanded = printf('%s%s << "\n=============================================\n" << %s;', a:indent, stkns[0], stkns[1])
    return expanded
endfunction


function! s:FormatArrOut(arrname, arrlen, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s: [\";", a:indent, stkns[0], a:arrname)
    let l2 = printf("for(int i=0;i<%s;++i)", a:arrlen)
    let l3 = printf("%s<<%s[i]<<\", \";", stkns[0], a:arrname)
    let l4 = printf("%s<<\"]\"<<%s;", stkns[0], stkns[1])
    let l5 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5)
    return res
endfunction


function! s:Format2DArrOut(arrname, nr, nc, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s:\\n\";", a:indent, stkns[0], a:arrname)
    let l2 = printf("for(int r=0;r<%s;++r){", a:nr)
    let l3 = printf("for(int c=0;c<%s;++c)", a:nc)
    let l4 = printf("%s<<%s[r][c]<<\"\\t\";", stkns[0], a:arrname)
    let l5 = printf("%s<<\"\\n\\n\";}", stkns[0])
    let l6 = printf("%s<<%s;", stkns[0], stkns[1])
    let l7 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5 . l6 . l7)
    return res
endfunction


function! s:Format2DVectorOut(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s:\\n\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(int r=0;r<%s.size();++r){", a:vecname)
    let l3 = printf("for(int c=0;c<%s[r].size();++c)", a:vecname)
    let l4 = printf("%s<<%s[r][c]<<\"\\t\";", stkns[0], a:vecname)
    let l5 = printf("%s<<\"\\n\\n\";}", stkns[0])
    let l6 = printf("%s<<%s;", stkns[0], stkns[1])
    let l7 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5 . l6 . l7)
    return res
endfunction


function! s:Format2DVectorOutIndexed(vecname, indent, stream_token)
    let stkns = <SID>SelectStreams(a:stream_token)
    let res = []
    let l1 = printf("%s%s<<\"%s:\\n\";", a:indent, stkns[0], a:vecname)
    let l2 = printf("for(int r=0;r<%s.size();++r){%s<<r<<\":\\t\";", a:vecname, stkns[0])
    let l3 = printf("for(int c=0;c<%s[r].size();++c)", a:vecname)
    let l4 = printf("%s<<%s[r][c]<<\"\\t\";", stkns[0], a:vecname)
    let l5 = printf("%s<<\"\\n\\n\";}", stkns[0])
    let l6 = printf("%s<<%s;", stkns[0], stkns[1])
    let l7 = "//FOR_DEBUG"
    call add(res, l1 . l2 . l3 . l4 . l5 . l6 . l7)
    return res
endfunction


function! coding_macros#expand_hash_macro()
    let lineno = line(".")
    let line = getline(".")
    " TODO use double-quote aware split
    let fields = split(line)
    let indent = split(line, '@', 1)[0]
    let aftercol = 100000
    let insert_flag = 0
    if (fields[0] ==# '@for')
        let expanded = printf('%sfor (size_t %s = 0; %s < %s; ++%s) {', indent, fields[1], fields[1], fields[2], fields[1])
        let closing = printf('%s}', indent)
        delete
        call append(lineno - 1, expanded)
        call append(lineno, closing)
    elseif (fields[0] ==# '@ifor')
        let expanded = printf('%sfor (int %s = 0; %s < %s; ++%s) {', indent, fields[1], fields[1], fields[2], fields[1])
        let closing = printf('%s}', indent)
        delete
        call append(lineno - 1, expanded)
        call append(lineno, closing)
    elseif (fields[0] ==# '@afor')
        let expanded = printf('%sfor (auto %s = %s.begin(); %s != %s.end(); ++%s) {', indent, fields[1], fields[2], fields[1], fields[2], fields[1])
        let closing = printf('%s}', indent)
        delete
        call append(lineno - 1, expanded)
        call append(lineno, closing)
    elseif (fields[0] ==# '@av')
        let expanded = printf('%s%s.insert(%s.end(), %s.begin(), %s.end());', indent, fields[1], fields[1], fields[2], fields[2])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]$')
        let expanded = <SID>FormatVarsOut(fields[1:], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]t$')
        let expanded = <SID>FormatVarsTabOut(fields[1:], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]a$')
        if (len(fields) < 3)
            echohl ErrorMsg | echo "Usage: @xa arr_name arr_len" | echohl None
            return
        endif
        let expanded = <SID>FormatArrOut(fields[1], fields[2], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]aa$')
        if (len(fields) < 4)
            echohl ErrorMsg | echo "Usage: @xa arr_name nr nc" | echohl None
            return
        endif
        let expanded = <SID>Format2DArrOut(fields[1], fields[2], fields[3], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]v$')
        let expanded = <SID>FormatVectorOut(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]vi$')
        let expanded = <SID>FormatVectorOutIndexed(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]s$')
        let expanded = <SID>FormatSetOut(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]m$')
        let expanded = <SID>FormatMapOut(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]vv$')
        let expanded = <SID>Format2DVectorOut(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]vvi$')
        let expanded = <SID>Format2DVectorOutIndexed(fields[1], indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (fields[0] =~# '^@[oOeE]delim$')
        let expanded = <SID>FormatDelimOut(indent, fields[0][1])
        delete
        call append(lineno - 1, expanded)
    elseif (match(line, '@vi') != -1)
        let expanded = substitute(line, '@vi', 'vector<int>', '')
        delete
        call append(lineno - 1, expanded)
    elseif (match(line, '@vb') != -1)
        let expanded = substitute(line, '@vb', 'vector<bool>', '')
        delete
        call append(lineno - 1, expanded)
    elseif (match(line, '@vvi') != -1)
        let expanded = substitute(line, '@vvi', 'vector<vector<int>>', '')
        delete
        call append(lineno - 1, expanded)
    elseif (match(line, '@vvb') != -1)
        let expanded = substitute(line, '@vvb', 'vector<vector<bool>>', '')
        delete
        call append(lineno - 1, expanded)
    elseif (match(line, 'if') != -1)
        let indent = split(line, 'i', 1)[0]
        delete
        call append(lineno - 1, indent . 'if () {')
        call append(lineno, indent . '}')
        let aftercol = len(indent) + len('if ()')
        let insert_flag = 1
    elseif (match(line, 'for') != -1)
        let indent = split(line, 'f', 1)[0]
        delete
        call append(lineno - 1, indent . 'for () {')
        call append(lineno, indent . '}')
        let aftercol = len(indent) + len('for ()')
        let insert_flag = 1
    elseif (match(line, 'while') != -1)
        let indent = split(line, 'w', 1)[0]
        delete
        call append(lineno - 1, indent . 'while () {')
        call append(lineno, indent . '}')
        let aftercol = len(indent) + len('while ()')
        let insert_flag = 1
    else
        echohl ErrorMsg | echo "Unknown macro: " . fields[0] | echohl None
        return
    endif
    call cursor(lineno, aftercol)
    if (insert_flag)
        startinsert
    endif
endfunction
