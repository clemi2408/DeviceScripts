#!/bin/bash
#cmdline
host=$1
command=$2
subcommand=$3

#debug
debug=false

#avr goes from slient -800 (-80,0 db) to loud 160 (16,0 db)
avrMax=160
avrMin=-800

# volume gets limited to -500 (-50db)
volumeLimit=-450 # -40,0 db

volumeStep=5 # increase and decrease 0,5 db

######################################################################

function sendRequest() {

    mode=$1
    blob=$2
    __resultvar=$3

  
    urlPattern="http://${host}/YamahaRemoteControl/ctrl"

    response="curl -s -X POST -d '<YAMAHA_AV cmd=\""${mode}\"">${blob}</YAMAHA_AV>' $urlPattern"
    eval $response


    if [[ "$__resultvar" ]]; then
        $__resultvar="'$response'"
    else
        echo "$myresult"
    fi




}

######################################################################

function power(){
    
    if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "on" ]; then
            #power on
            powerStatusResponse=$(sendRequest PUT "<System><Power_Control><Power>On</Power></Power_Control></System>")
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #power off
            powerStatusResponse=$(sendRequest PUT "<System><Power_Control><Power>Standby</Power></Power_Control></System>")
            echo "ok"
        
        elif [ "$subcommand" == "status" ]; then
            #power status
            powerStatusResponse=$(sendRequest GET "<Main_Zone><Power_Control><Power>GetParam</Power></Power_Control></Main_Zone>")
            local powerStatus=$(echo ${powerStatusResponse}|sed 's/.*<Power.//;s/..Power.*//')
            
            if [ "$powerStatus" == "On" ]; then
                echo "on"
            elif [ "$powerStatus" == "Standby" ]; then
                echo "off"
            else
                echo "error"
            fi

        elif [ "$subcommand" == "toggle" ]; then
            #toggle power status
            local newmode
            
            powerStatusResponse=$(sendRequest GET "<Main_Zone><Power_Control><Power>GetParam</Power></Power_Control></Main_Zone>")
           
            local isPower=$(echo ${powerStatusResponse}|sed 's/.*<Power.//;s/..Power.*//')
            
            [[ ${isPower} == Standby ]] && newmode=On || newmode=Standby
            powerStatusResponse=$(sendRequest PUT "<System><Power_Control><Power>${newmode}</Power></Power_Control></System>")
            echo "ok"
          

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
            inputStatusResponse=$(sendRequest GET "<Main_Zone><Input><Input_Sel>GetParam</Input_Sel></Input></Main_Zone>") 
            local inputStatus=$(echo ${inputStatusResponse}|sed 's/.*<Input_Sel.//;s/..Input_Sel.*//')
            echo $inputStatus
        else
            #set input to value
            inputResponse=$(sendRequest PUT "<Main_Zone><Input><Input_Sel>${subcommand}</Input_Sel></Input></Main_Zone>")
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

            muteStatusResponse=$(sendRequest GET "<Main_Zone><Volume><Mute>GetParam</Mute></Volume></Main_Zone>")
            local muteStatus=$(echo ${muteStatusResponse}|sed 's/.*<Mute.//;s/..Mute.*//')

            if [ "$muteStatus" == "On" ]; then
                echo "on"
            elif [ "$muteStatus" == "Off" ]; then
                echo "off"
            else
                echo "error"
            fi

        elif [ "$subcommand" == "on" ]; then
            #mute on
             muteStatusResponse=$(sendRequest PUT "<Main_Zone><Volume><Mute>On</Mute></Volume></Main_Zone>")
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #mute off
            muteStatusResponse=$(sendRequest PUT "<Main_Zone><Volume><Mute>Off</Mute></Volume></Main_Zone>")
            echo "ok"
        
        elif [ "$subcommand" == "toggle" ]; then
            #mute toggle
            local newmode
            muteStatusResponse=$(sendRequest GET "<Main_Zone><Volume><Mute>GetParam</Mute></Volume></Main_Zone>")
            local ismute=$(echo ${muteStatusResponse}|sed 's/.*<Mute.//;s/..Mute.*//')
            [[ ${ismute} == Off ]] && newmode=On || newmode=Off
            muteStatusResponse=$(sendRequest PUT "<Main_Zone><Volume><Mute>${newmode}</Mute></Volume></Main_Zone>")
            echo "ok"
        else
            #invalid subcommand
            echo "subcommand $command supports only: {on|off|toggle|status}"
           
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
            volumeStatusResponse=$(sendRequest GET "<Main_Zone><Volume><Lvl>GetParam</Lvl></Volume></Main_Zone>") 

            local volumeValue=$(echo ${volumeStatusResponse}|sed 's/.*<Val.//;s/..Val.*//')
            local exponent=$(echo ${volumeStatusResponse}|sed 's/.*<Exp.//;s/..Exp.*//')
            local unit=$(echo ${volumeStatusResponse}|sed 's/.*<Unit.//;s/..Unit.*//')

            echo "$volumeValue, $exponent, $unit"
        
        elif [ "$subcommand" == "up" ] || [ "$subcommand" = "down" ]; then
            
            volumeStatusResponse=$(sendRequest GET "<Main_Zone><Volume><Lvl>GetParam</Lvl></Volume></Main_Zone>") 
            
            local volumeValue=$(echo ${volumeStatusResponse}|sed 's/.*<Val.//;s/..Val.*//')
           
            if [ "$subcommand" == "up" ]; then
        
                newvolume=$((volumeValue + volumeStep))

            elif [ "$subcommand" == "down" ]; then

                newvolume=$((volumeValue - volumeStep))

            fi

          
            if ((   ($newvolume >= $avrMin) && ($newvolume <= $volumeLimit) )); then


                volumeStatusResponse=$(sendRequest PUT "<Main_Zone><Volume><Lvl><Val>${newvolume}</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone>")
                echo "ok"

            else
               echo "error $newvolume over limit $volumeLimit"
               
            fi 

        else
            
            if ((   ($subcommand >= $avrMin) && ($subcommand <= $volumeLimit) )); then

                volumeStatusResponse=$(sendRequest PUT "<Main_Zone><Volume><Lvl><Val>${subcommand}</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone>")
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
        echo "yamahaAvr.sh {host} {command} {subcommand}"
        echo ""
        echo "commands:"
        echo -e "\t power: {on|off|status}"   
        echo -e "\t input: {\$inputname|status}"
        echo -e "\t mute: {on|off|status}"   
        echo -e "\t volume: {up|down|status|\$value}"   
        echo ""
    
esac

######################################################################