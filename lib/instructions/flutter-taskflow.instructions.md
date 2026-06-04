---
description: "Strict coding standards and implementation guidelines for the TaskFlow Flutter application. To be used in conjunction with the flutter-taskflow-dev.agent.md."
applyTo: "**/*.dart, **/*.kt, **/*.xml, pubspec.yaml"
---

# TaskFlow Flutter & Native Code Generation Standards

## Purpose
Generate and modify production-grade mobile application code that is:
- aligned with Clean Architecture principles (conceptually similar to layered backend architecture).
- performant and strictly adheres to Flutter UI declarative patterns.
- capable of seamless native Android execution via Kotlin for background tasks.
- testable, observable, and maintainable.

## Source of Truth
When generating code, prioritize:
1. `flutter-taskflow-dev.agent.md` for overall architecture and execution rules.
2. The Clean Architecture folder structure (`core`, `domain`, `data`, `presentation`).
3. These instructions for specific coding styles, DI patterns, and error handling.

## Technology Standards
- **UI Framework:** Flutter (Dart)
- **Native OS:** Android (Kotlin)
- **State Management & DI:** Riverpod (`flutter_riverpod`)
- **Local Persistence:** Hive
- **Native Bridge:** `MethodChannel`

## Architecture Rules (Clean Architecture)
Follow a strict 4-layer separation. Do not mix UI code with business logic.

### 1. Domain Layer (`lib/domain/`)
- **The Core Business Logic:** Pure Dart only. No Flutter framework dependencies (`import 'package:flutter/...'` is strictly forbidden).
- **Entities:** Must be immutable. Use `copyWith` methods for state changes.
- **Interfaces (I-Repositories):** Define abstract Repository classes (e.g., `IMacroRepository`) to dictate data contracts.
- **UseCases:** Single-responsibility classes that execute specific business rules and orchestrate data flow.

### 2. Data Layer (`lib/data/`)
- **Implementations:** Contains the concrete implementations of the Domain repository interfaces.
- **Models (DTOs):** Contains Hive Models with `TypeAdapter` annotations. These act as Data Transfer Objects for local persistence.
- **Mapping:** Data Models must be mapped to Domain Entities before returning to the Domain layer to avoid leaking Hive dependencies upward.

### 3. Presentation Layer (`lib/presentation/`)
- **UI & State:** Contains all Flutter UI code (Pages, Widgets).
- **Providers:** Uses Riverpod to inject dependencies (UseCases, Repositories) into the UI.
- UI components must remain thin and only interact with UseCases or Repositories via Riverpod state objects.

### 4. Core Layer (`lib/core/`)
- **Shared Infrastructure:** Contains App Themes, Constants, Extensions, and global Error/Exception handling classes.
- **Platform Channels:** Contains `MethodChannel` definitions and bridging logic for calling Kotlin code.

## Native Android Standards (Kotlin)
- **Background Tasks:** Dart isolates are not reliable when the application is killed or in deep sleep. You must use Android `ForegroundService` for continuous monitoring (e.g., Battery level).
- **Event Listeners:** Use `BroadcastReceiver` to listen to OS-level events.
- **Bridge Configuration:** Implement `MethodChannel.MethodCallHandler` in `MainActivity.kt` or a dedicated bridge service to receive JSON configurations from Flutter and start the respective Kotlin services.

## State Management & Dependency Injection (Riverpod)
- Treat Riverpod as the Dependency Injection (DI) container. Use it to register Repositories and UseCases globally.
- Use `NotifierProvider` or `AsyncNotifierProvider` for managing complex state and asynchronous operations (e.g., fetching macros from Hive).
- **No `setState` for Business Logic:** Do not use `StatefulWidget`'s `setState` for managing data or business logic. It is only permitted for temporary, local UI animations (e.g., toggling a visual expansion panel).

## Error Handling
- Validate early and throw domain-appropriate custom Exceptions defined in the Core layer.
- Do not swallow exceptions silently in `catch` blocks.
- Map persistence errors (e.g., Hive write failures) into application-friendly error states to display in the UI.

## Code Style Standards
- **Immutability:** Use `const` constructors everywhere possible in Flutter widgets to optimize the rendering tree and prevent unnecessary rebuilds.
- Use `final` for all variables and fields unless they explicitly require mutation.
- **Naming Conventions:** Follow standard Dart conventions (PascalCase for classes, camelCase for variables/methods). Use descriptive names over abbreviations (e.g., `BatteryTriggerEntity` instead of `BatTrigEnt`).
- **Composition:** Keep widgets small and modular. Extract complex widget trees into separate stateless widgets to maintain readability.
