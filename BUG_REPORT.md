# Bug Report - Bracketer iOS Camera App

**Analysis Date:** 2025-11-12
**Analyzed By:** Claude Code
**Total Bugs Found:** 14

---

## Critical Bugs (Must Fix)

### 1. **PhotoSaver Returns Nil Asset ID** ⚠️ HIGH PRIORITY
**File:** `CameraController.swift:680-708`
**Severity:** Critical
**Type:** Logic Bug / Race Condition

**Issue:**
The `saveRAW` function returns `assetIdentifier` immediately, but `PHPhotoLibrary.shared().performChanges()` is asynchronous. The variable is always `nil` when returned because the closure hasn't executed yet.

```swift
var assetIdentifier: String?

PHPhotoLibrary.shared().performChanges({
    // ... sets assetIdentifier inside closure
}, completionHandler: { success, error in
    // ...
})

return assetIdentifier  // ❌ Always nil!
```

**Impact:** Bracket asset IDs are never captured, so `fetchBracketAssets()` never works properly. The image viewer won't show captured brackets.

**Fix:** Refactor to use completion handler or async/await pattern.

---

### 2. **Memory Leak: NotificationCenter Observer Not Removed**
**File:** `PreviewContainer.swift:255-261`
**Severity:** Critical
**Type:** Memory Leak

**Issue:**
An orientation observer is added in `makeUIView` but never removed, causing a memory leak.

```swift
NotificationCenter.default.addObserver(
    forName: UIDevice.orientationDidChangeNotification,
    object: nil,
    queue: .main
) { _ in
    updateOrientation(for: v.videoPreviewLayer)
}
// ❌ Observer is never removed!
```

**Impact:** Every time the preview is recreated, a new observer is added without removing the old one. Memory leaks accumulate.

**Fix:** Use a Coordinator to manage the observer lifecycle and remove it in `dismantleUIView`.

---

### 3. **Mutating Published Property in `getRelativeAttitude()`**
**File:** `MotionManager.swift:103-109`
**Severity:** High
**Type:** Logic Bug / State Corruption

**Issue:**
The method mutates the `currentAttitude` which is a `@Published` property, corrupting the state.

```swift
func getRelativeAttitude() -> CMAttitude? {
    guard let current = currentAttitude,
          let reference = referenceAttitude else { return nil }

    current.multiply(byInverseOf: reference)  // ❌ Mutates currentAttitude!
    return current
}
```

**Impact:** After calling this method once, `currentAttitude` is permanently altered, breaking all subsequent level calculations.

**Fix:** Create a copy before mutating.

```swift
func getRelativeAttitude() -> CMAttitude? {
    guard let current = currentAttitude?.copy() as? CMAttitude,
          let reference = referenceAttitude else { return nil }

    current.multiply(byInverseOf: reference)
    return current
}
```

---

### 4. **Timer Leak: Multiple Timers Created**
**File:** `CameraController.swift:151-153`
**Severity:** High
**Type:** Resource Leak

**Issue:**
If `start()` is called multiple times, multiple timers are created but only the last one is invalidated in `deinit`.

```swift
self.exposureUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    self.updateExposureUI()
}
```

**Impact:** Multiple timers fire simultaneously, wasting CPU and battery.

**Fix:** Invalidate existing timer before creating a new one.

```swift
exposureUpdateTimer?.invalidate()
exposureUpdateTimer = Timer.scheduledTimer(...)
```

---

## High Priority Bugs

### 5. **Potential Crash: Force Cast in PreviewView**
**File:** `PreviewContainer.swift:307-309`
**Severity:** Medium-High
**Type:** Force Cast / Potential Crash

**Issue:**
```swift
var videoPreviewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer  // ❌ Force cast
}
```

**Impact:** If layerClass is not properly set up, this will crash.

**Fix:** The code is actually correct because `layerClass` is overridden, but add a safety comment or use `guard let` for extra safety.

---

### 6. **Weak Self Not Checked in Recursive Closure**
**File:** `CameraController.swift:485-500`
**Severity:** Medium
**Type:** Potential Crash

**Issue:**
The `settleAutoExposure` function uses `[weak self]` in line 426, but inside the recursive `check()` function, `self` is used without nil-checking.

```swift
self.settleAutoExposure { [weak self] in
    guard let self = self else { return }
    // ...
}

// Inside settleAutoExposure:
func check() {
    if let off = self.device?.exposureTargetOffset, abs(off) <= threshold {
        completion()  // ✓ OK
        return
    }
    // ...
    self.sessionQueue.asyncAfter(deadline: .now() + poll) {
        check()  // ❌ Recursive call without checking if self exists
    }
}
```

**Impact:** If the CameraController is deallocated during the polling loop, undefined behavior or crash.

**Fix:** Capture `self` weakly in the recursive closure or use a structured approach.

---

### 7. **Haptic Engine Retain Cycle**
**File:** `HapticManager.swift:31-37`
**Severity:** Medium
**Type:** Potential Retain Cycle

**Issue:**
The `resetHandler` closure could create a retain cycle.

```swift
hapticEngine?.resetHandler = { [weak self] in
    do {
        try self?.hapticEngine?.start()
    } catch {
        print("Haptic engine restart failed: \(error)")
    }
}
```

**Impact:** While `[weak self]` is used correctly, it's worth verifying that `hapticEngine` doesn't retain the handler beyond its lifecycle.

