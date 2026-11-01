# AIRCRPYT — Codebase Architecture & Implementation Guide

This guide provides a detailed explanation of every folder, file, and key code component in the **AIRCRPYT** repository.

---

## 📁 `lib/` — Root Application Code

### [`lib/main.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/main.dart)
- **Purpose**: Main entry point of the Flutter application.
- **Key Code & Classes**:
  - `void main()`: Launches `AircryptApp`.
  - `AircryptApp`: Sets up `MaterialApp` with the dark `AirCryptTheme.darkTheme('Amatic')` theme and `HomeScreen` as `home`.
  - `HomeScreen`: Dashboard featuring:
    - **`SEND FILES`**: Navigates to `FileSelectionScreen`.
    - **`RECEIVE FILES`**: Navigates to `DeviceScreen` (Radar discovery scan).
    - **Shortcuts**: Links to `ReceivedFilesScreen`, `TransferHistoryScreen`, and `TrashScreen`.

---

## 📁 `lib/core/` — Foundation, Services, Models, & Theme

### 📂 `lib/core/database/` — SQLite Persistence Layer

1. [`database_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/database/database_service.dart)
   - **Purpose**: Initializes SQLite database (`aircrypt.db`).
   - **Key Code**: Creates tables `transfers`, `transfer_files`, and `trash`. Configures WAL journal mode for fast concurrent writes.

2. [`transfer_repository.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/database/transfer_repository.dart)
   - **Purpose**: Performs CRUD operations for file transfer history and individual file records.
   - **Key Code**:
     - `insertTransfer()` & `insertTransferFile()`: Records transfer metadata in SQLite.
     - `updateTransferStatus()` & `updateTransferFileStatus()`: Atomically updates transaction state (`transferring`, `completed`, `failed`, `cancelled`).
     - `getAllTransfers()` & `getTransferFiles()`: Queries history for the UI.

3. [`trash_repository_interface.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/database/trash_repository_interface.dart)
   - **Purpose**: Defines abstract contract for trash persistence.

4. [`trash_repository.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/database/trash_repository.dart)
   - **Purpose**: SQLite implementation for trash tracking.
   - **Key Code**:
     - `insertTrashItem()`: Stores deleted file record with `deleted_at` and `permanent_delete_at`.
     - `getExpiredItems(now)`: Queries items where `permanent_delete_at <= now` (older than 20 days).

---

### 📂 `lib/core/models/` — Data Structures

1. [`device_info.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/models/device_info.dart)
   - Model representing local/remote device details (`deviceId`, `deviceName`, `platform`).

2. [`transfer.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/models/transfer.dart)
   - Model representing a transfer session record in SQLite (`id`, `type`, `status`, `peerDeviceId`, `peerDeviceName`, `totalSize`, `createdAt`).

3. [`transfer_file.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/models/transfer_file.dart)
   - Model for individual file entries inside a transfer session (`id`, `transferId`, `fileName`, `fileSize`, `status`, `savedPath`, `sourcePath`).

4. [`trash_item.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/models/trash_item.dart)
   - Model for files stored in the trash vault (`id`, `fileId`, `originalPath`, `trashPath`, `deletedAt`, `permanentDeleteAt`).

---

### 📂 `lib/core/services/` — Core Business Logic

1. [`device_identity_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/device_identity_service.dart)
   - Generates and persists a unique UUID (`deviceId`) in `SharedPreferences`.

2. [`file_storage.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/file_storage.dart)
   - Abstract contract defining directory structure access.

3. [`file_storage_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/file_storage_service.dart)
   - Resolves directories: `Received` (`Download/airCrypt/Received`), `Sent`, `Temporary`, and `Trash`.
   - **Key Code**:
     - `_safeMoveFile()`: Handles moving files across different filesystem volumes (e.g. public `Download/` to internal app data) by attempting `file.rename()` first and falling back to `file.copy()` + `file.delete()` if cross-device link errors occur.

4. [`local_device_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/local_device_service.dart)
   - Constructs local device details (`DeviceInfo`) using broadcast settings and platform OS.

5. [`settings_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/settings_service.dart)
   - Saves and reads user-defined custom device broadcast name.

6. [`trash_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/services/trash_service.dart)
   - Manages file isolation, recovery, and auto-deletion.
   - **Key Code**:
     - `moveToTrash()`: Moves file into `Trash/` directory, setting `permanentDeleteAt = deletedAt + 20 days`.
     - `restore()`: Restores file back to `originalPath`.
     - `cleanupExpiredItems()`: Permanently deletes all items where `permanentDeleteAt <= now`.

---

### 📂 `lib/core/theme/` — Design System

1. [`aircrypt_theme.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/theme/aircrypt_theme.dart)
   - **`AirCryptColors`**: Color constants (`bgDark`, `cardBg`, `accentCyan`, `accentRed`, `textPrimary`, `textSecondary`).
   - **`AirCryptTheme`**: Dark theme setup with custom AppBar, Buttons, ListTiles, and InputDecorations.

---

### 📂 `lib/core/widgets/` — UI Component Library

1. [`cyber_widgets.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/widgets/cyber_widgets.dart)
   - Monospaced terminal/cyberpunk UI widgets:
     - `CyberCard`: Bordered panel with hover/touch feedback.
     - `CyberBadge`: Rectangular status badge tag.
     - `CyberButton`: Primary and secondary action buttons.
     - `PressInvert`: Tactile color-inversion matrix effect on press.
     - `AirCryptHeader`: Central visual identity banner.
     - `SecurityPipelineWidget`: Cryptographic progress step checklist.

