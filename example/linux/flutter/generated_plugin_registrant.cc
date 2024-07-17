//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <simple_parallax/simple_parallax_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) simple_parallax_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SimpleParallaxPlugin");
  simple_parallax_plugin_register_with_registrar(simple_parallax_registrar);
}
