#!/usr/bin/env bash

# Generate a small, realistic Git repository for a git-bisect exercise.
#
# Usage:
#   ./repo-generator.sh
#   ./repo-generator.sh --force
#
# By default the repository is created at ./git-bisect-demo, relative to this
# script. Override that with DEMO_DIR=/path/to/demo if you want a temporary copy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="${DEMO_DIR:-$SCRIPT_DIR/git-bisect-demo}"

if [[ "${1:-}" != "" && "${1:-}" != "--force" ]]; then
  echo "Usage: $0 [--force]"
  exit 2
fi

if [[ -e "$DEMO_DIR" ]]; then
  if [[ "${1:-}" == "--force" ]]; then
    rm -rf "$DEMO_DIR"
  else
    echo "Refusing to overwrite existing directory: $DEMO_DIR"
    echo "Run with --force to recreate it, or set DEMO_DIR=/path/to/new-demo."
    exit 1
  fi
fi

mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"

git init -q
git config user.name "Coffee Bot"
git config user.email "coffee.bot@example.test"

commit_number=0
base_epoch="${BASE_EPOCH:-1740963600}" # 2025-03-03 09:00:00 UTC

authors=(
  "Michael|michael.lydeamore@monash.edu"
  "Di|dicook@monash.edu"
  "Rob|rob.hyndman@monash.edu"
  "Asha|asha.patel@example.test"
)

fake_commit_date() {
  local n="$1"
  local days
  local seconds

  # Uneven gaps make the history feel less generated: weekends, quiet weeks,
  # and occasional same-day follow-ups.
  days=$((n * 3 + (n % 5) * 2 + (n % 11 == 0 ? 9 : 0)))
  seconds=$((base_epoch + days * 86400 + (n % 7) * 2713 + (n % 4) * 3600))

  if date -u -r "$seconds" "+%Y-%m-%dT%H:%M:%S %z" >/dev/null 2>&1; then
    date -u -r "$seconds" "+%Y-%m-%dT%H:%M:%S %z"
  else
    date -u -d "@$seconds" "+%Y-%m-%dT%H:%M:%S %z"
  fi
}

commit_all() {
  local message="$1"
  local author="${authors[$((commit_number % ${#authors[@]}))]}"
  local name="${author%%|*}"
  local email="${author##*|}"
  local commit_date

  commit_date="$(fake_commit_date "$commit_number")"

  git add -A
  GIT_AUTHOR_NAME="$name" \
    GIT_AUTHOR_EMAIL="$email" \
    GIT_AUTHOR_DATE="$commit_date" \
    GIT_COMMITTER_NAME="$name" \
    GIT_COMMITTER_EMAIL="$email" \
    GIT_COMMITTER_DATE="$commit_date" \
    git commit -q -m "$message"

  commit_number=$((commit_number + 1))
}

write_readme_basic() {
  cat > README.md <<'EOF'
# Campus Coffee Calculator

Tiny R scripts for pricing coffee orders at a fictional campus cart.

Run the checks with:

```sh
Rscript tests/test-pricing.R
```
EOF
}

write_initial_coffee() {
  mkdir -p tests

  cat > coffee.R <<'EOF'
menu <- data.frame(
  drink = c("espresso", "latte", "flat white", "mocha", "tea"),
  base_price = c(3.00, 4.20, 4.10, 4.60, 2.80),
  stringsAsFactors = FALSE
)

size_surcharge <- function(size) {
  if (size == "small") {
    return(0)
  }
  if (size == "medium") {
    return(0.70)
  }
  if (size == "large") {
    return(1.10)
  }
  stop("Unknown size: ", size)
}

milk_surcharge <- function(milk) {
  if (milk %in% c("oat", "soy", "almond")) {
    return(0.60)
  }
  0
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- menu[menu$drink == drink, ]
  if (nrow(row) == 0) {
    stop("Unknown drink: ", drink)
  }

  extra_shots <- max(shots - 1, 0) * 0.90
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shots, 2)
}

