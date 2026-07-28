/// The two MVP-scope Pet Interaction gesture classifications (GDD
/// `pet-interaction.md` "InteractionType Enum"; ADR-0004 Key Interfaces —
/// `petInteracted→InteractionType` payload contract). This is the payload
/// type for [GameEventType.petInteracted] (`core/game_event_bus.dart`) —
/// declared in its own file to match this codebase's one-payload-type-
/// per-file convention (see `pet_mood.dart`'s `MoodState`,
/// `triggered_state.dart`'s `TriggeredState`).
enum InteractionType { tap, swipe }
