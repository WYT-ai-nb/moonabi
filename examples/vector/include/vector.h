#ifndef MOONABI_VECTOR_H
#define MOONABI_VECTOR_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct vector_handle vector_handle;

typedef struct vector_config {
  uint32_t capacity;
  uint32_t flags;
  int64_t seed;
} vector_config;

enum {
  VECTOR_FLAG_GROW = 1,
  VECTOR_FLAG_ZERO = 2
};

vector_handle *vector_create(const vector_config *config);
void vector_destroy(vector_handle *handle);
int64_t vector_length(const vector_handle *handle);

#ifdef __cplusplus
}
#endif

#endif