order_total <- function(items, student_discount = FALSE) {
  subtotal <- sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))

  if (student_discount) {
    subtotal <- subtotal * 0.9
  }

  round(subtotal * 1.1, 2)
}
EOF

  cat > tests/test-pricing.R <<'EOF'
source("coffee.R")

assert_equal <- function(actual, expected, label) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop(label, ": expected ", expected, ", got ", actual, call. = FALSE)
  }
}

assert_equal(line_total("latte", size = "small", milk = "dairy", shots = 1), 4.20, "small latte")
assert_equal(line_total("latte", size = "large", milk = "oat", shots = 2), 6.80, "large oat latte with extra shot")

morning_order <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

assert_equal(order_total(morning_order, student_discount = TRUE), 9.5, "discounted morning order")
EOF
}

write_split_v1() {
  mkdir -p R tests

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/pricing.R")
EOF

  cat > R/menu.R <<'EOF'
menu <- data.frame(
  drink = c("espresso", "latte", "flat white", "mocha", "tea"),
  base_price = c(3.00, 4.20, 4.10, 4.60, 2.80),
  stringsAsFactors = FALSE
)

find_menu_item <- function(drink) {
  row <- menu[menu$drink == drink, ]
  if (nrow(row) == 0) {
    stop("Unknown drink: ", drink)
  }
  row
}
EOF

  cat > R/discounts.R <<'EOF'
student_discount_rate <- function(enabled) {
  if (isTRUE(enabled)) {
    return(0.10)
  }
  0
}
EOF

  cat > R/pricing.R <<'EOF'
size_surcharge <- function(size) {
  if (size == "small") {
    return(0)
  }
  if (size == "medium") {
    return(0.70)
  }
  if (size == "large") {
    return(1.10)
  }
  stop("Unknown size: ", size)
}

milk_surcharge <- function(milk) {
  if (milk %in% c("oat", "soy", "almond")) {
    return(0.60)
  }
  0
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  extra_shots <- max(shots - 1, 0) * 0.90
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shots, 2)
}

order_total <- function(items, student_discount = FALSE) {
  subtotal <- sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))

  discount <- student_discount_rate(student_discount)
  round(subtotal * (1 - discount) * 1.1, 2)
}
EOF
}

write_tests_with_helpers() {
  mkdir -p tests

  cat > tests/test-pricing.R <<'EOF'
source("coffee.R")

assert_equal <- function(actual, expected, label) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop(label, ": expected ", expected, ", got ", actual, call. = FALSE)
  }
}

assert_equal(line_total("latte", size = "small", milk = "dairy", shots = 1), 4.20, "small latte")
assert_equal(line_total("latte", size = "large", milk = "oat", shots = 2), 6.80, "large oat latte with extra shot")
assert_equal(line_total("espresso", size = "medium", milk = "dairy", shots = 2), 4.60, "espresso with extra shot")

morning_order <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

assert_equal(order_total(morning_order, student_discount = TRUE), 9.5, "discounted morning order")
EOF
}

