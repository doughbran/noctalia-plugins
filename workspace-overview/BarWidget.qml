import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
    id: root
    property var pluginApi: null
    property var screen: null

    // Ensures the widget occupies space in the bar
    implicitWidth: Style.baseWidgetSize
    implicitHeight: Style.baseWidgetSize
    
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // Use NIcon instead of NIconButton to avoid circular background with inverted colors
    NIcon {
        id: widgetIcon
        anchors.centerIn: parent
        icon: "layout-dashboard"
        // Default icon color: white/light gray, like the others. 
        // Add hover color if the mouse is over.
        color: mouseArea.containsMouse ? Color.mPrimary : Color.mOnSurface
    }

    NPopupContextMenu {
        id: contextMenu
        model: [
            {
                "label": "Configurações",
                "action": "settings",
                "icon": "settings"
            }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen);
            } else {
                if (pluginApi) {
                    pluginApi.openPanel(root.screen, root)
                }
            }
        }
    }
}
