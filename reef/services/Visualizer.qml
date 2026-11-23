pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Audio levels from cava (raw ASCII output), for the Island's mini waveform and
// later the Pearl. Runs only while something asks for it (`users` > 0), while media
// plays, and while Settings → Power & performance → Audio visualizer is on.
//
//   Component.onCompleted: Visualizer.users++ ; Component.onDestruction: Visualizer.users--
Singleton {
    id: root

    property int users: 0
    property int bars: 5
    readonly property bool enabled: Config.options.performance.visualizer
    readonly property bool running: enabled && users > 0 && Media.playing
    // bars values, 0..1
    property var levels: new Array(bars).fill(0)

    readonly property string configPath: Config.cacheDir + "/cava.conf"
    readonly property string configText: `[general]
bars = ${bars}
framerate = ${Config.options.performance.visualizerFps}
autosens = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
channels = mono
`

    onRunningChanged: {
        if (running) {
            conf.setText(configText);
            cava.running = true;
        } else {
            cava.running = false;
            levels = new Array(bars).fill(0);
        }
    }

    FileView {
        id: conf
        path: root.configPath
        printErrors: false
    }

    Process {
        id: cava
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(n => Number(n) / 100);
                if (v.length >= root.bars)
                    root.levels = v.slice(0, root.bars);
            }
        }
    }
}