write_tax_file() {
  cat > R/tax.R <<'EOF'
tax_rate <- function() {
  0.10
}

add_tax <- function(amount) {
  round(amount * (1 + tax_rate()), 2)
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/tax.R")
source("R/pricing.R")
EOF

  cat > R/pricing.R <<'EOF'
size_surcharge <- function(size) {
  if (size == "small") {
    return(0)
  }
  if (size == "medium") {
    return(0.70)
  }
  if (size == "large") {
    return(1.10)
  }
  stop("Unknown size: ", size)
}

milk_surcharge <- function(milk) {
  if (milk %in% c("oat", "soy", "almond")) {
    return(0.60)
  }
  0
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  extra_shots <- max(shots - 1, 0) * 0.90
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shots, 2)
}

order_total <- function(items, student_discount = FALSE) {
  subtotal <- sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))

  discount <- student_discount_rate(student_discount)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_receipts() {
  cat > R/receipts.R <<'EOF'
format_money <- function(amount) {
  sprintf("$%.2f", amount)
}

receipt_line <- function(item) {
  paste(
    item$size,
    item$milk,
    item$drink,
    paste0("x", item$shots),
    format_money(line_total(item$drink, item$size, item$milk, item$shots))
  )
}

receipt <- function(items, student_discount = FALSE) {
  c(
    vapply(items, receipt_line, character(1)),
    paste("Total", format_money(order_total(items, student_discount)))
  )
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/tax.R")
source("R/pricing.R")
source("R/receipts.R")
EOF
}

write_readme_with_examples() {
  cat > README.md <<'EOF'
# Campus Coffee Calculator

Tiny R scripts for pricing coffee orders at a fictional campus cart.

```r
source("coffee.R")
line_total("latte", size = "large", milk = "oat", shots = 2)
```

Run the checks with:

```sh
Rscript tests/test-pricing.R
```

For the bisect exercise, start from the known-good tag and compare it with the
current broken `HEAD`.
EOF
}

write_examples() {
  mkdir -p examples

  cat > examples/morning-rush.R <<'EOF'
source("coffee.R")

orders <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "flat white", size = "medium", milk = "dairy", shots = 1),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

cat(receipt(orders, student_discount = TRUE), sep = "\n")
EOF
}

write_notes() {
  mkdir -p notes

  cat > notes/pricing-policy.md <<'EOF'
# Pricing Notes

- Alternative milks cost 60 cents.
- Extra shots cost 90 cents.
- Student cards receive 10 percent off before tax.
- Prices include GST at checkout.
EOF
}

write_loyalty() {
  cat > R/loyalty.R <<'EOF'
loyalty_discount_rate <- function(stamps) {
  if (stamps >= 10) {
    return(0.15)
  }
  if (stamps >= 5) {
    return(0.05)
  }
  0
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/loyalty.R")
source("R/tax.R")
source("R/pricing.R")
source("R/receipts.R")
EOF
}

write_order_total_with_loyalty() {
  cat > R/pricing.R <<'EOF'
size_surcharge <- function(size) {
  if (size == "small") {
    return(0)
  }
  if (size == "medium") {
    return(0.70)
  }
  if (size == "large") {
    return(1.10)
  }
  stop("Unknown size: ", size)
}

milk_surcharge <- function(milk) {
  if (milk %in% c("oat", "soy", "almond")) {
    return(0.60)
  }
  0
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  extra_shots <- max(shots - 1, 0) * 0.90
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shots, 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) + loyalty_discount_rate(stamps)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_tests_with_loyalty() {
  cat > tests/test-pricing.R <<'EOF'
source("coffee.R")

assert_equal <- function(actual, expected, label) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop(label, ": expected ", expected, ", got ", actual, call. = FALSE)
  }
}

assert_equal(line_total("latte", size = "small", milk = "dairy", shots = 1), 4.20, "small latte")
assert_equal(line_total("latte", size = "large", milk = "oat", shots = 2), 6.80, "large oat latte with extra shot")
assert_equal(line_total("espresso", size = "medium", milk = "dairy", shots = 2), 4.60, "espresso with extra shot")

morning_order <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

assert_equal(order_total(morning_order, student_discount = TRUE), 9.5, "discounted morning order")
assert_equal(order_total(morning_order, stamps = 10), 8.98, "loyalty order")
EOF
}

write_temp_experiment() {
  mkdir -p experiments

  cat > experiments/punch-card-prototype.R <<'EOF'
stamp_message <- function(stamps) {
  remaining <- max(10 - stamps, 0)
  if (remaining == 0) {
    return("Free upgrade unlocked")
  }
  paste(remaining, "stamps until the next reward")
}
EOF
}

