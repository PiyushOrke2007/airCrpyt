# AIRCRPYT
### Secure File Sharing Over Wi-Fi — No Internet Needed

**AIRCRPYT** is a high-performance, offline peer-to-peer (P2P) file sharing application built with Flutter and Dart. It enables devices connected to the same local Wi-Fi network to discover each other and transfer files securely and directly without requiring an internet connection, cellular data, or third-party cloud servers.

---

## 🔑 Key Features & Highlights

- **100% Offline / Local P2P:** Operates entirely over local Wi-Fi subnets. Zero data leaves your local network.
- **Automatic UDP Network Discovery:** Uses UDP broadcasting (`UdpDiscoveryService`) to automatically detect nearby active AIRCRPYT peers in real-time.
- **Direct TCP Socket Streaming:** Establishes reliable point-to-point connections (`TcpServer`, `TcpClient`) with custom binary protocol framing for chunked file transmission.
- **Real-Time Transfer Speed & Dynamic ETA:** Calculates live throughput (`KB/s`, `MB/s`, `GB/s`) using exponential moving average smoothing, alongside dynamic Estimated Time Remaining (`ETA`).
- **1-Minute Transfer Rate Limiter:** Protects network bandwidth by estimating required transfer duration; if an active transfer is calculated to exceed **1 minute**, the system cancels transmission automatically with clear user notification.
- **Two-Phase Completion Verification:** Prevents false "100%" progress caused by local socket buffer fills. Progress displays `FINALIZING` (99%) until the receiving peer verifies disk writes and sends a cryptographic completion handshake (`VERIFIED / 100%`).
- **Universal File Opening with Type-Specific Filtering:** Received files vault allows opening files directly. Queries the device OS to present an app chooser displaying **only the apps on the device that feature or support that specific file type**.
- **Isolated Storage & Trash Recovery Vault:** Manages `Received`, `Sent`, `Temporary`, and `Trash` directories with full restore and permanent deletion support.
- **Persistent SQLite Audit Log:** Backed by SQLite (`DatabaseService`, `TransferRepository`, `TrashRepository`) to track full transfer history with peer details, file counts, and status filters.
- **Cyberpunk/AirCrypt UI Design System:** Custom monochrome terminal interface featuring blocky typography (`Silkscreen` font), sharp borders (`BorderRadius.zero`), tactile press-inversion feedback (`PressInvert`), and status badges (`CyberBadge`, `CyberCard`).

---

## 🛠️ How It Works (Networking Architecture)

```text
  [ Device A (Sender) ] ──( UDP Broadcast: 255.255.255.255:5001 )──> [ Local Wi-Fi Subnet ] <──( UDP Listen )── [ Device B (Receiver) ]
            │                                                                                                             │
            └─────────────────────────────( Direct TCP P2P Socket Stream )────────────────────────────────────────────────┘
                                                  │
                                                  ├─ Handshake: HELLO / HELLO_ACK
                                                  ├─ Transfer Request & Acceptance
                                                  ├─ Metadata & Chunked Payload Stream (32 KB chunks)
                                                  └─ Disk Finalization & Completion Acknowledgment
```

### Protocol & Transfer Pipeline Steps
1. **Discovery (UDP):** When searching for devices, AIRCRPYT binds to UDP port `5001` and broadcasts presence packets containing the device ID, name, and IP address.
2. **Handshake & Session Setup (TCP):** Connecting to a peer opens a TCP socket. A binary protocol message header validates magic bytes (`AIRCRYPT`) and exchanges protocol metadata (`helloResponse`, `transferRequest`).
3. **Chunked File Streaming:** Files are broken into 32 KB chunks (`ChunkReader`). Chunks are framed (`ChunkMetadata`), encoded into binary payloads (`ChunkPayload`), and streamed over TCP.
4. **Rate Limit & Speed Monitoring:** Real-time speed and remaining bytes are monitored continuously. If `estimatedSecondsRemaining > 60` (1 minute limit), a `transferCancel` frame is issued and the transfer terminates safely.
5. **Disk Assembly & Verification:** The receiver writes chunks to `Temporary/` using `ChunkWriter`. When all chunks arrive, the file is finalized, moved to `Received/`, recorded in SQLite, and an acknowledgement (`transferComplete`) is returned to the sender.

---

## 📁 Project Structure

```text
lib/
├── main.dart                          # App entry point, home screen, & navigation
├── core/
│   ├── database/                      # SQLite service, transfer & trash repositories
│   ├── models/                        # Data models (Transfer, File, DeviceInfo, TrashItem)
│   ├── services/                      # Business logic (FileStorage, DeviceIdentity, Settings, Trash)
│   ├── theme/                         # AirCrypt dark/light theme, colors, typography
│   └── widgets/                       # Cyber UI components (CyberCard, CyberBadge, CyberButton, PressInvert)
└── features/
    ├── files/                         # Received files screen with open-with-app integration
    ├── history/                       # SQLite-backed transfer history & filter screen
    ├── settings/                      # Device identity broadcast configuration & debug tools
    ├── transfer/                      # Core networking engine:
    │   ├── connection/                # Connection manager & state lifecycle
    │   ├── finder/                    # UDP discovery service & device radar scan UI
    │   ├── io/                        # ChunkReader & ChunkWriter file streaming
    │   ├── manager/                   # TransferSession, TransferManager, Sender & Receiver
    │   ├── progress/                  # Real-time circular progress, speed, ETA, & pipeline status
    │   └── protocol/                  # Binary protocol encoder, decoder, & message models
    └── trash/                         # Isolated trash vault & item recovery screen
```

---

## 🧪 Testing & Quality Assurance

AIRCRPYT includes a comprehensive test suite of **34+ unit and integration tests**:

- **Protocol & Framing Tests:** Binary message encoding/decoding and stream buffer parser tests.
- **IO & Chunk Streaming Tests:** Verification of file chunking and atomic re-assembly.
- **SQLite Database Tests:** Verification of transfer history logging, file tracking, and trash persistence.
- **Rate Limiter Tests:** Unit tests verifying 1-minute rate limiter triggers and ETA calculations.
- **End-to-End P2P Transfer Tests:** Complete simulated peer transfer and rejection workflows.
- **Widget UI Tests:** Sanity testing for home screens and visual components.

To run all unit tests:
```bash
flutter test
```

To run static analysis:
```bash
flutter analyze
```

---

## 🚀 Getting Started & How to Run

### Prerequisites
1. **Flutter SDK**: `^3.13.1` or higher ([Install Flutter](https://docs.flutter.dev/get-started/install)).
2. **Android SDK** / Android Studio with Android 8.0+ (API 26+) physical device or emulator.
3. Both test devices must be connected to the **same local Wi-Fi network**.

---

### Installation & Build Commands

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/aircrypt.git
   cd airCrypt
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on a connected device / emulator:**
   ```bash
   flutter run
   ```

4. **Build a Debug APK:**
   ```bash
   flutter build apk --debug
   ```

---

### 📱 Xiaomi / MIUI / HyperOS Device Setup Troubleshooting
If you encounter `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` when installing via ADB on Xiaomi/Redmi/POCO or Samsung devices:

1. Open **Settings** on your phone.
2. Go to **Additional Settings** $\rightarrow$ **Developer options**.
3. Enable **Install via USB** and **USB debugging (Security settings)**.
4. Keep your phone screen lit during `flutter run` and tap **Install / Allow** on the on-screen confirmation popup.
