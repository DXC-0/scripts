#!/usr/bin/env bash

set -u

trap 'stty sane; tput cnorm' EXIT

print_banner() {
    echo -e " ▄▖  ▗         ▖  ▖            "
    echo -e " ▌▌▛▘▜▘▛▘█▌█▌  ▛▖▞▌▀▌▛▌▀▌▛▌█▌▛▘"
    echo -e " ▙▌▄▌▐▖▌ ▙▖▙▖  ▌▝ ▌█▌▌▌█▌▙▌▙▖▌ "
    echo -e "                                   by DXC-0   ▄    "
    echo
    echo -e " 'Enjoy the art of atomic updates' "
    echo
}

MENU_ITEMS=(
    "Show deployments"
    "Pin a deployment"
    "Unpin a deployment"
    "Rollback"
    "Rebase image"
    "System update"
    "Quit"
)

cursor=0
CONFIRM_RESULT=1

BOLD=$(tput bold)
REV=$(tput rev)
RESET=$(tput sgr0)

read_key() {
    local key
    IFS= read -rsn1 key || true

    case "${key-}" in
        "")
            echo "ENTER"
            ;;
        $'\n')
            echo "ENTER"
            ;;
        $'\x1b')
            read -rsn2 key || true
            case "${key-}" in
                "[A") echo "UP" ;;
                "[B") echo "DOWN" ;;
                *) echo "OTHER" ;;
            esac
            ;;
        *)
            echo "${key-}"
            ;;
    esac
}

draw_menu() {
    clear
    print_banner

    for i in "${!MENU_ITEMS[@]}"; do
        if [[ $i -eq $cursor ]]; then
            echo -e "${REV}${MENU_ITEMS[$i]}${RESET}"
        else
            echo " ${MENU_ITEMS[$i]}"
        fi
    done
}

show_deployments() {
    clear
    echo -e "${BOLD}Current deployments${RESET}"
    echo
    rpm-ostree status
    echo
    read -rp "Press Enter to return..."
}

confirm_action() {
    local message="$1"
    local yes="$2"
    local no="$3"

    local OPTIONS=("$yes" "$no")
    local idx=0
    local key

    while true; do
        clear
        print_banner

        echo -e "${BOLD}${message}${RESET}"
        echo

        for i in "${!OPTIONS[@]}"; do
            if [[ $i -eq $idx ]]; then
                echo -e "${REV}${OPTIONS[$i]}${RESET}"
            else
                echo " ${OPTIONS[$i]}"
            fi
        done

        key=$(read_key)

        case "$key" in
            UP)
                ((idx--))
                ((idx < 0)) && idx=1
                ;;
            DOWN)
                ((idx++))
                ((idx > 1)) && idx=0
                ;;
            ENTER)
                CONFIRM_RESULT=$idx
                return
                ;;
            q)
                CONFIRM_RESULT=1
                return
                ;;
        esac
    done
}

