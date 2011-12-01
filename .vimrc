" vim:set ts=4 sts=4 sw=4 tw=0: (この行に関しては:help modelineを参照)

"初期処理----------
" バージョンの管理
if v:version < 702
    echoerr 'Error: vimrc: Require the Vim 7.2 or later.'
    finish
endif
for feat in ['multi_byte', 'iconv', 'syntax', 'autocmd']
    if !has(feat)
        echoerr 'Error: vimrc: Require the feature "' . feat . '"'
        finish
    endif
endfor
unlet feat

" Vimの初期処理の管理
if has('vim_starting')
    mapclear
    mapclear!
endif

" augroupの初期化
augroup vimrc
    autocmd!
augroup END

" WindowsかMacかを判断する
let s:chk_win = has('win32') || has('win64')
let s:chk_mac = !s:chk_win && (has('mac') || has('macunix') || has('gui_macvim') || system('uname') =~? '^darwin')

" Windows/Linuxにおいて、.vimとvimfilesの違いを吸収する
if s:chk_win
    let $DOTVIM = $HOME . '/vimfiles'
else
    let $DOTVIM = $HOME . '/.vim'
endif
" Vimで利用するディクショナリファイルや一時ファイルの場所を指定
let $MISCVIM = $HOME . '/misc'

"初期設定----------
" <Leader>に'\'の代わりに'<Space>'を使えるようにする
let mapleader   = ' '
let g:mapleader = ' '
" <Leader>.で即座にvimrcを開けるようにする
nnoremap <Leader>. :<C-u>edit $MYVIMRC<CR>
" autocmdの簡略化
command! -bang -nargs=* AutoCommand autocmd<bang> vimrc <args>
" Lazyコマンドの追加
command! -nargs=+ Lazy call s:cmd_lazy(<q-args>)
function! s:cmd_lazy(q_args)
    if a:q_args == ''
        return
    endif
    if has('vim_starting')
        execute 'autocmd vimrc VimEnter *' a:q_args
    else
        execute a:q_args
    endif
endfunction

set all&
filetype plugin indent off
" 各種プラグインのロード
set rtp+=$DOTVIM/bundle/vim-pathogen/
call pathogen#runtime_append_all_bundles()
try
    call pathogen#helptags()
catch /Duplicate tag/
endtry
" Vi互換ではなくする
set nocompatible
" ファイルタイプの検出、ファイルタイププラグインを使う、インデントファイルを使う
filetype plugin indent on
" ヘルプドキュメントに利用する言語
set helplang=ja,en

"日本語用エンコード設定----------
if s:chk_win
" WindowsはShift_JIS対応
    set encoding=cp932
    set fileencodings=ucs-bom,utf-8,iso-2022-jp,cp932,euc-jp,cp20932
    set fileformats=dos,unix,mac
    source $VIMRUNTIME/delmenu.vim
    set langmenu=menu_ja_jp.cp932.vim
    source $VIMRUNTIME/menu.vim
else
" Windows以外はUtf8対応
    set encoding=utf-8
    set fileencodings=ucs-bom,utf-8,iso-2022-jp,cp932,euc-jp,cp20932
    set fileformats=unix,dos,mac
    source $VIMRUNTIME/delmenu.vim
    set langmenu=menu_ja_jp.utf-8.vim
    source $VIMRUNTIME/menu.vim
endif

" modeline内にfencを指定されている場合の対応
let s:oldlang=v:lang
AutoCommand BufEnter * silent call <SID>DoModelineFileEncoding()
function! s:DoModelineFileEncoding()
    if &modified == 0 || &fileencoding == '' || v:cmdbang
        return
    endif
    silent lang mes C
    redir => line
    silent verbose set fenc?
    redir END
    exe "lang mes ".s:oldlang
    if split(line, "\n")[-1] =~ "modeline"
        exe "edit! ++bad=keep ++enc=".&fileencoding
        doautocmd BufEnter
    endif
endfunction

" 文字コードを指定して開き直す
command! -bang -bar -complete=file -nargs=? Utf8 edit<bang> ++enc=utf-8 <args>
command! -bang -bar -complete=file -nargs=? Jis  edit<bang> ++enc=iso-2022-jp <args>
command! -bang -bar -complete=file -nargs=? Sjis edit<bang> ++enc=cp932 <args>
command! -bang -bar -complete=file -nargs=? Euc  edit<bang> ++enc=euc-jp <args>

"プラットフォーム依存の問題の為の設定----------
" ファイル名に大文字小文字の区別がないシステム用の設定
if filereadable($VIM . '/vimrc') && filereadable($VIM . '/ViMrC')
    set tags=./tags,tags
endif

" コンソール版で環境変数$DISPLAYが設定されていると起動が遅くなる件へ対応
if !has('gui_running') && has('xterm_clipboard')
    set clipboard=exclude:cons\\\|linux\\\|cygwin\\\|rxvt\\\|screen