write_menu_with_cold_brew() {
  cat > R/menu.R <<'EOF'
menu <- data.frame(
  drink = c("espresso", "latte", "flat white", "mocha", "tea", "cold brew"),
  base_price = c(3.00, 4.20, 4.10, 4.60, 2.80, 4.80),
  stringsAsFactors = FALSE
)

find_menu_item <- function(drink) {
  row <- menu[menu$drink == drink, ]
  if (nrow(row) == 0) {
    stop("Unknown drink: ", drink)
  }
  row
}
EOF
}

write_size_file_good() {
  cat > R/size.R <<'EOF'
normalise_size <- function(size) {
  key <- tolower(trimws(size))

  if (key %in% c("small", "s")) {
    return("small")
  }
  if (key %in% c("medium", "m", "regular")) {
    return("medium")
  }
  if (key %in% c("large", "l")) {
    return("large")
  }

  stop("Unknown size: ", size)
}

size_surcharge <- function(size) {
  normalised <- normalise_size(size)

  if (normalised == "small") {
    return(0)
  }
  if (normalised == "medium") {
    return(0.70)
  }
  if (normalised == "large") {
    return(1.10)
  }
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/loyalty.R")
source("R/size.R")
source("R/tax.R")
source("R/pricing.R")
source("R/receipts.R")
EOF

  cat > R/pricing.R <<'EOF'
milk_surcharge <- function(milk) {
  if (milk %in% c("oat", "soy", "almond")) {
    return(0.60)
  }
  0
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  extra_shots <- max(shots - 1, 0) * 0.90
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shots, 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) + loyalty_discount_rate(stamps)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_size_file_buggy() {
  cat > R/size.R <<'EOF'
normalise_size <- function(size) {
  key <- tolower(trimws(size))

  if (key %in% c("small", "s")) {
    return("small")
  }
  if (key %in% c("medium", "m", "regular", "large", "l")) {
    return("medium")
  }

  stop("Unknown size: ", size)
}

size_surcharge <- function(size) {
  normalised <- normalise_size(size)

  if (normalised == "small") {
    return(0)
  }
  if (normalised == "medium") {
    return(0.70)
  }
  if (normalised == "large") {
    return(1.10)
  }
}
EOF
}

write_pricing_vectorised() {
  cat > R/pricing.R <<'EOF'
milk_surcharge <- function(milk) {
  alternatives <- c("oat", "soy", "almond")
  if (milk %in% alternatives) {
    return(0.60)
  }
  0
}

extra_shot_charge <- function(shots) {
  max(shots - 1, 0) * 0.90
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shot_charge(shots), 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) + loyalty_discount_rate(stamps)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_size_alias_table_buggy() {
  cat > R/size.R <<'EOF'
size_aliases <- c(
  s = "small",
  small = "small",
  m = "medium",
  medium = "medium",
  regular = "medium",
  l = "medium",
  large = "medium"
)

size_prices <- c(
  small = 0.00,
  medium = 0.70,
  large = 1.10
)

normalise_size <- function(size) {
  key <- tolower(trimws(size))
  normalised <- unname(size_aliases[key])

  if (is.na(normalised)) {
    stop("Unknown size: ", size)
  }

  normalised
}

size_surcharge <- function(size) {
  unname(size_prices[normalise_size(size)])
}
EOF
}

write_drink_aliases() {
  cat > R/menu.R <<'EOF'
menu <- data.frame(
  drink = c("espresso", "latte", "flat white", "mocha", "tea", "cold brew"),
  base_price = c(3.00, 4.20, 4.10, 4.60, 2.80, 4.80),
  stringsAsFactors = FALSE
)

drink_aliases <- c(
  fw = "flat white",
  flatwhite = "flat white",
  longblack = "espresso",
  cold = "cold brew"
)

normalise_drink <- function(drink) {
  key <- tolower(gsub(" ", "", trimws(drink)))
  alias <- unname(drink_aliases[key])

  if (is.na(alias)) {
    return(tolower(trimws(drink)))
  }

  alias
}

find_menu_item <- function(drink) {
  row <- menu[menu$drink == normalise_drink(drink), ]
  if (nrow(row) == 0) {
    stop("Unknown drink: ", drink)
  }
  row
}
EOF
}

write_coupon_file() {
  cat > R/coupons.R <<'EOF'
coupon_discount_rate <- function(code) {
  if (is.null(code) || identical(code, "")) {
    return(0)
  }

  code <- toupper(trimws(code))
  if (code == "CAMPUS5") {
    return(0.05)
  }
  if (code == "MUGCLUB") {
    return(0.08)
  }

  0
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/loyalty.R")
source("R/coupons.R")
source("R/size.R")
source("R/tax.R")
source("R/pricing.R")
source("R/receipts.R")
EOF

  cat > R/pricing.R <<'EOF'
milk_surcharge <- function(milk) {
  alternatives <- c("oat", "soy", "almond")
  if (milk %in% alternatives) {
    return(0.60)
  }
  0
}

extra_shot_charge <- function(shots) {
  max(shots - 1, 0) * 0.90
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shot_charge(shots), 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0, coupon = NULL) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) +
    loyalty_discount_rate(stamps) +
    coupon_discount_rate(coupon)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_tests_with_coupon() {
  cat > tests/test-pricing.R <<'EOF'
source("coffee.R")

assert_equal <- function(actual, expected, label) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop(label, ": expected ", expected, ", got ", actual, call. = FALSE)
  }
}

assert_equal(line_total("latte", size = "small", milk = "dairy", shots = 1), 4.20, "small latte")
assert_equal(line_total("latte", size = "large", milk = "oat", shots = 2), 6.80, "large oat latte with extra shot")
assert_equal(line_total("espresso", size = "medium", milk = "dairy", shots = 2), 4.60, "espresso with extra shot")
assert_equal(line_total("FW", size = "medium", milk = "dairy", shots = 1), 4.80, "flat white alias")

morning_order <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

assert_equal(order_total(morning_order, student_discount = TRUE), 9.5, "discounted morning order")
assert_equal(order_total(morning_order, stamps = 10), 8.98, "loyalty order")
assert_equal(order_total(morning_order, coupon = "CAMPUS5"), 10.03, "coupon order")
EOF
}

write_receipts_with_coupon() {
  cat > R/receipts.R <<'EOF'
format_money <- function(amount) {
  sprintf("$%.2f", amount)
}

receipt_line <- function(item) {
  paste(
    item$size,
    item$milk,
    item$drink,
    paste0("x", item$shots),
    format_money(line_total(item$drink, item$size, item$milk, item$shots))
  )
}

receipt <- function(items, student_discount = FALSE, stamps = 0, coupon = NULL) {
  c(
    vapply(items, receipt_line, character(1)),
    paste("Total", format_money(order_total(items, student_discount, stamps, coupon)))
  )
}
EOF
}

write_validation() {
  cat > R/validation.R <<'EOF'
required_item_fields <- c("drink", "size", "milk", "shots")

validate_item <- function(item) {
  missing <- setdiff(required_item_fields, names(item))
  if (length(missing) > 0) {
    stop("Order item missing fields: ", paste(missing, collapse = ", "))
  }

  invisible(TRUE)
}
EOF

  cat > coffee.R <<'EOF'
source("R/menu.R")
source("R/discounts.R")
source("R/loyalty.R")
source("R/coupons.R")
source("R/size.R")
source("R/tax.R")
source("R/validation.R")
source("R/pricing.R")
source("R/receipts.R")
EOF

  cat > R/pricing.R <<'EOF'
milk_surcharge <- function(milk) {
  alternatives <- c("oat", "soy", "almond")
  if (milk %in% alternatives) {
    return(0.60)
  }
  0
}

extra_shot_charge <- function(shots) {
  max(shots - 1, 0) * 0.90
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shot_charge(shots), 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    validate_item(item)
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0, coupon = NULL) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) +
    loyalty_discount_rate(stamps) +
    coupon_discount_rate(coupon)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_goldens() {
  mkdir -p tests/golden

  cat > tests/golden/morning-receipt.txt <<'EOF'
large oat latte x2 $6.40
small dairy tea x1 $2.80
Total $9.11
EOF
}

write_menu_markdown() {
  mkdir -p docs

  cat > docs/menu.md <<'EOF'
# Menu

| Drink | Base price |
| --- | ---: |
| Espresso | $3.00 |
| Latte | $4.20 |
| Flat white | $4.10 |
| Mocha | $4.60 |
| Tea | $2.80 |
| Cold brew | $4.80 |
EOF
}

write_final_readme() {
  cat > README.md <<'EOF'
# Campus Coffee Calculator

Tiny R scripts for pricing coffee orders at a fictional campus cart.

```r
source("coffee.R")
line_total("latte", size = "large", milk = "oat", shots = 2)
```

Run the checks with:

```sh
Rscript tests/test-pricing.R
```

Bisect starter:

```sh
git bisect start HEAD known-good
git bisect run Rscript tests/test-pricing.R
```
EOF
}

write_changelog() {
  cat > CHANGELOG.md <<'EOF'
# Changelog

## Unreleased

- Added drink aliases.
- Added coupon handling.
- Added receipt formatting helpers.
- Split pricing helpers across smaller files.
EOF
}

write_makefile() {
  cat > Makefile <<'EOF'
.PHONY: test example

test:
	Rscript tests/test-pricing.R

example:
	Rscript examples/morning-rush.R
EOF
}

write_examples_with_coupon() {
  cat > examples/morning-rush.R <<'EOF'
source("coffee.R")

orders <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "flat white", size = "medium", milk = "dairy", shots = 1),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

cat(receipt(orders, student_discount = TRUE, coupon = "CAMPUS5"), sep = "\n")
EOF
}

write_scratch_script() {
  mkdir -p scratch

  cat > scratch/compare-student-discounts.R <<'EOF'
source("coffee.R")

sample_order <- list(
  list(drink = "mocha", size = "medium", milk = "soy", shots = 1),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

print(order_total(sample_order))
print(order_total(sample_order, student_discount = TRUE))
EOF
}

write_tests_reordered() {
  cat > tests/test-pricing.R <<'EOF'
source("coffee.R")

assert_equal <- function(actual, expected, label) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop(label, ": expected ", expected, ", got ", actual, call. = FALSE)
  }
}

morning_order <- list(
  list(drink = "latte", size = "large", milk = "oat", shots = 2),
  list(drink = "tea", size = "small", milk = "dairy", shots = 1)
)

assert_equal(line_total("latte", size = "small", milk = "dairy", shots = 1), 4.20, "small latte")
assert_equal(line_total("espresso", size = "medium", milk = "dairy", shots = 2), 4.60, "espresso with extra shot")
assert_equal(line_total("FW", size = "medium", milk = "dairy", shots = 1), 4.80, "flat white alias")
assert_equal(line_total("latte", size = "large", milk = "oat", shots = 2), 6.80, "large oat latte with extra shot")

assert_equal(order_total(morning_order, student_discount = TRUE), 9.5, "discounted morning order")
assert_equal(order_total(morning_order, stamps = 10), 8.98, "loyalty order")
assert_equal(order_total(morning_order, coupon = "CAMPUS5"), 10.03, "coupon order")
EOF
}

