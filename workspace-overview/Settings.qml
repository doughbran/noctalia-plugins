import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    
    // Internal state for editing
    property bool editShowWorkspaceName: false
    property bool editHideWindowTitle: false
    property bool editShowAppName: false

    spacing: Style.marginM

    onPluginApiChanged: {
        if (pluginApi) {
            loadSettings()
        }
    }

    Component.onCompleted: {
        if (pluginApi) {
            loadSettings()
        }
    }

    function loadSettings() {
        if (!pluginApi) return
        
        const settings = pluginApi.pluginSettings
        const defaults = pluginApi.manifest?.metadata?.defaultSettings

        root.editShowWorkspaceName = settings?.showWorkspaceName ?? defaults?.showWorkspaceName ?? false
        root.editHideWindowTitle = settings?.hideWindowTitle ?? defaults?.hideWindowTitle ?? false
        root.editShowAppName = settings?.showAppName ?? defaults?.showAppName ?? false

        showWorkspaceNameToggle.checked = root.editShowWorkspaceName
        hideWindowTitlesToggle.checked = root.editHideWindowTitle
        showAppNameToggle.checked = root.editShowAppName
    }

    function saveSettings() {
        if (!pluginApi) return

        pluginApi.pluginSettings.showWorkspaceName = root.editShowWorkspaceName
        pluginApi.pluginSettings.hideWindowTitle = root.editHideWindowTitle
        pluginApi.pluginSettings.showAppName = root.editShowAppName

        pluginApi.saveSettings()
        
        if (pluginApi.mainInstance && pluginApi.mainInstance.settingsVersion !== undefined) {
             pluginApi.mainInstance.settingsVersion++
        }
    }

    // --- Workspace Settings ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: showWorkspaceNameToggle.implicitHeight
        
        NToggle {
            id: showWorkspaceNameToggle
            anchors.fill: parent
            label: "Show Workspace Name"
            description: "Display the workspace name instead of just the number."
            checked: root.editShowWorkspaceName
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.editShowWorkspaceName = !root.editShowWorkspaceName
                showWorkspaceNameToggle.checked = root.editShowWorkspaceName
                root.saveSettings()
            }
        }
    }

    NDivider { Layout.fillWidth: true }

    // --- Window Settings ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: hideWindowTitlesToggle.implicitHeight
        
        NToggle {
            id: hideWindowTitlesToggle
            anchors.fill: parent
            label: "Hide Window Titles"
            description: "Do not display the list of open windows in the overview."
            checked: root.editHideWindowTitle
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.editHideWindowTitle = !root.editHideWindowTitle
                hideWindowTitlesToggle.checked = root.editHideWindowTitle
                root.saveSettings()
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: showAppNameToggle.implicitHeight
        visible: !root.editHideWindowTitle
        
        NToggle {
            id: showAppNameToggle
            anchors.fill: parent
            label: "Show Application Name"
            description: "Display the application class name instead of the window title."
            checked: root.editShowAppName
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.editShowAppName = !root.editShowAppName
                showAppNameToggle.checked = root.editShowAppName
                root.saveSettings()
            }
        }
    }
}
