import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp

pub type Cron {
  Cron(
    minute: CronField,
    hour: CronField,
    day: CronField,
    month: CronField,
    weekday: CronField,
  )
}

pub opaque type CronField {
  Wildcard
  Value(Int)
  Range(Int, Int)
  List(List(CronField))
  Step(CronField, Int)
}

/// Creates a default Cron struct with all fields set to wildcard (`*`).
/// 
/// This represents a schedule that runs every minute of every hour of every day.
/// 
/// ## Examples
/// 
/// ```gleam
/// let cron = clockwork.default()
/// // Equivalent to "* * * * *" - runs every minute
/// ```
/// 
/// ## Returns
/// 
/// A `Cron` struct with all fields set to `Wildcard`.
pub fn default() -> Cron {
  Cron(Wildcard, Wildcard, Wildcard, Wildcard, Wildcard)
}

/// Sets the minute field of a Cron struct.
/// 
/// Minutes range from 0 to 59.
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to update
/// - `minute`: A `CronField` specifying when to run within the hour
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_minute(clockwork.exactly(at: 30))
/// // Runs at minute 30 of every hour
/// 
/// clockwork.default()
/// |> clockwork.with_minute(clockwork.every(15))
/// // Runs every 15 minutes (0, 15, 30, 45)
/// ```
/// 
/// ## Returns
/// 
/// A new `Cron` struct with the updated minute field.
pub fn with_minute(cron: Cron, minute) -> Cron {
  Cron(..cron, minute:)
}

/// Sets the hour field of a Cron struct.
/// 
/// Hours range from 0 to 23 (24-hour format).
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to update
/// - `hour`: A `CronField` specifying which hours to run
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_hour(clockwork.exactly(at: 9))
/// // Runs at 9 AM
/// 
/// clockwork.default()
/// |> clockwork.with_hour(clockwork.ranging(from: 9, to: 17))
/// // Runs every hour from 9 AM to 5 PM
/// ```
/// 
/// ## Returns
/// 
/// A new `Cron` struct with the updated hour field.
pub fn with_hour(cron: Cron, hour) -> Cron {
  Cron(..cron, hour:)
}

/// Sets the day of month field of a Cron struct.
/// 
/// Days range from 1 to 31 (depending on the month).
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to update
/// - `day`: A `CronField` specifying which days of the month to run
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_day(clockwork.exactly(at: 1))
/// // Runs on the first day of every month
/// 
/// clockwork.default()
/// |> clockwork.with_day(clockwork.list([
///   clockwork.exactly(1),
///   clockwork.exactly(15)
/// ]))
/// // Runs on the 1st and 15th of every month
/// ```
/// 
/// ## Returns
/// 
/// A new `Cron` struct with the updated day field.
pub fn with_day(cron: Cron, day) -> Cron {
  Cron(..cron, day:)
}

/// Sets the month field of a Cron struct.
/// 
/// Months range from 1 (January) to 12 (December).
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to update
/// - `month`: A `CronField` specifying which months to run
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_month(clockwork.exactly(at: 12))
/// // Runs only in December
/// 
/// clockwork.default()
/// |> clockwork.with_month(clockwork.ranging(from: 6, to: 8))
/// // Runs in June, July, and August
/// ```
/// 
/// ## Returns
/// 
/// A new `Cron` struct with the updated month field.
pub fn with_month(cron: Cron, month) -> Cron {
  Cron(..cron, month:)
}

/// Sets the weekday field of a Cron struct.
/// 
/// Weekdays range from 0 to 6, where:
/// - 0 = Sunday
/// - 1 = Monday
/// - 2 = Tuesday
/// - 3 = Wednesday
/// - 4 = Thursday
/// - 5 = Friday
/// - 6 = Saturday
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to update
/// - `weekday`: A `CronField` specifying which days of the week to run
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_weekday(clockwork.ranging(from: 1, to: 5))
/// // Runs Monday through Friday
/// 
/// clockwork.default()
/// |> clockwork.with_weekday(clockwork.exactly(at: 0))
/// // Runs only on Sundays
/// ```
/// 
/// ## Returns
/// 
/// A new `Cron` struct with the updated weekday field.
pub fn with_weekday(cron: Cron, weekday) -> Cron {
  Cron(..cron, weekday:)
}

