#!/bin/bash

USB_PORT=$(find /dev/ttyUSB*)
echo $USB_PORT
if aconnect -lo | grep ttymidi > /dev/null; then
  echo ttymidi is already running! ;
else
  echo Starting ttymidi...
  ttymidi -s $USB_PORT -b 38400 & > /dev/null
  echo ttymidi started
  sleep 1
fi

if aconnect -lo | grep TiMidity > /dev/null; then
  echo TiMidity is already running! ;
else
  echo Starting TiMidity...
  timidity -iAD -B4,8 > /dev/null
  echo timidity started
sleep 5
fi
echo start
IFS=$'\n'; arr=`aconnect -l`
echo $arr
for str in ${arr[*]} ; do
  if echo $str | grep -e '^client' > /dev/null; then
    client=`echo $str | sed 's/:.*$//' | sed 's/^.* //'`
    tmdt_curr=""; ttmd_curr=''
  elif echo $str | grep -e '^ *[0-9]* ' > /dev/null; then
    port=`echo $str | sed 's/^ *//' | sed 's/ .*$//'`
    if echo $str | grep TiMidity > /dev/null; then
      tmdt_curr="$client:$port"
      [ ! "$tmdt" ] && tmdt="$tmdt_curr"
    elif echo $str | grep 'MIDI out' > /dev/null; then
      ttmd_curr="$client:$port"
      [ ! "$ttmd" ] && ttmd="$ttmd_curr"
    fi
  elif echo $str | grep 'Connecting To:' > /dev/null && [ "$ttmd_curr" ]; then
    conn=`echo $str | sed 's/.*Connecting To: *//'`
    [ "$ttmd_conn" ] && ttmd_conn="$ttmd_conn "
    ttmd_conn="$ttmd_conn$ttmd_curr=$conn"
    ttmd=""
  elif echo $str | grep 'Connected From:' > /dev/null && [ "$tmdt_curr" ]; then
    conn=`echo $str | sed 's/.*Connected From: *//'`
    [ "$tmdt_conn" ] && tmdt_conn="$tmdt_conn "
    tmdt_conn="$tmdt_conn$conn=$tmdt_curr"
    tmdt=""
  fi
done
IFS=' '; arr=`echo $tmdt_conn`
for str in ${arr[@]}; do
  echo  $ttmd_conn | grep $str > /dev/null && already_connected=1
done
if [ "$already_connected" ]; then
  echo Already connected!
elif [ "$ttmd" ] && [ "$tmdt" ]; then
  echo Connecting $ttmd to $tmdt...
  aconnect $ttmd $tmdt
else
  echo Cannot connect...
fi
echo
aconnect -l
