#ifndef MOONABI_EVENTS_H
#define MOONABI_EVENTS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct event_bus event_bus;

typedef struct event_info {
  uint32_t kind;
  uint32_t priority;
  int64_t timestamp;
} event_info;

typedef void (*event_sink)(const event_info *info, void *user_data);

enum {
  EVENT_INFO = 1,
  EVENT_WARNING = 2,
  EVENT_ERROR = 3
};

event_bus *event_bus_new(const event_info *defaults);
void event_bus_free(event_bus *bus);
int32_t event_bus_subscribe(
  event_bus *bus,
  event_sink sink,
  void *user_data
);
int64_t event_bus_count(const event_bus *bus);

#ifdef __cplusplus
}
#endif

#endif