/// Creates a wildcard CronField that matches all values.
/// 
/// Equivalent to `*` in cron syntax.
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.default()
/// |> clockwork.with_hour(clockwork.every_time())
/// // Runs every hour (same as default)
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a wildcard.
pub fn every_time() -> CronField {
  Wildcard
}

/// Creates a CronField that matches exactly one specific value.
/// 
/// ## Parameters
/// 
/// - `at`: The exact value to match
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.exactly(at: 30)
/// // Matches when the field equals 30
/// 
/// clockwork.default()
/// |> clockwork.with_minute(clockwork.exactly(at: 0))
/// // Runs at the top of every hour
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a single value.
pub fn exactly(at v: Int) -> CronField {
  Value(v)
}

/// Creates a CronField that matches a range of values (inclusive).
/// 
/// ## Parameters
/// 
/// - `from`: The start of the range (inclusive)
/// - `to`: The end of the range (inclusive)
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.ranging(from: 9, to: 17)
/// // Matches values from 9 to 17 inclusive
/// 
/// clockwork.default()
/// |> clockwork.with_hour(clockwork.ranging(from: 9, to: 17))
/// // Runs every hour from 9 AM to 5 PM
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a range of values.
pub fn ranging(from start: Int, to end: Int) -> CronField {
  Range(start, end)
}

