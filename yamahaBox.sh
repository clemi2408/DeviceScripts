#!/bin/bash
#cmdline
host=$1
command=$2
subcommand=$3

#debug
debug=false

#box goes from slient 0 to loud 60
avrMax=60
avrMin=0

# volume gets limited to 50
volumeLimit=50
volumeStep=5  # increase and decrease 
          
######################################################################

function sendRequest() {

    path=$1
    __resultvar=$2

    urlPattern="http://${host}/YamahaExtendedControl/v1/main/${path}"
    httpResult=$(curl -s $urlPattern)

    if [[ "$__resultvar" ]]; then
        $__resultvar="'$httpResult'"
    else
        echo "$httpResult"
    fi
}
######################################################################

function power(){
    
    if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "on" ]; then
            #power on
            powerStatusResponse=$(sendRequest "setPower?power=on")
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #power off
            powerStatusResponse=$(sendRequest "setPower?power=standby")
            echo "ok"

        elif [ "$subcommand" == "toggle" ]; then
            #toggle power status
            powerStatusResponse=$(sendRequest "setPower?power=toggle")  
            echo "ok"

        elif [ "$subcommand" == "status" ]; then
            #power status
            powerStatusResponse=$(sendRequest "getStatus")  
            regex='"(power)":"((\\"|[^"])*)"'

            [[ $powerStatusResponse =~ $regex ]]; 

                if [ ${BASH_REMATCH[2]} == "standby" ]; then
                echo "off"
                else
                    echo "on"
                fi

        else
            #invalid subcommand
            echo "subcommand $command supports only: on,off,toggle,status"
        
        fi

    else 
        subcommand="status"
        power $subcommand
    fi

}
######################################################################

function input(){
    
    if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "status" ]; then
            #input status
            inputStatusResponse=$(sendRequest "getStatus")
            regex='"(input)":"((\\"|[^"])*)"'

            [[ $inputStatusResponse =~ $regex ]]; 
            echo "${BASH_REMATCH[2]}"

        else
            #set input to value
            inputResponse=$(sendRequest "setInput?input=${subcommand}") 
            echo "ok"
        fi

    else 
        subcommand="status"
        input $subcommand
    fi

}
######################################################################

function mute(){
    
    if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "status" ]; then
            #mute status
            muteStatusResponse=$(sendRequest "getStatus")  
            regex='("mute"):(\\"|[^",]*)'

            [[ $muteStatusResponse =~ $regex ]]; 
         
                if [ ${BASH_REMATCH[2]} == true ]; then
                echo "on"
                else
                    echo "off"
                fi

        elif [ "$subcommand" == "on" ]; then
            #mute on
            inputResponse=$(sendRequest "setMute?enable=true") 
            
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #mute off
            inputResponse=$(sendRequest "setMute?enable=false") 
              
            echo "ok"
        
        else
            #invalid subcommand
            echo "subcommand $command supports only: {on|off|status}"
           
        fi

    else 
        subcommand="status"
        mute $subcommand
    fi
}
######################################################################

function volume(){

    if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "status" ]; then
            #input status

            volumeStatusResponse=$(sendRequest "getStatus")  
            regex='("volume"):(\\"|[^",]*)'

            [[ $volumeStatusResponse =~ $regex ]]; 
            echo ${BASH_REMATCH[2]}

        elif [ "$subcommand" == "up" ] || [ "$subcommand" = "down" ]; then
            
            volumeStatusResponse=$(sendRequest "getStatus")  
            regex='("volume"):(\\"|[^",]*)'

            [[ $volumeStatusResponse =~ $regex ]]; 

            local volumeValue=${BASH_REMATCH[2]}
            
            if [ "$subcommand" == "up" ]; then
        
                newvolume=$((volumeValue + volumeStep))

            elif [ "$subcommand" == "down" ]; then

                newvolume=$((volumeValue - volumeStep))

            fi

          
            if ((   ($newvolume >= $avrMin) && ($newvolume <= $volumeLimit) )); then

                volumeStatusResponse=$(sendRequest "setVolume?volume=$newvolume")  
                echo "ok"

            else
               
               echo "error $newvolume not between $avrMin and $volumeLimit"
               
            fi 

        else
            
            if ((   ($subcommand >= $avrMin) && ($subcommand <= $volumeLimit) )); then

                volumeStatusResponse=$(sendRequest "setVolume?volume=$subcommand")
                echo "ok"


            else
                #invalid volume value as subcommand
                echo "subcommand $command supports only: up, down, status, {value}"
                echo "subcommand $command supports value between $avrMin and $avrMax limited to $volumeLimit"
            fi
          
        fi

    else 
        subcommand="status"
        volume $subcommand
    fi

}

######################################################################

if $debug
then
    echo "------"
    echo "Param host: $host"
    echo "Param command: $command"
    echo "Param subcommand: $subcommand"
    echo "------"
fi

######################################################################

case $command in
    power)
        power
        ;;
    input)
        input
        ;;

    mute)
        mute
        ;;
    volume)
        volume
        ;;
    *)
        echo ""
        echo "yamahaBox.sh {host} {command} {subcommand}"
        echo ""
        echo "commands:"
        echo -e "\t power: {on|off|status}"   
        echo -e "\t input: {\$inputname|status}"
        echo -e "\t mute: {on|off|status}"   
        echo -e "\t volume: {up|down|status|\$value}"   
        echo ""
    
esac

######################################################################
