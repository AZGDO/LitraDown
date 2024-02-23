#!/usr/bin/env bash
#Script created by AZGD0
#Thanks to all palera1n discord for such good community
os=$(uname)
echo -e "\e[1;36m iOS 16.7.X to 16.6.X unified downgrader \e[0m"
echo "Detected os: $os"
if [ "$os" = "Darwin" ]
then
futurerestore="futurerestore-macos"
else
futurerestore="futurerestore-linux"
fi
read -p "Specify your iPSW path(you can drag and drop to terminal): " ipswpath 
read -p "Specify your SHSH2 blob path(you can drag and drop to terminal): " blobpath
read -p "Did you already set nonce? (Y/N)" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS]] ]] || nonce=0
step() {
    rm -f .entered_dfu
    for i in $(seq "$1" -1 0); do
        if [[ -e .entered_dfu ]]; then
            rm -f .entered_dfu
            break
        fi
        if [[ $(get_device_mode) == "dfu" || ($1 == "10" && $(get_device_mode) != "none") ]]; then
            touch .entered_dfu
        fi &
        printf '\r\e[K\e[1;36m%s (%d)' "$2" "$i"
        sleep 1
    done
    printf '\e[0m\n'
}
get_device_mode() {
    if [ "$os" = "Darwin" ]; then
        sp="$(system_profiler SPUSBDataType 2> /dev/null)"
        apples="$(printf '%s' "$sp" | grep -B1 'Vendor ID: 0x05ac' | grep 'Product ID:' | cut -dx -f2 | cut -d' ' -f1 | tail -r)"
    elif [ "$os" = "Linux" ]; then
        apples="$(lsusb | cut -d' ' -f6 | grep '05ac:' | cut -d: -f2)"
    fi
    local device_count=0
    local usbserials=""
    for apple in $apples; do
        case "$apple" in
            12a8|12aa|12ab)
            device_mode=normal
            device_count=$((device_count+1))
            ;;
            1281)
            device_mode=recovery
            device_count=$((device_count+1))
            ;;
            1227)
            device_mode=dfu
            device_count=$((device_count+1))
            ;;
            1222)
            device_mode=diag
            device_count=$((device_count+1))
            ;;
            1338)
            device_mode=checkra1n_stage2
            device_count=$((device_count+1))
            ;;
            4141)
            device_mode=pongo
            device_count=$((device_count+1))
            ;;
        esac
    done
    if [ "$device_count" = "0" ]; then
        device_mode=none
    elif [ "$device_count" -ge "2" ]; then
        echo -e "\e[1;31m [-] Please attach only one device \e[0m" > /dev/tty
        kill -30 0
        exit 1;
    fi
    if [ "$os" = "Linux" ]; then
        usbserials=$(cat /sys/bus/usb/devices/*/serial)
    elif [ "$os" = "Darwin" ]; then
        usbserials=$(printf '%s' "$sp" | grep 'Serial Number' | cut -d: -f2- | sed 's/ //')
    fi
    if grep -qE '(ramdisk tool|SSHRD_Script) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}' <<< "$usbserials"; then
        device_mode=ramdisk
    fi
    echo "$device_mode"
}
dfu_help(){
if [ "$(get_device_mode)" = "dfu" ]; then
        echo -e "\e[1;36m [*] Device is already in DFU \e[0m"
        return
    fi

    local step_one;
    deviceid=$( [ -z "$deviceid" ] && _info normal ProductType || echo $deviceid )
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step_one="Hold volume down + side button"
    else
        step_one="Hold home + power button"
    fi
    if $dfuhelper_first_try; then
        echo -e "\e[1;36m [*] Press any key when ready for DFU mode \e[0m"
        read -n 1 -s
        dfuhelper_first_try=false
    fi
    step 3 "Get ready"
    step 4 "$step_one" &
    sleep 2
    ./irecovery-$os -c "reset" &
    wait
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step 10 'Release side button, but keep holding volume down'
    else
        step 10 'Release power button, but keep holding home button'
    fi
    sleep 1
    
    if [ "$(get_device_mode)" = "dfu" ]; then
        echo -e "\e[1;32m [*] Device entered DFU! \e[0m"
        dfuhelper_first_try=true
    else
        echo -e "\e[1;31m [-] Device did not enter DFU mode \e[0m"
        exit
    fi
}
_info() {
    if [ "$1" = 'recovery' ]; then
        echo $(./irecovery-$os -q | grep "$2" | sed "s/$2: //")
    elif [ "$1" = 'normal' ]; then
        echo $(./ideviceinfo-$os | grep "$2: " | sed "s/$2: //")
    fi
}
if [ $nonce -eq 0 ]
then
dfu_help
echo -e "\e[1;36m [*] Pwning device via Gaster \e[0m"
./gaster pwn
./gaster reset
echo "\e[1;36m [*] Setting NONCE \e[0m"
./$futurerestore -t $blobpath -0 -1 -3 -7 $ipswpath
echo -e "If setting NONCE fails you should try set it via Dimentio"
fi
echo -e "\e[1;36m [*] Flashing device to 16.6.X \e[0m"
./$futurerestore -t $blobpath -0 -1 $ipswpath
echo "Done! If futurerestore gives an error try manually setting nonce via Dimentio, or check your blob and ipsw"
