#!/usr/bin/env bash
set -euo pipefail

# Get bot username
BOT_USER=$(gh api /user --jq '.login')
echo "Bot user: $BOT_USER"

# Fetch unread notifications
NOTIFICATIONS=$(gh api /notifications --jq '
  [.[] | select(.reason == "mention" and (.subject.type == "Issue" or .subject.type == "PullRequest"))]
')

COUNT=$(echo "$NOTIFICATIONS" | jq 'length')
echo "Found $COUNT mention notifications"

if [ "$COUNT" -eq 0 ]; then
  echo "No notifications to process."
  exit 0
fi

echo "$NOTIFICATIONS" | jq -c '.[]' | while read -r notif; do
  THREAD_ID=$(echo "$notif" | jq -r '.id')
  SUBJECT_TYPE=$(echo "$notif" | jq -r '.subject.type')
  SUBJECT_URL=$(echo "$notif" | jq -r '.subject.url')
  LATEST_COMMENT_URL=$(echo "$notif" | jq -r '.subject.latest_comment_url')

  echo "---"
  echo "Processing thread $THREAD_ID ($SUBJECT_TYPE)"

  # Get the comment that triggered the notification
  if [ "$LATEST_COMMENT_URL" = "null" ] || [ -z "$LATEST_COMMENT_URL" ]; then
    echo "  No comment URL, skipping."
    gh api -X PATCH "/notifications/threads/$THREAD_ID" 2>/dev/null || true
    continue
  fi

  COMMENT=$(gh api "$LATEST_COMMENT_URL" 2>/dev/null) || {
    echo "  Failed to fetch comment, skipping."
    gh api -X PATCH "/notifications/threads/$THREAD_ID" 2>/dev/null || true
    continue
  }

  COMMENT_BODY=$(echo "$COMMENT" | jq -r '.body')
  COMMENT_ID=$(echo "$COMMENT" | jq -r '.id')
  COMMENT_USER=$(echo "$COMMENT" | jq -r '.user.login')

  # Parse @bot command from comment body
  # Match @bot-username command [args...]
  MENTION_PATTERN="@${BOT_USER}[[:space:]]+([a-zA-Z_-]+)(.*)"
  if ! echo "$COMMENT_BODY" | grep -qEi "$MENTION_PATTERN"; then
    echo "  No command found in comment, skipping."
    gh api -X PATCH "/notifications/threads/$THREAD_ID" 2>/dev/null || true
    continue
  fi

  COMMAND=$(echo "$COMMENT_BODY" | grep -oEi "$MENTION_PATTERN" | head -1 | sed -E "s/@${BOT_USER}[[:space:]]+//i" | awk '{print $1}')
  ARGS=$(echo "$COMMENT_BODY" | grep -oEi "$MENTION_PATTERN" | head -1 | sed -E "s/@${BOT_USER}[[:space:]]+[a-zA-Z_-]+[[:space:]]?//i")
  COMMAND=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

  echo "  Command: $COMMAND"
  echo "  Args: $ARGS"

  # Extract repo and issue number from the subject URL
  # subject.url looks like: https://api.github.com/repos/owner/repo/issues/123
  SOURCE_REPO=$(echo "$SUBJECT_URL" | sed -E 's|.*/repos/([^/]+/[^/]+)/.*|\1|')
  ISSUE_NUMBER=$(echo "$SUBJECT_URL" | sed -E 's|.*/([0-9]+)$|\1|')

  echo "  Repo: $SOURCE_REPO"
  echo "  Issue: #$ISSUE_NUMBER"

  # Check repo whitelist
  if [ -n "${REPO_WHITELIST:-}" ]; then
    if ! echo "$SOURCE_REPO" | grep -qE "$REPO_WHITELIST"; then
      echo "  Repo not in whitelist, skipping."
      gh api -X PATCH "/notifications/threads/$THREAD_ID" 2>/dev/null || true
      continue
    fi
  fi

  # Add 👀 reaction to the comment
  # Determine reaction API path based on comment type
  if echo "$LATEST_COMMENT_URL" | grep -q "/issues/comments/"; then
    REACTION_URL="repos/$SOURCE_REPO/issues/comments/$COMMENT_ID/reactions"
  elif echo "$LATEST_COMMENT_URL" | grep -q "/pulls/comments/"; then
    REACTION_URL="repos/$SOURCE_REPO/pulls/comments/$COMMENT_ID/reactions"
  else
    # Might be the issue/PR body itself
    REACTION_URL="repos/$SOURCE_REPO/issues/$ISSUE_NUMBER/reactions"
  fi

  gh api -X POST "$REACTION_URL" -f content="eyes" 2>/dev/null || echo "  Warning: failed to add reaction"

  # Handle command
  if [ "$COMMAND" = "ping" ]; then
    echo "  Responding with pong"
    gh api -X POST "repos/$SOURCE_REPO/issues/$ISSUE_NUMBER/comments" \
      -f body="pong 🏓" 2>/dev/null || echo "  Warning: failed to post comment"
  else
    echo "  Dispatching to bot.yml workflow"
    gh workflow run bot.yml \
      -f source_repo="$SOURCE_REPO" \
      -f issue_number="$ISSUE_NUMBER" \
      -f comment_body="$COMMENT_BODY" \
      -f comment_user="$COMMENT_USER" \
      -f comment_id="$COMMENT_ID" \
      -f command="$COMMAND" \
      -f args="$ARGS" \
      2>/dev/null || echo "  Warning: failed to dispatch workflow"
  fi

  # Mark notification as read
  gh api -X PATCH "/notifications/threads/$THREAD_ID" 2>/dev/null || true
  echo "  Done."
done

echo "Polling complete."