write_pricing_constants() {
  cat > R/constants.R <<'EOF'
alternative_milk_charge <- 0.60
extra_shot_price <- 0.90
EOF

  cat > coffee.R <<'EOF'
source("R/constants.R")
source("R/menu.R")
source("R/discounts.R")
source("R/loyalty.R")
source("R/coupons.R")
source("R/size.R")
source("R/tax.R")
source("R/validation.R")
source("R/pricing.R")
source("R/receipts.R")
EOF

  cat > R/pricing.R <<'EOF'
milk_surcharge <- function(milk) {
  alternatives <- c("oat", "soy", "almond")
  if (milk %in% alternatives) {
    return(alternative_milk_charge)
  }
  0
}

extra_shot_charge <- function(shots) {
  max(shots - 1, 0) * extra_shot_price
}

line_total <- function(drink, size = "medium", milk = "dairy", shots = 1) {
  row <- find_menu_item(drink)
  round(row$base_price + size_surcharge(size) + milk_surcharge(milk) + extra_shot_charge(shots), 2)
}

order_subtotal <- function(items) {
  sum(vapply(items, function(item) {
    validate_item(item)
    line_total(
      drink = item$drink,
      size = item$size,
      milk = item$milk,
      shots = item$shots
    )
  }, numeric(1)))
}

order_total <- function(items, student_discount = FALSE, stamps = 0, coupon = NULL) {
  subtotal <- order_subtotal(items)
  discount <- student_discount_rate(student_discount) +
    loyalty_discount_rate(stamps) +
    coupon_discount_rate(coupon)
  add_tax(subtotal * (1 - discount))
}
EOF
}