endif

" WinではPATHに$VIMが含まれていないときにexeを見つけ出せないので修正
if s:chk_win && $PATH !~? '\(^\|;\)' . escape($VIM, '\\') . '\(;\|$\)'
    let $PATH = $VIM . ';' . $PATH
endif

" Macではデフォルトの'iskeyword'がcp932に対応しきれていないので修正
if s:chk_mac
    set iskeyword=@,48-57,_,128-167,224-235
endif

" Vimで編集したファイルをMacのQuickLookで見られるようにする
AutoCommand BufWritePost * call SetUTF8Xattr(expand("<afile>"))
function! SetUTF8Xattr(file)
    let isutf8 = &fileencoding == "utf-8" || ( &fileencoding == "" && &encoding == "utf-8")
    if s:chk_mac
        call system("xattr -w com.apple.TextEncoding 'utf-8;134217984' '" . a:file . "'")
    endif
endfunction

" helptagsの生成
helptags $DOTVIM/doc
set notagbsearch

"IME切り替えの為の設定----------
if has('multi_byte_ime')
    highlight CursorIM guibg=Purple guifg=NONE
    set iminsert=0 imsearch=0
endif

"GUI固有ではない画面表示の設定----------
if !has('gui_running')
    colorscheme miku
endif
" 画面表示に関する設定
set guioptions=gip
" 構文強調表示を有効にする
if &t_Co > 2 || has("gui_running")
    syntax enable
    set hlsearch
endif
" 長い行についての折り返し
set wrap
" 現在のモードの表示
set showmode
" 行番号の表示
set nonumber
" カーソルが何行目何列目にあるかの表示
set noruler

" タイトル
" ウィンドウのタイトルの表示
set title

" ステータスライン
" ステータスラインの表示
set statusline=%<%{expand('%:p')}\ %m%r%h%w%=%{exists('*SkkGetModeStr')?SkkGetModeStr():''}%{'['.(&fenc!=''?&fenc:&enc).':'.&ff.']['.&ft.']'}(%l/%L)[%{tabpagenr()}/%{tabpagenr('$')}]
" タブページのラベルの表示
set showtabline=0
" ステータス行の表示
set laststatus=2
" コマンドラインに使われる画面上の行数
set cmdheight=1
" コマンドを画面最下行の表示
set showcmd
" コマンドラインにメッセージが表示される閾値
set report=1
" Insertモード時にステータスラインの色を変更
let g:hi_insert = 'highlight StatusLine gui=reverse cterm=reverse'
AutoCommand InsertEnter * call s:StatusLine('Enter')
AutoCommand InsertLeave * call s:StatusLine('Leave')
let s:slhlcmd = ''
function! s:StatusLine(mode)
    if a:mode == 'Enter'
        silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
        silent exec g:hi_insert
    else
        highlight clear StatusLine
        silent exec s:slhlcmd
    endif
endfunction
function! s:GetHighlight(hi)
    redir => hl
    exec 'highlight '.a:hi
    redir END
    let hl = substitute(hl, '[\r\n]', '', 'g')
    let hl = substitute(hl, 'xxx', '', '')
    return hl
endfunction

" GUI
" ビープ音にビジュアルベルの使用
set visualbell
" Vimを終了したときにコンソール画面を復元しない
set norestorescreen
set t_ti=
set t_te=

" カーソル
" Insertモードでautoindent、改行を超えたバックスペースの設定
set backspace=2

" 非表示文字
" タブ文字や行末の表示
set list
" タブ文字や行末に表示する文字の指定
set listchars=tab:>_,extends:>,precedes:<,eol:_,trail:~
" ステータス行と垂直分割の区切りを埋める文字の指定
set fillchars=stl:\ ,stlnc::,vert:\ ,fold:-,diff:-
" 全角スペースの表示
scriptencoding utf-8
AutoCommand VimEnter,BufEnter * call ZenkakuSpace()
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=underline ctermbg=2 gui=underline guibg=#2f4f4f
    silent! match ZenkakuSpace /　/
endfunction

" スクロール
" CTRL-UやCTRL-Dでスクロールする行数
set scroll=5
" <C-f>、<C-b>でスムーススクロールをする
let g:scroll_factor = 5000
let g:scroll_skip_line_size = 4
noremap <C-f> :call SmoothScroll("d",1, 1)<CR>
noremap <C-b> :call SmoothScroll("u",1, 1)<CR>
function! SmoothScroll(dir, windiv, factor)
    if &cursorline == 1
        set nocursorline
        let cursorline_changed_flag = 1
    else
        let cursorline_changed_flag = 0
    end
    let wh=winheight(0)
    let i=0
    let j=0
    while i < wh / a:windiv
        let t1=reltime()
        let i = i + 1
        if a:dir=="d"
            if line('w$') == line('$')
                break
            endif
            exec "normal \<C-E>j"
        else
            if line('w0') == 1
                break
            endif
            exec "normal \<C-Y>k"
        end
        if j >= g:scroll_skip_line_size
            let j = 0
            redraw
            while 1
                let t2=reltime(t1,reltime())
                if t2[1] > g:scroll_factor * a:factor
                    break
                endif
            endwhile
        else
            let j = j + 1
        endif
    endwhile
    if cursorline_changed_flag == 1
        set cursorline
    end
