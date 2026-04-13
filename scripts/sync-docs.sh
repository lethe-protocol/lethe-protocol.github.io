#!/usr/bin/env bash
# Sync docs from lethe-market into Starlight content directories.
# Called by CI and by local dev (./scripts/sync-docs.sh).
set -euo pipefail

MARKET="${1:-_market}"

add_frontmatter() {
    local src="$1" dst="$2" title="$3"
    printf -- '---\ntitle: "%s"\n---\n\n' "$title" > "$dst"
    cat "$src" >> "$dst"
}

# Vision & Strategy
declare -A VISION=(
    ["VISION.md"]="Vision Architecture"
    ["ROADMAP.md"]="Roadmap"
    ["EVOLUTION_ROADMAP.md"]="Evolution Strategy"
    ["MANIFESTO.md"]="Manifesto"
)
for f in "${!VISION[@]}"; do
    [ -f "$MARKET/docs/$f" ] || continue
    slug=$(echo "$f" | sed 's/.md//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    add_frontmatter "$MARKET/docs/$f" "src/content/docs/vision/$slug.md" "${VISION[$f]}"
done

# Market Design
declare -A MARKET_DOCS=(
    ["MARKET_PRINCIPLES.md"]="Market Principles"
    ["MARKET_RESULTS_AND_SETTLEMENT.md"]="Results & Settlement"
)
for f in "${!MARKET_DOCS[@]}"; do
    [ -f "$MARKET/docs/$f" ] || continue
    slug=$(echo "$f" | sed 's/.md//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    add_frontmatter "$MARKET/docs/$f" "src/content/docs/market/$slug.md" "${MARKET_DOCS[$f]}"
done

# Technical
declare -A TECH=(
    ["ENCRYPTED_DELIVERY_ARCHITECTURE.md"]="Encrypted Delivery"
    ["OASIS_ROFL_BLOCKERS.md"]="ROFL Blockers"
    ["poe-protocol-v2.md"]="PoE Protocol"
)
for f in "${!TECH[@]}"; do
    [ -f "$MARKET/docs/$f" ] || continue
    slug=$(echo "$f" | sed 's/.md//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    add_frontmatter "$MARKET/docs/$f" "src/content/docs/technical/$slug.md" "${TECH[$f]}"
done

# Participate
declare -A PARTICIPATE=(
    ["USER_SCENARIOS.md"]="User Scenarios"
    ["SIMULATION_TEST_PLAN.md"]="Simulation Test Plan"
)
for f in "${!PARTICIPATE[@]}"; do
    [ -f "$MARKET/docs/$f" ] || continue
    slug=$(echo "$f" | sed 's/.md//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    add_frontmatter "$MARKET/docs/$f" "src/content/docs/participate/$slug.md" "${PARTICIPATE[$f]}"
done

if [ -f "$MARKET/ONBOARDING.md" ]; then
    add_frontmatter "$MARKET/ONBOARDING.md" "src/content/docs/participate/onboarding.md" "Onboarding Guide"
fi

echo "Docs synced from $MARKET"
