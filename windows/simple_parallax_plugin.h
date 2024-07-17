#ifndef FLUTTER_PLUGIN_SIMPLE_PARALLAX_PLUGIN_H_
#define FLUTTER_PLUGIN_SIMPLE_PARALLAX_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace simple_parallax {

class SimpleParallaxPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SimpleParallaxPlugin();

  virtual ~SimpleParallaxPlugin();

  // Disallow copy and assign.
  SimpleParallaxPlugin(const SimpleParallaxPlugin&) = delete;
  SimpleParallaxPlugin& operator=(const SimpleParallaxPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace simple_parallax

#endif  // FLUTTER_PLUGIN_SIMPLE_PARALLAX_PLUGIN_H_
