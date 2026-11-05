# OOP & SOLID Analysis — Frontend (Flutter)

## Architecture Overview

The app uses a **feature-first** structure with clear separation:

| Layer | Path / Pattern | Responsibility |
|-------|----------------|----------------|
| **View** | `features/…/view/screen`, `view/widget` | UI, user input, display |
| **ViewModel** | `features/…/viewmodel`, `*_cubit.dart` | State, orchestration (BLoC/Cubit) |
| **Repository** | `features/…/repository/*_repository.dart` | Data access, API calls |
| **Model** | `features/…/model/*_model.dart` | Domain/data models |
| **Core** | `core/di`, `core/services`, `core/constants` | DI, shared services, config |

**Dependency injection**: GetIt (`sl`) in `core/di/service_locator.dart`. Repositories and services are registered by **interface** (e.g. `IShopRepository`, `IClassRepository`) and resolved as `sl<IShopRepository>()`.

---

## SOLID Principles

### S — Single Responsibility Principle (SRP)

**What’s good**

- **Repositories**: One per domain area (Feed, Class, Shop, Scoring, etc.); responsibility is “data for this feature.”
- **Cubits**: Usually one Cubit per screen or flow (e.g. `AddClassCubit`, `GetFeedCubit`), handling one kind of state.
- **Models**: Mostly data + `fromJson`/`toJson`; no UI or API logic.
- **Interfaces**: Abstract contracts only (e.g. `IFeedRepository`, `IShopRepository`).

**Issues**

- **Large screens**: e.g. `KhademShopScreen`, `MakhdoumShopScreen`, `super_admin_&_khadem_main_screen` (and similar) mix:
  - Loading state
  - Data fetching
  - UI building
  - Navigation / dialogs
  - Business rules (e.g. “can afford gift”)
  
  One class ends up with many reasons to change (data, UI, flow).

- **StatefulWidget with repo calls**: Screens call `sl<IShopRepository>()` and `_loadGifts()`, `_loadRequests()` directly. Moving “load and hold list state” into a Cubit (or similar) would leave the screen responsible mainly for layout and user actions.

- **AddEditGiftDialog**: Holds form state, validation, and repository calls; could be split into “form state” vs “submit use case” (e.g. a small Cubit or callback from parent).

**Recommendation**: One main responsibility per class. Prefer Cubits (or similar) for “load/list/error” state and use-case logic; keep screens focused on layout and dispatching actions.

---

### O — Open/Closed Principle (OCP)

**What’s good**

- **New features**: Shop was added by new feature folder (`shop/`), new repo, new screens, without changing existing Class or Scoring code.
- **New repositories**: New `*_repository.dart` and `i_*_repository.dart` plus registration in `service_locator.dart`; existing code stays unchanged.
- **Screens**: New tabs/screens are added by composition (e.g. new widget in the list of tabs), not by editing existing screen internals.

**Issues**

- **Service locator usage**: Screens and dialogs call `sl<IX>()` directly. To swap implementations (e.g. mock for tests), you must replace the global registrations. Prefer injecting dependencies (e.g. repository or Cubit) into the widget so tests can pass a fake without touching `sl`.
- **Hard-coded role/class logic**: e.g. `isSuperAdmin = false` in `KhademShopScreen`; such flags could come from a single “current user context” or config so behavior can be extended without editing the screen.

**Recommendation**: Prefer constructor injection for repositories and Cubits in widgets where possible; use a single source for “current user / role / class” so new roles or flags don’t require editing multiple screens.

---

### L — Liskov Substitution Principle (LSP)

**What’s good**

- **Repository implementations**: Every `XxxRepository implements IXxxRepository` and respects the abstract contract (same method names and semantics). Any implementation of `IShopRepository` can replace `ShopRepository` without breaking callers that depend only on the interface.
- **Cubits**: Concrete Cubits are used where their base type (e.g. `Cubit<State>`) is expected; substitution is natural.

**Issues**

- **Minimal**: No clear LSP violations in the sampled code. Substitution is mostly limited by the fact that only one implementation per interface is used in production; tests could benefit from substituting mocks.

**Recommendation**: Keep repository and service APIs consistent (same return types and error handling) so any implementation remains substitutable.

---

### I — Interface Segregation Principle (ISP)

**What’s good**

- **Feature-scoped interfaces**: `IFeedRepository`, `IShopRepository`, `IClassRepository`, etc. are scoped to one feature or domain, so clients don’t depend on unrelated methods.
- **Small, focused contracts**: e.g. `IShopRepository` lists only shop-related operations; `IApiService` focuses on HTTP. No “god interface” in the sampled code.

**Issues**

