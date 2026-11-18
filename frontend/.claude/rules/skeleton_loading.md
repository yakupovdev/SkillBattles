# Loading Skeletons — skeletonizer

> **Scope:** Mandatory for every loading placeholder in the app. Adds to `state_managment.md` ("UI, navigation and lifecycle", "Minimizing rebuilds") and `code_style.md`. Package: `skeletonizer` (see `pubspec.yaml`).

## The idea

A skeleton is **the real UI rendered with mock data and painted as bones** by `Skeletonizer`. It is never a separate placeholder layout drawn by hand.

- While the request loads, the screen renders the **same widgets** it renders on success, fed with **mock entities**, inside a `Skeletonizer(enabled: true)`.
- When the data arrives, the same tree gets the real entities and `enabled: false`. Nothing is swapped; the layout of the skeleton is always exactly the layout of the content.

## Forbidden

- Hand-built placeholders: `Bone(...)`, `Container`/`SizedBox`/`ColoredBox` boxes with guessed sizes, `AspectRatio` + grey box, etc. (`AppSkeleton` and `AppSkeletonizer` were deleted for this reason; do not bring them back or write a wrapper around `Skeletonizer`.)
- Separate `<Name>Skeleton` / `<Name>Placeholder` / `<Name>LoadPlaceholders` widgets that copy the layout of the content (`HomeSkeleton`, `TasksSkeleton`, `ContractLoadPlaceholders` are the old, wrong pattern).
- Switching widgets by status: `isLoading ? const XSkeleton() : XContent(data)`. Use one tree and `enabled:`.
- Sizes, widths, or bone counts written for the skeleton in specs or code. The sizes come from the real widgets and the mock data.
- `Skeletonizer.zone` with manual bones. Use the regular `Skeletonizer`, which turns the real widgets into bones.
- Passing `effect:` (or other look settings) to a `Skeletonizer` in a feature. The look comes from `AppSkeletonTheme`.

## How to build it

### 1. The look is configured once

`AppSkeletonTheme` (`lib/app/theme/app_skeleton_theme.dart`) wraps the whole app in `EasyBookingApp`'s `MaterialApp.router(builder:)` and provides `SkeletonizerConfig`: a shimmer over `AppColors.skeletonLight` / `AppColors.skeletonHighlight`, or a still `AppColors.skeletonLight` when `MediaQuery.disableAnimationsOf(context)`. Screens use the package widget directly — `Skeletonizer(enabled: ..., child: ...)` — and configure nothing else. Bottom sheets and dialogs are inside the navigator, so they get the same look.

### 2. Wrap the block that waits for the request

Reference implementation: `lib/features/home/presentation/screens/home_screen.dart` (`Skeletonizer` over `_HomeContent`, mock data in `home_skeleton_data.dart`).

Put `Skeletonizer` over the part of the screen whose content comes from the request: the screen body, or one loading block when a screen has several independent requests. Static parts that do not depend on the request (app bar, page title, tabs, a submit button that is not data) stay outside it.

```dart
// Inside the screen, keyed only on what decides loading + the data.
BlocBuilder<HomeBloc, HomeState>(
  buildWhen: (HomeState previous, HomeState current) =>
      previous.loadStatus != current.loadStatus ||
      previous.overview != current.overview,
  builder: (BuildContext context, HomeState state) {
    final HomeOverviewEntity? overview = state.overview;
    if (state.loadStatus == LoadStatus.failure && overview == null) {
      return HomeError(onRetry: ...);
    }
    return Skeletonizer(
      enabled: overview == null,
      child: _HomeContent(overview: overview ?? HomeSkeletonData.overview),
    );
  },
)
```

- `enabled` is derived from the request status and the data: **true** only while there is nothing real to show (first load). A refresh or a retry with data already on screen shows the data, not a skeleton (pull-to-refresh has its own indicator).
- A failure without data shows the error view, not a skeleton. An empty success shows the empty state, not a skeleton.
- A new search query is a new request: the results of the previous query do not answer it, so the result block is skeletonized again while the new query loads (`BookingGuestSuggestions`).
- Independent requests (e.g. a list and a counter) get independent `Skeletonizer`s, each keyed on its own status (`state_managment.md`: separate statuses).
- Do not nest `Skeletonizer`s to switch parts on and off; give each request block its own `Skeletonizer` side by side.
- Switching `enabled` swaps the subtree (the package keys it), so state inside it (scroll offsets, `TextEditingController`s of the content) starts fresh when the data arrives. Keep form controllers in the screen's `State`, above the `Skeletonizer`.
- Forms under a `Skeletonizer`: fill `TextEditingController`s only from real data (never from mocks), so the skeleton shows empty fields. A `GlobalKey` keeps its `State` when its widget moves to the new subtree, so a `FormFieldState` (e.g. `AppPickerField`) built with mock data would carry the mock value into the loaded form: pass form/field `GlobalKey`s (and mock-derived `initialValue`s) only once real data is loaded (`EditProfileScreen`).
- Actions outside the skeleton (save, send, invite) read the real state and stay disabled until the data is loaded; a callback that would act on the rendered entity is `null` while it is a mock.

