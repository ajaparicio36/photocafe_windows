//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camera_windows/camera_windows.h>
#include <printing/printing_plugin.h>
#include <video_player_win/video_player_win_plugin_c_api.h>
#include <windows_printer/windows_printer_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  CameraWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CameraWindows"));
  PrintingPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintingPlugin"));
  VideoPlayerWinPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("VideoPlayerWinPluginCApi"));
  WindowsPrinterPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowsPrinterPluginCApi"));
}