/// Creates a CronField that matches any value in a list of fields.
/// 
/// Equivalent to comma-separated values in cron syntax.
/// 
/// ## Parameters
/// 
/// - `fields`: A list of CronFields to match against
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.list([
///   clockwork.exactly(0),
///   clockwork.exactly(15),
///   clockwork.exactly(30),
///   clockwork.exactly(45)
/// ])
/// // Matches at 0, 15, 30, and 45
/// 
/// clockwork.list([
///   clockwork.ranging(from: 1, to: 5),
///   clockwork.exactly(10)
/// ])
/// // Matches 1-5 and 10
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a list of possible matches.
pub fn list(fields: List(CronField)) -> CronField {
  List(fields)
}

/// Creates a CronField that matches every nth value within a range.
/// 
/// Equivalent to `start-end/step` in cron syntax.
/// 
/// ## Parameters
/// 
/// - `step`: The interval between matches
/// - `from`: The start of the range (inclusive)
/// - `to`: The end of the range (inclusive)
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.ranging_every(2, from: 0, to: 10)
/// // Matches 0, 2, 4, 6, 8, 10
/// 
/// clockwork.default()
/// |> clockwork.with_weekday(clockwork.ranging_every(2, from: 1, to: 5))
/// // Runs on Monday, Wednesday, and Friday
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a stepped range.
pub fn ranging_every(step: Int, from start: Int, to end: Int) -> CronField {
  Step(Range(start, end), step)
}

/// Creates a CronField that matches every nth value.
/// 
/// Equivalent to `*/step` in cron syntax.
/// 
/// ## Parameters
/// 
/// - `step`: The interval between matches
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.every(15)
/// // Matches every 15th value (0, 15, 30, 45 for minutes)
/// 
/// clockwork.default()
/// |> clockwork.with_minute(clockwork.every(5))
/// // Runs every 5 minutes
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a step interval.
pub fn every(step: Int) -> CronField {
  Step(Wildcard, step)
}

/// Creates a CronField that matches every nth value starting from a specific value.
/// 
/// Equivalent to `from/step` in cron syntax.
/// 
/// ## Parameters
/// 
/// - `every`: The interval between matches
/// - `from`: The starting value
/// 
/// ## Examples
/// 
/// ```gleam
/// clockwork.stepping(every: 10, from: 5)
/// // Matches 5, 15, 25, 35, 45, 55 (for minutes)
/// 
/// clockwork.default()
/// |> clockwork.with_minute(clockwork.stepping(every: 20, from: 10))
/// // Runs at minutes 10, 30, and 50
/// ```
/// 
/// ## Returns
/// 
/// A `CronField` representing a stepped sequence starting from a value.
pub fn stepping(every step: Int, from from: Int) -> CronField {
  Step(Value(from), step)
}

/// Parses a cron expression string into a Cron struct.
/// 
/// Accepts standard 5-field cron expressions with support for:
/// - Wildcards (`*`)
/// - Specific values (`5`)
/// - Ranges (`1-5`)
/// - Lists (`1,5,10`)
/// - Steps (`*/5`, `10-30/5`)
/// - Month names (`JAN`, `FEB`, etc.)
/// - Weekday names (`SUN`, `MON`, etc.)
/// 
/// ## Parameters
/// 
/// - `cron`: A string containing a valid cron expression
/// 
/// ## Examples
/// 
/// ```gleam
/// let assert Ok(cron) = clockwork.from_string("0 9 * * 1-5")
/// // Weekdays at 9 AM
/// 
/// let assert Ok(cron) = clockwork.from_string("*/15 * * * *")
/// // Every 15 minutes
/// 
/// let assert Ok(cron) = clockwork.from_string("0 0 1 JAN,JUL *")
/// // Midnight on January 1st and July 1st
/// ```
/// 
/// ## Returns
/// 
/// - `Ok(Cron)` if the string is a valid cron expression
/// - `Error(Nil)` if the string is invalid
/// 
/// ## Errors
/// 
/// Returns an error if:
/// - The expression doesn't have exactly 5 fields
/// - Any field contains invalid syntax
/// - Values are out of valid ranges
pub fn from_string(cron: String) {
  let parts = string.split(cron, on: " ")
  use <- bool.guard(list.length(parts) != 5, return: Error(Nil))
  let assert [minute, hour, day, month, weekday] = parts

  use minute <- result.try(do_parse(minute, 0, 59, False, False))
  use hour <- result.try(do_parse(hour, 0, 23, False, False))
  use day <- result.try(do_parse(day, 1, 31, False, False))
  use month <- result.try(do_parse(month, 1, 12, True, False))
  use weekday <- result.try(do_parse(weekday, 0, 6, False, True))

  Ok(Cron(minute, hour, day, month, weekday))
}

/// Converts a Cron struct back into a cron expression string.
/// 
/// The output string can be parsed back using `from_string` to recreate
/// the same Cron struct.
/// 
/// ## Parameters
/// 
/// - `cron`: The Cron struct to convert
/// 
/// ## Examples
/// 
/// ```gleam
/// let cron = clockwork.default()
///   |> clockwork.with_minute(clockwork.every(15))
///   |> clockwork.with_hour(clockwork.ranging(from: 9, to: 17))
/// 
/// let cron_string = clockwork.to_string(cron)
/// // Returns: "*/15 9-17 * * *"
/// ```
/// 
/// ## Returns
/// 
/// A string representation of the cron expression.
pub fn to_string(cron: Cron) -> String {
  let minute = field_to_string(cron.minute)
  let hour = field_to_string(cron.hour)
  let day = field_to_string(cron.day)
  let month = field_to_string(cron.month)
  let weekday = field_to_string(cron.weekday)
  string.concat([minute, " ", hour, " ", day, " ", month, " ", weekday])
}

fn field_to_string(field: CronField) -> String {
  case field {
    Wildcard -> "*"
    Value(v) -> int.to_string(v)
    Range(start, end) ->
      string.concat([int.to_string(start), "-", int.to_string(end)])
    Step(f, step) ->
      string.concat([field_to_string(f), "/", int.to_string(step)])
    List(fields) -> fields |> list.map(field_to_string) |> string.join(",")
  }
}

/// Calculates the next occurrence of a cron schedule after the given timestamp.
/// 
/// This function finds the next time the cron expression would trigger,
/// starting from the provided timestamp. The result is always at least
/// one minute after the input timestamp.
/// 
/// ## Parameters
/// 
/// - `given`: The Cron struct defining the schedule
/// - `from`: The timestamp to start searching from
/// - `with_offset`: The timezone offset to use for calculations
/// 
/// ## Examples
/// 
/// ```gleam
/// import gleam/time/timestamp
/// import gleam/time/duration
/// 
/// let assert Ok(cron) = clockwork.from_string("0 9 * * 1-5")
/// let now = timestamp.system_time()
/// let offset = duration.seconds(0) // UTC
/// 
/// let next = clockwork.next_occurrence(
///   given: cron,
///   from: now,
///   with_offset: offset
/// )
/// // Returns the next weekday at 9 AM
/// ```
/// 
/// ## Returns
/// 
/// A `Timestamp` representing the next time the cron expression matches.
/// 
/// ## Notes
/// 
/// - The returned timestamp always has seconds set to 0
/// - The function accounts for month boundaries and leap years
/// - Weekday calculations follow the standard cron convention (0=Sunday)
pub fn next_occurrence(
  given cron: Cron,
  from from: timestamp.Timestamp,
  with_offset offset: duration.Duration,
) -> timestamp.Timestamp {
  jump_candidate(
    cron,
    timestamp.add(from |> round_seconds(offset), duration.milliseconds(60_000)),
    offset,
  )
  |> set_seconds_to_zero(offset)
}

fn round_seconds(timestamp, offset) {
  let #(date, time) = timestamp.to_calendar(timestamp, offset)
  let time = case time.seconds {
    59 -> calendar.TimeOfDay(time.hours, time.minutes + 1, 0, 0)
    _ -> calendar.TimeOfDay(time.hours, time.minutes, 0, 0)
  }
  timestamp.from_calendar(date, time, offset)
}

fn do_parse(input, min, max, is_month, is_weekday) -> Result(CronField, Nil) {
  let parts = string.split(input, on: ",")
  case parts {
    [part] -> parse_step(part, min, max, is_month, is_weekday)
    parts -> {
      let fields =
        list.map(parts, parse_step(_, min, max, is_month, is_weekday))
      use fields <- result.try(result.all(fields))
      Ok(List(fields))
    }
  }
}

fn parse_step(input, min, max, is_month, is_weekday) -> Result(CronField, Nil) {
  let parts = string.split(input, on: "/")
  case parts {
    [part] -> parse_range(part, min, max, is_month, is_weekday)
    [field, step] -> {
      use step <- result.try(int.parse(step))
      use field <- result.try(parse_range(field, min, max, is_month, is_weekday))
      Ok(Step(field, step))
    }
    _ -> Error(Nil)
  }
}

fn parse_range(input, min, max, is_month, is_weekday) -> Result(CronField, Nil) {
  let parts = string.split(input, on: "-")
  case parts, is_month, is_weekday {
    ["SUN"], False, True -> Ok(Value(0))
    ["MON"], False, True -> Ok(Value(1))
    ["TUE"], False, True -> Ok(Value(2))
    ["WED"], False, True -> Ok(Value(3))
    ["THU"], False, True -> Ok(Value(4))
    ["FRI"], False, True -> Ok(Value(5))
    ["SAT"], False, True -> Ok(Value(6))
    ["JAN"], True, False -> Ok(Value(1))
    ["FEB"], True, False -> Ok(Value(2))
    ["MAR"], True, False -> Ok(Value(3))
    ["APR"], True, False -> Ok(Value(4))
    ["MAY"], True, False -> Ok(Value(5))
    ["JUN"], True, False -> Ok(Value(6))
    ["JUL"], True, False -> Ok(Value(7))
    ["AUG"], True, False -> Ok(Value(8))
    ["SEP"], True, False -> Ok(Value(9))
    ["OCT"], True, False -> Ok(Value(10))
    ["NOV"], True, False -> Ok(Value(11))
    ["DEC"], True, False -> Ok(Value(12))
    ["*"], _, _ -> Ok(Wildcard)
    [number], _, _ -> {
      use number <- result.try(int.parse(number))
      use <- bool.guard(number < min || number > max, return: Error(Nil))
      Ok(Value(number))
    }
    [start, end], _, _ -> {
      use start <- result.try(int.parse(start))
      use end <- result.try(int.parse(end))
      Ok(Range(start, end))
    }
    _, _, _ -> Error(Nil)
  }
}

fn field_matches(field: CronField, value: Int) -> Bool {
  case field {
    Wildcard -> True
    Value(v) -> v == value
    Range(start, end) -> start <= value && value <= end
    Step(f, step) ->
      case f {
        Wildcard -> { value % step } == 0
        Value(v) -> {
          let diff = value - v
          case diff < 0 {
            True -> False
            False -> { diff % step } == 0
          }
        }
        Range(min, max) -> {
          let offset = { value - min } % step
          offset == 0 && value <= max
        }
        Step(_, _) ->
          panic as "invalid step in step, parse would never return this value"
        List(_) ->
          panic as "invalid step in list, parse would never return this value"
      }
    List(fields) ->
      fields
      |> list.any(fn(f) { field_matches(f, value) })
  }
}

fn next_in_field(
  field: CronField,
  current: Int,
  min: Int,
  max: Int,
) -> #(Int, Bool) {
  case field {
    Wildcard ->
      case current < min || current > max {
        True -> #(min, True)
        False -> #(current, False)
      }
    Value(v) ->
      case { current < v } {
        True -> #(v, False)
        False -> #(v, True)
      }
    Range(start, end) ->
      case { current <= start } {
        True -> #(start, False)
        False ->
          case { current < end } {
            True ->
              case { current < end } {
                // Increment by one unit
                True -> #(current + 1, False)
                False -> #(start, True)
              }
            False -> #(start, True)
          }
      }
    Step(Wildcard, step) -> {
      let offset = {
        current % step
      }
      let next = current + step - offset
      case { next <= max } {
        True -> #(next, False)
        False -> #(min, True)
      }
    }
    Step(Range(min_val, max_val), step) -> {
      let offset = current - min_val
      let next = current + step - { offset % step }
      case { next <= max_val } {
        True -> #(next, False)
        False -> #(min_val, True)
      }
    }
    Step(Value(v), step) -> {
      let diff = current - v
      case { diff < 0 } {
        True -> #(v, False)
        False -> {
          let offset = {
            diff % step
          }
          let next = current + step - offset
          case { next <= max } {
            True -> #(next, False)
            False -> #(v, True)
          }
        }
      }
    }
    Step(Step(_, _), _) ->
      panic as "invalid step in step, parse would never return this value"
    Step(List(_), _) ->
      panic as "invalid step in list, parse would never return this value"
    List(fields) -> {
      let candidates =
        fields
        |> list.map(fn(f) { next_in_field(f, current, min, max) })
      let filtered = candidates |> list.filter(fn(c) { c.0 > current })
      case filtered {
        [] -> {
          let sorted =
            candidates |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
          case sorted {
            [first, ..] -> #(first.0, True)
            [] -> panic
          }
        }
        [next, ..] -> next
      }
    }
  }
}

fn minimal(field: CronField, min: Int, max: Int) -> Int {
  case field {
    Wildcard -> min
    Value(v) -> v
    Range(start, _) -> start
    Step(field, _) -> {
      let next = next_in_field(field, min, min, max)
      case next.1 {
        True -> min
        False -> next.0
      }
    }
    List(fields) ->
      fields
      |> list.map(minimal(_, min, max))
      |> list.fold(max, fn(a, b) { int.min(a, b) })
  }
}

fn jump_candidate(
  cron: Cron,
  t: timestamp.Timestamp,
  offset: duration.Duration,
) -> timestamp.Timestamp {
  case
    field_matches(cron.minute, get_minute(t, offset)),
    field_matches(cron.hour, get_hour(t, offset)),
    field_matches(cron.day, get_day(t, offset)),
    field_matches(cron.month, get_month(t, offset)),
    field_matches(cron.weekday, get_weekday(t, offset))
  {
    True, True, True, True, True -> t
    True, True, True, True, False ->
      jump_candidate(
        cron,
        t
          |> set_hour(minimal(cron.hour, 0, 23), offset)
          |> set_minute(minimal(cron.minute, 0, 59), offset)
          |> add_days(1),
        offset,
      )
    True, True, True, False, _ ->
      jump_candidate(
        cron,
        t
          |> set_day(minimal(cron.day, 1, days_in_month(t, offset)), offset)
          |> set_hour(minimal(cron.hour, 0, 23), offset)
          |> set_minute(minimal(cron.minute, 0, 59), offset)
          |> add_month(1, offset),
        offset,
      )
    True, True, False, _, _ ->
      jump_candidate(
        cron,
        t
          |> set_hour(minimal(cron.hour, 0, 23), offset)
          |> set_minute(minimal(cron.minute, 0, 59), offset)
          |> add_days(1),
        offset,
      )
    True, False, _, _, _ ->
      jump_candidate(
        cron,
        t
          |> set_minute(minimal(cron.minute, 0, 59), offset)
          |> add_hours(1),
        offset,
      )
    False, _, _, _, _ -> jump_candidate(cron, add_minutes(t, 1), offset)
  }
}

fn add_minutes(t: timestamp.Timestamp, minutes: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds(minutes * 60))
}

