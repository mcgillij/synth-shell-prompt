#!/bin/bash

##  +-----------------------------------+-----------------------------------+
##  |                                                                       |
##  | Copyright (c) 2018-2020, Andres Gongora <mail@andresgongora.com>.     |
##  |                                                                       |
##  | This program is free software: you can redistribute it and/or modify  |
##  | it under the terms of the GNU General Public License as published by  |
##  | the Free Software Foundation, either version 3 of the License, or     |
##  | (at your option) any later version.                                   |
##  |                                                                       |
##  | This program is distributed in the hope that it will be useful,       |
##  | but WITHOUT ANY WARRANTY; without even the implied warranty of        |
##  | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         |
##  | GNU General Public License for more details.                          |
##  |                                                                       |
##  | You should have received a copy of the GNU General Public License     |
##  | along with this program. If not, see <http://www.gnu.org/licenses/>.  |
##  |                                                                       |
##  +-----------------------------------------------------------------------+


##
##	DESCRIPTION
##
##	This script updates your "PS1" environment variable to display colors.
##	Additionally, it also shortens the name of your current path to a 
##	maximum 25 characters, which is quite useful when working in deeply
##	nested folders.
##
##
##
##	REFFERENCES
##
##	* http://tldp.org/HOWTO/Bash-Prompt-HOWTO/index.html
##
##



##==============================================================================
##	EXTERNAL DEPENDENCIES
##==============================================================================
[ "$(type -t include)" != 'function' ]&&{ include(){ { [ -z "$_IR" ]&&_IR="$PWD"&&cd $(dirname "${BASH_SOURCE[0]}")&&include "$1"&&cd "$_IR"&&unset _IR;}||{ local d=$PWD&&cd "$(dirname "$PWD/$1")"&&. "$(basename "$1")"&&cd "$d";}||{ echo "Include failed $PWD->$1"&&exit 1;};};}

include '../bash-tools/bash-tools/color.sh'
include '../bash-tools/bash-tools/shorten_path.sh'
include '../config/synth-shell-prompt.config.default'






