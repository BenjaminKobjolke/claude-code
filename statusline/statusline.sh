#!/usr/bin/env bash
# Claude Code status line — widget-based context dashboard.
# Reads JSON from stdin, outputs ANSI-colored status to stdout.

set -euo pipefail

INPUT=$(cat)

# ── Config file ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/statusline.conf"
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

# ── Early exit if all widgets disabled ───────────────
if [ "${SHOW_PROGRESS:-1}" != "1" ] && \
   [ "${SHOW_TOKENS:-1}" != "1" ] && \
   [ "${SHOW_DURATION:-1}" != "1" ] && \
   [ "${SHOW_RATELIMIT:-1}" != "1" ] && \
   [ "${SHOW_COST:-1}" != "1" ] && \
   [ "${SHOW_MODEL:-1}" != "1" ]; then
  echo ""
  exit 0
fi

# ── ANSI colors ──────────────────────────────────────
# Semantic palette — only these 4 are used throughout.

C_RESET='\033[0m'
C_DIM="${C_DIM:-\033[38;5;245m}"       # gray   — separators, labels, secondary text
C_ACCENT="${C_ACCENT:-\033[36m}"       # cyan   — healthy state, base values
C_WARN="${C_WARN:-\033[33m}"           # yellow — moderate usage, attention needed
C_DANGER="${C_DANGER:-\033[31m}"       # red    — high usage, degradation likely

# ── Thresholds ──────────────────────────────────────

# Context: 60% = "lost in the middle" onset, 80% = consensus exit point
CONTEXT_WARN_PCT="${CONTEXT_WARN_PCT:-60}"
CONTEXT_DANGER_PCT="${CONTEXT_DANGER_PCT:-80}"

# Duration (minutes): typical sessions run 15–30 min, long sessions 45–60+.
DURATION_WARN_MIN="${DURATION_WARN_MIN:-30}"
DURATION_DANGER_MIN="${DURATION_DANGER_MIN:-60}"

# Rate limits: 50% = half quota burned, 80% = throttling imminent
RATE_WARN_PCT="${RATE_WARN_PCT:-50}"
RATE_DANGER_PCT="${RATE_DANGER_PCT:-80}"

# Cost (USD): per-session thresholds assuming Opus 4.6 in a 200K context window.
# Light session ≈ $1–2, full context ≈ $5–10, ceiling ≈ $10–15.
COST_WARN_USD="${COST_WARN_USD:-5}"
COST_DANGER_USD="${COST_DANGER_USD:-10}"

# ── Locale ─────────────────────────────────────────
# Detect once, reuse everywhere.  Falls back to en_US defaults.

L_RADIX=$(locale decimal_point 2>/dev/null) || L_RADIX="."
L_THOUSANDS=$(locale thousands_sep 2>/dev/null) || L_THOUSANDS=","

_curr_raw=$(locale int_curr_symbol 2>/dev/null) || _curr_raw=""
_curr_raw="${_curr_raw%% *}"
L_CURRENCY_CODE="${_curr_raw:-USD}"
case "$_curr_raw" in
  EUR) L_CURRENCY="€"; L_CURRENCY_POS="suffix" ;;
  GBP) L_CURRENCY="£"; L_CURRENCY_POS="prefix" ;;
  JPY) L_CURRENCY="¥"; L_CURRENCY_POS="prefix" ;;
  CHF) L_CURRENCY="CHF "; L_CURRENCY_POS="prefix" ;;
  *)   L_CURRENCY="\$"; L_CURRENCY_POS="prefix"; L_CURRENCY_CODE="USD" ;;
esac
unset _curr_raw

# Format a number with locale thousands separator (integer only).
# Usage: fmt_thousands 47000  →  "47.000" (de) or "47,000" (en)
fmt_thousands() {
  local n="$1" sign="" result="" count=0
  [ "$n" -lt 0 ] 2>/dev/null && { sign="-"; n="${n#-}"; }
  while [ "$n" -gt 0 ]; do
    if [ "$count" -gt 0 ] && [ $((count % 3)) -eq 0 ]; then
      result="${L_THOUSANDS}${result}"
    fi
    result="$((n % 10))${result}"
    n=$((n / 10))
    count=$((count + 1))
  done
  echo "${sign}${result:-0}"
}

