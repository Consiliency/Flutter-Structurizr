#!/bin/bash

# Ensure logs directory exists
mkdir -p logs

TABLES=(
  "Table_1__Token_ContextStack_Node_Foundation"
  "Table_2__Model_Node_Group_Enterprise_Element_Foundation"
  "Table_3__IncludeParser_Methods"
  "Table_4__ElementParser_Methods"
  "Table_5__RelationshipParser_Methods"
  "Table_6__ViewsParser_Methods"
  "Table_7__ModelParser_Methods"
  "Table_8__WorkspaceBuilderImpl___SystemContextViewParser_Methods"
)

COMPLETION_FLAG_REQ='**AT THE END OF YOUR OUTPUT, YOU MUST PRINT ONE OF THE FOLLOWING STATUS WORDS (AS THE LAST LINE, INSIDE ANGLE BRACKETS): <Complete>, <Incomplete>, or <Error>. CHOOSE <Complete> IF YOU FINISHED THE JOB, <Incomplete> IF YOU PARTIALLY COMPLETED THE JOB, OR <Error> IF YOU ENCOUNTERED AN ERROR. DO NOT OUTPUT ANYTHING AFTER THIS STATUS WORD.**'

MAX_RETRIES=10
declare -A TEST_PIDS
declare -A IMPL_PIDS
declare -A TEST_RETRIES
declare -A IMPL_RETRIES

echo "Launching all TEST agents in parallel..."

for TABLE in "${TABLES[@]}"; do
  PROMPT_FILE="claude_prompt_${TABLE}.md"
  TEST_LOG="logs/$(basename "$PROMPT_FILE" .md).log"
  echo "Launching TEST agent for: $TABLE (log: $TEST_LOG)"
  (echo -e "$COMPLETION_FLAG_REQ\n"; \
   cat "$PROMPT_FILE"; \
   echo -e "\n$COMPLETION_FLAG_REQ\n") | claude -p - > "$TEST_LOG" 2>&1 &
  TEST_PIDS[$TABLE]=$!
  TEST_RETRIES[$TABLE]=0
  IMPL_RETRIES[$TABLE]=0
  # IMPL_PIDS will be set later
  # IMPL_LAUNCHED will be set later

done

success_count=0
fail_count=0

declare -A IMPL_LAUNCHED

echo "Monitoring TEST agents and launching IMPLEMENTATION agents as soon as their tests succeed..."

