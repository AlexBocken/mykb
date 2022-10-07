# Vim-Wiki

## TL;DR - keybindings

- `<Leader>ww` -- Open default wiki index file.
- `<Leader>wt` -- Open default wiki index file in a new tab.
- `<Leader>ws` -- Select and open wiki index file.
- `<Leader>wd` -- Delete wiki file you are in.
- `<Leader>wr` -- Rename wiki file you are in.
- `<Enter>` -- Follow/Create wiki link.
- `<Shift-Enter>` -- Split and follow/create wiki link.
- `<Ctrl-Enter>` -- Vertical split and follow/create wiki link.
- `<Backspace>` -- Go back to parent(previous) wiki link.
- `<Tab>` -- Find next wiki link.
- `<Shift-Tab>` -- Find previous wiki link.


## General

Vim wiki is a vim plugin making it possible to effectivly keep wiki-style knowledge sorted on your local machine.
The single pages are written in Markdown and are interlinked.
It can further be used as a Diary or to manage TODO lists, and to export the whole wiki in to a website, meaning single HTML files, which are interlinked and can be published.
Since every entry is a simple markdown file, this makes it easy to collaborate on a common wiki using git.

### Installation

The vim-wiki plugin can be installed like every vim plugin.
To test if the installation was successful, execute `:VimwikiIndex` in the command prompt of vim.
You have to add the following lines to your `.vimrc`, irrespective of the installation method used.
```vim
set nocompatible
filetype plugin on
syntax on
```

#### [Vim-Plug](https://github.com/junegunn/vim-plug)

Add `Plug 'vimwiki/vimwiki'` to the Plug-Section of your `init.vim` or `.vimrc`.
Afterwords run `:PlugInstall` in the command prompt of vim.

#### [Pathogen](https://www.vim.org/scripts/script.php?script_id=2332)

Go to your vim config folder and clone the vimwiki gitHub repository into the `bundle` folder.
```sh
cd $CONFIG/vim
mkdir bundle
cd bundle
git clone https://github.com/vimwiki/vimwiki.git
```
Afterwords run `:Helptags` in the command prompt of vim.

#### [Vundle](https://github.com/VundleVim/Vundle.vim)

Add `Plugin 'vimwiki/vimwiki'` to the `init.vim` or `.vimrc`.
Afterwords run `vim +PluginInstall +qall` in the shell to install it.

## Install of the mykb - vimwiki

To install the _mykb_ version of vimwiki, clone [https://github.com/AlexBocken/mykb](https://github.com/AlexBocken/mykb) in to the folder of your preference and add
```
let g:vimwiki_list = [{'path': '/PATH/TO/DIRECTORY/mykb', 'syntax': 'markdown', 'ext': '.md'}]
```
to your `.vimrc`.
To make the usage more userfriendly, add
```
alias mykb='nvim /PATH/index.md`
```
to your aliases. To then open it, just run `mykb`.


### Configuration

To go to the index page you enter `<leader>ww`.
For a bare vim-install this is `\ww`.
To change this, put the following line to your `.vimrc`:
```vim
map <leader>v :VimwikiIndex <Enter>
```
On default the directory for the markdown files is `~/vimwiki/index.wiki`.
To change this, add the following line to your `.vimrc`:
```vim
let g:vimwiki_list = [{'path': '/PATH/TO/DIRECTORY/vimwiki', 'syntax': 'markdown', 'ext': '.md'}]
```
Here you can also add several wikis.
Assuming you want to have one wiki exclusively for coding related matters and another one for everyday related knowledge, add
```vim
let g:vimwiki_list = [
	\ {'path': '/PATH/wiki_code', 'syntax': 'markdown', 'ext': '.md'},
	\ {'path': '/PATH/wiki_household', 'syntax': 'markdown', 'ext': '.md'} ]
```
to your `.vimrc`.
To then select the correct wiki to go to, use `<leader>ws` to select which wiki you want to choose.
You can also use `[number] <leader>ww` to directly move to the corresponding wiki.

All the key bindings and how to remap them are listed under `:h vimwiki-mappings`.

### Basic Usage

#### Navigation

To navigate the vimwiki you need to know 3 basic commands.

1. Add a new page
	- To add a new page, you write the name of the main wiki-index page. Visually select the title of the page and press `<Enter>`. This creates a link to a new markdown file.
2. Go to a new page
	- To follow a link, press `<Enter>` on the link again, this opens the new markdown file.
3. Go one page back
	- To go back to the previous page, press `<Backspace>`.

#### Diary

To keep a diary in your vimwiki, use the `:VimwikiMakeDiaryNote` command. This opens a markdown file with the current date as its name.
Write your entry and save it.
To link the new entry to the diary index page, use `:VimwikiDiaryIndex` to go to the index page itself.
Then execute `:VimwikiDiaryGenerateLinks`. This adds all unlinked diary entries to the diary index page.
The default keybindings for this are
- `[number] <leader> wi`: Move to the diary index of wiki i.
- `[number] <leader> w <leader> w`: Open today's diary file for wiki i.
- `[number] <leader> w <leader> t`: Open today's diary file for wiki i in a new tab.

#### Encryption of pages

Using the [vim gnupg](https://github.com/jamessan/vim-gnupg) plugin, you can encrypt your pages.
This is done by first adding the folling line to your `.vimrc`.
```vim
let g:GPGFilePattern = '*.\(gpg\|asc\|pgp\)\(.md\)\='
```
To then create an encrypted entry, you have to add `.asc` to your link.
The new file will then be named `filename.asc.md`.
Opening it initially, a prompt will ask you which key to choose.
Select thee correct key and close the prompt.

#### Conversion to HTML

Vimwiki has the built-in feature to export your wiki in to an HTML wiki.
The build in version only supports the vimwiki markup language.
If you write in this language, you should change the `vimwiki_list` command such that it includes `'syntax': 'vimwiki', 'ext': '.wiki'`.
Afterwords you can just run
```
:VimwikiAll2HTML
```
To only convert the current page to Html, use `:Vimwiki2HTML`
which converts all existing `.wiki` files in to Html files and links them against each other.

To expand this capability to Markdown, you have to include certain wrapper scripts.
This wrapper script takes several arguments
```
1. force : [0/1] overwrite an existing file
2. syntax : the syntax chosen for this wiki
3. extension : the file extension for this wiki
4. output_dir : the full path of the output directory, i.e. ‘path_html’
5. input_file : the full path of the wiki page
6. css_file : the full path of the css file for this wiki
7. template_path : the full path to the wiki’s templates
8. template_default : the default template name
9. template_ext : the extension of template files
10. root_path : a count of ../ for pages buried in subdirs if you have wikilink [[dir1/dir2/dir3/my page in a subdir]] then e %root_path% is replaced by ‘../../../’.
```
With this you then can use `pandoc` or similar markdown parser to generate your html files.
The script used for this is found [here](https://mykb.dieminger.ch/snippets/wikihtml.sh).
To enable the custom script, change the `vimwiki_list` to:
```
let g:vimwiki_list = [{"path": '/PATH/TO/DIRECTORY/vimwiki',
\ "path_html": '/PATH/TO/DIRECTORY/vimwiki/HTML,
\ "syntax": 'markdown', "ext": '.md',
\ "custom_wiki2html": '~/wikihtml.sh',
\ "force": 1, "auto_export": 1}]
```
