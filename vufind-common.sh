declare -A START_TIMES
declare -A LEVEL_TEXTS
LEVEL=0

start() {
  LEVEL=$(($LEVEL + 1))
  START_TIMES[$LEVEL]=$(date +%s.%N)
  LEVEL_TEXTS[$LEVEL]="$*"
  print_info $LEVEL Started "$*"
}

finish() {
  local EXIT_CODE START_TIME FINISH_TIME DURATION LEVEL_TEXT

  EXIT_CODE=$?
  START_TIME=${START_TIMES[$LEVEL]}
  FINISH_TIME=$(date +%s.%N)
  DURATION=$(LC_ALL=C printf '%.2f' $(bc -l <<< "($FINISH_TIME - $START_TIME) / 60"))
  LEVEL_TEXT=${LEVEL_TEXTS[$LEVEL]}
  print_info $LEVEL Finished "$LEVEL_TEXT" in $DURATION minutes $(
    if [[ $LEVEL = 1 ]]
    then
      echo with exit code $EXIT_CODE
    fi
  )
  LEVEL=$(($LEVEL - 1))
}

print_info() {
  printf '%s:\t%s%s\n' "$(date --rfc-3339=seconds)" \
    "$(for INDEX in $(seq 2 $1); do printf '  '; done)" \
    "${*:2}"
}