fn set_minute(
  t: timestamp.Timestamp,
  minute: Int,
  offset,
) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, offset)
  let time = calendar.TimeOfDay(..time, minutes: minute)
  timestamp.from_calendar(date, time, offset)
}

fn get_minute(t: timestamp.Timestamp, offset) -> Int {
  let #(_, time) = timestamp.to_calendar(t, offset)
  time.minutes
}

fn add_hours(t: timestamp.Timestamp, hours: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds({ hours * 3600 }))
}

fn set_hour(t: timestamp.Timestamp, hour: Int, offset) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, offset)
  let time = calendar.TimeOfDay(..time, hours: hour)
  timestamp.from_calendar(date, time, offset)
}

fn get_hour(t: timestamp.Timestamp, offset) -> Int {
  let #(_, time) = timestamp.to_calendar(t, offset)
  time.hours
}

fn add_days(t: timestamp.Timestamp, days: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds(days * 86_400))
}

fn get_day(t: timestamp.Timestamp, offset) -> Int {
  let #(date, _) = timestamp.to_calendar(t, offset)
  date.day
}

fn set_day(t: timestamp.Timestamp, day: Int, offset) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, offset)
  let date = calendar.Date(..date, day: day)
  timestamp.from_calendar(date, time, offset)
}

