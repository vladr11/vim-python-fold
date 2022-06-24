" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
finish
endif
let b:did_ftplugin = 1

set foldmethod=expr
set foldexpr=PythonFoldExpr(v:lnum)
set foldtext=PythonFoldText()

let b:folded = 1

let g:pythonFoldCollectionLength = get(g:, "pythonFoldCollectionLength", 0)
let g:pythonFoldImportLength = get(g:, "pythonFoldImportLength", 0)

function! ToggleFold()
    if( b:folded == 0 )
        exec "normal! zM"
        let b:folded = 1
    else
        exec "normal! zR"
        let b:folded = 0
    endif
endfunction

function! PythonFoldText()

    let size = 1 + v:foldend - v:foldstart
    if size < 10
        let size = " " . size
    endif
    if size < 100
        let size = " " . size
    endif
    if size < 1000
        let size = " " . size
    endif
    
    if match(getline(v:foldstart), '"""') >= 0
        let text = substitute(getline(v:foldstart), '"""', '', 'g' ) . ' '
    elseif match(getline(v:foldstart), "'''") >= 0
        let text = substitute(getline(v:foldstart), "'''", '', 'g' ) . ' '
    else
        let text = getline(v:foldstart)
    endif
    
    return size . ' lines:'. text . ' '

endfunction

function! PythonFoldExpr(lnum)

	return get(b:foldlevels, a:lnum)

endfunction

" In case folding breaks down
function! ReFold()
    set foldmethod=expr
    set foldexpr=0
    set foldnestmax=1
    set foldmethod=expr
    set foldexpr=PythonFoldExpr(v:lnum)
    set foldtext=PythonFoldText()
    echo 
endfunction

function! _indent_level(lnum)
	return indent(a:lnum) / shiftwidth('$')
endfunction

function! GetFoldLevels(code, collectionFoldLen, importFoldLen)
py3 << EOF
from typing import List, Tuple
import ast
import vim


def get_fold_levels(code: str, collection_fold_len: int = 0, import_fold_len: int = 0) -> List[int]:
    collection_fold_len = int(collection_fold_len)
    import_fold_len = int(import_fold_len)

    module = ast.parse(code)

    levels = [0] * (module.body[-1].end_lineno + 1)

    def parse_node(node: ast.stmt, levels: List[int], level: int):
        if isinstance(node, ast.ClassDef) or isinstance(node, ast.FunctionDef):
            line_range = slice(node.body[0].lineno, node.body[-1].end_lineno + 1)
            levels[line_range] = [level + 1] * (line_range.stop - line_range.start)
            for n in node.body:
                parse_node(n, levels, level + 1)
        elif isinstance(node, ast.List):
            lst_node: ast.List = node
            lst_level = level
            if collection_fold_len > 0 and len(lst_node.elts) > 0:
                lst_range = slice(lst_node.elts[0].lineno, lst_node.elts[-1].lineno + 1)
                len_range = lst_range.stop - lst_range.start
                if len_range >= collection_fold_len:
                    levels[lst_range] = [level + 1] * len_range
                    lst_level = level + 1
            for n in lst_node.elts:
                parse_node(n, levels, lst_level)
        elif isinstance(node, ast.Dict):
            dct_node: ast.Dict = node
            if collection_fold_len > 0 and len(dct_node.keys) > 0:
                dct_range = slice(dct_node.keys[0].lineno, dct_node.values[-1].end_lineno + 1)
                len_range = dct_range.stop - dct_range.start
                if len_range >= collection_fold_len:
                    levels[dct_range] = [level + 1] * len_range
        elif isinstance(node, ast.Tuple):
            tpl_node: ast.Tuple = node
            if collection_fold_len > 0 and len(tpl_node.elts) > 0:
                tpl_range = slice(tpl_node.elts[0].lineno, tpl_node.elts[-1].end_lineno + 1)
                len_range = tpl_range.stop - tpl_range.start
                if len_range >= collection_fold_len:
                    levels[tpl_range] = [level + 1] * len_range
        elif isinstance(node, ast.If):
            if_node: ast.If = node
            parse_node(if_node.body, levels, level)
            for n in if_node.orelse:
                parse_node(n, levels, level)
        elif isinstance(node, ast.For) or isinstance(node, ast.While) or isinstance(node, ast.With):
            for n in node.body:
                parse_node(n, levels, level)
        elif isinstance(node, ast.ImportFrom):
            if import_fold_len > 0:
                imp_node: ast.ImportFrom = node
                imp_range = slice(imp_node.names[0].lineno, imp_node.names[-1].end_lineno + 1)
                len_range = imp_range.stop - imp_range.start
                if len_range >= import_fold_len:
                    levels[imp_range] = [level + 1] * len_range
        elif isinstance(node, ast.Assign):
            parse_node(node.value, levels, level)

    for node in module.body:
        parse_node(node, levels, 0)

    return levels

code = vim.eval("a:code")
collection_fold_len = vim.eval("a:collectionFoldLen")
import_fold_len = vim.eval("a:importFoldLen")

vim.command(f"let l:result={get_fold_levels(code, collection_fold_len, import_fold_len)}")
EOF

	return l:result
endfunction

let b:foldlevels = GetFoldLevels(join(getline(1, "$"), "\n"), g:pythonFoldCollectionLength, g:pythonFoldImportLength)
