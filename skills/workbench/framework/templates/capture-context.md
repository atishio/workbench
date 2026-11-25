# Capture Context Template

Produced by stub-and-capture. Consumed by test-scaffold as input for test generation.

```
## Capture Context: {Feature Name}

### Source
{observed | confirmed | inferred} — how this capture was produced

### Feature Under Test
{One-sentence description}

### Proposed Test Cases
1. {TC-1}: {description}
2. {TC-2}: {description}

### Network Capture

#### Mock journal
{Relevant request/response pairs from the journal}

#### Browser network (if captured)
{Client-side network calls observed}

### Stub Setup Hints
- Stub 1: {endpoint} → {response shape}
- Stub 2: {endpoint} → {response shape}

### Notes
{Observations from the capture session — unexpected calls, timing issues, etc.}
```

## Usage

1. stub-and-capture fills this template during capture
2. Developer reviews and adjusts (adds/removes test cases)
3. test-scaffold consumes it to generate test code
