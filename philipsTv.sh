#!/bin/sh
#cmdline
host=$1
command=$2
subcommand=$3

#debug
debug=false

#box goes from slient 0 to loud 60
volumeMax=60
volumeMin=0

# volume gets limited to 50
volumeLimit=50
volumeStep=5  # increase and decrease 
timeoutInSeconds=1
# http://jointspace.sourceforge.net/projectdata/documentation/jasonApi/1/doc/API-Method-audio-volume-POST.html

######################################################################

function getRequest() {

    path=$1
    __resultvar=$2

    urlPattern="http://${host}:1925/1${path}"
    httpResultRAW=$(curl -s $urlPattern --connect-timeout $timeoutInSeconds)

    httpResult=${httpResultRAW//[$'\t\r\n']}

    if [[ "$__resultvar" ]]; then
        $__resultvar="'$httpResult'"
    else
        echo "$httpResult"
    fi
}

          
######################################################################

function postRequest() {

    path=$1
    blob="$2"
    __resultvar=$3

    urlPattern="http://${host}:1925/1${path}"

    echo $urlPattern
    echo $blob
    httpResultRAW=$(curl -s -X POST $urlPattern --connect-timeout $timeoutInSeconds --data "$blob")
    httpResult=${httpResultRAW//[$'\t\r\n']}

    if [[ "$__resultvar" ]]; then
        $__resultvar="'$httpResult'"
    else
        echo "$httpResult"
    fi
}


######################################################################

function extractJsonValue() {
    data="$1"
    key=$2
  #  echo "CALLED: key: $key data: $data"

    a="${data//\{/}"
    b="${a//\}/}"
    c="${b//\"/}"
    string="${c// /}"

    delimiter=","

    while test "${string#*$delimiter}" != "$string" ; do

        stringA="${string%%$delimiter*}"
        string="${string#*$delimiter}"

        echoValueAndExitIfMatched $stringA $key

    done

    echoValueAndExitIfMatched $string $key

}

######################################################################

function echoValueAndExitIfMatched(){

    value2=$1
    key=$2

    delimiter2=":"

    while test "${value2#*$delimiter2}" != "$value2" ; do

        key2="${value2%%$delimiter2*}"
        value2="${value2#*$delimiter2}"

        if [ "$key2" == "$key" ]; then
            echo $value2
            exit 0
        fi

    done

}

######################################################################

function power(){
    
    if [ ! -z "$subcommand" ]; then
        
        if [ "$subcommand" == "off" ]; then
         
            jsonRequest="{\"key\": \"Standby\"}"
            powerStatusResponse=$(postRequest "/input/key" "$jsonRequest")                 
            echo "ok"

        elif [ "$subcommand" == "status" ]; then

             #power status
            powerStatusResponse=$(getRequest "/system")  
            value=$(extractJsonValue "$powerStatusResponse" "model")
                      
            urlPattern="http://${host}:1925/1/system"

            if curl -I -s $urlPattern --connect-timeout $timeoutInSeconds > /dev/null ; then
                echo "on"
            else
                echo "off"
            fi


        else
            #invalid subcommand
            echo "subcommand $command supports only: off,status"
        
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
            
            inputStatusResponse=$(getRequest "/sources/current")     
            value=$(extractJsonValue "$inputStatusResponse" "id")
            echo $value
            
        else
            #set input to value
            jsonRequest="{\"id\": \"$subcommand\"}"
            inputStatusResponse=$(postRequest "/sources/current" "$jsonRequest")                 
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
            muteStatusResponse=$(getRequest "/audio/volume")     
            value=$(extractJsonValue "$muteStatusResponse" "muted")
 
            if [ "$value" == "true" ]; then
                echo "on"
           
            elif [ "$value" == "false" ]; then
                echo "off"
            else
                echo "error: $value"
            fi

        elif [ "$subcommand" == "on" ]; then
            #mute on
            jsonRequest="{\"muted\": true}"
            inputResponse=$(postRequest "/audio/volume" "$jsonRequest")                 
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #mute off
            jsonRequest="{\"muted\": false}"
            inputResponse=$(postRequest "/audio/volume" "$jsonRequest")                 
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
      
            volumeStatusResponse=$(getRequest "/audio/volume")     
            value=$(extractJsonValue "$volumeStatusResponse" "current")
            echo $value

        elif [ "$subcommand" == "up" ] || [ "$subcommand" = "down" ]; then
            
            volumeStatusResponse=$(getRequest "/audio/volume")     
            value=$(extractJsonValue "$volumeStatusResponse" "current")
           
            if [ "$subcommand" == "up" ]; then
        
                newvolume=$((value + volumeStep))

            elif [ "$subcommand" == "down" ]; then

                newvolume=$((value - volumeStep))

            fi

            if [ "$newvolume" -ge "$volumeMin" ]; then
    

                if [ "$newvolume" -le "$volumeLimit" ]; then
    
                    jsonRequest="{\"current\": $newvolume}"
                    volumeStatusResponse=$(postRequest "/audio/volume" "$jsonRequest")                 
                    echo "ok"

                else
                echo "error $newvolume is bigger than $volumeLimit"
                fi

            else
                echo "error $newvolume is smaller than $volumeMin"
            fi

        else
  
            if [ "$subcommand" -ge "$volumeMin" ]; then

                if [ "$subcommand" -le "$volumeLimit" ]; then
    
                    jsonRequest="{\"current\": $subcommand}"
                    volumeStatusResponse=$(postRequest "/audio/volume" "$jsonRequest")                 
                    echo "ok"

                else
                    echo "error $newvolume is bigger than $volumeLimit"
                fi

            else
                #invalid volume value as subcommand
                echo "subcommand $command supports only: up, down, status, {value}"
                echo "subcommand $command supports value between $volumeMin and $volumeMax limited to $volumeLimit"
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
        echo "philipsTv.sh {host} {command} {subcommand}"
        echo ""
        echo "commands:"
        echo -e "\t power: {off|status}"   
        echo -e "\t input: {\$inputname|status}"
        echo -e "\t mute: {on|off|status}"   
        echo -e "\t volume: {up|down|status|\$value}"   
        echo ""
    
esac

######################################################################
