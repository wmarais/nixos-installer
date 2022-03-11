{ pkgs, ... }:
{
  environment.variables = {
    EDITOR = "vim";
  };

  environment.systemPackages = with pkgs; [
    vim
    (vim_configurable.customize
    {
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins;
      {
        start = [
          airline
          molokai
          vim-airline-themes
          vim-nix
          vim-lastplace
          YouCompleteMe
          fugitive
        ];
        opt = [];
      };

      vimrcConfig.customRC = ''
        autocmd FileType nix :packadd vim-nix

        set backspace=indent,eol,start

        highlight ColorColumn ctermbg=gray
        set colorcolumn=81
        set tabstop=2
        set shiftwidth=2
        set expandtab

        set background=dark
        colorscheme molokai
        "set t_Co=256
        "let g:airline_powerline_fonts=1
        let g:airline_theme='molokai'
        set laststatus=2

        set smartindent
        syntax enable
        set number

        set spell spelllang=en_au
        hi clear SpellBad
        hi SpellBad cterm=underline
        hi SpellBad ctermbg=NONE
        match ErrorMsg '\s\+$'
      '';
    })
  ];
}

