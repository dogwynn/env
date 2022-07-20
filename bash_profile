function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

shopt -s direxpand

red="\033[0;31m"
yellow="\033[0;33m"
bright_yellow="\033[1;33m"
bright_blue="\033[1;34m"
cyan="\033[1;36m"
green="\033[0;32m"
light_green="\033[1;32m"
light_gray="\033[0;37m"
nocolor="\033[0m"

PS1="\n(\$(date +'%Y/%m/%d %H:%M:%S')) | ${cyan}\w${nocolor}\n[\h] >>] "

export HISTIGNORE=f:u:dr:ls:ll:lal:lart:history

export LS_COLORS=${LS_COLORS}:'di=01;36:ln=01;35'

export MASSCAN_RATE=2000
export MASSCAN_IFACE=eth0
export MASSCAN_WAIT=2

alias f='pushd -0>/dev/null'
alias u='pushd +1>/dev/null'
alias dr='popd>/dev/null'
alias ls='ls -h --color=auto'
alias la='ls -la'
alias ll='ls -l'
alias lal='la'
alias lart='ls -lart'
alias lars='ls -larS'
alias screen='screen -e ^\\^\\ -s bash'
# alias emacs="emacs -nw -q -l ~/.emacs.light"
alias xcopy="xclip -selection clipboard"
alias here='basename $PWD'
alias nmap-all='sudo nmap -v -sS -p 1-65535 $(here) | tee nmap-$(here)-all.txt'
alias nmap-found='sudo nmap -A -v -p $(nsi-nmap-ports nmap-$(here)-all.txt --sep ,) $(here) | tee nmap-$(here).txt'
alias noansi="sed 's/\x1b\[[0-9;]*m//g'|sed 's/\x00//g'"
alias lower="tr '[:upper:]' '[:lower:]'"
alias upper="tr '[:lower:]' '[:upper:]'"
alias less='less -R'

alias mscan-all='sudo masscan -v --rate ${MASSCAN_RATE} --wait ${MASSCAN_WAIT} --interface ${MASSCAN_IFACE} -oG - -p 1-65535 $(here) | tee mscan-$(here)-all.txt'
function mscan-found () {
    sudo nmap -A -v -p $(cat mscan-$(here)-all.txt | grep 'Ports: ' | awk '{ print $7 }' | cut -d/ -f1 | tr '\n' ',') $(here) | tee mscan-$(here).txt
}

alias plaintext-secrets='grep -h -A1 -a _SC * | grep -v "\[\*" | grep -v - -- | sort -u'

function tmux-script() {
    date_str=$(date +'%Y-%m-%d')
    ts=$(date +'%Y-%m-%d-%H%M')
    TMUX_WINDOW=$(tmux list-windows | grep '(active)' | cut -d: -f1)
    TMUX_PANE=$(tmux list-panes | grep '(active)' | cut -d: -f1)

    tmux_dir="tmux-${date_str}"

    mkdir -p ${tmux_dir}
    script_filename_root=${tmux_dir}/tmux-window-${TMUX_WINDOW}-pane-${TMUX_PANE}

    script_filename=${script_filename_root}.txt
    timing_filename=${script_filename_root}-timing.txt

    if [ -f $script_filename ]
    then
    	cp $script_filename $script_filename-${ts}.bak
    fi
    if [ -f $timing_filename ]
    then
    	cp $timing_filename $timing_filename-${ts}.bak
    fi
    script --timing=${timing_filename} -fa ${script_filename} -c 'bash -l'
}


function VI () {
    if [ ! "$*" ]; then
        vim;
    else
        if [[ -a "$*" ]]; then
            less -R "$*";
        else
            vim "$*";
        fi
    fi
}
alias vi=VI

function cd () {
    if [ "$*" ]; then
	pushd "$*">/dev/null
    elif [ ! "$*" ]; then
	pushd $HOME>/dev/null;
    fi
}

function wincat() {
    iconv -f UTF-16LE -t UTF-8 "${1}"
}

function winvi() {
    wincat "${1}" | less
}

function dush() {
    du -sh "$@" | sort -h
}

SCAN_BASE=subnets.txt
EXCLUDE_BASE=exclude.txt

function raw-port-scan() {
    p=$1
    echo sudo nmap -Pn -n -v -iL ${SCAN_BASE} -p ${p} -oG - 
    sudo nmap -Pn -v -n -iL ${SCAN_BASE} -p ${p} -oG - | tee nmap-${p}.txt | grep "${p}/open/" | awk '{print $2}' | sortips | uniq | tee port-${p}.txt
}

function get-printers-nmap() {
    if [ ! -f printers.txt ]; then
	echo -e "${bright_yellow}Getting printer information...${nocolor}"
	raw-port-scan 9100
	raw-port-scan 515
	cat port-9100.txt port-515.txt | sortips | uniq > printers.txt
    fi
}

function get-exclude() {
    if [ ! -f exclude.txt ]; then
	echo -e "${bright_yellow}Could not find exclude.txt. Please create by hand or initialize empty with "touch exclude.txt" ${nocolor}"
        exit 1
    fi
}

function init-scan-nmap() {
    sudo true
    get-exclude
    get-printers-nmap
}

function port-scan() {
    init-scan-nmap
    p=$1
    raw-port-scan ${p}
    diffips port-${p}.txt printers.txt | tee .port-${p}.txt
    mv .port-${p}.txt port-${p}.txt
}

function uport-scan() {
    p=$1
    sudo nmap -v -sU -iL ${SCAN_BASE} -p ${p} -oG - | tee nmap-${p}.txt | grep "${p}/open/" | awk '{print $2}' | sortips | uniq | tee port-${p}.txt
    diffips port-${p}.txt port-9100.txt | tee .port-${p}.txt
    mv .port-${p}.txt port-${p}.txt
}

function raw-mass-scan() {
    p=$1
    sudo masscan --excludefile ${EXCLUDE_BASE} --interface ${MASSCAN_IFACE} -v -iL ${SCAN_BASE} --rate $MASSCAN_RATE --wait ${MASSCAN_WAIT}  -p ${p} -oG - | tee mscan-${p}.txt | grep "${p}/open/" | awk '{print $4}' | sortips | uniq | tee port-${p}.txt
}

function get-printers-mscan() {
    if [ ! -f printers.txt ]; then
	echo -e "${bright_yellow}Getting printer information...${nocolor}"
	raw-mass-scan 9100
	raw-mass-scan 515
	cat port-9100.txt port-515.txt | sortips | uniq > printers.txt
    fi
}

function init-scan-mscan() {
    sudo true
    get-exclude
    get-printers-mscan
}

function mass-scan() {
    get-printers-mscan
    p=$1
    raw-mass-scan ${p}
    diffips port-${p}.txt printers.txt | tee .port-${p}.txt
    mv .port-${p}.txt port-${p}.txt
}

function umass-scan() {
    p=$1
    sudo masscan --interface ${MASSCAN_IFACE}  --rate $MASSCAN_RATE --wait ${MASSCAN_WAIT} -v -sU -iL ${SCAN_BASE} -p ${p} -oG - | tee mscan-${p}.txt | grep "${p}/open/" | awk '{print $4}' | sortips | uniq | tee port-${p}.txt
    diffips port-${p}.txt port-9100.txt | tee .port-${p}.txt
    mv .port-${p}.txt port-${p}.txt
}

export EDITOR="emacs -nw -q"

export PATH=/opt/python/bin:${HOME}/.local/bin:${PATH}:${HOME}/bin:

set bell-style visible

alias this='basename $PWD'