synth_shell_prompt()
{
##==============================================================================
##	FUNCTIONS
##==============================================================================


##------------------------------------------------------------------------------
##	getGitInfo
##	Returns current git branch for current directory, if (and only if)
##	the current directory is part of a git repository, and git is installed.
##
##	In addition, it adds a symbol to indicate the state of the repository.
##	By default, these symbols and their meaning are (set globally):
##
##		UPSTREAM	NO CHANGE		DIRTY
##		up to date	SSP_GIT_SYNCED		SSP_GIT_DIRTY
##		ahead		SSP_GIT_AHEAD		SSP_GIT_DIRTY_AHEAD
##		behind		SSP_GIT_BEHIND		SSP_GIT_DIRTY_BEHIND
##		diverged	SSP_GIT_DIVERGED	SSP_GIT_DIRTY_DIVERGED		
##
##	Returns an empty string otherwise.
##
##	Inspired by twolfson's sexy-bash-prompt:
##	https://github.com/twolfson/sexy-bash-prompt
##
getGitBranch()
{
	if ( which git > /dev/null 2>&1 ); then

		## CHECK IF IN A GIT REPOSITORY, OTHERWISE SKIP
		local branch=$(git branch 2> /dev/null |\
		             sed -n '/^[^*]/d;s/*\s*\(.*\)/\1/p')	

		if [[ -n "$branch" ]]; then

			## GET GIT STATUS
			## This information contains whether the current branch is
			## ahead, behind or diverged (ahead & behind), as well as
			## whether any file has been modified locally (is dirty).
			## --porcelain: script friendly outbut.
			## -b:          show branch tracking info.
			## -u no:       do not list untracked/dirty files
			## From the first line we get whether we are synced, and if
			## there are more lines, then we know it is dirty.
			## NOTE: this requires that tyou fetch your repository,
			##       otherwise your information is outdated.
			local is_dirty=false &&\
				       [[ -n "$(git status --porcelain)" ]] &&\
				       is_dirty=true
			local is_ahead=false &&\
				       [[ "$(git status --porcelain -u no -b)" == *"ahead"* ]] &&\
				       is_ahead=true
			local is_behind=false &&\
				        [[ "$(git status --porcelain -u no -b)" == *"behind"* ]] &&\
				        is_behind=true


			## SELECT SYMBOL
			if   $is_dirty && $is_ahead && $is_behind; then
				local symbol=$SSP_GIT_DIRTY_DIVERGED
			elif $is_dirty && $is_ahead; then
				local symbol=$SSP_GIT_DIRTY_AHEAD
			elif $is_dirty && $is_behind; then
				local symbol=$SSP_GIT_DIRTY_BEHIND
			elif $is_dirty; then
				local symbol=$SSP_GIT_DIRTY
			elif $is_ahead && $is_behind; then
				local symbol=$SSP_GIT_DIVERGED
			elif $is_ahead; then
				local symbol=$SSP_GIT_AHEAD
			elif $is_behind; then
				local symbol=$SSP_GIT_BEHIND
			else
				local symbol=$SSP_GIT_SYNCED
			fi


			## RETURN STRING
			echo "$branch $symbol"	
		fi
	fi
	
	## DEFAULT
	echo ""
}






##------------------------------------------------------------------------------
##
printSegment()
{
	## GET PARAMETERS
	local text=$1
	local font_color=$2
	local background_color=$3
	local next_background_color=$4
	local font_effect=$5


	## COMPUTE COLOR FORMAT CODES
	local no_color="\[$(getFormatCode -e reset)\]"
	local text_format="\[$(getFormatCode -c $font_color -b $background_color -e $font_effect)\]"
	local separator_format="\[$(getFormatCode -c $background_color -b $next_background_color)\]"


	## GENERATE TEXT
	printf "${text_format}${segment_padding}${text}${segment_padding}${separator_padding_left}${separator_format}${separator_char}${separator_padding_right}${no_color}"
}






##------------------------------------------------------------------------------
##
prompt_command_hook()
{
	## GET PARAMETERS
	local user=$USER
	local host=$HOSTNAME
	local path="$(shortenPath "$PWD" 20)"
	local git_branch="$(shortenPath "$(getGitBranch)" 10)"


	## UPDATE BASH PROMPT ELEMENTS
	SSP_USER="$user"
	SSP_HOST="$host"
	SSP_PWD="$path"
	if [ -z "$git_branch" ]; then
		SSP_GIT=""
	else
		SSP_GIT="$git_branch"
	fi


	## CHOOSE PS1 FORMAT IF INSIDE GIT REPO
	if [ ! -z "$(getGitBranch)" ] && $SSP_GIT_SHOW; then
		PS1=$SSP_PS1_GIT
	else
		PS1=$SSP_PS1
	fi
}






##==============================================================================
##	MAIN
##==============================================================================

	## LOAD USER CONFIGURATION
	local user_config_file="$HOME/.config/synth-shell/synth-shell-prompt.config"
	local root_config_file="/etc/synth-shell/synth-shell-prompt.root.config"
	local sys_config_file="/etc/synth-shell/synth-shell-prompt.config"
	if   [ -f $user_config_file ]; then
		source $user_config_file
	elif [ -f $root_config_file  -a "$USER" == "root"  ]; then
		source $root_config_file
	elif [ -f $sys_config_file ]; then
		source $sys_config_file
	fi


	## PADDING
	if $enable_vertical_padding; then
		local vertical_padding="\n"
	else
		local vertical_padding=""
	fi


	## GENERATE COLOR FORMATTING SEQUENCES
	## The sequences will confuse the bash prompt. To tell the terminal that they are non-printing
	## characters, we must surround them by \[ and \]
	local no_color="\[$(getFormatCode -e reset)\]"
	local ps1_input_format="\[$(getFormatCode       -c $font_color_input -b $background_input -e $texteffect_input)\]"
	local ps1_input="${ps1_input_format} "

	local ps1_user_git=$(printSegment "${prompt_horizontal_padding}\${SSP_USER}" $font_color_user $background_user $background_host $texteffect_user)
	local ps1_host_git=$(printSegment "\${SSP_HOST}" $font_color_host $background_host $background_pwd $texteffect_host)
	local ps1_pwd_git=$(printSegment "\${SSP_PWD}" $font_color_pwd $background_pwd $background_git $texteffect_pwd)
	local ps1_git_git=$(printSegment "\${SSP_GIT}" $font_color_git $background_git $background_input $texteffect_git)

	local ps1_user=$(printSegment "${prompt_horizontal_padding}\${SSP_USER}" $font_color_user $background_user $background_host $texteffect_user)
	local ps1_host=$(printSegment "\${SSP_HOST}" $font_color_host $background_host $background_pwd $texteffect_host)
	local ps1_pwd=$(printSegment "\${SSP_PWD}" $font_color_pwd $background_pwd $background_input $texteffect_pwd)
	local ps1_git=""


	## MAKE GIT OPTIONS GLOBALLY AVAILABLE
	## This is needed because each time the prompt updates,
	## it must re-check the status of the current git repository,
	## and to do so, it must remember the user's configuation
	SSP_GIT_SHOW=$show_git
	SSP_GIT_SYNCED=$git_symbol_synced
	SSP_GIT_AHEAD=$git_symbol_unpushed
	SSP_GIT_BEHIND=$git_symbol_unpulled
	SSP_GIT_DIVERGED=$git_symbol_unpushedunpulled
	SSP_GIT_DIRTY=$git_symbol_dirty
	SSP_GIT_DIRTY_AHEAD=$git_symbol_dirty_unpushed
	SSP_GIT_DIRTY_BEHIND=$git_symbol_dirty_unpulled
	SSP_GIT_DIRTY_DIVERGED=$git_symbol_dirty_unpushedunpulled


	## WINDOW TITLE
	## Prevent messed up terminal-window titles
	## Must be set in PS1
	case $TERM in
	xterm*|rxvt*)
		local titlebar="\[\033]0;\${SSP_USER}@\${SSP_HOST}: \${SSP_PWD}\007\]"
		;;
	*)
		local titlebar=""
		;;
	esac


	## BASH PROMPT - Generate prompt and remove format from the rest
	SSP_PS1="${titlebar}${vertical_padding}${ps1_user}${ps1_host}${ps1_pwd}${ps1_git}${ps1_input}${prompt_final_padding}"
	SSP_PS1_GIT="${titlebar}${vertical_padding}${ps1_user_git}${ps1_host_git}${ps1_pwd_git}${ps1_git_git}${ps1_input}${prompt_final_padding}"


	## For terminal line coloring, leaving the rest standard
	none="$(tput sgr0)"
	trap 'echo -ne "${none}"' DEBUG


	## ADD HOOK TO UPDATE PS1 AFTER EACH COMMAND
	## Bash provides an environment variable called PROMPT_COMMAND.
	## The contents of this variable are executed as a regular Bash command
	## just before Bash displays a prompt.
	## We want it to call our own command to truncate PWD and store it in NEW_PWD
	PROMPT_COMMAND=prompt_command_hook
}


## CALL SCRIPT FUNCTION
## - CHECK IF SCRIPT IS _NOT_ BEING SOURCED
## - CHECK IF COLOR SUPPORTED
##     - Check if compliant with Ecma-48 (ISO/IEC-6429)
##	   - Call script
## - Unset script
## If not running interactively, don't do anything
if [ -n "$( echo $- | grep i )" ]; then

	if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
		echo -e "Do not run this script, it will do nothing.\nPlease source it instead by running:\n"
		echo -e "\t. ${BASH_SOURCE[0]}\n"

	elif [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		synth_shell_prompt
	fi
	unset synth_shell_prompt
	unset include
fi
