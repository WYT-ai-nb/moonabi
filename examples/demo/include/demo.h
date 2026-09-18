#ifndef MOONABI_DEMO_H
#define MOONABI_DEMO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct demo_handle demo_handle;

typedef struct demo_config {
  uint32_t flags;
  uint32_t reserved;
  int64_t timeout_ms;
} demo_config;

typedef void (*demo_log_callback)(const char *message, void *user_data);

enum {
  DEMO_FLAG_COMPRESSED = 1,
  DEMO_FLAG_SECURE = 2
};

demo_handle *demo_create(const demo_config *config);

void demo_destroy(demo_handle *handle);

int32_t demo_set_log_callback(
  demo_handle *handle,
  demo_log_callback callback,
  void *user_data
);

int64_t demo_timeout(const demo_handle *handle);

#ifdef __cplusplus
}
#endif

#endif

