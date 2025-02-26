# clockwork

[![Package Version](https://img.shields.io/hexpm/v/clockwork)](https://hex.pm/packages/clockwork)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/clockwork/)

```sh
gleam add clockwork
```

```gleam
import clockwork

pub fn main() {

  /// Here we create a cron schedule that triggers every 15 minutes on the 1st and 15th of the month.
  let assert Ok(cron) = "*/15 0 1,15 5-10 2-6/2" |> clockwork.from_string

  /// Here we create a cron using functions instead.
  let cron = clockwork.default()
    |> clockwork.with_minute(clockwork.every(15))
    |> clockwork.with_hour(clockwork.exactly(at: 0))
    |> clockwork.with_day(clockwork.list([clockwork.exactly(1), clockwork.exactly(15)]))
    |> clockwork.with_month(clockwork.ranging(from: 5, to: 10))
    |> clockwork.with_weekday(clockwork.ranging_every(2, from: 2, to: 6))

  let now = ...

  /// Here we calculate the next occurrence of the cron schedule after the given timestamp.
  clockwork.next_occurrence(given: cron, from: now)

}
```

Further documentation can be found at <https://hexdocs.pm/clockwork>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