fn days_in_month(t: timestamp.Timestamp, offset) -> Int {
  let #(date, _) = timestamp.to_calendar(t, offset)
  case date.month {
    calendar.January -> 31
    calendar.February ->
      case is_leap_year(date.year) {
        True -> 29
        False -> 28
      }
    calendar.March -> 31
    calendar.April -> 30
    calendar.May -> 31
    calendar.June -> 30
    calendar.July -> 31
    calendar.August -> 31
    calendar.September -> 30
    calendar.October -> 31
    calendar.November -> 30
    calendar.December -> 31
  }
}

fn is_leap_year(year: Int) -> Bool {
  { year % 4 } == 0 && { year % 100 } != 0 || { year % 400 } == 0
}

fn get_month(t: timestamp.Timestamp, offset) -> Int {
  let #(date, _) = timestamp.to_calendar(t, offset)
  case date.month {
    calendar.January -> 1
    calendar.February -> 2
    calendar.March -> 3
    calendar.April -> 4
    calendar.May -> 5
    calendar.June -> 6
    calendar.July -> 7
    calendar.August -> 8
    calendar.September -> 9
    calendar.October -> 10
    calendar.November -> 11
    calendar.December -> 12
  }
}

fn add_month(t: timestamp.Timestamp, months: Int, offset) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, offset)
  let month = case { month_to_int(date.month) + months } {
    1 -> calendar.January
    2 -> calendar.February
    3 -> calendar.March
    4 -> calendar.April
    5 -> calendar.May
    6 -> calendar.June
    7 -> calendar.July
    8 -> calendar.August
    9 -> calendar.September
    10 -> calendar.October
    11 -> calendar.November
    12 -> calendar.December
    13 -> calendar.January
    _ -> panic
  }
  let date = calendar.Date(..date, month: month)
  timestamp.from_calendar(date, time, offset)
}

