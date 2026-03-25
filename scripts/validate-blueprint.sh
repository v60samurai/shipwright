#!/bin/bash
# Validate a Product Blueprint YAML for completeness
# Usage: validate-blueprint.sh docs/product-blueprint.yaml

BLUEPRINT="$1"

if [ -z "$BLUEPRINT" ] || [ ! -f "$BLUEPRINT" ]; then
  echo "ERROR: Blueprint file not found: $BLUEPRINT"
  echo "Run /shipwright:blueprint first."
  exit 1
fi

ERRORS=0
WARNINGS=0

# Check required top-level sections exist
for section in "product:" "users:" "interfaces:" "architecture:" "stack:" "features:" "user_journeys:" "testing:" "deployment:" "constraints:"; do
  if ! grep -q "^$section" "$BLUEPRINT"; then
    echo "ERROR: Missing required section: $section"
    ERRORS=$((ERRORS + 1))
  fi
done

# Check product fields
if ! grep -q "name:" "$BLUEPRINT" | head -1; then
  echo "ERROR: product.name is empty"
  ERRORS=$((ERRORS + 1))
fi

# Check at least one interface
INTERFACE_COUNT=$(grep -c "^  - type:" "$BLUEPRINT" 2>/dev/null || echo "0")
if [ "$INTERFACE_COUNT" -eq 0 ]; then
  echo "ERROR: No interfaces defined"
  ERRORS=$((ERRORS + 1))
fi

# Check at least one core feature
if ! grep -q "core:" "$BLUEPRINT"; then
  echo "ERROR: No core features defined"
  ERRORS=$((ERRORS + 1))
fi

# Check at least one user journey
if ! grep -q "user_journeys:" "$BLUEPRINT"; then
  echo "WARNING: No user journeys defined"
  WARNINGS=$((WARNINGS + 1))
fi

# Check env_vars section exists if external services present
if grep -q "external_services:" "$BLUEPRINT" && ! grep -q "env_vars:" "$BLUEPRINT"; then
  echo "WARNING: External services defined but no env_vars section"
  WARNINGS=$((WARNINGS + 1))
fi

# Check resilience section exists if external services present
if grep -q "external_services:" "$BLUEPRINT" && ! grep -q "resilience:" "$BLUEPRINT"; then
  echo "WARNING: External services defined but no resilience section"
  WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "Validation complete: $ERRORS errors, $WARNINGS warnings"

if [ "$ERRORS" -gt 0 ]; then
  echo "Blueprint has errors. Fix them before running /shipwright:build."
  exit 1
else
  echo "Blueprint is valid."
  exit 0
fi
