---
description: tokensmax — who solved what + token usage (estimate vs actual, ⚠ limit hits)
argument-hint: "[today | all | YYYY-MM-DD]"
allowed-tools: Bash(tokensmax usage:*)
---
!`tokensmax usage $ARGUMENTS`

Summarize the table above: which engine solved what, EST vs ACTUAL tokens, **$ cost**, the **window total**, and call out any **⚠ maxed (+ reset time)**. If a `session_limit` is set, give the remaining. Don't invent a remaining-quota number — there's no API for it; cost + reset + window is the honest readout.
