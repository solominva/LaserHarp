#!/bin/bash

#process command name to check
declare -a KILLLIST
KILLLIST=("ttymidi" "timidity")
#max cpu % load
MAX_CPU=90
#max execution time for CPU percentage > MAX_CPU (in seconds 7200s=2h)
MAX_SEC=5
#max execution time for any %CPU (in seconds 2700s=45min)
MAX_SEC2=2700
#colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
NC=`tput sgr0` # No Color
NEED_RESTART=0

#
# PARSE ARGUMENTS
#

#print command signature and usage
if [ "$1" = "" ] || [ "$1" = "--help" ] || [ $# -lt 1 ] || [ $# -gt 3 ]; then
    printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
        "USAGE: bash $0 [dry|kill|--help] [top|ps] [cpu|time]" \
        "Example:" \
        "bash $0 dry" \
        "bash $0 dry top" \
        "bash $0 kill top cpu" \
        "For help:" \
        "bash $0" \
        "OR" \
        "bash $0 --help" >&2
    exit 0
fi

#kill or not kill?
if [ "$1" = "kill" ]; then
    KILL=1
    echo "${RED}Process execute in 'kill' mode.${NC}"
else
    KILL=0
    echo "Process execute in '${YELLOW}dry${NC}' mode (no kill)."
fi

#command to retrive process
if [ "$2" = "ps" ]; then
    CMD="ps"
    echo "Process fetched by '${YELLOW}ps${NC}' command"
elif [ "$2" = "top" ]; then
    CMD="top"
    echo "Process fetched by '${YELLOW}top${NC}' command"
else
    CMD="top"
    echo "Process fetched by '${YELLOW}top${NC}' command"
fi

#process Sort by
if [ "$3" = "cpu" ]; then
    if [ "$CMD" = "ps" ]; then
        SORTBY=2
    else
        SORTBY=9
    fi
    echo "Process sort by ${YELLOW}%CPU${NC} ( $SORTBY )"
elif [ "$3" = "time" ]; then
    if [ "$CMD" = "ps" ]; then
        SORTBY=3
    else
        SORTBY=11
    fi
    echo "Process sort by ${YELLOW}TIME${NC} ( $SORTBY )"
else
    if [ "$CMD" = "ps" ]; then
        SORTBY=2
    else
        SORTBY=9
    fi
    echo "Process sort by ${YELLOW}TIME${NC} ( $SORTBY )"
fi


#iterate for each process to check in list
for PROCESS_TOCHECK in ${KILLLIST[*]}
do
    echo "Check ${YELLOW}$PROCESS_TOCHECK${NC} process..."

    #pid
    if [ "$CMD" = "ps" ]; then
        PID=$(ps -eo pid,pcpu,time,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $1}')
    else
        PID=$(top -bcSH -n 1 | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $1}')
    fi

    if [ -z "$PID" ]; then
        echo "${GREEN}There isn't any matched process for $PROCESS_TOCHECK${NC}"
        continue
    fi

    #Fetch other process stats by pid
    #% CPU
    if [ "$CMD" = "ps" ]; then
        CPU=$(ps -p $PID -o pid,pcpu,time,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $2}')
    else
        CPU=$(top -p $PID -bcSH -n 1 | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $9}')
    fi

    #format integer cpu
    CPU=${CPU%%.*}

    #time elapsed d-HH:MM:ss
    if [ "$CMD" = "ps" ]; then
        TIME_STR=$(ps -p $PID -o pid,pcpu,time,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $3}')
    else
        TIME_STR=$(top -p $PID -bcSH -n 1 | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $11}')
    fi

    #process name
    if [ "$CMD" = "ps" ]; then
        PNAME=$(ps -p $PID -o pid,pcpu,time,comm,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $4}')
    else
        PNAME=$(ps -p $PID -o pid,pcpu,time,comm,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $4}')
    fi

    #full process command
    if [ "$CMD" = "ps" ]; then
        COMMAND=$(ps -p $PID -o pid,pcpu,time,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $4}')
    else
        COMMAND=$(top -p $PID -bcSH -n 1 | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $12,$13,$14}')
    fi

    #user
    if [ "$CMD" = "ps" ]; then
        USER=$(ps -p $PID -o pid,pcpu,time,user,command | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $4}')
    else
        USER=$(top -p $PID -bcSH -n 1 | grep $PROCESS_TOCHECK | sort -k $SORTBY -r | head -n 1 | awk '{print $2}')
    fi

    # Decode the CPU time format [dd-]hh:mm:ss.
    TIME_SEC=0
    IFS="-:" read c1 c2 c3 c4 <<< "$TIME_STR"

    #with top command time format is hh:mm.ss, so truncare seconds in c2
    c2=${c2%%.*}

    if [ -n "$c4" ]
    then
      TIME_SEC=$((10#$c4+60*(10#$c3+60*(10#$c2+24*10#$c1))))
    elif [ -n "$c3" ]
    then
      if [ "$CMD" = "ps" ]; then
        TIME_SEC=$((10#$c3+60*(10#$c2+60*10#$c1)))
      else
        TIME_SEC=$(((10#$c3*24)*60*60)+60*(10#$c2+60*10#$c1))             
      fi   
    else
      if [ "$CMD" = "ps" ]; then
        TIME_SEC=$((10#0+(10#$c2+60*10#$c1)))
      else
        TIME_SEC=$((10#0+60*(10#$c2+60*10#$c1)))
      fi
    fi

    #process summary
    if [ "$3" = "time" ]; then
        echo "${YELLOW}TOP Long Time $PROCESS_TOCHECK process is:${NC}"
    else
        echo "${YELLOW}TOP %CPU consuming $PROCESS_TOCHECK process is:${NC}"
    fi
    echo "c1:$c1"
    echo "c2:$c2"
    echo "c3:$c3"
    echo "c4:$c4"
    echo "PID:$PID"
    echo "PNAME:$PNAME"
    echo "CPU:$CPU"
    echo "TIME_STR:$TIME_STR"
    echo "TIME_SEC:$TIME_SEC"
    echo "USER:$USER"
    echo "COMMAND:$COMMAND"

    #check if need to kill process
    if [ $CPU -gt $MAX_CPU ] && [ $TIME_SEC -gt $MAX_SEC ]; then

        echo "CPU load from process $PNAME ( PID: $PID ) User: $USER has reached ${CPU}% for $TIME_STR. Process was killed."
        if [ "$KILL" = "1" ]; then
            echo "${RED}kill -15 $PID${NC}"
            aconnect -x
	    kill -15 $PID
            sleep 3
            echo "kill -9 $PID"
            kill -9 $PID
            echo "kill zombies"
            kill -HUP $(ps -A -ostat,ppid | grep -e '[zZ]'| awk '{ print $2 }')
            NEED_RESTART=1
        fi
    else
        echo "${GREEN}$PROCESS_TOCHECK it's OK!${NC}"
    fi

    echo " "
done

echo need_restart: $NEED_RESTART
if [ $NEED_RESTART -eq 1 ]; then
  sleep 1
  echo restart harp_prepare
  sleep 5
  bash /etc/harp_prepare.sh
fi
