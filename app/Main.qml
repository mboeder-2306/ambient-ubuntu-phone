import QtQuick 2.4
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.0
import QtMultimedia 5.6
import Ubuntu.Components.Popups 1.3


import "resources.js" as RES

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "ambient.sil"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true


    width: units.gu(40)
    height: units.gu(70)

    ListModel {
        id: lm
        Component.onCompleted: {
            RES.RES.forEach(function(o) {
                lm.append(o);
            });
        }
    }

    Component {
        id: infoComponent
        Popover {
            id: infoPopover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                    leftMargin: units.gu(1)
                    rightMargin: units.gu(1)
                }
                ListItem {
                    Label {
                        text: "<b>Sound:</b> " + player.sound_credit_name
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: Qt.openUrlExternally(player.sound_credit_url)
                }
                ListItem {
                    Label {
                        text: "<b>Art:</b> " + player.image_credit_name
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: Qt.openUrlExternally(player.image_credit_url)
                }
            }
        }
    }

    Page {
        id: front
        title: player.title == "" ? i18n.tr("Ambient") : player.title

        header: PageHeader {
            id: header
            title: player.title == "" ? i18n.tr("Ambient") : player.title
            exposed: true
            StyleHints {
                foregroundColor: UbuntuColors.warmGrey
                backgroundColor: "#292929"
            }
            leadingActionBar.actions: [
                Action {
                    iconName: "back"
                    text: "Back"
                    visible: moveout.x == 0
                    onTriggered: {
                        moveout.x = player.width
                        if (aud.playbackState != Audio.PlayingState) {
                            header.title = i18n.tr("Ambient")
                        }
                    }
                }
            ]
            trailingActionBar.actions: [
                Action {
                    iconName: "settings"
                    text: "Settings"
                    visible: false
                },
                Action {
                    id: info
                    iconName: "info"
                    text: "Sound info"
                    visible: moveout.x == 0
                    onTriggered: PopupUtils.open(infoComponent, header);
                }
            ]
        }

        ListView {
            id: lv
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            model: lm
            delegate: ListItem {

                height: units.gu(20)

                Image {
                    source: "resources/" + model.image_letterbox_filename
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                }

                Text {
                    id: lbl
                    text: model.title
                    font.pixelSize: units.gu(5)
                    color: "white"
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                }

                DropShadow {
                    anchors.fill: lbl
                    horizontalOffset: units.dp(2)
                    verticalOffset: units.dp(2)
                    radius: units.dp(2)
                    samples: 16
                    color: "#cc000000"
                    source: lbl
                }
                onClicked: player.showItem(model.index)
            }
        }


        Item {
            function showItem(idx) {
                var iidx = idx % lm.count
                if (iidx < 0) iidx = lm.count + iidx; // + because iidx is -1
                var model = lm.get(iidx);
                player.itemIndex = iidx;
                player.title = model.title;
                header.title = model.title;
                player.image_letterbox_filename = model.image_letterbox_filename;
                player.image_credit_name = model.image_credit_name;
                player.image_credit_url = model.image_credit_url;
                player.sound_filename = model.sound_filename;
                player.sound_credit_name = model.sound_credit_name;
                player.sound_credit_url = model.sound_credit_url;
                moveout.x = 0;

                if (aud.playbackState == Audio.PlayingState) {
                    // trigger this in a Timer to get it off the main thread
                    stopStartSound.start();
                }
            }

            Timer {
                id: stopStartSound
                interval: 1
                running: false
                onTriggered: {
                    aud.pause();
                    playlist.clear();
                    for (var i=0; i<5; i++) {
                        playlist.addItem(Qt.resolvedUrl("resources/" + player.sound_filename));
                    }
                    aud.play();
                }
            }

            id: player
            property int itemIndex: 0
            property string title: ""
            property string image_letterbox_filename: "river.jpg"
            property string image_credit_name
            property string image_credit_url
            property string sound_filename
            property string sound_credit_name
            property string sound_credit_url
            property string currentlyPlaying: "none"

            anchors.fill: parent
            transform: Translate {
                 id: moveout
                 x: parent.width
                 Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }

            Image {
                id: bgimg
                source: "resources/" + player.image_letterbox_filename
                fillMode: Image.PreserveAspectCrop
                anchors.fill: parent
            }

            Audio {
                id: aud
                playlist: Playlist {
                    id: playlist
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: console.log("Swallowing clicks so they don't hit the ListView")
            }

            Rectangle {
                anchors.top: buttons.top
                anchors.bottom: buttons.bottom
                anchors.left: buttons.left
                anchors.right: buttons.right
                anchors.bottomMargin: -units.gu(1)
                anchors.topMargin: -units.gu(1)
                anchors.leftMargin: -units.gu(1)
                anchors.rightMargin: -units.gu(1)
                width: buttons.width + units.gu(2)
                height: buttons.height + units.gu(2)
                color: Qt.rgba(0,0,0,0.2)
            }

            Row {
                id: buttons
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height / 10
                anchors.left: parent.left
                anchors.leftMargin: units.gu(1)
                width: parent.width - units.gu(2)
                spacing: units.gu(1)

                Button {
                    Icon {
                        name: "media-skip-backward"
                        width: parent.width * 0.9
                        height: parent.width * 0.9
                        anchors.centerIn: parent
                        color: "white"
                    }

                    color: Qt.rgba(255,255,255,0.2)
                    onClicked: player.showItem(player.itemIndex - 1)
                    width: (parent.width - units.gu(2)) / 3
                    height: width
                }
                Button {
                    Icon {
                        name: aud.playbackState == Audio.PlayingState ? "media-playback-stop" : "media-playback-start"
                        width: parent.width * 0.9
                        height: parent.width * 0.9
                        anchors.centerIn: parent
                        color: "white"
                    }

                    color: Qt.rgba(255,255,255,0.2)
                    onClicked: {
                        if (aud.playbackState == Audio.PlayingState) {
                            aud.pause();
                        } else {
                            playlist.clear();
                            for (var i=0; i<5; i++) {
                                playlist.addItem(Qt.resolvedUrl("resources/" + player.sound_filename));
                            }
                            aud.play();
                        }
                    }

                    width: (parent.width - units.gu(2)) / 3
                    height: width
                }
                Button {
                    Icon {
                        name: "media-skip-forward"
                        width: parent.width * 0.9
                        height: parent.width * 0.9
                        anchors.centerIn: parent
                        color: "white"
                    }

                    color: Qt.rgba(255,255,255,0.2)
                    onClicked: player.showItem(player.itemIndex + 1)
                    width: (parent.width - units.gu(2)) / 3
                    height: width
                }
            }
        }



    }

}