# ── Currency conversion ───────────────────────────────
# Fetch exchange rate from API, update conf file cache.
refresh_exchange_rate() {
  local resp rate
  resp=$(curl -s --max-time 5 "https://open.er-api.com/v6/latest/USD" 2>/dev/null) || return
  rate=$(echo "$resp" | jq -r ".rates.$L_CURRENCY_CODE // empty" 2>/dev/null) || return
  [ -z "$rate" ] && return
  if [ -f "$CONF_FILE" ]; then
    sed -i "s/^XIDA_RATE=.*/XIDA_RATE=$rate/" "$CONF_FILE"
    sed -i "s/^XIDA_RATE_EPOCH=.*/XIDA_RATE_EPOCH=$(date +%s)/" "$CONF_FILE"
  fi
}

# Load exchange rate; lazy-refresh if stale (>7 days).
L_RATE=1
if [ "$L_CURRENCY_CODE" != "USD" ]; then
  L_RATE="${XIDA_RATE:-1}"
  now=$(date +%s)
  if [ $(( now - ${XIDA_RATE_EPOCH:-0} )) -ge 604800 ]; then
    refresh_exchange_rate &
  fi
fi

# ── Batch JSON parse ─────────────────────────────────
# Extract all needed values from stdin JSON in a single jq call
# to avoid forking jq ~12 times per render.

eval "$(echo "$INPUT" | jq -r '
  @sh "J_MODEL_ID=\(.model.id // "")",
  @sh "J_DISPLAY_NAME=\(.model.display_name // "")",
  @sh "J_CONTEXT_SIZE=\(.context_window.context_window_size // 0)",
  "J_CURRENT_TOKENS=\(
    if .context_window.current_usage != null then
      (.context_window.current_usage.input_tokens // 0)
      + (.context_window.current_usage.cache_creation_input_tokens // 0)
      + (.context_window.current_usage.cache_read_input_tokens // 0)
    else 0 end
  )",
  @sh "J_COST=\(.cost.total_cost_usd // "")",
  "J_DURATION_MS=\(.cost.total_duration_ms // 0)"
')"

# ── Cache autocompact setting ─────────────────────────
# Read ~/.claude.json once; calc_effective uses the cached value.

_AUTOCOMPACT=1
if [ -n "${DISABLE_COMPACT:-}" ] && [ "$DISABLE_COMPACT" != "0" ] && [ "$DISABLE_COMPACT" != "false" ]; then
  _AUTOCOMPACT=0
fi
if [ -n "${DISABLE_AUTO_COMPACT:-}" ] && [ "$DISABLE_AUTO_COMPACT" != "0" ] && [ "$DISABLE_AUTO_COMPACT" != "false" ]; then
  _AUTOCOMPACT=0
fi
_claude_config="$HOME/.claude.json"
if [ "$_AUTOCOMPACT" = "1" ] && [ -f "$_claude_config" ]; then
  _config_val=$(jq -r 'if has("autoCompactEnabled") then .autoCompactEnabled else true end' "$_claude_config" 2>/dev/null) || _config_val="true"
  if [ "$_config_val" = "false" ]; then
    _AUTOCOMPACT=0
  fi
fi

# Cache effort level (used by widget_model)
_EFFORT="${CLAUDE_CODE_EFFORT_LEVEL:-}"
if [ -z "$_EFFORT" ]; then
  _settings="$HOME/.claude/settings.json"
  if [ -f "$_settings" ]; then
    _EFFORT=$(jq -r '.effortLevel // empty' "$_settings" 2>/dev/null) || _EFFORT=""
  fi
fi

# ── Widget: Model ────────────────────────────────────
# Shows versioned model name (e.g., "Opus 4.6") + effort level suffix

widget_model() {
  # Parse model.id to short versioned name
  local name
  case "$J_MODEL_ID" in
    *opus-4-6*)   name="Opus 4.6" ;;
    *opus-4-5*)   name="Opus 4.5" ;;
    *opus-4*)     name="Opus 4" ;;
    *sonnet-4-6*) name="Sonnet 4.6" ;;
    *sonnet-4-5*) name="Sonnet 4.5" ;;
    *sonnet-4*)   name="Sonnet 4" ;;
    *haiku-4-5*)  name="Haiku 4.5" ;;
    *haiku-4*)    name="Haiku 4" ;;
    *)            name="$J_DISPLAY_NAME" ;;
  esac

  local suffix=""
  case "$_EFFORT" in
    high) suffix="(H)" ;;
    medium) suffix="(M)" ;;
    low) suffix="(L)" ;;
  esac

  [ "${SHOW_EMOJIS:-0}" = "1" ] && printf '🤖 '
  printf '%b%s%b' "$C_ACCENT" "$name" "$C_RESET"
  [ -n "$suffix" ] && printf '%b%s%b' "$C_DIM" "$suffix" "$C_RESET"
  :
}

