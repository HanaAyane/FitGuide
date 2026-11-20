# FitGuide v2.0 Validation

Date: 2026-08-01
Branch: `v2.0`
Target: iPhone 17 Simulator, iOS 26.5

## Automated validation

Command:

```bash
xcodegen generate
xcodebuild -project FitGuide.xcodeproj -scheme FitGuide \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO test
```

Current automated evidence (after the v2 data-model and persistence changes):

- WorkoutStoreTests: **34 passed, 0 failures**.
- PerformanceTests: **9 passed, 0 failures**. The 1,000-session on-disk
  history fixture measured 30-row fetch plus `WorkoutMetrics` at about
  **138 ms average**, below the 500 ms target.
- AttributionTests: **4 passed, 0 failures**.
- Unsigned Release generic-iPhone build: **passed on 2026-08-01 after the
  latest UI changes**; version is `2.0 (2)`, `UIDeviceFamily = [1]`, portrait
  only, and full screen is required.
- The current product removes all favorites UI and interaction. The old v1
  favorites tables remain only for non-destructive store compatibility.

The UI suite uses isolated fixtures and covers plan start, free workout,
background/foreground continuation, completion, abandonment, cold-launch
recovery, rest controls, and history review. A final clean rerun is still
required after the latest UI touch-target changes; it was intentionally paused
to make the simulator immediately available for stakeholder acceptance.

## Accessibility validation

Partial automated coverage is present on the target simulator:

- The training home, workout session, summary, and history-detail audit is
  automated, but must be rerun after the latest UI changes.
- Manual VoiceOver remains unverified and is not a release-complete claim.

The automated pixel contrast audit is not used as a release assertion because
the animated space background can produce false sampling results. Contrast is
instead covered by the Increase Contrast matrix and visual simulator review.
Manual VoiceOver traversal remains a physical-device release gate.

## Manual simulator flow

Previously exercised on the simulator; revalidation is pending after the
latest UI changes:

1. Launched v2 against an existing v1 simulator store.
2. Confirmed the existing plan and its two items remained visible.
3. Started a free workout.
4. Added an exercise and completed three sets.
5. Exercised rest pause, `+15s`, and skip controls.
6. Finished the workout and verified the summary metrics and set details.
7. Returned to Training and verified the saved workout in Recent.

## Static audit

- Active branch is `v2.0`.
- Existing `v1.0` tag remains present.
- Marketing version is 2.0; build is 2.
- `git diff --check` passes.
- Current acceptance build was installed and launched on iPhone 17 Simulator
  (iOS 26.5) on 2026-08-01.

## Remaining release gates

These checks remain intentionally incomplete:

- Three complete workouts on a physical device.
- Manual VoiceOver traversal on a physical device.
- Instruments check for current GIF memory growth and a longer background run.
- iOS 18 simulator fallback-path verification.
- Final clean full UI regression after the latest UI touch-target changes.
