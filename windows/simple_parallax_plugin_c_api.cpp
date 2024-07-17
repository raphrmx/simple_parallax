#include "include/simple_parallax/simple_parallax_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "simple_parallax_plugin.h"

void SimpleParallaxPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  simple_parallax::SimpleParallaxPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
