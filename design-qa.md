# Home Projects Design QA

## Evidence

- Source visual truth: `Docs/design/home_projects_reference.png`
- Final implementation screenshot: `Docs/design/home_projects_implementation_pass2.png`
- Full-view comparison: `Docs/design/home_projects_comparison_pass2.png`
- Focused card comparison: `Docs/design/home_projects_card_comparison_pass2.png`
- Viewport: iPhone 17 Pro Simulator, iOS 26.5, light appearance, Simplified Chinese
- Source dimensions: 852 x 1846 pixels, intended 390 x 844 logical mobile viewport
- Implementation dimensions: 1206 x 2622 pixels, 402 x 874 logical points at device pixel ratio 3
- Density normalization: implementation screenshot resized to 852 x 1846 for the side-by-side comparison; app-owned content was judged while ignoring the Simulator-owned status bar that the source mock intentionally omits
- State: seeded active project with 2 boxes, 2 pending physical marks, and arrival progress 0/2

## Findings

- No actionable P0, P1, or P2 differences remain.
- Fonts and typography: the final hierarchy matches the source intent: compact 22-point page title, 20-point project title, readable route/count copy, and smaller status labels. Native Flutter/SF Chinese font rasterization differs slightly from the generated mock but does not change hierarchy or wrapping.
- Spacing and layout rhythm: 20-point page margins, a single compact project card, lightweight section label, grouped status row, and the safe-area-aware full-width primary action match the source composition. The card remains responsive by stacking status rows below 320 points or above 1.15 text scale.
- Colors and tokens: the existing warm ivory canvas and seeded forest-teal system were retained. The card border and dividers were reduced to 70% outline opacity, and red is limited to the unresolved physical-mark state.
- Image quality and assets: the target contains no photographic or custom raster assets. All visible icons use the existing Material icon family; no placeholder, handcrafted SVG, or raster substitute was introduced.
- Copy and content: all target Chinese labels are present. `进行中` was added to both Chinese and English localization sources as `Active`.
- Interaction and accessibility: the whole card remains tappable; search, More, Settings navigation, and New Project remain functional. Touch targets are at least 44 points, and the narrow-screen/large-text widget path completes without overflow.

## Comparison History

### Pass 1

- Evidence: `Docs/design/home_projects_comparison_pass1.png` and `Docs/design/home_projects_card_comparison_pass1.png`.
- [P2] The project icon, project title, status labels, border, and primary button were visually heavier than the source, making the card read more like a dashboard panel than a lightweight project row.
- Fixes: reduced the page title to 22 points, project icon from 52 to 44 points, project title to 20 points, status icons/text by one type step, button height from 58 to 54 points, card padding, and border/divider opacity.

### Pass 2

- Evidence: `Docs/design/home_projects_comparison_pass2.png` and `Docs/design/home_projects_card_comparison_pass2.png`.
- The earlier density mismatch is resolved. No P0, P1, or P2 difference remains after the second Simulator capture.

## Open Questions

- None for this selected light-mode home state. Dark mode and real-device rendering were not part of the supplied visual target.

## Implementation Checklist

- [x] Preserve project, search, More, archive/settings, and create behavior.
- [x] Use a compact card rather than metric chips.
- [x] Add localized active-project section copy.
- [x] Keep the primary action aligned to the page margins and safe area.
- [x] Verify narrow layout, enlarged text, localization switching, and primary actions with widget tests.
- [x] Capture and compare the final iPhone 17 Pro Simulator state.

## Follow-up Polish

- P3: the generated source omits native system chrome while the Simulator capture includes it. This is expected device infrastructure and is not recreated in app content.

## Home More Panel Extension QA

### Evidence

- User-approved specification: `Docs/design/home_more_spec.md`
- Selected home visual language: `Docs/design/home_projects_final.png`
- First implementation screenshot: `Docs/design/home_more_implementation_pass1.png`
- Final implementation screenshot: `Docs/design/home_more_implementation_pass2.png`
- Full-view design-language comparison: `Docs/design/home_more_comparison_pass2.png`
- Focused component comparison: `Docs/design/home_more_region_comparison_pass2.png`
- Viewport and state: the same iPhone 17 Pro Simulator, iOS 26.5, light appearance, Simplified Chinese, with the More panel open over the seeded active project
- Comparison method: the approved home screen and final More-panel state were combined at their native 1206 x 2622 dimensions. This validates visual-system continuity rather than pixel parity between two intentionally different UI states.

### Findings

- No actionable P0, P1, or P2 differences remain.
- Structure: the former system action sheet is now a compact native bottom sheet with a clear title, one grouped card, and a quiet cancel action.
- Card language: the 20-point page margins, warm ivory surface, subtle outline, rounded corners, mint icon containers, dark labels, and chevrons visibly match the selected home card.
- Density and hierarchy: both destinations are immediately scannable without the oversized full-width text treatment in the original sheet. The title leads, the grouped destinations follow, and Cancel remains visually secondary.
- Interaction and accessibility: both rows remain fully tappable and keep their original destinations. The sheet uses a scroll fallback and was verified at a 320 x 568 viewport with 1.3 text scale without overflow.

### Comparison History

- Pass 1: [P2] the two action rows were still taller than the selected home card language required, leaving the panel visually heavy.
- Fix: reduced row vertical padding and icon containers while preserving touch-target size and label readability.
- Pass 2: the action density is now consistent with the compact home card. No actionable P0, P1, or P2 difference remains.

