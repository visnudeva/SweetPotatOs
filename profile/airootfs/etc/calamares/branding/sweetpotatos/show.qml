/* SweetPotatOs install slideshow */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function onActivate() {
        presentation.currentSlide = 0
    }

    function onLeave() {}

    Slide {
        Image {
            id: logo
            source: "welcome.png"
            width: Math.min(parent.width * 0.7, 480)
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#f5e6e8"
            text: "Installing SweetPotatOs…"
        }
    }
}
