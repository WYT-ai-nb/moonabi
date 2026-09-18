#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdlib.h>

#ifdef _WIN32
#include <process.h>
#endif

#include "moonbit.h"

#ifdef _WIN32
typedef moonbit_string_t moonabi_os_string_t;
#else
typedef moonbit_bytes_t moonabi_os_string_t;
#endif

MOONBIT_FFI_EXPORT int32_t moonabi_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t
moonabi_run_command(moonabi_os_string_t command) {
#ifdef _WIN32
  return _wsystem((const wchar_t *)command);
#else
  return system((const char *)command);
#endif
}

#ifdef __cplusplus
}
#endif