write_issue_template() {
  mkdir -p .github/ISSUE_TEMPLATE

  cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOF'
---
name: Bug report
about: Report a surprising coffee total
---

## Order

## Expected

## Actual
EOF
}

write_final_notes() {
  cat > notes/bisect-cheatsheet.md <<'EOF'
# Bisect Cheatsheet

```sh
git bisect start HEAD known-good
git bisect run Rscript tests/test-pricing.R
git bisect reset
```
EOF
}

# Repository history starts here.
write_readme_basic
write_initial_coffee
commit_all "Initial coffee pricing calculator"

write_split_v1
commit_all "Split menu and pricing helpers"

write_tests_with_helpers
commit_all "Cover espresso and large latte pricing"

write_tax_file
commit_all "Move GST calculation into helper"

write_receipts
commit_all "Add receipt formatting"

write_readme_with_examples
commit_all "Document latte pricing example"

write_examples
commit_all "Add morning rush example"

write_notes
commit_all "Record pricing policy notes"

write_loyalty
commit_all "Add loyalty discount helper"

write_order_total_with_loyalty
commit_all "Apply loyalty discounts at checkout"

write_tests_with_loyalty
commit_all "Test loyalty checkout totals"

write_temp_experiment
commit_all "Prototype punch card messages"

rm -rf experiments
commit_all "Remove unused punch card prototype"

