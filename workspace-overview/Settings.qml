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
            label: "Exibir Nome do Workspace"
            description: "Exibe o nome do workspace em vez de apenas o número."
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
            label: "Esconder Títulos das Janelas"
            description: "Não exibe a lista de janelas abertas no panorama."
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
            label: "Exibir Nome do Aplicativo"
            description: "Exibe o nome da classe do aplicativo em vez do título da janela."
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