pin_deployment() {
    clear
    echo "Loading deployments..."
    echo "Please wait..."

    mapfile -t DEPS < <(
        rpm-ostree status --json | jq -r '
            .deployments
            | to_entries[]
            | "\(.key)|\(.value.id) \(.value.checksum[0:12])"
        '
    )

    local idx=0
    local key
    local display
    local real_index

    while true; do
        clear
        print_banner

        echo -e "${BOLD}Select deployment to PIN${RESET}"
        echo

        for i in "${!DEPS[@]}"; do
            display="${DEPS[$i]#*|}"
            if [[ $i -eq $idx ]]; then
                echo -e "${REV}${display}${RESET}"
            else
                echo " ${display}"
            fi
        done

        key=$(read_key)

        case "$key" in
            UP)
                ((idx--))
                ((idx < 0)) && idx=$((${#DEPS[@]} - 1))
                ;;
            DOWN)
                ((idx++))
                ((idx >= ${#DEPS[@]})) && idx=0
                ;;
            ENTER)
                confirm_action "Confirm PIN?" "Yes" "Cancel"

                if [[ $CONFIRM_RESULT -eq 0 ]]; then
                    real_index="${DEPS[$idx]%%|*}"
                    echo "Pinning deployment $real_index"
                    sudo ostree admin pin "$real_index"
                    read -rp "Press Enter..."
                fi
                return
                ;;
            q)
                return
                ;;
        esac
    done
}

unpin_deployment() {
    clear
    echo "Loading pinned deployments..."
    echo "Please wait..."

    mapfile -t PINNED < <(
        rpm-ostree status --json | jq -r '
            .deployments
            | to_entries[]
            | select(.value.pinned==true)
            | "\(.key)|\(.value.id) \(.value.checksum[0:12])"
        '
    )

    local idx=0
    local key
    local display
    local real_index

    while true; do
        clear
        print_banner

        echo -e "${BOLD}Select deployment to UNPIN${RESET}"
        echo

        if [[ ${#PINNED[@]} -eq 0 ]]; then
            echo "No pinned deployments."
            echo
            read -rp "Press Enter..."
            return
        fi

        for i in "${!PINNED[@]}"; do
            display="${PINNED[$i]#*|}"
            if [[ $i -eq $idx ]]; then
                echo -e "${REV}${display}${RESET}"
            else
                echo " ${display}"
            fi
        done

        key=$(read_key)

        case "$key" in
            UP)
                ((idx--))
                ((idx < 0)) && idx=$((${#PINNED[@]} - 1))
                ;;
            DOWN)
                ((idx++))
                ((idx >= ${#PINNED[@]})) && idx=0
                ;;
            ENTER)
                confirm_action "Confirm UNPIN?" "Yes" "Cancel"

                if [[ $CONFIRM_RESULT -eq 0 ]]; then
                    real_index="${PINNED[$idx]%%|*}"
                    echo "Unpinning deployment $real_index"
                    sudo ostree admin pin --unpin "$real_index"
                    read -rp "Press Enter..."
                fi
                return
                ;;
            q)
                return
                ;;
        esac
    done
}

rollback() {
    confirm_action "Confirm rollback?" "Yes" "Cancel"

    if [[ $CONFIRM_RESULT -eq 0 ]]; then
        clear
        echo "Rolling back..."
        sudo rpm-ostree rollback
        read -rp "Press Enter..."
    fi
}

rebase() {
    clear
    echo "Loading refs..."
    mapfile -t REFS < <(ostree remote refs fedora)

    local idx=0
    local key

    while true; do
        clear
        print_banner

        echo -e "${BOLD}Select rebase image${RESET}"
        echo

        for i in "${!REFS[@]}"; do
            if [[ $i -eq $idx ]]; then
                echo -e "${REV}${REFS[$i]}${RESET}"
            else
                echo " ${REFS[$i]}"
            fi
        done

        key=$(read_key)

        case "$key" in
            UP)
                ((idx--))
                ((idx < 0)) && idx=$((${#REFS[@]} - 1))
                ;;
            DOWN)
                ((idx++))
                ((idx >= ${#REFS[@]})) && idx=0
                ;;
            ENTER)
                confirm_action "Confirm rebase?" "Yes" "Cancel"

                if [[ $CONFIRM_RESULT -eq 0 ]]; then
                    echo "Rebasing to: ${REFS[$idx]}"
                    sudo rpm-ostree rebase "${REFS[$idx]}"
                    read -rp "Press Enter..."
                fi
                return
                ;;
            q)
                return
                ;;
        esac
    done
}

update_system() {
    confirm_action "Run system update?" "Yes" "Cancel"

    if [[ $CONFIRM_RESULT -eq 0 ]]; then
        clear
        echo "Updating system..."
        echo

        sudo rpm-ostree upgrade

        echo
        echo "Update complete."
        read -rp "Press Enter..."
    fi
}

execute_choice() {
    case $cursor in
        0) show_deployments ;;
        1) pin_deployment ;;
        2) unpin_deployment ;;
        3) rollback ;;
        4) rebase ;;
        5) update_system ;;
        6)
            clear
            exit 0
            ;;
    esac
}

while true; do
    draw_menu
    key=$(read_key)

    case "$key" in
        UP)
            ((cursor--))
            ((cursor < 0)) && cursor=$((${#MENU_ITEMS[@]} - 1))
            ;;
        DOWN)
            ((cursor++))
            ((cursor >= ${#MENU_ITEMS[@]})) && cursor=0
            ;;
        ENTER)
            execute_choice
            ;;
        q)
            clear
            exit 0
            ;;
    esac
done
