---
description: 구현 전 계획 검증 인터뷰. mattpocock/skills의 grill-me 패턴 — 모든 결정 분기가 해소될 때까지 질문. 스펙 정합성 보장.
allowed-tools: Read(**), Glob(**), Grep(**)
---

# /grill-me — Pre-Implementation Plan Validation

Based on Matt Pocock's grill-me skill. Runs intensive questioning to resolve all ambiguities before the first line of code is written.

## Steps

### 1. Read the spec
Read the relevant spec section (SCR-* or API-*) from `solidosis_ge_docs/`:
```bash
grep -r "$FEATURE_NAME" solidosis_ge_docs/ --include="*.md" -l
```

### 2. Grill mode
Ask probing questions until ALL of these are answered:

**Scope questions:**
- Exactly which files will change?
- Are there dependencies on other unreleased features?
- Is there a Mock implementation path if Firebase is unavailable?

**Edge case questions:**
- What happens on network failure?
- What happens with empty data?
- What are the DDD layer boundaries?

**Validation questions:**
- What is the success criteria? (specific test assertions)
- Which existing tests might break?
- Is there a PHI field involved? If so, what's the encryption plan?

### 3. Alignment document
Write a brief plan (5 bullets max) to `.claude/memory.md` under `## Current feature: <name>`:
```
- Feature: <name>
- Files changing: <list>
- Success criteria: <test assertions>
- PHI involved: yes/no — encryption: <plan>
- Spec ref: SCR-XX / API-XX
```

### 4. Proceed
Only after all questions answered and alignment document written.

## Rules
- Never start implementation before all edge cases are resolved
- If spec is ambiguous: flag it, don't guess
- Output: alignment doc + green light to proceed