endfunction

" 括弧
" 対応する括弧へのジャンプ
set showmatch
" 対応する括弧にジャンプする時間
set matchtime=3
" ジャンプ中に文字を入力する際のカーソルの移動
set cpoptions& cpoptions-=m
" 対応する括弧のペアの追加
set matchpairs& matchpairs+=<:>

" 折り畳み
" 折り畳みの設定
set foldenable
" マーカーでの折り畳みの指定
set foldmethod=marker
" 折り畳みの表示
set foldcolumn=0
" 行頭で h を押すと選択範囲に含まれるfoldを閉じる
vnoremap <expr> h col('.') == 1 && foldlevel(line('.')) > 0 ? 'zcgv' : 'h'
" 折畳上で l を押すと選択範囲に含まれるfoldを開く
vnoremap <expr> l foldclosed(line('.')) != -1 ? 'zogv0' : 'l'
" 現在のfoldのみ開いた状態にする
nnoremap z<Space> :<C-u>call <SID>fold_current_expand()<CR>
function! s:fold_current_expand()
    silent! %foldclose!
    normal! zvzz
endfunc

" カレントウィンドウにのみ罫線を引く
AutoCommand WinLeave * set nocursorline
AutoCommand WinEnter,BufRead * set cursorline

" misc
" マルチバイト文字の幅の扱いの指定
set ambiwidth=double
" Diffモード用の設定
set diffopt=filler,vertical
" ヘルプ用言語の設定
set helplang=ja,en
" 行連結コマンドにおいての空白の挿入
set nojoinspaces

"マウスに関する設定----------
if has('mouse')
    set mouse=a
    set guioptions+=a
    set ttymouse=xterm
endif
" ダブルクリックで指定単語をハイライトする
nnoremap <2-LeftMouse> g*

"編集に関する設定----------
" インデント
" 新しい行を開始したときに新しい行のインデントの設定
set autoindent
set smartindent
" Insertモードでタブ文字を挿入するときの空白の設定
set expandtab
set smarttab
set tabstop=8
set softtabstop=4
set shiftwidth=4
" インデントをshiftwidthの値の整数倍にまとめる設定
set shiftround

" 補完
" キーワード補完にディクショナリーファイルを追加
set complete& complete=.,w,b,u,t,k
AutoCommand FileType * execute printf("setlocal dict=$MISCVIM/dict/%s.dict", &filetype)
" コマンドライン補完を拡張モードで行う設定
set wildmenu
set wildmode=full
set wildchar=<Tab>
" Insertモード補完のポップアップに表示される項目数の最大値
set pumheight=20

" テンプレート
" 拡張子awkのファイルを作成した場合にテンプレートを読み込む設定
AutoCommand BufNewFile *.awk 0r $MISCVIM/template/awk.template
" 拡張子javaのファイルを作成した場合にテンプレートを読み込む設定
AutoCommand BufNewFile *.java 0r $MISCVIM/template/java.template
" 拡張子kshのファイルを作成した場合にテンプレートを読み込む設定
AutoCommand BufNewFile *.ksh 0r $MISCVIM/template/ksh.template
" 拡張子perlのファイルを作成した場合にテンプレートを読み込む設定
AutoCommand BufNewFile *.pl 0r $MISCVIM/template/perl.template

" スワップファイル
set noswapfile
set updatecount=0
if has('unix')
    set nofsync
    set swapsync=
endif

" バックアップファイル
set nobackup
set backupdir=$DOTVIM/tmp/backup

" 無限Undo
if v:version > 702
    set undofile
    set undodir=$DOTVIM/tmp/undo
endif

" vimfinfo
set viminfo+=n$DOTVIM/tmp/_viminfo

" misc
" バッファを放棄したときのファイルの開放の設定
set hidden
" フォーマットオプションの設定
set formatoptions& formatoptions+=mM
" 数の増減に関する設定
set nrformats& nrformats=alpha,hex
" grepで利用するプログラム
set grepprg=internal
" クリップボードに利用するレジスタの設定
set clipboard& clipboard+=unnamed,autoselect
" YをDやPに合わせる
nnoremap Y y$
" zip、jar、xpiファイルを直接読み書きすることを可能にする設定
AutoCommand BufReadCmd *.jar,*.xpi call zip#Browse(expand("<amatch>"))
" コメント行で改行した場合、自動でコメントアウトしない
AutoCommand FileType * setl formatoptions-=ro

