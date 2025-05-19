#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m"
BOLD="\033[1m"

separator() {
  echo -e "${CYAN}==============================================${NC}"
}

read_input() {
  local prompt="$1"
  local var_name="$2"
  local valid_pattern="$3"
  local error_msg="$4"

  while true; do
    read -rp "$prompt" input
    if [[ "$input" =~ $valid_pattern ]]; then
      eval "$var_name=\"\$input\""
      break
    else
      echo -e "${RED}$error_msg${NC}"
    fi
  done
}

confirm() {
  local prompt="$1"
  while true; do
    read -rp "$prompt [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo -e "${RED}Invalid input. Please enter y or n.${NC}" ;;
    esac
  done
}

handle_error() {
  local msg="$1"
  echo -e "${RED}Error: $msg${NC}"
  mkdir -p logs
  if [[ ! -w "logs" ]]; then
    echo -e "${RED}Error: Cannot write to logs directory.${NC}"
    exit 1
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $msg" >> logs/error_log.txt
  exit 1
}

check_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    handle_error "$path does not exist."
  elif [[ ! -r "$path" ]]; then
    handle_error "$path is not readable."
  elif [[ -d "$path" && ! -z "$(ls -A "$path")" && ! -r "$path" ]]; then
    handle_error "$path is empty or not accessible."
  fi
}

search_pattern() {
  local pattern="$1"
  local file="$2"
  if [[ "$file" == *.gz ]]; then
    zgrep --color=auto "$pattern" "$file" || handle_error "Search failed in compressed file."
  else
    grep --color=auto "$pattern" "$file" || handle_error "Search failed in file."
  fi
}

check_dependencies() {
  local deps=("grep" "zgrep" "tail" "find")
  for dep in "${deps[@]}"; do
    command -v "$dep" &>/dev/null || handle_error "$dep is required but not installed."
  done
}

menu() {
  while true; do
    clear
    separator
    echo -e "${BOLD}${CYAN}GREP ADVANCED TOOL${NC}"
    separator
    echo -e "${YELLOW}1.${NC} Simple search in file"
    echo -e "${YELLOW}2.${NC} Case-insensitive search"
    echo -e "${YELLOW}3.${NC} Count pattern occurrences"
    echo -e "${YELLOW}4.${NC} Show line numbers"
    echo -e "${YELLOW}5.${NC} Exclude lines containing word"
    echo -e "${YELLOW}6.${NC} Recursive folder search"
    echo -e "${YELLOW}7.${NC} Highlight matches"
    echo -e "${YELLOW}8.${NC} Regex search"
    echo -e "${YELLOW}9.${NC} Context search (lines before/after)"
    echo -e "${YELLOW}10.${NC} Search in .gz files in folder"
    echo -e "${YELLOW}11.${NC} Save results to file"
    echo -e "${YELLOW}12.${NC} Live monitoring (tail + grep)"
    echo -e "${YELLOW}13.${NC} Exit"
    separator
    read -rp "Choose an option: " opt

    case $opt in
      1)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        search_pattern "$word" "$file"
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      2)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -i --color=auto "$word" "$file" || handle_error "Case-insensitive search failed."
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      3)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -c "$word" "$file" || handle_error "Count failed."
        echo -e "${GREEN}Count complete.${NC}"
        ;;
      4)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -n --color=auto "$word" "$file" || handle_error "Show line numbers failed."
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      5)
        read_input "Enter word to exclude: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -v --color=auto "$word" "$file" || handle_error "Excluding lines failed."
        echo -e "${GREEN}Exclusion complete.${NC}"
        ;;
      6)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter directory: " dir ".+" "Invalid directory."
        check_path "$dir"
        grep -r --color=auto "$word" "$dir" || handle_error "Recursive search failed."
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      7)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep --color=always "$word" "$file" || handle_error "Highlighting matches failed."
        echo -e "${GREEN}Highlight complete.${NC}"
        ;;
      8)
        read_input "Enter regex pattern: " pattern ".+" "Invalid regex."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -E --color=auto "$pattern" "$file" || handle_error "Regex search failed."
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      9)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter context lines (number): " ctx "^[0-9]+$" "Must be a number."
        read_input "Enter file name: " file ".+" "Invalid file name."
        check_path "$file"
        grep -B "$ctx" -A "$ctx" --color=auto "$word" "$file" || handle_error "Context search failed."
        echo -e "${GREEN}Context search complete.${NC}"
        ;;
      10)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter folder: " dir ".+" "Invalid folder."
        check_path "$dir"
        find "$dir" -type f -name "*.gz" -exec zgrep --color=always "$word" {} \; || handle_error "Search in .gz files failed."
        echo -e "${GREEN}Search complete.${NC}"
        ;;
      11)
        read_input "Enter search word: " word ".+" "Invalid input."
        read_input "Enter input file: " file ".+" "Invalid input file."
        read_input "Enter output file: " out ".+" "Invalid output file name."
        check_path "$file"
        grep --color=never "$word" "$file" > "$out" && echo -e "${GREEN}Results saved to $out${NC}" || handle_error "Saving results failed."
        ;;
      12)
        read_input "Enter log file to monitor: " file ".+" "Invalid file."
        read_input "Enter pattern to match: " word ".+" "Invalid input."
        check_path "$file"
        echo -e "${CYAN}Monitoring... Press Ctrl+C to stop.${NC}"
        tail -f "$file" | grep --line-buffered --color=always "$word" || handle_error "Live monitoring failed."
        ;;
      13)
        echo -e "${GREEN}Exiting...${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option. Try again.${NC}"
        ;;
    esac
    echo
    read -rp "Press ENTER to return to menu..." _
  done
}

set -o errexit -o nounset -o pipefail

check_dependencies

menu
