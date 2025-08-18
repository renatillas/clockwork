# clockwork

[![Package Version](https://img.shields.io/hexpm/v/clockwork)](https://hex.pm/packages/clockwork)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/clockwork/)

A powerful and intuitive cron expression parser and scheduler for Gleam applications. Parse, validate, and calculate occurrences with ease.

## Features

- **Parse cron expressions** from strings with full validation
- **Build cron schedules** programmatically using a fluent API
- **Calculate next occurrences** from any given timestamp
- **Support for standard cron syntax** including ranges, lists, and step values
- **Type-safe API** with helpful error messages

## Installation

```sh
gleam add clockwork
```

## Usage

### Parsing Cron Expressions

Parse standard cron expressions with comprehensive validation:

```gleam
import clockwork

pub fn parse_example() {
  // Parse a cron expression that runs every 15 minutes
  // on the 1st and 15th of the month, from May to October
  let assert Ok(cron) = "*/15 0 1,15 5-10 2-6/2" 
    |> clockwork.from_string
    
  // The parser validates all fields and returns helpful
  // error messages for invalid expressions
}
```

### Building Cron Schedules Programmatically

Create precise schedules using the builder API:

```gleam
import clockwork

pub fn builder_example() {
  // Build the same schedule using the fluent API
  let cron = clockwork.default()
    |> clockwork.with_minute(clockwork.every(15))
    |> clockwork.with_hour(clockwork.exactly(at: 0))
    |> clockwork.with_day(clockwork.list([
      clockwork.exactly(1), 
      clockwork.exactly(15)
    ]))
    |> clockwork.with_month(clockwork.ranging(from: 5, to: 10))
    |> clockwork.with_weekday(clockwork.ranging_every(2, from: 2, to: 6))
}
```

### Calculating Next Occurrences

Determine when your cron schedule will trigger next:

```gleam
import clockwork
import gleam/time/timestamp

pub fn next_occurrence_example() {
  let assert Ok(cron) = "0 9 * * 1-5" 
    |> clockwork.from_string  // Weekdays at 9 AM
  
  let now = timestamp.system_time()
  
  // Get the next scheduled time
  let next = clockwork.next_occurrence(given: cron, from: now)
}
```

## Cron Expression Format

Clockwork supports standard cron expressions with five fields:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 7, Sunday = 0 or 7)
│ │ │ │ │
* * * * *
```

### Supported Patterns

- **Wildcard (`*`)**: Matches any value
- **Specific values**: `5`, `10`, `15`
- **Ranges**: `1-5`, `10-20`
- **Lists**: `1,5,10,15`
- **Steps**: `*/5`, `10-30/5`
- **Combined**: `1-5,10,15-20/2`

### Examples

| Expression | Description |
|------------|-------------|
| `0 0 * * *` | Daily at midnight |
| `*/15 * * * *` | Every 15 minutes |
| `0 9-17 * * 1-5` | Every hour from 9 AM to 5 PM on weekdays |
| `0 0 1 * *` | First day of every month at midnight |
| `30 3 * * 0` | Every Sunday at 3:30 AM |

## API Documentation

For detailed API documentation and advanced usage, visit [hexdocs.pm/clockwork](https://hexdocs.pm/clockwork).

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.