" カレントディレクトリをファイルと同じディレクトリに移動
AutoCommand BufEnter * execute ":silent! lcd " . escape(expand("%:p:h"), ' ')

" QuickFixウィンドウで、lで指定行を開く
AutoCommand FileType qf nnoremap <buffer> l <CR>

" 縦に連番の入力
nnoremap <silent> co :ContinuousNumber <C-a><CR>
vnoremap <silent> co :ContinuousNumber <C-a><CR>
command! -count -nargs=1 ContinuousNumber let c = col('.')|for n in range(1, <count>?<count>-line('.'):1)|exec 'normal! j' . n . <q-args>|call cursor('.', c)|endfor

" 現在編集中のバッファのファイル名の変更
command! -nargs=+ -bang -complete=file Rename let pbnr=fnamemodify(bufname('%'), ':p')|exec 'f '.escape(<q-args>, ' ')|w<bang>|call delete(pbnr)

" ウィンドウを閉じずにファイルを削除する
command! -bar -bang -complete=file -nargs=+ Delete call s:cmd_del_file([<f-args>], <bang>0)
function! s:cmd_del_file(args, delete_buffer)
    if empty(a:args)
        return
    endif
    for arg in a:args
        for file in split(expand(arg), '\n')
            let file = resolve(file)
            let bufnr = bufnr(file)
            let type = getftype(file)
            if type ==# 'file'
                let success = 0
                if delete(file) !=# success
                    call s:warn("Can't delete '" . file . "'")
                    continue
                endif
            elseif type ==# 'dir'
            else
                redraw
                call s:warn(file . ": Unknown file type '" . type . "'.")
            endif
            if a:delete_buffer && bufnr != -1
                if bufnr == bufnr('%')
                    enew
                endif
                execute bufnr 'bwipeout'
            endif
        endfor
    endfor
    checktime
endfunction
function! s:warn(msg)
    try
        echohl WarningMsg
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction

