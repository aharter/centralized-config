#
# ~/.extend.bashrc
#

[[ $- != *i* ]] && return

colors() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

#
# # ex - archive extractor
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Change the window title of X terminals
case ${TERM} in
	xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
		;;
	screen*)
		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
		;;
esac

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
	# Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
	if type -P dircolors >/dev/null ; then
		if [[ -f ~/.dir_colors ]] ; then
			eval $(dircolors -b ~/.dir_colors)
		elif [[ -f /etc/DIR_COLORS ]] ; then
			eval $(dircolors -b /etc/DIR_COLORS)
		fi
	fi

	if [[ ${EUID} == 0 ]] ; then
		PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
	else
		PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
	fi

	alias ls='ls --color=auto'
	alias grep='grep --colour=auto'
	alias egrep='egrep --colour=auto'
	alias fgrep='fgrep --colour=auto'
else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \$ '
	else
		PS1='\u@\h \w \$ '
	fi
fi

unset use_color safe_term match_lhs sh

# bash_completion
[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

# bash completion custom commands
function _git_sr() {
	_git_rebase
}

function _git_ld() {
    _git_diff
}

# Enable nvm
source /usr/share/nvm/init-nvm.sh

# Use ssh-agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    eval "$(<"$XDG_RUNTIME_DIR/ssh-agent.env")" > /dev/null
fi

# Extend existing commands
alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias more=less

# Screen config with xrandr
alias screen1k='xrandr --output eDP1 --auto --pos 0x2160 --output HDMI1 --mode 1920x1080 --scale 2x2 --pos 0x0'
alias screen2k='xrandr --output eDP1 --auto --pos 0x2880 --output HDMI1 --mode 2560x1440 --scale 2x2 --pos 0x0'
alias screenextonly='xrandr --output HDMI1 --auto --pos 0x0'
alias screendocking='xrandr --output eDP-1 --off --output DVI-I-1-1 --auto --pos 0x0'
alias screendocking2k='xrandr --output eDP-1 --off --output DVI-I-1-1 --mode 2560x1440 --scale 1x1 --pos 0x0'

# WM config
alias con='nano $HOME/.i3/config'
alias comp='nano $HOME/.config/compton.conf'

alias gren='grep -rn --exclude-dir=.git --exclude-dir=node_modules'
alias odoogren='grep -rn --exclude-dir=.git --exclude-dir=node_modules --include=*.py --exclude-dir=tests'
alias robogren='gren --exclude-dir=output* --exclude-dir=docs'
alias grmo='find . -iname "*.orig" | xargs rm'
alias gprune="git branch -vv | gawk '{print \$1,\$4}' | grep 'gone]' | gawk '{print \$1}' | xargs git branch -d"
alias dprune='docker rmi -f $(docker images --filter "dangling=true" -q --no-trunc)'
alias la='ls -la --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias ll='ls -l --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias lh='la -h'
alias np='nano -w PKGBUILD'
#alias az='docker run -it anha/azure-cli az' 
alias cdj='cd ~/dev/odoo-addons-jobrad'
alias nano='vim'
alias nasbackup='restic -r /mnt/jobrad_restic_2024/ --files-from=.resticinclude --exclude-file=.resticignore --exclude-larger-than 1G backup /home/anha'

xhost +local:root > /dev/null 2>&1

complete -cf sudo


# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

shopt -s expand_aliases

# Enable history appending instead of overwriting.  #139609
shopt -s histappend

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=-1
export HISTFILESIZE=-1

export EDITOR=/usr/bin/nano

export PYENV_ROOT=$HOME/.pyenv

export ANDROID_HOME=$HOME/Android/Sdk/platform-tools

#export PATH=$PYENV_ROOT/bin:$PATH:$HOME/dev/bin:$ANDROID_HOME
export PATH=$PYENV_ROOT/bin:$PATH:$ANDROID_HOME:$HOME/go/bin

