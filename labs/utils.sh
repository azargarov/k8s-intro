# ── colors ────────────────────────────────────────────
RST=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
BLUE=$'\e[38;5;75m'
GREEN=$'\e[38;5;114m'
PURPLE=$'\e[38;5;141m'
CYAN=$'\e[38;5;80m'
YELLOW=$'\e[38;5;180m'
GRAY=$'\e[38;5;59m'

SEP="${GRAY}$(printf '%.0s─' {1..52})${RST}"
step() { echo; echo "${BLUE}${BOLD}[$1/$2]${RST} ${BOLD}$3${RST}"; echo "${GRAY}$(printf '%.0s┄' {1..48})${RST}"; }

# ── banner ────────────────────────────────────────────
banner(){
    echo "$SEP"
    printf "  ${PURPLE}${BOLD}lab: ${1}${RST}\n"
    echo "$SEP"
}

tip() {
  echo "  ${CYAN}tip:${RST} $*"
}

pause_lab() {
  echo
  read -n 1 -srp "  press any key to continue..."
  echo
}