" 存在しないディレクトリの自動作成
AutoCommand BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (a:force ||
    \    input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
        call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
endfunction

" 使い捨て用のファイルの生成
nnoremap <Leader>j :<C-u>JunkFile<CR>
command! -nargs=0 JunkFile call s:open_junk_file()
function! s:open_junk_file()
    let l:junk_dir = $MISCVIM . '/junk'
    if !isdirectory(l:junk_dir)
        call mkdir(l:junk_dir, 'p')
    endif
    let l:filename = input('Junk Code: ', l:junk_dir.strftime('/%Y-%m-%d_'))
    if l:filename != ''
        execute 'edit ' . l:filename
    endif
endfunction

" コマンドの出力のキャプチャ
command! -nargs=+ -complete=command Capture call s:cmd_capture(<q-args>)
function! s:cmd_capture(q_args)
    redir => output
    silent execute a:q_args
    redir END
    let output = substitute(output, '^\n\+', '', '')
    belowright new
    silent file `=printf('[Capture: %s]', a:q_args)`
    setlocal buftype=nofile bufhidden=unload noswapfile nobuflisted
    call setline(1, split(output, '\n'))
endfunction

" 開いているファイル内の関数へジャンプする
nnoremap go :<C-u>copen<CR>
nnoremap gc :<C-u>cclose<CR>
nnoremap g<Space> :<C-u>call Navi()<CR>
function! Navi()
    if &ft ==? "c" || &ft ==? "cpp"
        vimgrep /^[^ \t#/\\*]\+[0-9A-Za-z_ :\t\\*]\+([^;]*$/j %
    elseif &ft ==? "perl"
        vimgrep /^\s*sub\s/j %
    elseif &ft ==? "ruby"
        vimgrep /^\s*\(class\|module\|def\|alias\)\s/j %
    elseif &ft ==? "python"
        vimgrep /^\s*\(class\|def\)\s/j %
    elseif &ft ==? "javascript"
        vimgrep /^\s*function\s\|[a-zA-Z_$][a-zA-Z0-9_$]*\s*[=:]\s*function\s*(/j %
    elseif &ft ==? "sh"
        vimgrep /^\s*\(\h\w*\s*()\|function\s\+\h\w*\)/j %
    elseif &ft ==? "html"
        vimgrep /\c^\s*\(<h[1-6]\|<head\|<body\|<form\)/j %
    elseif &ft ==? ""
        "Text ( 1. 2. ,etc )
        vimgrep /^\s*\d\+\./j %
    elseif &ft ==? "java"
        vimgrep /^\s*[^#/\*=]\+[0-9a-zA-Z_ \t\*,.()]\+{[^;]*$/j %
    elseif &ft ==? "diff"
        "diff (unified format)
        vimgrep /^@@[0-9 \t,+-]\+@@$/j %
    else
        echo "This filetype is not supported."
    endif
    cw
endfunction

" タブページ毎のカレントディレクトリの設定
nnoremap tcd :<C-u>TabpageCD %:p:h<CR>
command! -bar -complete=dir -nargs=? CD TabpageCD <args>
command! -bar -complete=dir -nargs=? TabpageCD execute 'cd' fnameescape(expand(<q-args>)) | let t:cwd = getcwd()
AutoCommand TabEnter *
\ if exists('t:cwd') && !isdirectory(t:cwd)
\| unlet t:cwd
\| endif
\| if !exists('t:cwd')
\| let t:cwd = getcwd()
\| endif
\| execute 'cd' fnameescape(expand(t:cwd))

"検索に関する設定----------
" インクリメンタルサーチ
set incsearch
" 大文字と小文字の区別
set ignorecase
" 大文字を含んでいた場合ignorecaseを上書きする設定
set smartcase
" 検索がファイル末尾まで進んだらファイル先頭から再び検索する設定
set wrapscan
" 検索パターン入力中は/で\/を入力する設定
cnoremap <expr> / getcmdtype() == '/' ? '\/' : '/'
" 検索パターン入力中は?で\?を入力する設定
cnoremap <expr> ? getcmdtype() == '?' ? '\?' : '?'
" fを利用するときにIMEをオフにする
nnoremap <silent> f :<C-u>set iminsert=0<CR>f
nnoremap <silent> F :<C-u>set iminsert=0<CR>F
" <Leader>の2回押しでハイライト消去
nnoremap <silent> <Leader><Leader> :<C-u>nohlsearch<CR><ESC>
" vimgrepでの検索後、QuickFixウィンドウを開く
augroup grepopen
    autocmd!
    autocmd QuickFixCmdPost vimgrep cw
augroup END

"バイナリの編集に関する設定----------
augroup BinaryXXD
    autocmd!
    autocmd BufReadPre   *.bin let &binary =1
    autocmd BufReadPost  * if &binary | silent %!xxd -g 1
    autocmd BufReadPost  * set ft=xxd | endif
    autocmd BufWritePre  * if &binary | %!xxd -r | endif
    autocmd BufWritePost * if &binary | silent %!xxd -g 1
    autocmd BufWritePost * set nomod | endif
augroup END

"差分に関する設定----------
" 現バッファの差分表示
command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
" ファイルまたはバッファ番号を指定して差分表示し、#なら裏バッファと比較
command! -nargs=? -complete=file Diff if '<args>'=='' | browse vertical diffsplit|else| vertical diffsplit <args>|endif

"Sticky Shift----------
let g:sticky_us_keyboard = 0
inoremap <expr> ; <SID>sticky_func()
cnoremap <expr> ; <SID>sticky_func()
snoremap <expr> ; <SID>sticky_func()
function! s:sticky_func()
    let l:sticky_table = {
        \'0' : {
            \'1' : '!', '2' : '"', '3' : '#', '4' : '$', '5' : '%',
            \'6' : '&', '7' : "'", '8' : '(', '9' : ')', '0' : '|',
            \'-' : '=', '^' : '~',
            \'@' : '`', '[' : '{',
            \';' : '+', ':' : '*', ']' : '}',
            \',' : '<', '.' : '>', '/' : '?', '\' : '_',
        \},
        \'1' : {
            \'1' : '!', '2' : '@', '3' : '#', '4' : '$', '5' : '%',
            \'6' : '^', '7' : "&", '8' : '*', '9' : '(', '0' : ')',
            \'`' : '~', '-' : '_', '=' : '+',
            \'[' : '{', ']' : '}', '\' : '|',
            \';' : ':', "'" : '"',
            \',' : '<', '.' : '>', '/' : '?',
        \}
    \}
    let l:special_table = {
        \"\<ESC>" : "\<ESC>", "\<Space>" : ';', "\<CR>" : ";\<CR>"
    \}

    let l:key = getchar()
    if nr2char(l:key) =~ '\l'
        return toupper(nr2char(l:key))
    elseif has_key(get(l:sticky_table, g:sticky_us_keyboard), nr2char(l:key))
        return get(l:sticky_table, g:sticky_us_keyboard)[nr2char(l:key)]
    elseif has_key(l:special_table, nr2char(l:key))
        return l:special_table[nr2char(l:key)]
    else
        return ''
    endif
endfunction

"マップ定義 - Normalモード----------
" Window関係
set splitbelow
set splitright
" デフォルトの最小ウィンドウの高さ
set winminheight=0
" <C-w><Space>または<Tab>で次のウィンドウに移動する
nnoremap <C-w><Space> <C-w>w
nnoremap <Tab> <C-w>w<C-w>_
" 画面を再描画する
nnoremap <C-z> <C-l>
" sを利用しない
nnoremap s <Nop>

" 画面分割用のキーマップ
nmap <C-w>sj <SID>(split-to-j)
nmap <C-w>sk <SID>(split-to-k)
nmap <C-w>sh <SID>(split-to-h)
nmap <C-w>sl <SID>(split-to-l)

nnoremap <SID>(split-to-j) :<C-u>execute 'belowright' (v:count == 0 ? '' : v:count) 'split'<CR><C-w>_
nnoremap <SID>(split-to-k) :<C-u>execute 'aboveleft'  (v:count == 0 ? '' : v:count) 'split'<CR><C-w>_
nnoremap <SID>(split-to-h) :<C-u>execute 'topleft'    (v:count == 0 ? '' : v:count) 'vsplit'<CR>
nnoremap <SID>(split-to-l) :<C-u>execute 'botright'   (v:count == 0 ? '' : v:count) 'vsplit'<CR>

" ウィンドウの入れ替え
nnoremap [Swap] <Nop>
nnoremap <C-s> <Nop>
nmap <C-s> [Swap]

nmap [Swap]<C-n> <SID>swap_window_next
nmap [Swap]<C-p> <SID>swap_window_prev
nmap [Swap]<C-j> <SID>swap_window_j
nmap [Swap]<C-k> <SID>swap_window_k
nmap [Swap]<C-h> <SID>swap_window_h
nmap [Swap]<C-l> <SID>swap_window_l

nnoremap <silent> <SID>swap_window_next :<C-u>call <SID>swap_window_count(v:count1)<CR>
nnoremap <silent> <SID>swap_window_prev :<C-u>call <SID>swap_window_count(-v:count1)<CR>
nnoremap <silent> <SID>swap_window_j    :<C-u>call <SID>swap_window_dir(v:count1, 'j')<CR>
nnoremap <silent> <SID>swap_window_k    :<C-u>call <SID>swap_window_dir(v:count1, 'k')<CR>
nnoremap <silent> <SID>swap_window_h    :<C-u>call <SID>swap_window_dir(v:count1, 'h')<CR>
nnoremap <silent> <SID>swap_window_l    :<C-u>call <SID>swap_window_dir(v:count1, 'l')<CR>
nnoremap <silent> <SID>swap_window_t    :<C-u>call <SID>swap_window_dir(v:count1, 't')<CR>
nnoremap <silent> <SID>swap_window_b    :<C-u>call <SID>swap_window_dir(v:count1, 'b')<CR>

function! s:modulo(n, m)
    let d = a:n * a:m < 0 ? 1 : 0
    return a:n + (-(a:n + (0 < a:m ? d : -d)) / a:m + d) * a:m
endfunction
function! s:swap_window_count(n)
    let curwin = winnr()
    let target = s:modulo(curwin + a:n - 1, winnr('$')) + 1
    call s:swap_window(curwin, target)
endfunction
function! s:swap_window_dir(n, dir)
    let curwin = winnr()
    execute a:n 'wincmd' a:dir
    let targetwin = winnr()
    wincmd p
    call s:swap_window(curwin, targetwin)
endfunction
function! s:swap_window(curwin, targetwin)
    let curbuf = winbufnr(a:curwin)
    let targetbuf = winbufnr(a:targetwin)
    if curbuf == targetbuf
    else
        execute 'hide' targetbuf . 'buffer'
        execute a:targetwin 'wincmd w'
        execute curbuf 'buffer'
    endif
endfunction

" Buffer関係
" Hで前のバッファを表示
nnoremap H :bprevious<CR>
" Lで次のバッファを表示
nnoremap L :bnext<CR>
" <Leader>bで現在のバッファを表示
nnoremap <Leader>b :<C-u>buffers<CR>

" Tab関係
" <C-p>、<C-n>でタブを移動
nnoremap <C-p> :tabprevious<CR>
nnoremap <C-n> :tabnext<CR>
nnoremap [Tabbed] <Nop>
nnoremap <C-t> <Nop>
nmap <C-t> [Tabbed]

nnoremap <silent> [Tabbed]s       :<C-u>tabs<CR>
nnoremap <silent> [Tabbed]n       :<C-u>tabnext<CR>
nnoremap <silent> [Tabbed]<Space> :<C-u>tabnext<CR>
nnoremap <silent> [Tabbed]p       :<C-u>tabprevious<CR>
nnoremap <silent> [Tabbed]c       :<C-u>tabnew<CR>
nnoremap <silent> [Tabbed]k       :<C-u>tabclose<CR>
nnoremap <silent> [Tabbed]o       :<C-u>tabonly<CR>
nnoremap <silent> [Tabbed]r       :<C-u>TabRecent<Space>
nnoremap <silent> [Tabbed]l       :<C-u>execute 'tabmove' min([tabpagenr() + v:count1 - 1, tabpagenr('$')])<CR>
nnoremap <silent> [Tabbed]h       :<C-u>execute 'tabmove' max([tabpagenr() - v:count1 - 1, 0])<CR>
" GNU screen風にタブを移動
for i in range(10)
    execute 'nnoremap <silent>' ('[Tabbed]'.(i))  ((i).'gt')
endfor
unlet i
" 現在編集中のバッファをタブに切り出す
nnoremap <silent> [Tabbed]l :<C-u>call <SID>move_window_into_tab_page(0)<CR>
function! s:move_window_into_tab_page(target_tabpagenr)
    if a:target_tabpagenr < 0
        return
    endif
    let original_tabnr = tabpagenr()
    let target_bufnr   = bufnr('')
    let window_view    = winsaveview()
    if a:target_tabpagenr == 0
        tabnew
        tabmove
        execute target_bufnr 'buffer'
        let target_tabpagenr = tabpagenr()
    else
        execute a:target_tabpagenr 'tabnext'
        let target_tabpagenr = a:target_tabpagenr
        topleft new
        execute target_bufnr 'buffer'
    endif
    call winrestview(window_view)
    execute original_tabnr 'tabnext'
    if 1 < winnr('$')
        close
    else
        enew
    endif
    execute target_tabpagenr 'tabnext'
endfunction

" 移動関係
" 最後に編集された位置に移動
nnoremap gb '[
nnoremap gp ']
" 最後に変更されたテキストを選択
nnoremap gl  `[v`]
vnoremap gl :<C-u>normal gc<Enter>
onoremap gl :<C-u>normal gc<Enter>

" help関係
" <C-h>でヘルプを実行
nnoremap <C-h> :<C-u>help<Space>
" カーソル下のキーワードでヘルプを実行
nnoremap <silent> g<C-h> :<C-u>help<Space><C-r><C-w><CR>
" ヘルプのgrep
nnoremap grh :<C-u>Hg<Space>

" misc
" ファイルタイプを変更
nmap <Leader>ew :<C-u>setlocal fileformat=dos<CR>
nmap <Leader>ea :<C-u>setlocal fileformat=mac<CR>
nmap <Leader>eu :<C-u>setlocal fileformat=unix<CR>

"マップ定義 - Visualモード----------
" <CR>をchangeにする
xnoremap <CR> c
" <Tab>をindentにする
xnoremap <Tab> >
" <S-Tab>をunindentにする
xnoremap <S-Tab> <
" Visualモードの*で選択範囲を検索
vnoremap <silent> * "vy/\V<C-r>=substitute(escape(@v,'\/'),"\n",'\\n','g')<CR><CR>
"ビジュアルモード時vで行末まで選択
vnoremap v $h

"マップ定義 - Insertモード----------
" <C-t>をTabにする
inoremap <C-t> <C-v><Tab>
" <C-d>をDelにする
inoremap <C-d> <Del>
" <C-v>でクリップボードの内容を貼り付け
imap <C-v> <Esc>"*pa
" <C-a>で先頭に移動
inoremap <silent><C-a> <C-o>^
" <C-e>で最後に移動
inoremap <silent><C-e> <C-o>$
" <A-h>で前文字に移動
inoremap <A-h> <Left>
" <A-l>で次文字に移動
inoremap <A-l> <Right>
" <A-k>で前行に移動
inoremap <A-k> <Up>
" <A-j>で次行に移動
inoremap <A-j> <Down>
" <C-u>でundoする
inoremap <C-u> <C-g>u<C-u>
inoremap <C-w> <C-g>u<C-w>
" ]を入力した際に、対応する括弧が見つからない場合は補完キーとする
inoremap <expr> ] searchpair('\[', '', '\]', 'nbW', 'synIDattr(synID(line("."), col("."), 1), "name") =~? "String"') ? ']' : "\<C-n>"
" <C-]>でオムニ補完を利用
inoremap <C-]> <C-x><C-o>

"マップ定義 - Command-lineモード----------
" <C-d>をDelにする
cnoremap <C-d> <Del>
" <C-a>で先頭に移動
cnoremap <C-a> <Home>
" <C-e>で最後に移動
cnoremap <C-e> <End>
" <C-n>, <C-p>でコマンド履歴
cnoremap <C-n> <Down>
cnoremap <Down> <C-n>
cnoremap <C-p> <Up>
cnoremap <Up> <C-p>
" <C-q>でコマンド履歴を表示
cnoremap <C-q> <C-f>
" <C-l>で補完履歴をリスト
cnoremap <C-l> <C-d>
" <A-h>で前の言葉に移動
cnoremap <A-h> <S-Left>
" <A-l>で次の言葉に移動
cnoremap <A-l> <S-Right>

"マップ定義 - レジスタ用キーマップ----------
" <Leader>mでマーク内容を確認
nnoremap <Leader>m :<C-u>marks<CR>
" <Leader>qでレジスタ内容を確認
nnoremap <Leader>q :<C-u>registers<CR>

"Plug-in用設定----------
" netrw用設定
" hで上のディレクトリに移動、lでディレクトリを展開もしくはファイルを開く
AutoCommand FileType netrw nmap <buffer> h -
AutoCommand FileType netrw nmap <buffer> l <CR>
" 常にtree view
let g:netrw_liststyle = 3
" 'v'でファイルを開くときは右側に開く。
let g:netrw_altv = 1
" 'o'でファイルを開くときは下側に開く。
let g:netrw_alto = 1

" skk.vim用設定
let g:skk_jisyo              = $MISCVIM . '/dict/_skk-jisyo'
let g:skk_large_jisyo        = $MISCVIM . '/dict/SKK-JISYO.L'
let g:skk_select_cand_keys   = "ASDFGHJKL"
let g:skk_egg_like_newline   = 1
let g:skk_marker_white       = "'"
let g:skk_marker_black       = "\""
let g:skk_use_color_cursor   = 1
let g:skk_cursor_hira_color  = "Purple"
let g:skk_cursor_kata_color  = "Purple"
let g:skk_cursor_zenei_color = "Purple"
let g:skk_cursor_ascii_color = "Purple"
let g:skk_sticky_key         = ';'
let g:skk_auto_save_jisyo    = 1

" unite.vim用設定
let g:unite_data_directory      = $DOTVIM . '/unite'
let g:unite_enable_start_insert = 1
let g:unite_winheight           = 20
let g:unite_winwidth            = 32
let g:unite_source_file_mru_time_format = '(%Y/%m/%d %H:%M:%S) '
let g:unite_source_directory_mru_time_format = '(%Y/%m/%d %H:%M:%S) '
let g:unite_source_session_enable_auto_save = 0
" The prefix key.
nnoremap [unite] <Nop>
nnoremap <C-u> <Nop>
nmap <C-u> [unite]

nnoremap [unite]<Space>        :<C-u>Unite<Space>
nnoremap <silent> [unite]<C-u> :<C-u>UniteWithCurrentDir -buffer-name=files buffer file_mru bookmark file<CR>
nnoremap <silent> [unite]e     :<C-u>Unite -buffer-name=files -vertical -no-quit -no-start-insert file<CR>
nnoremap <silent> [unite]c     :<C-u>Unite command<CR>
nnoremap <silent> [unite]t     :<C-u>Unite -immediately tab:no-current<CR>
nnoremap <silent> [unite]w     :<C-u>Unite -immediately window:no-current<CR>
nnoremap <silent> [unite]f     :<C-u>Unite -buffer-name=files file<CR>
nnoremap <silent> [unite]y     :<C-u>Unite -buffer-name=register register<CR>
nnoremap <silent> [unite]l     :<C-u>Unite line<CR>
nnoremap <silent> [unite]s     :<C-u>Unite source<CR>
nnoremap <silent> [unite]b     :<C-u>Unite buffer_tab<CR>
nnoremap <silent> [unite]g     :<C-u>Unite grep<CR>

AutoCommand FileType unite call s:unite_my_settings()
function! s:unite_my_settings()
    highlight link uniteSource__FileMru_Time Pmenu
    nmap <buffer> <ESC>          <Plug>(unite_exit)
    imap <buffer> <silent> <C-c> <Plug>(unite_exit)
    imap <buffer> jj             <Plug>(unite_insert_leave)<Plug>(unite_loop_cursor_down)
    imap <buffer> kk             <Plug>(unite_insert_leave)<Plug>(unite_loop_cursor_up)
    nmap <buffer> <silent> <C-n> <Plug>(unite_loop_cursor_down)
    nmap <buffer> <silent> <C-p> <Plug>(unite_loop_cursor_up)
    nmap <buffer> <silent> <C-u> <Plug>(unite_append_end)<Plug>(unite_delete_backward_line)
    imap <buffer> <silent> <C-w> <Plug>(unite_delete_backward_path)
    nnoremap <silent> <buffer> <expr> <C-J> unite#do_action('right')
    call unite#set_substitute_pattern('files', '\*\*\+', '*', -1)
    call unite#set_substitute_pattern('files', '^@', substitute(substitute($MISCVIM,  '\\', '/', 'g'), ' ', '\\\\ ', 'g'), -100)
    " デフォルトでは ignorecase と smartcase を使う
    call unite#set_buffer_name_option('default', 'ignorecase', 1)
    call unite#set_buffer_name_option('default', 'smartcase', 1)
    " ファイル選択時は smartcase を使わない
    call unite#set_buffer_name_option('files', 'smartcase', 0)
endfunction

" vim-quickrun用設定
nnoremap qr :<C-u>QuickRun<Space>-args<Space>
let g:quickrun_config = {'runmode': 'async:remote:vimproc'}
" Windows用Perl設定
if executable('Perl') && s:chk_win
    let g:quickrun_config.perl = {'output_encode': 'cp932'}
endif

set secure
