# PennyPilot Spending Check — Local Smart Helper

## Purpose and user control
The helper offers an understandable spending message based on the current month's
expense total and user-selected monthly budget. It runs locally. It does not
send transaction data to a remote service, train a model, or make financial decisions.
The user controls the budget and can ignore the suggestion.

## Alternative and baseline
Alternative: no suggestions, only a numeric budget progress bar.
Baseline: always display “Review your expenses regularly.”
Proposed rule-based helper: if no budget, request a budget; if spending >= 100%,
warn about the limit; if >= 80%, report the percentage; otherwise reassure.

## Test cases and metric
Run `flutter test` to check zero budget, 30%, 85%, 100%, and 130% cases.
For a graduate held-out evaluation, create at least ten additional unseen
cases after freezing the thresholds. Compare helper output to expected
labels and baseline using exact-match accuracy and helpfulness review.
Record actual results here after running tests. Do not claim results in advance.

## Counterexample and limitation
An expensive one-time medical or tuition purchase could trigger an alarming
message despite being necessary. A rule cannot know context or predict future
spending. Revision candidate: allow a user to dismiss a warning and optionally
exclude exceptional categories, documenting the resulting test cases.

## Offline proof
Run in airplane mode, add transactions, restart, and verify the same suggestion.
Capture evidence on two devices/emulators. Results pending actual execution.
