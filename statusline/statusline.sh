#!/usr/bin/env bash
# Claude Code status line — widget-based context dashboard.
# Reads JSON from stdin, outputs ANSI-colored status to stdout.

set -euo pipefail

INPUT=$(cat)

# ── ANSI colors ──────────────────────────────────────

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_CYAN='\033[36m'
C_WHITE='\033[37m'

# ── JSON helpers ─────────────────────────────────────

jval() { echo "$INPUT" | jq -r "$1"; }
jnum() { echo "$INPUT" | jq "$1"; }

# ── Widget: Model ────────────────────────────────────
# Shows versioned model name (e.g., "Opus 4.6") + effort level suffix

widget_model() {
  local model_id
  model_id=$(jval '.model.id')
  local display_name
  display_name=$(jval '.model.display_name')

  # Parse model.id to short versioned name
  local name
  case "$model_id" in
    *opus-4-6*)   name="Opus 4.6" ;;
    *opus-4-5*)   name="Opus 4.5" ;;
    *opus-4*)     name="Opus 4" ;;
    *sonnet-4-6*) name="Sonnet 4.6" ;;
    *sonnet-4-5*) name="Sonnet 4.5" ;;
    *sonnet-4*)   name="Sonnet 4" ;;
    *haiku-4-5*)  name="Haiku 4.5" ;;
    *haiku-4*)    name="Haiku 4" ;;
    *)            name="$display_name" ;;
  esac

  # Effort level: env var takes precedence, then settings.json
  local effort="${CLAUDE_CODE_EFFORT_LEVEL:-}"
  if [ -z "$effort" ]; then
    local settings="$HOME/.claude/settings.json"
    if [ -f "$settings" ]; then
      effort=$(jq -r '.effortLevel // empty' "$settings" 2>/dev/null) || effort=""
    fi
  fi

  local suffix=""
  case "$effort" in
    high) suffix="(H)" ;;
    medium) suffix="(M)" ;;
    low) suffix="(L)" ;;
  esac

  printf '%b%b%s%s%b' "$C_BOLD" "$C_CYAN" "$name" "$suffix" "$C_RESET"
}

# ── Widget: Progress ─────────────────────────────────
# Shows colored 10-char progress bar + percentage

widget_progress() {
  local context_size current_tokens percent effective
  context_size=$(jnum '.context_window.context_window_size')
  local usage
  usage=$(jnum '.context_window.current_usage')

  if [ "$usage" = "null" ]; then
    printf '%b%s%b' "$C_DIM" "n/a" "$C_RESET"
    return
  fi

  current_tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')

  # Calculate effective window (autocompact-aware)
  effective=$(calc_effective "$context_size")
  percent=$((current_tokens * 100 / effective))
  [ "$percent" -gt 100 ] && percent=100

  # Color based on percentage
  local color
  if [ "$percent" -lt 50 ]; then color="$C_GREEN"
  elif [ "$percent" -lt 80 ]; then color="$C_YELLOW"
  else color="$C_RED"
  fi

  # Build 10-char bar
  local filled=$((percent / 10))
  local empty=$((10 - filled))
  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done

  printf '%b%s %d%%%b' "$color" "$bar" "$percent" "$C_RESET"
}

# ── Widget: Tokens ───────────────────────────────────
# Shows token ratio in K format (e.g., "90K/200K")

widget_tokens() {
  local context_size
  context_size=$(jnum '.context_window.context_window_size')
  local usage
  usage=$(jnum '.context_window.current_usage')

  if [ "$usage" = "null" ]; then
    return
  fi

  local current_tokens
  current_tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')

  printf '%b%sK/%sK%b' "$C_DIM" "$((current_tokens / 1000))" "$((context_size / 1000))" "$C_RESET"
}

# ── Widget: Cost ─────────────────────────────────────
# Shows session cost in USD

widget_cost() {
  local cost
  cost=$(jval '.cost.total_cost_usd // empty')

  if [ -z "$cost" ] || [ "$cost" = "null" ]; then
    return
  fi

  printf '%b$%s%b' "$C_WHITE" "$cost" "$C_RESET"
}

# ── Widget: Rate Limit ───────────────────────────────
# Shows 5h and optionally 7d usage with reset countdown

widget_ratelimit() {
  local data
  data=$(get_usage_cached)
  [ -z "$data" ] && return

  local five_h seven_d
  five_h=$(echo "$data" | jq -r '.five_hour // empty')
  seven_d=$(echo "$data" | jq -r '.seven_day // empty')

  if [ -n "$five_h" ] && [ "$five_h" != "null" ]; then
    local util reset_at countdown
    util=$(echo "$five_h" | jq -r '.utilization // 0')
    reset_at=$(echo "$five_h" | jq -r '.resets_at // empty')
    countdown=$(format_countdown "$reset_at")

    local color
    local util_int=${util%.*}
    if [ "$util_int" -lt 50 ]; then color="$C_GREEN"
    elif [ "$util_int" -lt 80 ]; then color="$C_YELLOW"
    else color="$C_RED"
    fi

    printf '%b5h:%s%%%b' "$color" "$util_int" "$C_RESET"
    [ -n "$countdown" ] && printf '%b(%s)%b' "$C_DIM" "$countdown" "$C_RESET"
  fi

  if [ -n "$seven_d" ] && [ "$seven_d" != "null" ]; then
    local util7 reset7 countdown7
    util7=$(echo "$seven_d" | jq -r '.utilization // 0')
    reset7=$(echo "$seven_d" | jq -r '.resets_at // empty')
    countdown7=$(format_countdown "$reset7")

    local color7
    local util7_int=${util7%.*}
    if [ "$util7_int" -lt 50 ]; then color7="$C_GREEN"
    elif [ "$util7_int" -lt 80 ]; then color7="$C_YELLOW"
    else color7="$C_RED"
    fi

    printf ' %b7d:%s%%%b' "$color7" "$util7_int" "$C_RESET"
    [ -n "$countdown7" ] && printf '%b(%s)%b' "$C_DIM" "$countdown7" "$C_RESET"
  fi
}

