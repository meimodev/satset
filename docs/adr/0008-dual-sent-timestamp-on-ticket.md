# Ticket carries both a string and a DateTime sent-time

The domain `Ticket` keeps `sentAt` as a `String` (HH:mm) **and** a `sentAtTime` as a full-precision `DateTime`, mapped from the same DTO field. The string is the canonical card-grouping key on the KDS — `kitchen_screen` collapses every ticket sharing one HH:mm into a single order card (`groups.putIfAbsent(t.sentAt, ...)`), and same-minute courses must stay grouped. A `DateTime` with seconds would split those into separate cards. But the live age counter on each card needs sub-minute precision to tick like the other counters (`formatElapsedId`, top bar), so we added `sentAtTime` alongside rather than widening `sentAt`.

## Consequences

- The two fields are derived from one source (`OrderDto.sentAt`) and must not drift; the only conversion point is `tickets_repository` mapping.
- Grouping/sort/display keep using the string; only the age display reads `sentAtTime`.
