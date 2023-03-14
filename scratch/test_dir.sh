#!/usr/bin/env bash
dryRun=${dryRun:-0}
rm -rf ./srv/nfs/ 2>&1 > /dev/null || true
rsyncCommand="rsync --recursive --archive --mkpath --no-i-r --info=progress2"
[[ $dryRun -ne 0 ]] && rsyncCommand="$rsyncCommand --dry-run"

function padString(){
    padlimit=$(tput cols)
    string1=${1:-"test string 1"}
    string2=${2:-"test string 2"}
    
    pad=$(printf '%*s' "$padlimit")
    pad=${pad// / }
    padlength=$padlimit

    printf '%s' "$string1"
    printf '%*.*s' 0 $((padlength - ${#string1} - ${#string2} )) "$pad"
    printf '%s\n' "$string2"
}

function testDir(){ 
    counter=1;
    pushd ${1} || exit 1
    fileCount=$(sudo find -type d | wc -l); 
    ((fileCount--))
    fileList=$(sudo find -type d -printf "%P\n"); 
    for file in $fileList; do 
        percent=$(awk -vx=${counter} -vy=${fileCount} 'BEGIN{printf("%.2f\n",x/y*100)}');
        padString "$file" "$counter/$fileCount $percent%"; 
        ((counter++));
    done 
    printf "\n";
    popd || exit 1;
}

$rsyncCommand ./tmpmnt/rootfs/* ./srv/nfs/123456789/
