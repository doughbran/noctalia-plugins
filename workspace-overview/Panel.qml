import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: root

    // --- Mandatory Panel Properties (Injected by Noctalia) ---
    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    
    // Recommended dimensions adapted to the interface scale
    property real contentPreferredWidth: 840 * Style.uiScaleRatio
    property real contentPreferredHeight: Math.max(320 * Style.uiScaleRatio, (workspaceGrid.computedRows * workspaceGrid.cellHeight) + 100 * Style.uiScaleRatio)

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                NText {
                    text: "Workspace Overview"
                    pointSize: Style.fontSizeXL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }
                NIconButton {
                    icon: "x"
                    onClicked: {
                        if (pluginApi) {
                            pluginApi.closePanel(pluginApi.panelOpenScreen)
                        }
                    }
                }
            }

            // --- Workspaces Area (Grid) ---
            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true // Enable clipping to hide the overflow

                NGridView {
                    id: workspaceGrid
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    // Widen the grid and push its internal scrollbar beyond the clipped parent edge
                    width: parent.width + (40 * Style.uiScaleRatio)
                    
                    anchors.topMargin: Style.marginM
                    anchors.bottomMargin: Style.marginM
                    
                    // Use parent.width (the visible area) for cells, not its own widened width
                    cellWidth: parent.width / columns
                    cellHeight: (194.002 + 13.284) * Style.uiScaleRatio
                    
                    // The distribution is now handled by the dynamic cellWidth relative to the visible panel
                    property int columns: Math.max(1, Math.min(count, 3))
                    property int computedRows: Math.max(1, Math.ceil(count / columns))
                    
                    leftMargin: 0
                    topMargin: Math.max(0, (height - (computedRows * cellHeight)) / 2)
                    
                    clip: true
                    
                    // Using the real Hyprland model provided by Quickshell
                    model: Hyprland.workspaces

                    // --- Workspace Component ---
                    delegate: DropArea {
                        id: workspaceDelegate
                        width: workspaceGrid.cellWidth
                        height: workspaceGrid.cellHeight

                        // The "required property" tells QML: "I expect the model to send me a modelData"
                        required property var modelData 
                        
                        // Now you use it directly, without fear of being undefined
                        property int targetWorkspaceId: modelData.id
                        property bool isEditingName: false

                        // Action when dropping the window in this workspace
                        onDropped: (drop) => {
                            if (drop.hasText && drop.text !== "") {
                                let windowData = JSON.parse(drop.text);
                                Logger.i("Workspace Overview", "Move window " + windowData.winId + " to workspace " + targetWorkspaceId);
                                
                                // Hyprland command via Quickshell
                                Hyprland.dispatch("movetoworkspacesilent " + targetWorkspaceId + ",address:" + windowData.winId);
                            }
                        }

                        NBox {
                            id: workspaceBg
                            width: 228.646 * Style.uiScaleRatio // Keep fixed width
                            height: 194.002 * Style.uiScaleRatio // Keep fixed height
                            anchors.centerIn: parent
                            
                            // Visual highlight if it is the active workspace or if it contains drag
                            readonly property bool isActiveWorkspace: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id
                            
                            // Using conditional color while still being an NBox for theme consistency
                            color: isActiveWorkspace ? Color.mPrimary : (parent.containsDrag ? Color.mSurfaceVariant : Color.mSurface)
                            border.color: isActiveWorkspace ? Color.mOnPrimary : Color.mOutline
                            border.width: parent.containsDrag ? 4 : 0
                            opacity: parent.containsDrag ? 0.8 : 1.0

                            // MouseArea to click on the workspace and switch to it
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (targetWorkspaceId !== undefined) {
                                        Hyprland.dispatch("workspace " + targetWorkspaceId);
                                        if (pluginApi) {
                                            pluginApi.closePanel(pluginApi.panelOpenScreen);
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Style.marginM / 2
                                spacing: Style.marginS

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24 * Style.uiScaleRatio
                                    Layout.alignment: Qt.AlignHCenter
                                    
                                    // Special Workspace detection
                                    readonly property bool isSpecial: modelData.id === -98 || (modelData.name && modelData.name.indexOf("special:") === 0)

                                    NText {
                                        visible: !workspaceDelegate.isEditingName
                                        anchors.centerIn: parent
                                        text: {
                                            if (parent.isSpecial) return "Workspace Especial";
                                            
                                            const showName = pluginApi?.pluginSettings?.showWorkspaceName ?? false;
                                            if (showName) {
                                                if (modelData.name !== "" && modelData.name !== modelData.id.toString()) return modelData.name;
                                                return "Workspace " + modelData.id;
                                            } else {
                                                return modelData.id.toString();
                                            }
                                        }
                                        font.weight: Font.Bold
                                        color: workspaceBg.isActiveWorkspace ? Color.mOnPrimary : Color.mOnSurface
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: parent.parent.isSpecial ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            enabled: !parent.parent.isSpecial
                                            onClicked: workspaceDelegate.isEditingName = true
                                        }
                                    }

                                    TextInput {
                                        id: nameInput
                                        visible: workspaceDelegate.isEditingName
                                        anchors.centerIn: parent
                                        text: modelData.name !== "" ? modelData.name : modelData.id.toString()
                                        color: workspaceBg.isActiveWorkspace ? Color.mOnPrimary : Color.mOnSurface
                                        font.bold: true
                                        font.pixelSize: Style.fontSizeM
                                        focus: visible
                                        selectByMouse: true
                                        horizontalAlignment: TextInput.AlignHCenter

                                        onAccepted: {
                                            Hyprland.dispatch("renameworkspace " + modelData.id + " " + text);
                                            workspaceDelegate.isEditingName = false;
                                        }
                                        
                                        onActiveFocusChanged: {
                                            if (!activeFocus) workspaceDelegate.isEditingName = false;
                                        }
                                    }
                                }

                                Item {
                                    visible: !(pluginApi?.pluginSettings?.hideWindowTitle ?? false)
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20 * Style.uiScaleRatio
                                    clip: true

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 4 * Style.uiScaleRatio
                                        height: parent.height

                                        Repeater {
                                            model: modelData.toplevels || null
                                            delegate: Item {
                                                id: windowItem
                                                width: Math.min(innerText.implicitWidth, 180 * Style.uiScaleRatio)
                                                height: 20 * Style.uiScaleRatio
                                                clip: true
                                                
                                                property bool isHovered: mouseArea.containsMouse

                                                NText {
                                                    id: innerText
                                                    property var win: modelData
                                                    text: {
                                                        const showApp = pluginApi?.pluginSettings?.showAppName ?? false;
                                                        const label = showApp 
                                                            ? (win.class || win.lastIpcObject?.class || win.initialClass || "Aplicativo") 
                                                            : (win.title || "Aplicativo");
                                                        return (index === 0 ? "" : "• ") + label;
                                                    }
                                                    pointSize: 8 * Style.uiScaleRatio
                                                    color: workspaceBg.isActiveWorkspace ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    
                                                    // Scrolling animation
                                                    NumberAnimation on x {
                                                        id: scrollAnim
                                                        from: 0
                                                        to: -(innerText.implicitWidth - windowItem.width)
                                                        duration: Math.max(1000, (innerText.implicitWidth - windowItem.width) * 30)
                                                        running: windowItem.isHovered && innerText.implicitWidth > windowItem.width
                                                        loops: Animation.Infinite
                                                        onRunningChanged: if (!running) x = 0
                                                    }
                                                }
                                                
                                                MouseArea {
                                                    id: mouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                }
                                            }
                                        }
                                    }
                                }

                                // Mini-monitor background (Real wallpaper or solid color)
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    Layout.preferredWidth: 199.663 * Style.uiScaleRatio
                                    Layout.preferredHeight: 112.256 * Style.uiScaleRatio
                                    color: Qt.rgba(0, 0, 0, 0.4)
                                    border.color: parent.parent.isActiveWorkspace ? Color.mOnPrimary : Color.mOutline
                                    border.width: 2 * Style.uiScaleRatio
                                    radius: Style.radiusS
                                    clip: true

                                    // Wallpaper
                                    Image {
                                        anchors.fill: parent
                                        source: typeof WallpaperService !== "undefined" ? WallpaperService.getWallpaper(modelData.monitor.name) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: source != ""
                                        opacity: 0.8
                                    }
                                    
                                    // Actual dimensions and positions come from the workspace monitor
                                    property var wsMonitor: modelData.monitor || null
                                    property real monitorX: wsMonitor ? wsMonitor.x : 0
                                    property real monitorY: wsMonitor ? wsMonitor.y : 0
                                    property real monitorW: wsMonitor && wsMonitor.width > 0 ? wsMonitor.width : 1920
                                    property real monitorH: wsMonitor && wsMonitor.height > 0 ? wsMonitor.height : 1080
                                    property real scaleX: width / monitorW
                                    property real scaleY: height / monitorH

                                    Repeater {
                                        model: modelData.toplevels || null
                                        delegate: Rectangle {
                                            // Using 'required property var modelData' forces QML to get the modelData from the internal Repeater
                                            // escaping the scope shadowing generated by the external GridView.
                                            required property var modelData
                                            
                                            // Geometric information comes from the lastIpcObject associated with the window (inner modelData)
                                            property var ipcObj: modelData.lastIpcObject || null
                                            property real winX: ipcObj && ipcObj.at ? ipcObj.at[0] : 0
                                            property real winY: ipcObj && ipcObj.at ? ipcObj.at[1] : 0
                                            property real winW: ipcObj && ipcObj.size ? ipcObj.size[0] : 0
                                            property real winH: ipcObj && ipcObj.size ? ipcObj.size[1] : 0
                                            
                                            // Position relative to the monitor
                                            x: (winX - parent.monitorX) * parent.scaleX
                                            y: (winY - parent.monitorY) * parent.scaleY
                                            width: Math.max(2, winW * parent.scaleX)
                                            height: Math.max(2, winH * parent.scaleY)
                                            
                                            // Ignore unmapped (hidden) windows
                                            visible: modelData.mapped !== undefined ? modelData.mapped : (ipcObj !== null && ipcObj.mapped !== undefined ? ipcObj.mapped : true)
                                            
                                            color: Color.mPrimary
                                            border.color: Color.mBackground
                                            border.width: Math.max(1, 1 * Style.uiScaleRatio)
                                            radius: 2 * Style.uiScaleRatio
                                            clip: true
                                            
                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: modelData.wayland
                                                live: true
                                                paintCursor: true
                                                
                                                // Optimization: Only capture at the resolution we are displaying
                                                constraintSize: Qt.size(parent.width, parent.height)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
