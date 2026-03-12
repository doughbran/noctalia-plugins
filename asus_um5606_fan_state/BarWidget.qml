import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property bool hovered: false

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  implicitWidth: isVertical ? Style.capsuleHeight : layout.implicitWidth + Style.marginS * 2
  implicitHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : Style.capsuleHeight

  color: root.hovered ? Color.mHover : Style.capsuleColor
  radius: Style.radiusM
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth
  
  property int fanState: -1
  
  Component.onCompleted: {
    if (pluginApi?.mainInstance) {
      root.fanState = pluginApi.mainInstance.fanState;
      pluginApi.mainInstance.refreshFanState();
    }
  }

  onPluginApiChanged: {
    if (pluginApi?.mainInstance) {
      root.fanState = pluginApi.mainInstance.fanState;
    }
  }

  Connections {
    target: pluginApi?.mainInstance ?? null

    function onFanStateChanged() {
      Logger.i("ASUS Fan State", `onFanStateChanged called, target: ${target}, new fanState: ${target?.fanState}`);
      if (target) {
        root.fanState = target.fanState;
      }
    }
  }

  function setFanState(value) {
    Logger.i("ASUS Fan State", `setFanState called with value ${value}, pluginApi.mainInstance: ${pluginApi?.mainInstance}`);
    if (pluginApi?.mainInstance) {
      pluginApi.mainInstance.setFanState(value);
    }
  }
  
  function getTooltipText() {
    switch (fanState) {
    case 0:
      return pluginApi?.tr("tooltip.standard");
    case 1:
      return pluginApi?.tr("tooltip.quiet");
    case 2:
      return pluginApi?.tr("tooltip.high");
    case 3:
      return pluginApi?.tr("tooltip.full");
    default:
      return pluginApi?.tr("tooltip.unknown");
    }
  }

  function getIcon() {
    switch (fanState) {
    case 0:
      return "car-fan";
    case 1:
      return "car-fan-1";
    case 2:
      return "car-fan-2";
    case 3:
      return "car-fan-3";
    default:
      return "car-fan";
    }
  }

  function getColor() {
    switch (fanState) {
    case 3:
      return Color.mPrimary;
    case 2:
      return Color.mTertiary;
    case 1:
      return Color.mSecondary;
    case 0:
      return Color.mOnSurface;
    default:
      return Color.mOnSurface;
    }
  }

  Item {
    id: layout
    anchors.centerIn: parent

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      // Optical alignment bs
      anchors.horizontalCenterOffset: -0.25

      NIcon {
        icon: getIcon()
        color: root.hovered ? Color.mOnHover : getColor()
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.pluginApi?.mainInstance?.updateCount > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

      onClicked: {
          Logger.i("ASUS Fan State Widget", `Clicked, current fanState: ${fanState}`);
          setFanState((fanState + 1) % 4);
      }

      onEntered: {
        root.hovered = true;
        TooltipService.show(root, getTooltipText(), BarService.getTooltipDirection());
      }

      onExited: {
        root.hovered = false;
        TooltipService.hide();
      }
    }
  }
}