**Fix:** Current code is likely fine, but consider setting handlers to `nil` in deinit for explicit cleanup.

---

## Medium Priority Bugs

### 8. **Duplicate Import Statement**
**File:** `PreviewContainer.swift:1-2`
**Severity:** Low
**Type:** Code Quality

**Issue:**
```swift
import SwiftUI
import SwiftUI
```

**Impact:** None (compiler ignores), but indicates code quality issue.

**Fix:** Remove one import.

---

### 9. **Uncancelled DispatchQueue.asyncAfter Tasks**
**File:** `ModernContentView.swift:218-222`, `MotionLevelOverlay.swift:236-258`
**Severity:** Medium
**Type:** Resource Leak / UI Bug

**Issue:**
`DispatchQueue.main.asyncAfter` calls are not cancellable. If the view disappears or mode changes rapidly, orphaned tasks execute.

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showModeChangeToast = false
    }
}
```

**Impact:**
- Toast might hide at wrong time
- Multiple overlapping animations
- State changes after view is gone

**Fix:** Use `DispatchWorkItem` and cancel on view disappear or state change.

```swift
private var toastHideTask: DispatchWorkItem?

// When showing toast:
toastHideTask?.cancel()
let task = DispatchWorkItem {
    withAnimation {
        showModeChangeToast = false
    }
}
toastHideTask = task
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
```

---

### 10. **Date() in View Body Without State Management**
**File:** `PreviewContainer.swift:686-694, 728`
**Severity:** Low-Medium
**Type:** Animation Bug

**Issue:**
`Date().timeIntervalSince1970` is used directly in SwiftUI view body for animations, but SwiftUI won't redraw unless state changes.

```swift
ForEach(0..<8) { index in
    let time = Date().timeIntervalSince1970  // ❌ Won't update!
    // ...
}
```

**Impact:** Animations don't work - the view is static unless redrawn by other state changes.

**Fix:** Use a Timer publisher or @State with onAppear to update the time.

```swift
@State private var currentTime: TimeInterval = Date().timeIntervalSince1970

var body: some View {
    // Use currentTime
}
.onAppear {
    Timer.publish(every: 0.05, on: .main, in: .common)
        .autoconnect()
        .sink { _ in
            currentTime = Date().timeIntervalSince1970
        }
        .store(in: &cancellables)
}
```

---

## Low Priority / Code Quality Issues

### 11. **Thread Safety: sessionQueue Access Pattern**
**File:** `CameraController.swift:121-128, 188-194`
**Severity:** Low
**Type:** Potential Race Condition

**Issue:**
`attachPreviewLayer` stores a weak reference to the layer, then accesses it async on sessionQueue. Theoretical race condition if layer is deallocated.

**Impact:** Very unlikely in practice since the layer is retained by the view hierarchy, but worth noting.

**Fix:** Capture the layer in the async block or ensure it's retained.

---

### 12. **Missing Explicit Combine Cancellation**
**File:** `OrientationManager.swift:10, 61-63`
**Severity:** Very Low
**Type:** Code Quality

**Issue:**
`cancellables` is a `Set<AnyCancellable>` that should auto-cancel, but there's no explicit cancellation in deinit.

**Impact:** Should work fine due to Swift's automatic cancellation, but explicit cleanup is best practice.

**Fix:** Add to deinit:
```swift
deinit {
    cancellables.removeAll()
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
}
```

---

### 13. **Error Handler Silently Ignores Error**
**File:** `CameraController.swift:519`
**Severity:** Low
**Type:** Error Handling

**Issue:**
```swift
} catch {}
```

Empty catch block silently ignores configuration errors in `finishSequence()`.

**Impact:** Debugging is harder if errors occur.

**Fix:** Log the error:
```swift
} catch {
    Logger.camera("Failed to restore auto modes: \(error)")
}
```

---

### 14. **Unused Constant in GoldenSpiralGrid**
**File:** `PreviewContainer.swift:171`
**Severity:** Very Low
**Type:** Dead Code

**Issue:**
Comment says "Removed unused phi constant" - the golden spiral implementation doesn't actually use the golden ratio formula.

**Impact:** The spiral is not mathematically accurate.

**Fix:** Either implement true golden spiral or rename to "Simplified Spiral".

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| High | 3 |
| Medium | 5 |
| Low | 2 |

### Recommended Fix Order:
1. Fix #1 (PhotoSaver async issue) - Breaks bracket capture
2. Fix #2 (NotificationCenter leak) - Memory leak
3. Fix #3 (Mutating published property) - State corruption
4. Fix #4 (Timer leak) - Resource leak
5. Fix #6 (Weak self in recursive closure) - Potential crash
6. Fix #9 (Uncancelled async tasks) - UI bugs
7. Fix #10 (Date() in view body) - Broken animations
8. Fix remaining issues as code quality improvements

---

## Testing Recommendations

After fixes, test:
1. **Bracket capture** - Verify images appear in viewer
2. **Memory leaks** - Use Instruments to check for leaks
3. **Orientation changes** - Rotate device rapidly
4. **Mode switching** - Change modes rapidly
5. **Focus peaking animations** - Verify they actually animate
6. **Level overlay** - Check animations work correctly
7. **Multiple start() calls** - Verify no timer accumulation

---

**End of Report**