write_menu_with_cold_brew
commit_all "Add cold brew to menu"

write_size_file_good
commit_all "Move size prices into their own file"

git tag known-good

write_size_file_buggy
commit_all "Accept common size aliases"

write_pricing_vectorised
commit_all "Extract extra shot charge helper"

write_size_alias_table_buggy
commit_all "Use lookup table for size aliases"

write_drink_aliases
commit_all "Add drink aliases for till shortcuts"

write_coupon_file
commit_all "Add coupon discounts"

write_tests_with_coupon
commit_all "Cover coupons and drink aliases"

write_receipts_with_coupon
commit_all "Pass coupon details through receipts"

write_validation
commit_all "Validate order item fields"

write_goldens
commit_all "Add golden receipt fixture"

write_menu_markdown
commit_all "Publish menu table"

write_final_readme
commit_all "Add bisect instructions"

write_changelog
commit_all "Start changelog"

write_makefile
commit_all "Add make targets"

write_examples_with_coupon
commit_all "Use coupon in morning rush example"

write_scratch_script
commit_all "Compare student discount totals"

rm -rf scratch
commit_all "Drop scratch comparison script"

write_tests_reordered
commit_all "Group pricing checks before checkout checks"

write_pricing_constants
commit_all "Centralise pricing constants"

write_issue_template
commit_all "Add bug report template"

write_final_notes
commit_all "Add bisect cheatsheet"

echo "Created git-bisect demo repository at: $DEMO_DIR"
echo
echo "Try it:"
echo "  cd \"$DEMO_DIR\""
echo "  Rscript tests/test-pricing.R       # currently fails"
echo "  git bisect start HEAD known-good"
echo "  git bisect run Rscript tests/test-pricing.R"
