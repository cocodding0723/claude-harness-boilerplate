---
description: 구조적 디버깅 6단계. mattpocock/skills의 diagnose 패턴 — reproduce → minimize → hypothesize → instrument → fix → regression-test.
allowed-tools: Bash(*), Read(**), Grep(**), Glob(**), Edit(*), Write(*)
---

# /diagnose — Structured Debugging (6-step)

Based on Matt Pocock's diagnose skill. Forces systematic root-cause analysis instead of guessing.

## Steps

### 1. Reproduce
```bash
# Run the failing test/command to confirm the problem exists
flutter test test/<failing_test>.dart --verbose
```
If cannot reproduce: stop and ask user for exact steps.

### 2. Minimize
Reduce the problem to the smallest possible reproducer:
- Which file / line?
- Which data input triggers it?
- Does it happen in isolation?

### 3. Hypothesize
Generate 3 distinct hypotheses for root cause. Rank by likelihood:
1. Hypothesis A (most likely)
2. Hypothesis B
3. Hypothesis C

### 4. Instrument
Add temporary logging/asserts to test each hypothesis:
```dart
// Hypothesis A check
assert(value != null, 'Hypothesis A: value should not be null here');
print('[diagnose] state=$state before call');
```
Run and observe which hypothesis holds.

### 5. Fix
Apply the minimal fix for the confirmed root cause. No cleanup of unrelated code.

### 6. Regression test
```bash
flutter test  # full suite — confirm no regressions
```
Add a specific test for the bug if none exists.

## Output format
```
## Diagnosis — <bug description>

### Root cause
<one sentence>

### Fix applied
<file:line, what changed>

### Regression test
<test name or "existing test covers it">
```