- **Some large interfaces**: e.g. `IScoringRepository` has many methods (config, tiers, user score, transactions, leaderboard). A screen that only needs “my score” still depends on the full interface. Splitting into e.g. `IUserScoreRepository` and `IScoringConfigRepository` would better match actual usage.
- **IApiService**: Used everywhere; any change to the API contract affects all callers. Acceptable for a single HTTP client, but be cautious about adding optional parameters or behavior that only some features need.

**Recommendation**: If a repository interface grows beyond a single “theme” (e.g. config vs user score vs leaderboard), split it so widgets and Cubits depend only on the part they use.

---

### D — Dependency Inversion Principle (DIP)

**What’s good**

- **High-level depends on abstractions**: Screens and Cubits depend on `IShopRepository`, `IClassRepository`, `IApiService`, etc., not on `ShopRepository` or `ApiService` by name. This is correct dependency direction.
- **DI container**: GetIt registers interfaces and resolves them; production code depends on abstractions registered in one place.
- **Repositories depend on IApiService**: Data layer depends on an abstraction for HTTP, not on a concrete client.

**Issues**

- **Service locator as global**: Calling `sl<IShopRepository>()` inside a widget is still “inversion” (depend on interface), but the dependency is hidden (not in constructor). That makes testing and reuse harder; the widget is tied to the global `sl` and its registrations.
- **No constructor injection for screens**: Most screens don’t receive repository or Cubit as parameters; they pull from `sl` in `initState` or in the widget. So “what this screen needs” is not explicit and tests must override `sl`.

**Recommendation**: Prefer injecting repositories and Cubits via constructors (or BlocProvider) so that:
- Dependencies are explicit.
- Tests can pass fakes without configuring the global service locator for that widget.

---

## OOP Aspects

### Encapsulation

- **Models**: Fields and `fromJson`/`toJson`; sometimes getters (e.g. `ShopPurchaseRequestModel.isPending`). No UI or API logic inside models; good.
- **Repositories**: Internal details (Dio, endpoints, response parsing) are private; only the public interface is exposed.
- **Cubits**: State is emitted through the BLoC API; internal variables are not exposed. Good.

### Cohesion

- **High**: Repositories (one domain each), Models (one entity each), Interfaces (one contract each).
- **Variable**: Screens that both fetch data and build a large UI have lower cohesion; splitting “state/logic” (Cubit) and “UI” (Widget) would improve it.

### Coupling

- **Screens ↔ Repository**: Screens are coupled to repository *interfaces*, which is good. They are also coupled to the global `sl`, which increases coupling to the environment.
- **Screens ↔ Models**: Screens know about `ShopGiftModel`, `ClassModel`, etc.; acceptable for view layer. Avoid pushing UI-specific fields into shared models if they’re only used in one place.
- **Feature-to-feature**: Some screens depend on other features (e.g. Class, Profile) for “current class” or “current user”; this is acceptable if done via interfaces or a shared “session” abstraction.

### Abstraction

- **Interfaces**: Clear abstraction over data access and services.
- **Either (dartz)**: Good abstraction for success/failure instead of throwing or nullable returns; used consistently in repositories.
- **Cubits**: Abstraction over “state over time” for a given flow; screens depend on Cubit/Bloc, not on concrete state implementation.

---

## Summary Table (Frontend)

| Principle | Status | Notes |
|-----------|--------|--------|
| **SRP** | Partial | Repos/Cubits/Models good; some screens and dialogs do too much (data + UI + flow) |
| **OCP** | Good | New features added by extension; minor: heavy use of `sl` and hard-coded flags |
| **LSP** | OK | Implementations substitutable for interfaces |
| **ISP** | Good | Interfaces feature-scoped; some (e.g. scoring) could be split further |
| **DIP** | Good | Depend on abstractions; improve by preferring constructor injection over `sl` in widgets |

---

## Recommended Next Steps (Frontend)

1. **Extract logic from large screens**: Introduce or reuse Cubits for “shop list”, “my requests”, “class list with hasShop”, etc., so screens mainly build UI and dispatch events.
2. **Prefer constructor injection**: Where practical, pass `IShopRepository` or the relevant Cubit into the screen/dialog (e.g. `KhademShopScreen(shopRepository: sl<IShopRepository>())` or via BlocProvider) so tests don’t need to reconfigure GetIt.
3. **Split big repository interfaces**: If `IScoringRepository` (or similar) grows, split into smaller interfaces (e.g. “my score” vs “config”) so widgets only depend on what they use.
4. **Single source for “current context”**: Provide current user/role/class via a single place (e.g. profile repo or a small “session” Cubit) so screens don’t hard-code `isSuperAdmin` or duplicate “selected class” logic.
5. **Keep feature boundaries**: Continue adding new features as new folders with their own repo, models, and UI; avoid putting shop-specific logic inside class or scoring modules.
