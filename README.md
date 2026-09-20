# AirCrypt
### Secure File Sharing Over Wi-Fi — No Internet Needed

AirCrypt is a high-performance, offline peer-to-peer (P2P) file sharing application built with Flutter. It enables devices connected to the same local Wi-Fi network to discover each other and transfer files securely and directly without requiring an internet connection, cellular data, routers with internet access, or third-party cloud servers.

---

## 🔑 Key Highlights

- **100% Offline / Local:** Operates entirely over local Wi-Fi networks. No internet connection or external servers required.
- **UDP Discovery:** Uses UDP broadcasting (`UdpDiscoveryService`) for instant, automatic discovery of nearby online devices.
- **TCP Direct Transfer:** Establishes reliable point-to-point connections (`TcpServer`, `TcpClient`) with custom protocol framing for data transfer.
- **Local Storage & Persistence:** Manages received, sent, temporary, and trash files (`FileStorageService`), backed by a local SQLite database (`DatabaseService`, `TransferRepository`, `TrashRepository`).
- **Complete Test Coverage:** Fully tested suite of unit and widget tests covering networking protocol parsers, storage, and repositories.

---

## 🛠️ How It Works (Networking Architecture)

```text
  [ Device A ] ──( UDP Broadcast )──> [ Local Network (255.255.255.255) ] <──( UDP Broadcast )── [ Device B ]
       │                                                                                             │
       └─────────────────────────( Direct TCP P2P Connection )───────────────────────────────────────┘
```

1. **Discovery (UDP):** When you open the Send/Receive discovery screen, AirCrypt binds to a UDP port and broadcasts presence packets across the local subnet. It listens for other active AirCrypt devices and populates the device list in real-time.
2. **Connection & Handshake (TCP):** Tapping a discovered device initiates a direct TCP connection. A custom binary protocol performs handshake messages (`HELLO` / `HELLO_ACK`) to establish a trusted peer session.
3. **Data Management:** Transferred files, history, and system logs are stored locally with support for deletion, trash recovery, and cleanup.

---

## 📁 Project Structure

```text
lib/
├── main.dart                          # App entry point & Home navigation
├── core/
│   ├── database/                      # SQLite database service, transfer & trash repositories
│   ├── models/                        # Data models (Transfer, File, Device, Trash)
│   └── services/                      # Business logic (File storage, identity, settings, trash)
└── features/
    ├── files/                         # Received files viewer
    ├── history/                       # Transfer history screen
    ├── settings/                      # Device naming & settings
    ├── transfer/                      # UDP discovery, TCP server/client, & binary protocol parser
    └── trash/                         # Trash bin & recovery screen
```

---

## 🧪 Testing & Quality Assurance

AirCrypt includes a robust unit and widget test suite (`28+ tests`).

To run tests:
```bash
flutter test
```

To run static analysis:
```bash
flutter analyze
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.1` or higher)
- Android SDK / emulator or physical Android device

### Setup & Run
1. Clone the repository and navigate to the project root.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```