# ── Widget: Progress ─────────────────────────────────
# Shows colored 10-char progress bar + percentage

widget_progress() {
  local percent=0
  local effective
  effective=$(calc_effective "$J_CONTEXT_SIZE")
  if [ "$effective" -gt 0 ]; then
    percent=$((J_CURRENT_TOKENS * 100 / effective))
    [ "$percent" -gt 100 ] && percent=100
  fi

  local color
  if [ "$percent" -lt "$CONTEXT_WARN_PCT" ]; then color="$C_ACCENT"
  elif [ "$percent" -lt "$CONTEXT_DANGER_PCT" ]; then color="$C_WARN"
  else color="$C_DANGER"
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
# Current value colored by context utilization; max stays dim.

widget_tokens() {
  local percent=0
  local effective
  effective=$(calc_effective "$J_CONTEXT_SIZE")
  if [ "$effective" -gt 0 ]; then
    percent=$((J_CURRENT_TOKENS * 100 / effective))
    [ "$percent" -gt 100 ] && percent=100
  fi

  local color
  if [ "$percent" -lt "$CONTEXT_WARN_PCT" ]; then color="$C_ACCENT"
  elif [ "$percent" -lt "$CONTEXT_DANGER_PCT" ]; then color="$C_WARN"
  else color="$C_DANGER"
  fi

  local cur_k; cur_k=$(fmt_thousands "$((J_CURRENT_TOKENS / 1000))")
  local max_k; max_k=$(fmt_thousands "$((J_CONTEXT_SIZE / 1000))")
  [ "${SHOW_EMOJIS:-0}" = "1" ] && printf '📋 '
  printf '%b%sK%b%b/%sK%b' "$color" "$cur_k" "$C_RESET" "$C_DIM" "$max_k" "$C_RESET"
}

# ── Widget: Cost ─────────────────────────────────────
# Shows session cost, localized to system locale

widget_cost() {
  if [ -z "$J_COST" ] || [ "$J_COST" = "null" ]; then
    return
  fi
  # Suppress zero cost (handles both "0" and "0.00" formats)
  if awk "BEGIN{exit(!($J_COST+0==0))}" 2>/dev/null; then
    return
  fi

  # Convert to local currency and round to 2 decimal places
  local display_cost
  display_cost=$(awk "BEGIN{printf \"%.2f\", $J_COST * $L_RATE}")
  local formatted="$display_cost"
  if [ "$L_RADIX" != "." ]; then
    formatted="${formatted/./$L_RADIX}"
  fi

  # Apply locale currency symbol
  if [ "$L_CURRENCY_POS" = "suffix" ]; then
    formatted="${formatted}${L_CURRENCY}"
  else
    formatted="${L_CURRENCY}${formatted}"
  fi

  local color
  if awk "BEGIN{exit(!($J_COST+0 < $COST_WARN_USD+0))}" 2>/dev/null; then color="$C_ACCENT"
  elif awk "BEGIN{exit(!($J_COST+0 < $COST_DANGER_USD+0))}" 2>/dev/null; then color="$C_WARN"
  else color="$C_DANGER"
  fi

  [ "${SHOW_EMOJIS:-0}" = "1" ] && printf '💰 '
  printf '%b%s%b' "$color" "$formatted" "$C_RESET"
}

# ── Widget: Duration ─────────────────────────────────
# Shows session wall-clock time with color thresholds

widget_duration() {
  if [ "$J_DURATION_MS" = "null" ] || [ "$J_DURATION_MS" = "0" ]; then
    return
  fi

  local total_secs=$((J_DURATION_MS / 1000))
  local days=$((total_secs / 86400))
  local hours=$(( (total_secs % 86400) / 3600 ))
  local mins=$(( (total_secs % 3600) / 60 ))
  local secs=$((total_secs % 60))

  local display
  if [ "$days" -gt 0 ]; then
    display="${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then
    display="${hours}h ${mins}m"
  elif [ "$mins" -gt 0 ]; then
    display="${mins}m ${secs}s"
  else
    display="${secs}s"
  fi

  local color
  local total_mins=$((total_secs / 60))
  if [ "$total_mins" -lt "$DURATION_WARN_MIN" ]; then color="$C_ACCENT"
  elif [ "$total_mins" -lt "$DURATION_DANGER_MIN" ]; then color="$C_WARN"
  else color="$C_DANGER"
  fi

  [ "${SHOW_EMOJIS:-0}" = "1" ] && printf '⏱️ '
  printf '%b%s%b' "$color" "$display" "$C_RESET"
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
    util_int=${util_int:-0}
    if [ "$util_int" -lt "$RATE_WARN_PCT" ]; then color="$C_ACCENT"
    elif [ "$util_int" -lt "$RATE_DANGER_PCT" ]; then color="$C_WARN"
    else color="$C_DANGER"
    fi

    [ "${SHOW_EMOJIS:-0}" = "1" ] && printf '⚡ '
    printf '%b5h: %b%b%s%% %b' "$C_DIM" "$C_RESET" "$color" "$util_int" "$C_RESET"
    [ -n "$countdown" ] && printf '%b(%s)%b' "$C_DIM" "$countdown" "$C_RESET"
  fi

  if [ -n "$seven_d" ] && [ "$seven_d" != "null" ]; then
    local util7 reset7 countdown7
    util7=$(echo "$seven_d" | jq -r '.utilization // 0')
    reset7=$(echo "$seven_d" | jq -r '.resets_at // empty')
    countdown7=$(format_countdown "$reset7")

    local color7
    local util7_int=${util7%.*}
    util7_int=${util7_int:-0}
    if [ "$util7_int" -lt "$RATE_WARN_PCT" ]; then color7="$C_ACCENT"
    elif [ "$util7_int" -lt "$RATE_DANGER_PCT" ]; then color7="$C_WARN"
    else color7="$C_DANGER"
    fi

    printf ' %b7d: %b%b%s%% %b' "$C_DIM" "$C_RESET" "$color7" "$util7_int" "$C_RESET"
    [ -n "$countdown7" ] && printf '%b(%s)%b' "$C_DIM" "$countdown7" "$C_RESET"
  fi
  :
}

# ── Autocompact calculation ──────────────────────────

calc_effective() {
  local context_size="$1"

  # Max output tokens per model (CC caps at 20000 internally)
  local model_max
  case "$J_MODEL_ID" in
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

  if [ "$_AUTOCOMPACT" = "1" ]; then
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
CACHE_TTL=180

get_usage_cached() {
  # Return cached data if fresh enough
  if [ -f "$CACHE_FILE" ]; then
    local now file_age
    now=$(date +%s)
    file_age=$(stat -c '%Y' "$CACHE_FILE" 2>/dev/null || stat -f '%m' "$CACHE_FILE" 2>/dev/null || date -r "$CACHE_FILE" +%s 2>/dev/null) || file_age=0
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

  local days=$((diff / 86400))
  local hours=$(( (diff % 86400) / 3600 ))
  local minutes=$(( (diff % 3600) / 60 ))

  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$minutes"
  elif [ "$minutes" -gt 0 ]; then
    printf '%dm' "$minutes"
  else
    printf '%ds' "$diff"
  fi
}

# ── Main ─────────────────────────────────────────────

parts=()

[ "${SHOW_PROGRESS:-1}" = "1" ] && parts+=("$(widget_progress)")
[ "${SHOW_TOKENS:-1}" = "1" ] && parts+=("$(widget_tokens)")

if [ "${SHOW_DURATION:-1}" = "1" ]; then
  dur_out=$(widget_duration)
  [ -n "$dur_out" ] && parts+=("$dur_out")
fi

if [ "${SHOW_RATELIMIT:-1}" = "1" ]; then
  rl_out=$(widget_ratelimit)
  [ -n "$rl_out" ] && parts+=("$rl_out")
fi

if [ "${SHOW_COST:-1}" = "1" ]; then
  cost_out=$(widget_cost)
  [ -n "$cost_out" ] && parts+=("$cost_out")
fi

[ "${SHOW_MODEL:-1}" = "1" ] && parts+=("$(widget_model)")

# Join with dim separator
SEP=$(printf ' %b│%b ' "$C_DIM" "$C_RESET")
output=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && output+="$SEP"
  output+="${parts[$i]}"
done

printf '%b\n' "$output"