### Implementation Checklist

- [x] Preserve Archived Projects, Settings, and Cancel behavior.
- [x] Keep the presentation as a native, dismissible bottom sheet.
- [x] Use one grouped card with left-aligned icons, labels, and chevrons.
- [x] Match the selected home screen's margins, colors, borders, and radii.
- [x] Verify navigation, cancellation, narrow layout, and enlarged text with widget tests.
- [x] Capture and inspect a second Simulator pass after the density adjustment.

final result: passed

---

# Project Detail Option 3 Design QA

## Evidence

- Source visual truth: `/Users/starburst/.codex/generated_images/01a04750-9845-7582-b1e7-4044a1065dc6/exec-b65a5b44-4369-448a-bc18-04a69ea5d66a.png`
- First Simulator screenshot: `Docs/design/project_detail_option3_simulator_pass1.png`
- Final Simulator screenshot: `Docs/design/project_detail_option3_simulator_pass2.png`
- Normalized final screenshot: `Docs/design/project_detail_option3_implementation_pass2_normalized.png`
- Full-view comparison: `Docs/design/project_detail_option3_comparison_pass2.png`
- Focused filter and quick-entry comparison: `Docs/design/project_detail_option3_regions_comparison_pass2.png`
- Viewport: iPhone 16e Simulator, iOS 18.3, light appearance, Simplified Chinese; 390 x 844 logical points at device pixel ratio 3.
- Source dimensions: 851 x 1847 pixels, representing the selected 390 x 844 mobile concept.
- Implementation dimensions: 1170 x 2532 pixels; normalized to 851 x 1847 for the side-by-side comparison.
- Density normalization: the Simulator image was resized to the source pixel dimensions. App-owned content was judged while ignoring the native status bar and home indicator.
- State: 2 boxes; 2 waiting to load; 2 not arrived; 2 not unpacked; 0 suspected missing; 2 pending physical marks. C-002 is a draft with a local image and C-001 is packed.

## Findings

- No actionable P0, P1, or P2 differences remain.
- Fonts and typography: native iOS Chinese typography preserves the selected hierarchy across the project title, progress summary, filters, search, grouped list, and action dock. The generated source uses slightly lighter synthetic type, but the implementation remains visually equivalent without wrapping or truncation.
- Spacing and layout rhythm: the implementation follows the selected list-first order: compact progress and next task, one-row stage filters, search, box section utility, grouped rows, then a safe-area-aware quick-entry dock. Both box rows remain visible in the first 390 x 844 viewport.
- Colors and visual tokens: the existing warm ivory canvas, white surfaces, deep green accents, pale mint primary action, subtle gray-green outlines, and semantic red pending state match the selected direction without gradients or heavy elevation.
- Image quality and asset fidelity: production rows continue to render the user's local photo with `Image.file` and `BoxFit.cover`; empty records use the existing Material inventory icon. The QA fixture uses the bundled onboarding illustration as a real local image, so its subject differs from the mock's keyboard photo but the crop, mask, and image slot are validated.
- Copy and content: all selected Chinese copy and counts are present, including `疑似遗漏 0`, `分享全部 A4 标签`, and the four quick-entry labels.
- Interaction and accessibility: stage filters preserve multi-select OR semantics and can be cleared; pending marks, QR, row navigation, label sharing, resume batch, search, and all four registration paths retain their existing callbacks. The quick-entry dock hides when the keyboard creates a bottom inset. Widget coverage passes at 390 x 844 and at 320 x 568 with 1.3 text scale without overflow.

## Comparison History

### Pass 1

- Evidence: `Docs/design/project_detail_option3_simulator_pass1.png` and `Docs/design/project_detail_option3_comparison_pass1.png`.
- [P2] The fourth equal-width filter clipped the trailing `0` from `疑似遗漏 0`, weakening the promised at-a-glance status summary.
- Fix: gave the longest filter a 6:5 width ratio relative to the other stages and used the compact label text style while retaining the icon and 44-point touch target.

### Pass 2

- Evidence: `Docs/design/project_detail_option3_simulator_pass2.png`, `Docs/design/project_detail_option3_comparison_pass2.png`, and `Docs/design/project_detail_option3_regions_comparison_pass2.png`.
- The earlier count clipping is resolved. All four filters are fully readable; no P0, P1, or P2 mismatch remains.

## Open Questions

- None for the selected light-mode project-detail state. Dark mode and real-device rendering were not part of the selected visual target.

## Implementation Checklist

- [x] Preserve back, scan, More, pending-mark, unfinished-batch, search, filters, QR, labels, and box-edit behavior.
- [x] Move the box list into the primary first-viewport position.
- [x] Group box rows into one surface with a divider.
- [x] Keep quick registration visible in a bottom action dock and emphasize continuous capture.
- [x] Adapt filters and action labels for narrow screens and enlarged text.
- [x] Run Analyzer, the complete widget/service suite, and the focused layout tests.
- [x] Capture and compare a second Simulator pass after fixing the filter count.

## Follow-up Polish

- P3: the Simulator capture includes native status-bar and home-indicator infrastructure omitted by the generated mock. These are runtime-owned and intentionally not recreated in app content.
- P3: the QA fixture photo subject differs from the mock; production content remains user-supplied and the image treatment matches.

final result: passed
