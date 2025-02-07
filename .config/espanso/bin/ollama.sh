#!/bin/bash

# Function to show usage
function show_usage() {
  echo "Usage: $0 '<message>' <task>"
  echo "Task options:"
  echo "  grammar  - Correct grammar"
  echo "  paraphrase - Paraphrase the text"
  exit 1
}

# Check if the correct number of parameters is provided
if [ "$#" -ne 2 ]; then
  show_usage
fi

# User-provided message and task
USER_MESSAGE="$1"
TASK="$2"

# Validate the task input
if [[ "$TASK" != "grammar" && "$TASK" != "paraphrase" ]]; then
  echo "Error: Invalid task. Must be 'grammar' or 'paraphrase'."
  show_usage
fi

# Set task-specific prompt
if [ "$TASK" == "grammar" ]; then
  PROMPT="Please correct the grammar in the following text only give the result no need additional information:"
elif [ "$TASK" == "paraphrase" ]; then
  PROMPT="Please paraphrase the following text:"
fi

# Combine the task-specific prompt with the user's message
FULL_PROMPT="$PROMPT $USER_MESSAGE"

# API endpoint and authorization
API_URL="https://olla.nexanode.live/api/generate"
AUTH_HEADER="Authorization: Basic ZXppbzpCaW5nbyE="

# Make the API request and capture the response
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d "{
  \"model\": \"phi4:latest\",
  \"prompt\": \"$FULL_PROMPT\"
}")

# Extract and print only the content message
CONTENT=$(echo "$RESPONSE" | jq -r '.response')
echo "$CONTENT"
