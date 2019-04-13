#!/bin/sh
host=$1
username=$2
command=$3
lampId=$4
subcommand=$5
brightnessStep=20
brightnessMin=0
brightnessMax=254

apiUrl="http://$host/api/"
userUrl=$apiUrl$username


# Press Button & get Username
# url: http://$host/api
# method: post
# body: {"devicetype":"my_hue_app#postman"}
# response: [{"success": {"username": "E538lje4yg3wqpOnP49QQD1B7z-36IGSbJgdCZdc"}}]

################################## CORE ###############################
function setPowerStatus(){
  local lightId=$1
  local onOff=$2
  local url=$userUrl/lights/$lightId/state

  result=$(curl -s --request PUT --data "{\"on\":$onOff}" $url)

}
function getPowerStatus(){

    local lightId=$1
    local url=$userUrl/lights/$lightId/

    DATA=$(curl -s --request GET $url)

    if [ "${DATA:15:5}" = "false" ]; then

    echo "off"

    elif [ "${DATA:15:4}" = "true" ]; then

    echo "on"
    
    else
    echo "ERROR"
    fi

}
function setBrightness(){
    local lightId=$1
    local brightness=$2
    local url=$userUrl/lights/$lightId/state

    result=$(curl -s --request PUT --data "{\"on\":true,\"bri\":$brightness}" $url)

    echo $result
}
function getBrightnessStatus(){

    local lightId=$1
    local url=$userUrl/lights/$lightId/

    RESPONSE=$(curl -s --request GET $url)

    pre="${RESPONSE:26:5}"
    post="$(echo $pre | cut -d',' -f1)"

    echo $post

}
function bridge(){

     if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "help" ]; then

            echo ""
            echo "Press the Button on the Hue Bridge and run:"
            echo "\t ./philipsHue.sh {bridgeIp} connect bridge to {devicename}"
            echo ""

        elif [ "$lampId" == "to" ]; then


            if [ ${#subcommand} -ge 2 ]; then 
                
            
                DATA=$(curl -s --request POST --data "{\"devicetype\":\"$subcommand\"}" $apiUrl)
                echo ""

                if [ "${DATA:3:5}"  = "error" ]; then
                        
                        echo "Bridge error"
                        subcommand="help"
                        bridge
                else
    
                    if [ "${DATA:3:7}"  = "success" ]; then
                        echo "Device $subcommand bridged with $bridgeIp"
                        echo ""
                        newUser="${DATA:25:40}"
                        echo "\tusername: $newUser"
                        echo ""
                        echo "Use this value for further requests"
                        echo ""
                    
                    else
                        echo "Bridge error"
                        subcommand="help"
                        bridge
                    fi 
                fi

            else 
                echo "Device Name should have at least 2 characters"
            fi

            
        fi

    else 
        subcommand="help"
        bridge
        
    fi


}

################################## EXTENDED ###########################
function power(){
    
    if [ ! -z "$subcommand" ]; then
        if [ "$subcommand" == "on" ]; then
            #power on
            setPowerStatus $lampId true
            echo "ok"
        
        elif [ "$subcommand" == "off" ]; then
            #power off
            setPowerStatus $lampId false
            echo "ok"

        elif [ "$subcommand" == "toggle" ]; then
            #toggle power status
            #power status
            powerStatusResponse=$(getPowerStatus $lampId)  

       
            if [ $powerStatusResponse == "off" ]; then
                setPowerStatus $lampId true
                echo "ok"
           
            elif [ $powerStatusResponse == "on" ]; then
                setPowerStatus $lampId false
                echo "ok"
            else
                echo "error: $value"
            fi

        elif [ "$subcommand" == "status" ]; then

            #power status
            powerStatusResponse=$(getPowerStatus $lampId)  
       
            if [ $powerStatusResponse == "off" ]; then
                echo "off"
           
            elif [ $powerStatusResponse == "on" ]; then
                echo "on"
            else
                echo "error: $value"
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
function brightness(){

      if [ ! -z "$subcommand" ]; then

        if [ "$subcommand" == "status" ]; then
            #brightness status
            brightnessStatus=$(getBrightnessStatus $lampId)  

            echo $brightnessStatus

        elif [ "$subcommand" == "up" ] || [ "$subcommand" = "down" ]; then
                   
            brightnessStatus=$(getBrightnessStatus $lampId)  
           
            if [ "$subcommand" == "up" ]; then
        
                newBrightness=$((brightnessStatus + brightnessStep))

            elif [ "$subcommand" == "down" ]; then

                newBrightness=$((brightnessStatus - brightnessStep))

            fi

            if [ "$newBrightness" -ge "$brightnessMin" ]; then
    

                if [ "$newBrightness" -le "$brightnessMax" ]; then
    
                    result=$(setBrightness $lampId $newBrightness)
                     
                      echo "ok"

                else
                echo "error $newBrightness is bigger than $brightnessMax"
                fi



            else
                echo "error $newBrightness is smaller than $brightnessMin"
            fi

        else
  
            if [ "$subcommand" -ge "$brightnessMin" ]; then

                if [ "$subcommand" -le "$brightnessMax" ]; then
    
                    result=$(setBrightness $lampId $subcommand)
                    echo "ok"

                else
                    echo "error $newBrightness is bigger than $brightnessMax"
                fi

            else
                #invalid brightness value as subcommand
                echo "subcommand $command supports only: up, down, status, {value}"
                echo "subcommand $command supports value between $brightnessMin and $brightnessMax"
            fi
          
        fi

    else 
        subcommand="status"
        brightness $subcommand
    fi
}
######################################################################
case $command in
    power)
        power
        ;;
    brightness)
        brightness
        ;;
    bridge)
        bridge
        ;;
    *)
        echo ""
        echo "philipsHue.sh {bridgeIp} {username} {command} {lampId} {subcommand}"
        echo ""
        echo "commands:"
        echo -e "\t power: {on|off|status|toggle}"    
        echo -e "\t brightness: {up|down|status|\$value}"   
        echo -e "\t bridge \$deviceName"
        echo ""
    
esac
