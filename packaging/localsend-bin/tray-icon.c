/* Swaybar only looks up icon-theme names. LocalSend passes a file path,
   so the bar draws its red sad face. Report the theme name instead. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>

static const char *tray_icon(const char *icon_name) {
  if (icon_name && icon_name[0] == '/') {
    return "localsend-tray";
  }
  return icon_name;
}

void app_indicator_set_icon_full(void *self, const char *icon_name,
                                 const char *icon_desc) {
  static void (*real)(void *, const char *, const char *) = NULL;
  if (!real) {
    real = dlsym(RTLD_NEXT, "app_indicator_set_icon_full");
  }
  real(self, tray_icon(icon_name), icon_desc);
}

void app_indicator_set_icon(void *self, const char *icon_name) {
  static void (*real)(void *, const char *) = NULL;
  if (!real) {
    real = dlsym(RTLD_NEXT, "app_indicator_set_icon");
  }
  real(self, tray_icon(icon_name));
}

void *app_indicator_new(const char *id, const char *icon_name, int category) {
  static void *(*real)(const char *, const char *, int) = NULL;
  if (!real) {
    real = dlsym(RTLD_NEXT, "app_indicator_new");
  }
  return real(id, tray_icon(icon_name), category);
}
