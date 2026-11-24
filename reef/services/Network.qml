pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Connection state for the Status cay (Quickshell.Networking, NetworkManager backend).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // 0..1 (Quickshell may report 0..100 on some versions)
    readonly property real signal: {
        const s = wifiNetwork?.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }
    readonly property bool connected: !!wired || !!wifiNetwork

    readonly property string icon: wired ? "lan"
        : wifiNetwork ? (signal > 0.66 ? "wifi" : signal > 0.33 ? "wifi_2_bar" : "wifi_1_bar")
        : wifi && wifiEnabled ? "signal_wifi_statusbar_not_connected"
        : "wifi_off"

    // Wi-Fi networks for the menu: connected first, then known, then by signal.
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    function signalIcon(n) {
        const s = n.signalStrength > 1 ? n.signalStrength / 100 : n.signalStrength;
        return s > 0.66 ? "wifi" : s > 0.33 ? "wifi_2_bar" : "wifi_1_bar";
    }

    function secured(n) {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Unknown;
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    // Scan while the Wi-Fi menu is open.
    function scan(on) {
        if (wifi)
            wifi.scannerEnabled = on;
    }

    // Known or open networks connect directly; others need the password.
    function connect(n, password) {
        if (n.connected)
            n.disconnect();
        else if (password)
            n.connectWithPsk(password);
        else
            n.connect();
    }

    readonly property string shortLabel: wired ? "Wired" : wifiNetwork ? wifiNetwork.name : wifiEnabled ? "Not connected" : "Off"

    readonly property string label: wired ? "Wired network connected"
        : wifiNetwork ? `Wi-Fi ${wifiNetwork.name}`
        : wifi && wifiEnabled ? "Wi-Fi not connected" : "Wi-Fi off"
}
