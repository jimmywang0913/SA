#!/usr/local/bin/bash
temp=$(mktemp -t test.XXXXXX)
trap 'echo "Ctrl + C pressed." && exit 2' 
main(){
dialog --menu "System info" 30 50 20 1 "LOGIN RANK" 2 "PORT INFO" 3 "MOUNTPOINT INFO" 4 "SAVE SYSTEM INFO" 5 "LOAD SYSTEM INFO" 2> $temp
if [ "$?" == "1" ]; then
	echo "Exit."
	exit 2
	fi
option=$(cat $temp)
case $option in
	1) loginrank;;
	2) port;;
	3) mount_;;
	4) savefile;;
	5) loadfile;;
esac
if [ "$option" == "" ]; then
	>&2 echo "Esc pressed."
	exit 1
	fi

}
loginrank() {
	month=`date | awk -F" " '{print $2}'`
	cmd=`last | awk -v month=$month -F" " '{print $1}' | sort -r | uniq -c | sort -k1 -r | awk -v count=1 -F" " 'BEGIN{print "Rank\tName\tTimes"}{if(NR>5){}else{print count"\t"$2"\t"$1;count++;}}'`
	dialog --title "LOGIN RANK" --msgbox "$cmd" 30 50 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		main
	fi
}
port() {
	cmd=`sockstat -4l | awk -F" " '{if(NR!=1){print $3" \""$5"_"$6"\""}}'`
	dialog --menu "PORT INFO(PID and Port)" 30 50 20 ${cmd} 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		main
	fi
	portinfo $option
}
portinfo(){
	pid=$1
	cmd=`ps ax -o user,pid,ppid,stat,%cpu,%mem | grep $pid | awk -v pid=$pid -F" " '{if($2==pid){print "USER: "$1"\nPID: "$2"\nPPID: "$3"\nSTAT: "$4"\n%CPU: "$5"\n%MEM: "$6}}END{print "\nCOMMAND: "}' > temp.text`
	cmd2=`ps ax -o pid,command | awk -v pid=$pid -F" " '{if($1==pid){for(i=2;i<=NF;i++){printf $i" "}}}' > temp2.text`
	dialog --msgbox "`cat temp.text``cat temp2.text`" 30 50 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		port
	fi
	#echo "dialog --msgbox ${cmd} 40 10"
	#echo "$cmd" "$cmd
}
mount_(){
	cmd=`df | awk -F" " '{if(NR!=1){print $1"\t"$6}}'`
	dialog --menu "MOUNTPOINT INFO" 30 50 20 ${cmd} 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		main
	fi
	mountinfo $option
}
mountinfo(){
	mountpath=$1
	cmd=`df -h | awk -v m=$mountpath -F" " '{if($1==m){print "Filesystem:  "$1"\nType: "}}' > tempmount.text`
	cmd2=`mount | awk -v m=$mountpath -F" " '{if($1==m){print $4}}' | sed 's/(//; s/,//' > tempmount2.text`
	cmd3=`df -h | awk -v m=$mountpath -F" " '{if($1==m){print "\nSize:  "$2"\nUsed: "$3"\nAvail: "$4"\nCapacity: "$5"\nMounted_on: "$6}}' > tempmount3.text`
	dialog --msgbox "`cat tempmount.text``cat tempmount2.text``cat tempmount3.text`" 30 50 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		mount_
	fi
}
savefile(){
	dialog --title "Save to file" --inputbox "Enter the path:" 20 50 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		main
	fi
	save2 $option
}
save2(){
	path=$1
	cmd1=`date | awk '{print "This system reprot is generated on "$0"\n============================================================="}' > tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd2=`sysctl -n kern.hostname | awk '{print "Hostname: "$0}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd3=`sysctl -n kern.ostype | awk '{print "OS Name: "$0}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd4=`sysctl -n kern.version | awk -F" " '{if($1!=""){print "OS Release Version: "$2}}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd5=`sysctl -n hw.machine_arch | awk '{print "OS Architeture: "$0}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd6=`sysctl -n hw.model | awk '{print "Processor Model: "$0}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd7=`sysctl -n kern.compress_user_cores_level | awk '{print "Number of Processor: "$0}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`
	cmd8=`sysctl -n hw.physmem | awk '{if ($0>1073741824){print "Tatol Physical Memmory: "$0/1073741824"GB"}else if($0>1048576){print "Tatol Physical Memory: "$0/1048576"MB"}}' >> tempsysinfo`
	cmd=`echo "\n " >> tempsysinfo`     
	cmd9=`grep memory /var/run/dmesg.boot | grep real | awk -F" " '{if (NR==1){print $4}}'`
	cmd10=`grep memory /var/run/dmesg.boot | grep avail | awk -F" " '{print $4}'`
	cmd14=`echo "Free Memory (%): " >> tempsysinfo`
	let avail=cmd10*100
	let free=avail/cmd9
	cmd14=`echo $free"%\n" >> tempsysinfo`
	cmd11=`sysctl -n kern.userasymcrypto | awk '{print "Total logged in users: "$0}' >> tempsysinfo`
	cmd11=`echo "\n" >>tempsysinfo`
	cmd11=`echo "rightreserved" >> tempsysinfo`
	#cmd14=`cat "$path" >> tempsysinfo`
	#cmd12=`awk -v free=$freemem '{print "Free Memory (%): "free*100}' >> tempsysinfo`
	if [[ $path =~ ^[\/.*] ]]; then
		cmd2=`echo $path | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
		if [ -d "$cmd2" ]; then
  		# Take action if $DIR exists. #
  		cmd13=`\cp tempsysinfo $path 2>&1 | awk -F" " '{print $4}'`
  		if [[ $cmd13 == "denied" ]]; then
  			dialog --title "Permission Denied" --msgbox "`echo "No write permission to "$cmd2"!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				savefile
				fi
  		fi
		cmd13=`\cp tempsysinfo $path`
		cmd=`echo "\n\n\nthe output file is save to "$path >> tempsysinfo`
		dialog --title "System Info" --msgbox "`cat tempsysinfo`" 30 80 2> $temp
		option=$(cat $temp)
		if [ "$option" == "" ]; then
			savefile
		fi
		else
  			cmd=`echo $cmd2" not found!"`
			dialog --title "Directory not found" --msgbox "`echo $cmd`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				savefile
			fi
		fi
	else 
		cmd2=`echo $path | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
		cmd=`echo -n $HOME > tempp`
		cmd=`echo -n "/" >> tempp`
		cmd=`echo -n $cmd2 >> tempp`
		cmd3=`cat tempp`
		if [ -d "$cmd3" ]; then
  		# Take action if $DIR exists. #
		cmd=`echo -n $HOME > tempp`
		cmd=`echo -n "/" >> tempp`
		cmd=`echo -n $path >> tempp`
		cmd=`cat tempp`
		cmd13=`\cp tempsysinfo $cmd 2>&1 | awk -F" " '{print $4}'`
  		if [[ $cmd13 == "denied" ]]; then
  			cmd2=`echo $cmd | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
  			dialog --title "Permission Denied" --msgbox "`echo "No write permission to "$cmd2"!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				savefile
				fi
  		fi
		cmd13=`\cp -f tempsysinfo $cmd`
		cmd=`cat tempp `
		cm=`cat tempsysinfo | awk '{if(NR<21){print $0}}' > tempsysinfo2`
		cmd=`echo "\n\n\nthe output file is save to "$cmd >> tempsysinfo2`
		
		dialog --title "System Info" --msgbox "`cat tempsysinfo2`" 30 80 2> $temp
		option=$(cat $temp)
		if [ "$option" == "" ]; then
			savefile
		fi
		else
			cmd3=`cat tempp`
			dialog --title "Directory not found" --msgbox "`echo $cmd3" not found!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				savefile
			fi
		fi
	fi
}
loadfile(){
	dialog --title "Load from file" --inputbox "Enter the path:" 20 50 2> $temp
	option=$(cat $temp)
	if [ "$option" == "" ]; then
		main
	fi
	load2 $option
}
load2(){
	path=$1
	if [[ $path =~ ^[\/.*] ]]; then
		cmd2=`echo $path | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
		cmd13=`cat $path 2>&1 | awk -F" " '{print $4}'`
  		if [[ $cmd13 == "denied" ]]; then
  			dialog --title "Permission Denied" --msgbox "`echo "No read permission to "$cmd2"!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
				fi
  		fi
		if [ -d "$cmd2" ]; then
		cmd1=`cat $path | awk '{if(NR==22){print $0}}'`
			if [ "$cmd1" == "rightreserved" ]; then
  				dialog --title "`echo $path`" --msgbox "`cat $path | awk '{if(NR<21){print $0}}'`" 30 80 2> $temp
				option=$(cat $temp)
				if [ "$option" == "" ]; then
					loadfile
				fi
  			else
  				dialog --title "File not valid" --msgbox "`echo "The file is not generated by this program."`" 30 80 2> $temp
				option=$(cat $temp)
				if [ "$option" == "" ]; then
					loadfile
				fi
  			fi	
		else
  			cmd=`echo $cmd2" not found!"`
			dialog --title "File not found" --msgbox "`echo $cmd`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
			fi
		fi
	else 
	cmd2=`echo $path | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
		cmd=`echo -n $HOME > tempp`
		cmd=`echo -n "/" >> tempp`
		cmd=`echo -n $cmd2 >> tempp`
		cmd3=`cat tempp`
		if [ -d "$cmd3" ]; then
		cmd=`echo -n $HOME > tempp`
		cmd=`echo -n "/" >> tempp`
		cmd=`echo -n $path >> tempp`
		cmd=`cat tempp`
		cmd13=`cat $cmd 2>&1 | awk -F" " '{print $4}'`
  		if [[ $cmd13 == "denied" ]]; then
  			cmd2=`echo $cmd | awk -F"/" '{$NF=""}1' | sed -r 's/ $//' | sed -r 's/ +/\//g'`
  			dialog --title "Permission Denied" --msgbox "`echo "No read permission to "$cmd2"!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
				fi
  		fi
  		cmd1=`cat $cmd | awk '{if(NR==22){print $0}}'`
  		if [ "$cmd1" == "rightreserved" ]; then
  			dialog --title "`echo $path`" --msgbox "`cat $cmd | awk '{if(NR<21){print $0}}'`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
			fi
  		else
  		dialog --title "File not valid" --msgbox "`echo "The file is not generated by this program."`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
			fi
  		fi	
		else
			cmd3=`cat tempp`
			dialog --title "File not found" --msgbox "`echo $cmd3" not found!"`" 30 80 2> $temp
			option=$(cat $temp)
			if [ "$option" == "" ]; then
				loadfile
			fi
		fi
	fi
}
main