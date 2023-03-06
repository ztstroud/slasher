# Keeps track of the last segment's background color
SLASHER_BACKGROUND=""

# Context used when rendering segments, either PROMPT, RPROMPT, or NONE
SLASHER_CONTEXT="NONE"

# Default segments used for slasher PROMPT
[[ -z "$SLASHER_SEGMENTS" ]] && SLASHER_SEGMENTS=(user directory git)
[[ "$SLASHER_SEGMENTS" == "none" ]] && SLASHER_SEGMENTS=()

# Default segments used for slasher RPROMPT
[[ -z "$SLASHER_RSEGMENTS" ]] && SLASHER_RSEGMENTS=(time)
[[ "$SLASHER_RSEGMENTS" == "none" ]] && SLASHER_RSEGMENTS=()

# Default symbol used to join to segments
[[ -z "$SLASHER_JOIN" ]] && SLASHER_JOIN="\uE0BC"

# Default symbol used to join segments that have the same background color
[[ -z "$SLASHER_JOIN_SAME" ]] && SLASHER_JOIN_SAME="\uE0BD"

# Default symbol used to start the RPROMPT segments
[[ -z "$SLASHER_RPROMPT_START" ]] && SLASHER_RPROMPT_START="\uE0BA"

# Default symbol used for the prompt
[[ -z "$SLASHER_PROMPT_SYMBOL" ]] && SLASHER_PROMPT_SYMBOL="$"

##### SLAHSER SEGMENTS #####

# Display the current directory
slasher_directory() {
    slasher_segment 15 2 "%4~"
}

# Display information about the current git branch
slasher_git() {
    [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) != "true" ]] && return

    local branch_symbol="\uE0A0"
    local head_symbol="\u27A6"
    local modifications_symbol="\u00B1"
    local untracked_symbol="?"

    local repository_name=$(basename $(git rev-parse --show-toplevel))
    
    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $branch == "HEAD" ]]; then
	local hash=$(git rev-parse --short HEAD)	
	branch="$head_symbol $hash"
    else
	branch="$branch_symbol $branch"
    fi

    local status_symbols=""    
    [[ -n "$(git diff-index --name-only HEAD)" ]] && status_symbols+="$modifications_symbol"
    [[ -n "$(git status --porcelain 2> /dev/null | grep '^??')" ]] && status_symbols+="$untracked_symbol"
	
    slasher_segment 0 15 $repository_name $branch $status_symbols
}

# Display the locatiion
slasher_location() {
    slasher_segment 15 2 "$SLASHER_LOCATION"
}

# Display the current time
slasher_time() {
    slasher_segment 15 4 "%*"
}

# Dispay the current user
slasher_user() {
    slasher_segment 15 4 "%n"
}

##### SLASHER UTILS #####

# Prints a segment of the slasher prompt, printing the join if needed
slasher_segment() {
    local fg bg
    [[ -n "$1" ]] && fg=$1 || fg="default"
    [[ -n "$2" ]] && bg=$2 || bg="default"
    
    if [[ -n "$SLASHER_BACKGROUND" ]]; then
	if [[ "$bg" == "$SLASHER_BACKGROUND" ]]; then
	    echo -n "%{%F{$fg}%K{$bg}%}$SLASHER_JOIN_SAME"
	else
	    echo -n "%{%F{$SLASHER_BACKGROUND}%K{$bg}%}$SLASHER_JOIN"
	fi
    else
	if [[ "$SLASHER_CONTEXT" == "RPROMPT" ]]; then
	    echo -n "%{%F{$bg}%k%}$SLASHER_RPROMPT_START"
	fi
    fi

    echo -n "%{%F{$fg}%K{$bg}%}"
    [[ -n "$3" ]] && slasher_segment_text "${@:3}"

    SLASHER_BACKGROUND=$bg
}

# Prints text for a slasher segment
#
# Using this funtion ensure that your segment is surrounded by spaces
slasher_segment_text() {
    echo -n " $@ "
}

# Start the slahser PROMPT
slasher_start() {
    SLASHER_BACKGROUND=""
    SLASHER_CONTEXT="PROMPT"
}

# Ends the slasher PROMPT, printing the last join and reseting the background
slasher_end() {
    [[ -n "$SLASHER_BACKGROUND" ]] && echo -n "%{%F{$SLASHER_BACKGROUND}%k%}$SLASHER_JOIN"

    SLASHER_BACKGROUND=""
    SLASHER_CONTEXT="NONE"
}

# Start the slahser RPROMPT
slasher_rstart() {
    SLASHER_BACKGROUND=""
    SLASHER_CONTEXT="RPROMPT"
}

# Ends the slasher RPROMPT
slasher_rend() {
    SLASHER_BACKGROUND=""
    SLASHER_CONTEXT="NONE"
}

# Builds the slasher PROMPT
slasher_prompt() {
    slasher_start
    
    for segment in $SLASHER_SEGMENTS; do
	slasher_$segment
    done

    slasher_end
}

# Builds the slasher RPROMPT
slasher_rprompt() {
    slasher_rstart
    
    for segment in $SLASHER_RSEGMENTS; do
	slasher_$segment
    done

    slasher_rend
}

PROMPT=$'%{%f%k%b%}$(slasher_prompt)%{%f%k%b%}\n$SLASHER_PROMPT_SYMBOL '
RPROMPT=$'%{%f%k%b%}$(slasher_rprompt)%{%f%k%b%}'