fn get_weekday(t: timestamp.Timestamp, offset) -> Int {
  let date = timestamp.to_calendar(t, offset).0
  let year = case { month_to_int(date.month) } < 3 {
    True -> date.year - 1
    False -> date.year
  }
  let month = case { month_to_int(date.month) } < 3 {
    True -> { month_to_int(date.month) } + 12
    False -> month_to_int(date.month)
  }
  let k = year % 100
  let j = {
    year / 100
  }
  let h =
    {
      date.day
      + { { 13 * { month + 1 } } / 5 }
      + k
      + { k / 4 }
      + { j / 4 }
      + { 5 * j }
    }
    % 7
  case h == 0 {
    True -> 6
    False -> h - 1
  }
}

fn month_to_int(month: calendar.Month) -> Int {
  case month {
    calendar.January -> 1
    calendar.February -> 2
    calendar.March -> 3
    calendar.April -> 4
    calendar.May -> 5
    calendar.June -> 6
    calendar.July -> 7
    calendar.August -> 8
    calendar.September -> 9
    calendar.October -> 10
    calendar.November -> 11
    calendar.December -> 12
  }
}

fn set_seconds_to_zero(t: timestamp.Timestamp, offset) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, offset)
  let time = calendar.TimeOfDay(time.hours, time.minutes, 0, 0)
  timestamp.from_calendar(date, time, offset)
}