### 3. Mock data

- Mock data is a set of **domain entities** of a realistic shape, so text lengths, list lengths, and optional parts match a typical answer. Use `BoneMock` (`BoneMock.title`, `BoneMock.name`, `BoneMock.words(n)`, `BoneMock.date`, `BoneMock.chars(n)`) for strings; realistic numbers, `DateTime`s, and enum values for the rest.
- It lives in the feature's presentation layer, in `presentation/widgets/<feature>_skeleton_data.dart`, as a `final class <Feature>SkeletonData` with private constructor and `static final` members (`HomeSkeletonData.overview`, `GuestsSkeletonData.guests`). A shared widget in `lib/core` that needs mock data receives it through its constructor, like any other data.
- Lists use a fixed small number of mock items that fills the visible area (typically 3–6), built with `List<XEntity>.generate(...)` or listed explicitly. Ids are unique and obviously fake (`'skeleton-0'`).
- Mock data never reaches the BLoC, the repository, the cache, or tests of business logic. It exists only for rendering.
- Never invent placeholder entities inside a widget's `build`; reference the `SkeletonData` constants.

### 4. Fine-tuning the bones (inside the real widgets)

Use skeletonizer annotations in the real widgets only where the default result is wrong:

- `Skeleton.keep(child:)` — stays visible while loading (a static label, a section icon).
- `Skeleton.ignore(child:)` — hidden while loading (badges, counters, action buttons that make no sense without data).
- `Skeleton.leaf(child:)` — the whole subtree is one bone (a card, a chip, a stat tile).
- `Skeleton.unite(child:)` — several small bones (a row of icons) become one.
- `Skeleton.replace(width:, height:, replacement:)` — a widget that cannot render with mock data, e.g. a network image.
- Images: never load a mock URL. `AppPhoto` (and any widget that loads from the network or decodes files) checks `Skeletonizer.maybeOf(context)?.enabled ?? false` and, instead of starting the load, renders one bone (`Skeleton.leaf`) or its offline fallback (`AppAccountIdentity` shows the initials).
- Annotations are no-ops when skeletonizer is disabled, so they are safe to leave in the widget.

### 5. Behavior while loading

- `Skeletonizer` ignores pointers by default (`ignorePointers: true`); keep it, so taps on mock items never navigate or dispatch events with mock ids.
- `BlocListener`s react to real state only; nothing listens to mock data.
- Pull-to-refresh, retry buttons, and navigation must not depend on mock data: compute them from the real state (`state.overview`), not from the rendered mock entity.

## Specs and designs

- Specs in `docs/specs/` describe a loading state as "the content of <block> skeletonized with mock data" plus any `keep`/`ignore`/`leaf` exceptions taken from the Paper artboard. They do not list bone sizes.
- When the Paper loading artboard differs from what the real widgets produce with mock data, fix it with annotations or mock data shape, not with a hand-made layout.

## Tests

- Screen tests pump the loading state and assert that the `Skeletonizer` has `enabled: true` and that the real content widgets (`StayCard`, `TaskRow`, ...) are in the tree; after the success state, `enabled: false` and the real values are shown.
- Assert that a failure without data shows the error view and no enabled skeletonizer, and that a refresh with data shows the data without an enabled skeletonizer.
- Assert that a tap on a skeletonized item does nothing (no navigation, no event).
- Do not assert bone sizes or the number of `Bone` widgets.
- `find.byType(Skeletonizer)` finds nothing (the runtime type is a private subclass): use `find.byWidgetPredicate((Widget w) => w is Skeletonizer && w.enabled)`.
- A screen pumped outside `EasyBookingApp` has no `AppSkeletonTheme`, so its skeleton shimmers forever and `pumpAndSettle` times out while loading: wrap the test app in `AppSkeletonTheme` and disable animations (`FakeAccessibilityFeatures(disableAnimations: true)`), or use `pump()`.
- `AppSkeletonTheme` is tested in `test/app/theme/`: shimmer vs. still effect under reduced motion.

## Completion check

- No `Bone(`, hand-sized grey box, `Skeletonizer` wrapper widget, or `*Skeleton`/`*Placeholder` layout widget added.
- The skeleton is the real widget tree with `<Feature>SkeletonData`.
- `enabled` follows the request status and data presence; error, empty, and refresh states are not skeletonized.
- Network images and other side-effecting widgets do not load mock data.
- `buildWhen` covers every field used to compute `enabled` and the data.
