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

/// Default cron struct with all fields set to wildcard.
pub fn default() -> Cron {
  Cron(Wildcard, Wildcard, Wildcard, Wildcard, Wildcard)
}

/// Set the minute field of a cron struct.
pub fn with_minute(cron: Cron, minute) -> Cron {
  Cron(..cron, minute:)
}

/// Set the hour field of a cron struct.
pub fn with_hour(cron: Cron, hour) -> Cron {
  Cron(..cron, hour:)
}

/// Set the day field of a cron struct.
pub fn with_day(cron: Cron, day) -> Cron {
  Cron(..cron, day:)
}

/// Set the month field of a cron struct.
pub fn with_month(cron: Cron, month) -> Cron {
  Cron(..cron, month:)
}

/// Set the weekday field of a cron struct.
pub fn with_weekday(cron: Cron, weekday) -> Cron {
  Cron(..cron, weekday:)
}

/// Wildcard field for a cron struct.
pub fn wildcard() -> CronField {
  Wildcard
}

/// Value field for a cron struct.
pub fn value(v: Int) -> CronField {
  Value(v)
}

/// Range field for a cron struct.
pub fn range(start: Int, end: Int) -> CronField {
  Range(start, end)
}

/// List field for a cron struct.
pub fn list(fields: List(CronField)) -> CronField {
  List(fields)
}

/// Step field for a cron struct.
/// May contain a wildcard, value, range, or list field.
/// The step value must be greater than 0.
pub fn step(field: CronField, step: Int) -> Result(CronField, Nil) {
  case field {
    _ if step <= 0 -> Error(Nil)
    Wildcard -> Ok(Step(Wildcard, step))
    Value(v) -> Ok(Step(Value(v), step))
    Range(min, max) -> Ok(Step(Range(min, max), step))
    _ -> Error(Nil)
  }
}

/// Parse a cron string into a Cron struct.
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

/// Convert a Cron struct into a cron string.
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

/// Returns the next occurrence of a cron job after the given timestamp.
pub fn next_occurrence(
  cron: Cron,
  from: timestamp.Timestamp,
) -> timestamp.Timestamp {
  jump_candidate(cron, timestamp.add(from, duration.seconds(60)))
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

@internal
pub fn field_matches(field: CronField, value: Int) -> Bool {
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

@internal
pub fn next_in_field(
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

/// Returns the minimal matching value for the field.
@internal
pub fn minimal(field: CronField, min: Int, max: Int) -> Int {
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

/// Adjusts candidate time field-by-field (month → day → hour → minute) and resets lower fields on rollover.
/// Finally, it ensures the weekday matches.
fn jump_candidate(cron: Cron, t: timestamp.Timestamp) -> timestamp.Timestamp {
  let t = set_seconds_to_zero(t)
  case
    field_matches(cron.minute, get_minute(t)),
    field_matches(cron.hour, get_hour(t)),
    field_matches(cron.day, get_day(t)),
    field_matches(cron.month, get_month(t)),
    field_matches(cron.weekday, get_weekday(t))
  {
    True, True, True, True, True -> t
    True, True, True, True, False ->
      jump_candidate(cron, {
        t
        |> set_hour(minimal(cron.hour, 0, 23))
        |> set_minute(minimal(cron.minute, 0, 59))
        |> add_days(1)
      })
    True, True, True, False, _ ->
      jump_candidate(cron, {
        t
        |> set_day(minimal(cron.day, 1, days_in_month(t)))
        |> set_hour(minimal(cron.hour, 0, 23))
        |> set_minute(minimal(cron.minute, 0, 59))
        |> add_month(1)
      })
    True, True, False, _, _ ->
      jump_candidate(cron, {
        t
        |> set_hour(minimal(cron.hour, 0, 23))
        |> set_minute(minimal(cron.minute, 0, 59))
        |> add_days(1)
      })
    True, False, _, _, _ ->
      jump_candidate(cron, {
        t
        |> set_minute(minimal(cron.minute, 0, 59))
        |> add_hours(1)
      })
    False, _, _, _, _ -> jump_candidate(cron, add_minutes(t, 1))
  }
}

fn add_minutes(t: timestamp.Timestamp, minutes: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds(minutes * 60))
}

fn set_minute(t: timestamp.Timestamp, minute: Int) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, calendar.utc_offset)
  let time = calendar.TimeOfDay(..time, minutes: minute)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn get_minute(t: timestamp.Timestamp) -> Int {
  let #(_, time) = timestamp.to_calendar(t, calendar.utc_offset)
  time.minutes
}

fn add_hours(t: timestamp.Timestamp, hours: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds({ hours * 3600 }))
}

fn set_hour(t: timestamp.Timestamp, hour: Int) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, calendar.utc_offset)
  let time = calendar.TimeOfDay(..time, hours: hour)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn get_hour(t: timestamp.Timestamp) -> Int {
  let #(_, time) = timestamp.to_calendar(t, calendar.utc_offset)
  time.hours
}

fn add_days(t: timestamp.Timestamp, days: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds({ days * 86_400 }))
}

fn get_day(t: timestamp.Timestamp) -> Int {
  let #(date, _) = timestamp.to_calendar(t, calendar.utc_offset)
  date.day
}

fn set_day(t: timestamp.Timestamp, day: Int) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, calendar.utc_offset)
  let date = calendar.Date(..date, day: day)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn days_in_month(t: timestamp.Timestamp) -> Int {
  let #(date, _) = timestamp.to_calendar(t, calendar.utc_offset)
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

fn get_month(t: timestamp.Timestamp) -> Int {
  let #(date, _) = timestamp.to_calendar(t, calendar.utc_offset)
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

fn add_month(t: timestamp.Timestamp, months: Int) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, calendar.utc_offset)
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
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

/// Uses Zeller's Congruence to compute the weekday from a timestamp.
/// Returns: 0 = Sunday, 1 = Monday, …, 6 = Saturday.
fn get_weekday(t: timestamp.Timestamp) -> Int {
  let date = timestamp.to_calendar(t, calendar.utc_offset).0
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

fn set_seconds_to_zero(t: timestamp.Timestamp) -> timestamp.Timestamp {
  let #(date, time) = timestamp.to_calendar(t, calendar.utc_offset)
  let time = calendar.TimeOfDay(time.hours, time.minutes, 0, 0)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}