2. [`radar_scan_widget.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/core/widgets/radar_scan_widget.dart)
   - Animated P2P network radar scan component displaying expanding cyan pulse rings for the device discovery screen.

---

## 📁 `lib/features/` — Application Modules & Workflows

### 📂 `lib/features/files/` — Received Files Vault

1. [`received_files_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/files/received_files_screen.dart)
   - **Purpose**: Displays received files stored in `Download/airCrypt/Received`.
   - **Key Code**:
     - `_openFile()`: Invokes `OpenFilex.open(file.path)` to trigger system intent (`ACTION_VIEW`), displaying only apps that feature/support that specific file type.
     - `_moveToTrash()`: Calls `TrashService.moveToTrash()` to safely isolate deleted files.

---

### 📂 `lib/features/history/` — Audit Log

1. [`transfer_history_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/history/transfer_history_screen.dart)
   - **Purpose**: Historical log of all past transactions.
   - **Key Code**: Queries SQLite transfers and transfer files; offers filtering by `ALL`, `SENT`, and `RECEIVED`.

---

### 📂 `lib/features/settings/` — Preferences & Diagnostics

1. [`settings_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/settings/settings_screen.dart)
   - Allows users to change broadcast device name, access trash, and open network protocol diagnostic tools (`DeviceIdDebugScreen`, `TcpReceiverScreen`, `TcpSenderScreen`).

---

### 📂 `lib/features/transfer/` — Core Networking Engine

#### 📁 `connection/`
- [`connection_state.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/connection/connection_state.dart): State enum (`disconnected`, `connecting`, `connected`, `closing`, `failed`).
- [`connection_manager.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/connection/connection_manager.dart): Wraps `TcpClient` and handles initial `hello` handshake.

#### 📁 `finder/` (UDP Discovery)
- [`models/discovered_device.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/finder/models/discovered_device.dart): Model for discovered network nodes (`id`, `name`, `address`, `port`, `lastSeen`, `status`).
- [`udp_discovery_service.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/finder/udp_discovery_service.dart): Binds to UDP port `5001`, broadcasts presence packets (`AIRCRYPT_DISCOVERY`), and listens for peers.
- [`services/connection_handler.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/finder/services/connection_handler.dart): Controller coordinating UDP discovery, TCP listener server, and active transfers.
- [`device_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/finder/device_screen.dart): Interactive radar scan UI for selecting recipients and starting transfer sessions.

#### 📁 `io/` (Chunk File Streaming)
- [`chunk_reader.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/io/chunk_reader.dart): Reads local files in 32 KB chunk streams (`Stream<List<int>>`).
- [`chunk_writer.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/io/chunk_writer.dart): Writes incoming byte chunks to `Temporary/` and finalizes complete files into `Received/`.

#### 📁 `manager/` (Session & Transfer Execution)
- [`transfer_session.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/manager/transfer_session.dart):
  - Tracks progress (`0.0` to `1.0`), bytes transferred, and status (`sending`, `finalizing`, `completed`).
  - **Speed Calculation**: Exponential moving average throughput (`speedText`).
  - **ETA Calculation**: Computes remaining time (`etaText`).
  - **Rate Limiter**: `maxAllowedTransferSeconds = 60`. If `estimatedSecondsRemaining > 60`, `isExceedingTimeLimit` evaluates to `true`.
- [`transfer_manager.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/manager/transfer_manager.dart): Reactive manager broadcasting active session list updates via Stream.
- [`transfer_sender.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/manager/transfer_sender.dart):
  - Sends request $\rightarrow$ metadata $\rightarrow$ chunk stream $\rightarrow$ rate limiter check $\rightarrow$ sets `finalizing` status (99%) $\rightarrow$ waits for dynamic completion confirmation timeout $\rightarrow$ sets `completed` (100%).
- [`transfer_receiver.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/manager/transfer_receiver.dart):
  - Receives metadata $\rightarrow$ writes chunks $\rightarrow$ rate limiter check $\rightarrow$ finalizes file $\rightarrow$ logs SQLite $\rightarrow$ sends `transferComplete` acknowledgement.

#### 📁 `progress/`
- [`transfer_progress_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/progress/transfer_progress_screen.dart):
  - Live progress screen featuring circular percentage, total speed (`MB/s`), total ETA, security pipeline checklist, and per-device live progress cards.

#### 📁 `protocol/` (Binary Message Framing)
- Models for protocol serialization: `MessageType`, `ProtocolMessage`, `ProtocolEncoder`, `ProtocolDecoder`, `ProtocolStreamParser`, `ChunkMetadata`, `ChunkPayload`, `FileMetadata`, `TransferMetadata`, `TransferRequest`, `JsonPayload`.

#### Core TCP Socket Classes
- [`tcp_server.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/tcp_server.dart): Dart `ServerSocket` wrapper listening for incoming P2P connections.
- [`tcp_client.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/transfer/tcp_client.dart): Dart `Socket` wrapper connecting to remote peer IPs.

---

### 📂 `lib/features/trash/` — Isolated Trash Vault

1. [`trash_screen.dart`](file:///D:/Third%20Year%20Engineering/Mini%20Project/Code/airCrpyt/lib/features/trash/trash_screen.dart)
   - Displays deleted files with days remaining badge.
   - **Key Code**:
     - `_loadTrash()`: Invokes `_trashService.cleanupExpiredItems()` to automatically erase items older than 20 days upon loading.
     - **`RECOVER`** button: Restores file to Received directory.
     - **`DELETE`** button: Prompts confirmation and permanently deletes file.