done_tables=()
while [ ${#done_tables[@]} -lt ${#TABLES[@]} ]; do
  for TABLE in "${TABLES[@]}"; do
    if [[ " ${done_tables[@]} " =~ " $TABLE " ]]; then
      continue
    fi
    PID=${TEST_PIDS[$TABLE]}
    if ! kill -0 $PID 2>/dev/null; then
      PROMPT_FILE="claude_prompt_${TABLE}.md"
      TEST_LOG="logs/$(basename "$PROMPT_FILE" .md).log"
      # Get last non-empty line as status
      STATUS_LINE=$(tac "$TEST_LOG" | grep -m 1 -v '^\s*$')
      STATUS="Unknown"
      if [[ "$STATUS_LINE" == "<Complete>" ]]; then
        STATUS="Complete"
      elif [[ "$STATUS_LINE" == "<Incomplete>" ]]; then
        STATUS="Incomplete"
      elif [[ "$STATUS_LINE" == "<Error>" ]]; then
        STATUS="Error"
      fi
      ABS_PATH="$(realpath "$TEST_LOG")"
      echo -e "Test Agent for $TABLE finished. Log: file://$ABS_PATH"
      echo "Test Agent Status: $STATUS"
      if [[ "$STATUS" == "Complete" ]]; then
        ((success_count++))
        # Launch implementation agent
        IMPL_PROMPT_FILE="claude_prompt_${TABLE}_impl.md"
        IMPL_LOG="logs/$(basename "$IMPL_PROMPT_FILE" .md).log"
        echo "Launching IMPLEMENTATION agent for: $TABLE (log: $IMPL_LOG)"
        (echo -e "$COMPLETION_FLAG_REQ\n"; \
         cat "$IMPL_PROMPT_FILE"; \
         echo -e "\n$COMPLETION_FLAG_REQ\n") | claude -p - > "$IMPL_LOG" 2>&1 &
        IMPL_PIDS[$TABLE]=$!
        IMPL_LAUNCHED[$TABLE]=1
      else
        ((fail_count++))
        IMPL_LAUNCHED[$TABLE]=0
        # Retry logic for TEST agent
        while [ ${TEST_RETRIES[$TABLE]} -lt $MAX_RETRIES ]; do
          ((TEST_RETRIES[$TABLE]++))
          RETRY_LOG="logs/$(basename "$PROMPT_FILE" .md)_retry${TEST_RETRIES[$TABLE]}.log"
          echo "Retrying TEST agent for $TABLE (attempt ${TEST_RETRIES[$TABLE]})"
          (echo -e "$COMPLETION_FLAG_REQ\n"; \
           cat "$PROMPT_FILE"; \
           echo -e "\n$COMPLETION_FLAG_REQ\n"; \
           echo -e "\nThis is where the last agent left off. Please complete their work.\n"; \
           echo -e "\n===== Previous Agent Log Output =====\n"; \
           cat "$TEST_LOG") | claude -p - > "$RETRY_LOG" 2>&1
          STATUS_LINE_RETRY=$(tac "$RETRY_LOG" | grep -m 1 -v '^\s*$')
          STATUS_RETRY="Unknown"
          if [[ "$STATUS_LINE_RETRY" == "<Complete>" ]]; then
            STATUS_RETRY="Complete"
          elif [[ "$STATUS_LINE_RETRY" == "<Incomplete>" ]]; then
            STATUS_RETRY="Incomplete"
          elif [[ "$STATUS_LINE_RETRY" == "<Error>" ]]; then
            STATUS_RETRY="Error"
          fi
          if [[ "$STATUS_RETRY" == "Complete" ]]; then
            ((success_count++))
            # Launch implementation agent
            IMPL_PROMPT_FILE="claude_prompt_${TABLE}_impl.md"
            IMPL_LOG="logs/$(basename "$IMPL_PROMPT_FILE" .md).log"
            echo "Launching IMPLEMENTATION agent for: $TABLE (log: $IMPL_LOG)"
            (echo -e "$COMPLETION_FLAG_REQ\n"; \
             cat "$IMPL_PROMPT_FILE"; \
             echo -e "\n$COMPLETION_FLAG_REQ\n") | claude -p - > "$IMPL_LOG" 2>&1 &
            IMPL_PIDS[$TABLE]=$!
            IMPL_LAUNCHED[$TABLE]=1
            break
          fi
        done
      fi
      done_tables+=("$TABLE")
    fi
  done
  sleep 1
done

# Wait for all implementation agents that were launched
echo "Waiting for all IMPLEMENTATION agents to finish..."
for TABLE in "${TABLES[@]}"; do
  if [[ "${IMPL_LAUNCHED[$TABLE]}" == "1" ]]; then
    PID=${IMPL_PIDS[$TABLE]}
    if [ -n "$PID" ]; then
      wait $PID
      IMPL_PROMPT_FILE="claude_prompt_${TABLE}_impl.md"
      IMPL_LOG="logs/$(basename "$IMPL_PROMPT_FILE" .md).log"
      STATUS_LINE_IMPL=$(tac "$IMPL_LOG" | grep -m 1 -v '^\s*$')
      STATUS_IMPL="Unknown"
      if [[ "$STATUS_LINE_IMPL" == "<Complete>" ]]; then
        STATUS_IMPL="Complete"
      elif [[ "$STATUS_LINE_IMPL" == "<Incomplete>" ]]; then
        STATUS_IMPL="Incomplete"
      elif [[ "$STATUS_LINE_IMPL" == "<Error>" ]]; then
        STATUS_IMPL="Error"
      fi
      # Retry logic for IMPLEMENTATION agent
      while [[ "$STATUS_IMPL" != "Complete" && ${IMPL_RETRIES[$TABLE]} -lt $MAX_RETRIES ]]; do
        ((IMPL_RETRIES[$TABLE]++))
        RETRY_IMPL_LOG="logs/$(basename "$IMPL_PROMPT_FILE" .md)_retry${IMPL_RETRIES[$TABLE]}.log"
        echo "Retrying IMPLEMENTATION agent for $TABLE (attempt ${IMPL_RETRIES[$TABLE]})"
        (echo -e "$COMPLETION_FLAG_REQ\n"; \
         cat "$IMPL_PROMPT_FILE"; \
         echo -e "\n$COMPLETION_FLAG_REQ\n"; \
         echo -e "\nThis is where the last agent left off. Please complete their work.\n"; \
         echo -e "\n===== Previous Agent Log Output =====\n"; \
         cat "$IMPL_LOG") | claude -p - > "$RETRY_IMPL_LOG" 2>&1
        STATUS_LINE_IMPL=$(tac "$RETRY_IMPL_LOG" | grep -m 1 -v '^\s*$')
        STATUS_IMPL="Unknown"
        if [[ "$STATUS_LINE_IMPL" == "<Complete>" ]]; then
          STATUS_IMPL="Complete"
        elif [[ "$STATUS_LINE_IMPL" == "<Incomplete>" ]]; then
          STATUS_IMPL="Incomplete"
        elif [[ "$STATUS_LINE_IMPL" == "<Error>" ]]; then
          STATUS_IMPL="Error"
        fi
      done
      ABS_PATH_IMPL="$(realpath "$IMPL_LOG")"
      echo -e "Impl Agent for $TABLE finished. Log: file://$ABS_PATH_IMPL"
      echo "Impl Agent Status: $STATUS_IMPL"
    fi
  fi
done

echo "\n=== SUMMARY ==="
echo "Tables with successful test agents: $success_count"
echo "Tables with failed test agents: $fail_count"
echo "Check logs in the logs/ directory for details."