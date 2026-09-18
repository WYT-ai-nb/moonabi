#include "demo.h"

#include <stdlib.h>

struct demo_handle {
  demo_config config;
  demo_log_callback callback;
  void *user_data;
};

demo_handle *demo_create(const demo_config *config) {
  if (config == NULL) {
    return NULL;
  }
  demo_handle *handle = (demo_handle *)calloc(1, sizeof(demo_handle));
  if (handle == NULL) {
    return NULL;
  }
  handle->config = *config;
  return handle;
}

void demo_destroy(demo_handle *handle) {
  free(handle);
}

int32_t demo_set_log_callback(
  demo_handle *handle,
  demo_log_callback callback,
  void *user_data
) {
  if (handle == NULL) {
    return -1;
  }
  handle->callback = callback;
  handle->user_data = user_data;
  return 0;
}

int64_t demo_timeout(const demo_handle *handle) {
  if (handle == NULL) {
    return -1;
  }
  return handle->config.timeout_ms;
}

