#include "events.h"

#include <stdlib.h>

struct event_bus {
  event_info defaults;
  event_sink sink;
  void *user_data;
  int64_t count;
};

event_bus *event_bus_new(const event_info *defaults) {
  if (defaults == NULL) {
    return NULL;
  }
  event_bus *bus = (event_bus *)calloc(1, sizeof(event_bus));
  if (bus == NULL) {
    return NULL;
  }
  bus->defaults = *defaults;
  return bus;
}

void event_bus_free(event_bus *bus) {
  free(bus);
}

int32_t event_bus_subscribe(
  event_bus *bus,
  event_sink sink,
  void *user_data
) {
  if (bus == NULL) {
    return -1;
  }
  bus->sink = sink;
  bus->user_data = user_data;
  bus->count += 1;
  return 0;
}

int64_t event_bus_count(const event_bus *bus) {
  if (bus == NULL) {
    return -1;
  }
  return bus->count;
}

