{config, pkgs, ...}:
{
  environment = {
    systemPackages = with pkgs; [
      vivid
      bash
    ];

    interactiveShellInit = ''
      parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
      }
      export LS_COLORS="$(vivid generate molokai)"
      export PS1="\[\e[94m\]\u@\h:\[\e[92m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "
    '';
  };

  programs.bash = {
    shellAliases = {
      ls = "ls -hNF --color=auto --group-directories-first --time-style=iso";
    };
  };
}
