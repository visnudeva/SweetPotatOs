/* SweetPotatOs installer notes */
import io.calamares.ui 1.0

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Item {
    width: 740
    height: 420

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 8
        contentHeight: intro.implicitHeight + 24
        clip: true

        ScrollBar.vertical: ScrollBar {
            id: fscrollbar
            width: 10
            policy: ScrollBar.AsNeeded
        }

        TextArea {
            id: intro
            width: parent.width - fscrollbar.width
            readOnly: true
            font.pointSize: 12
            textFormat: Text.RichText
            antialiasing: true
            activeFocusOnPress: false
            wrapMode: Text.WordWrap
            background: Item {}

            text: "<h3>" + Branding.string(Branding.VersionedName) + "</h3>"
                  + "<p>This installer copies a complete SweetPotatOs system onto your disk. "
                  + "Intel and AMD graphics use the open Mesa drivers already on the image.</p>"
                  + "<h3>NVIDIA</h3>"
                  + "<p>If you have an <b>NVIDIA GPU (Turing or newer)</b> and want the "
                  + "<b>nvidia-open</b> drivers installed automatically, stay connected to the "
                  + "<b>internet</b> during installation. The installer downloads about 325&nbsp;MiB "
                  + "from Arch mirrors when a suitable GPU is detected.</p>"
                  + "<p>Without a network connection, installation continues with the open "
                  + "Mesa/nouveau stack. You can install <code>nvidia-open</code> later with pacman "
                  + "or yay after you are online.</p>"
        }
    }
}
