# TaskFlow - System Requirement Specification (MVP)

## Project Overview
TaskFlow is an offline Android automation utility app that allows users to create macros (If This Then That) to control their device state and trigger specific actions based on system events.

## MVP Scope (Minimum Viable Product)
For the initial release, the application will solely focus on solving the "Battery Overcharge" problem.

### 1. Core Features
- **Create Macro:** Users can create a rule to monitor battery level.
- **Toggle Macro:** Users can enable/disable the monitoring rule.
- **Foreground Persistence:** The app MUST run a continuous Foreground Service in Android to monitor the battery without being killed by the OS.

### 2. Supported Triggers (Conditions)
- `BatteryTrigger`: Triggers when the device is plugged in AND reaches a specific user-defined percentage (e.g., 90%).

### 3. Supported Actions (Executions)
- `SoundAction`: Plays a custom MP3 ringtone on a continuous loop at a specific volume level until the user unplugs the charger.

### 4. Data Persistence
- User macros must be saved locally using the Hive NoSQL database.

### 5. Native Integration Contract (MethodChannel)
- The Flutter UI will send the active `BatteryTrigger` rules via a MethodChannel named `com.solehin.taskflow/automation`.
- Native Kotlin code will receive this JSON, start a `ForegroundService`, register a `BroadcastReceiver` for `ACTION_BATTERY_CHANGED`, and trigger the MediaPlayer when conditions are met.