# ── Autocompact calculation ──────────────────────────

calc_effective() {
  local context_size="$1"
  local model_id
  model_id=$(jval '.model.id')

  # Max output tokens per model (CC caps at 20000 internally)
  local model_max
  case "$model_id" in
    *opus-4-6*)                     model_max=128000 ;;
    *opus-4-5*|*sonnet-4*|*haiku-4*) model_max=64000 ;;
    *opus-4*)                       model_max=32000 ;;
    *3-5*)                          model_max=8192 ;;
    *claude-3-opus*)                model_max=4096 ;;
    *claude-3-sonnet*)              model_max=8192 ;;
    *claude-3-haiku*)               model_max=4096 ;;
    *)                              model_max=32000 ;;
  esac

  local max_output_cap=20000
  local max_output
  [ "$model_max" -lt "$max_output_cap" ] && max_output=$model_max || max_output=$max_output_cap

  # EHA = available context after output reservation
  local eha=$((context_size - max_output))

  # Check autocompact settings
  local autocompact=1
  if [ -n "${DISABLE_COMPACT:-}" ] && [ "$DISABLE_COMPACT" != "0" ] && [ "$DISABLE_COMPACT" != "false" ]; then
    autocompact=0
  fi
  if [ -n "${DISABLE_AUTO_COMPACT:-}" ] && [ "$DISABLE_AUTO_COMPACT" != "0" ] && [ "$DISABLE_AUTO_COMPACT" != "false" ]; then
    autocompact=0
  fi

  local config_file="$HOME/.claude.json"
  if [ -f "$config_file" ]; then
    local config_val
    config_val=$(jq -r 'if has("autoCompactEnabled") then .autoCompactEnabled else true end' "$config_file" 2>/dev/null) || config_val="true"
    if [ "$config_val" = "false" ]; then
      autocompact=0
    fi
  fi

  if [ "$autocompact" = "1" ]; then
    # Threshold = EHA - 13000 (or pct override)
    local threshold
    if [ -n "${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-}" ]; then
      local pct_threshold=$((eha * CLAUDE_AUTOCOMPACT_PCT_OVERRIDE / 100))
      local default_threshold=$((eha - 13000))
      [ "$pct_threshold" -lt "$default_threshold" ] && threshold=$pct_threshold || threshold=$default_threshold
    else
      threshold=$((eha - 13000))
    fi
    echo "$threshold"
  else
    echo "$eha"
  fi
}

# ── Rate limit API (cached) ─────────────────────────

CACHE_DIR="$HOME/.cache/xida-statusline"
CACHE_FILE="$CACHE_DIR/usage.json"
CACHE_TTL=60

get_usage_cached() {
  # Return cached data if fresh enough
  if [ -f "$CACHE_FILE" ]; then
    local now file_age
    now=$(date +%s)
    file_age=$(date -r "$CACHE_FILE" +%s 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null) || file_age=0
    if [ $((now - file_age)) -lt $CACHE_TTL ]; then
      cat "$CACHE_FILE"
      return
    fi
  fi

  # Fetch fresh data
  local token
  token=$(get_oauth_token)
  [ -z "$token" ] && return

  mkdir -p "$CACHE_DIR"

  local response
  response=$(curl -s --max-time 5 \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return

  # Validate response has expected fields
  if echo "$response" | jq -e '.five_hour' &>/dev/null; then
    echo "$response" > "$CACHE_FILE"
    echo "$response"
  fi
}

get_oauth_token() {
  # macOS: try Keychain first
  if [ "$(uname)" = "Darwin" ]; then
    local kc_token
    kc_token=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null) || true
    if [ -n "$kc_token" ]; then
      echo "$kc_token" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
      return
    fi
  fi

  # All platforms: credential file
  local cred_file="$HOME/.claude/.credentials.json"
  if [ -f "$cred_file" ]; then
    jq -r '.claudeAiOauth.accessToken // empty' "$cred_file" 2>/dev/null
  fi
}

format_countdown() {
  local reset_at="$1"
  [ -z "$reset_at" ] && return

  local now reset_epoch diff
  now=$(date +%s)

  # Parse ISO 8601 timestamp
  reset_epoch=$(date -d "$reset_at" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "${reset_at%%.*}" +%s 2>/dev/null) || return
  diff=$((reset_epoch - now))
  [ "$diff" -le 0 ] && return

  if [ "$diff" -ge 86400 ]; then
    printf '%dd' "$((diff / 86400))"
  elif [ "$diff" -ge 3600 ]; then
    printf '%dh' "$((diff / 3600))"
  else
    printf '%dm' "$((diff / 60))"
  fi
}

# ── Main ─────────────────────────────────────────────

parts=()
parts+=("$(widget_model)")
parts+=("$(widget_progress)")
parts+=("$(widget_tokens)")

cost_out=$(widget_cost)
[ -n "$cost_out" ] && parts+=("$cost_out")

rl_out=$(widget_ratelimit)
[ -n "$rl_out" ] && parts+=("$rl_out")

# Join with dim separator
SEP=$(printf ' %b│%b ' "$C_DIM" "$C_RESET")
output=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && output+="$SEP"
  output+="${parts[$i]}"
done

printf '%b\n' "$output"
