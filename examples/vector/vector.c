#include "vector.h"

#include <stdlib.h>

struct vector_handle {
  vector_config config;
  int64_t length;
};

vector_handle *vector_create(const vector_config *config) {
  if (config == NULL) {
    return NULL;
  }
  vector_handle *handle = (vector_handle *)calloc(1, sizeof(vector_handle));
  if (handle == NULL) {
    return NULL;
  }
  handle->config = *config;
  handle->length = (int64_t)config->capacity;
  return handle;
}

void vector_destroy(vector_handle *handle) {
  free(handle);
}

int64_t vector_length(const vector_handle *handle) {
  if (handle == NULL) {
    return -1;
  }
  return handle->length;
}

