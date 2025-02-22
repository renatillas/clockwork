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

pub type CronField {
  Wildcard
  Value(Int)
  Range(Int, Int)
  List(List(CronField))
  Step(CronField, Int)
}

pub fn parse(cron: String) {
  let parts = string.split(cron, on: " ")
  use <- bool.guard(list.length(parts) != 5, return: Error(Nil))
  let assert [minute, hour, day, month, weekday] = parts

  use minute <- result.try(do_parse(minute, 0, 59, False, False))
  use hour <- result.try(do_parse(hour, 0, 23, False, False))
  use day <- result.try(do_parse(day, 1, 31, False, False))
  use month <- result.try(do_parse(month, 1, 12, False, False))
  use weekday <- result.try(do_parse(weekday, 0, 6, False, False))

  Ok(Cron(minute, hour, day, month, weekday))
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
    ["MAR"], False, True -> Ok(Value(3))
    ["APR"], False, True -> Ok(Value(4))
    ["MAY"], False, True -> Ok(Value(5))
    ["JUN"], False, True -> Ok(Value(6))
    ["JUL"], False, True -> Ok(Value(7))
    ["AUG"], False, True -> Ok(Value(8))
    ["SEP"], False, True -> Ok(Value(9))
    ["OCT"], False, True -> Ok(Value(10))
    ["NOV"], False, True -> Ok(Value(11))
    ["DEC"], False, True -> Ok(Value(12))
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

/// Returns True if the given integer value matches the cron field.
@internal
pub fn field_matches(field: CronField, value: Int) -> Bool {
  case field {
    Wildcard -> True
    Value(v) -> v == value
    Range(start, end) -> start <= value && value <= end
    Step(f, step) ->
      case f {
        Wildcard -> {
          let offset = value % step
          offset == 0
        }
        Value(v) -> {
          let diff = value - v
          case diff < 0 {
            True -> False
            False -> {
              let offset = diff % step
              offset == 0
            }
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

/// Given a field, current value, and the valid range (min–max),
/// returns a record with the next matching value and a carry flag.
/// The carry flag indicates that no valid value ≥ current exists and a rollover is needed.
@internal
pub fn next_in_field(
  field: CronField,
  current: Int,
  min: Int,
  max: Int,
) -> #(Int, Bool) {
  case field {
    Wildcard ->
      // Wildcard accepts any value; no jump needed.
      #(current, False)
    Value(v) ->
      case current < v {
        True -> #(v, False)
        // No candidate in the current cycle; roll over.
        False -> #(v, True)
      }
    Range(start, end) ->
      case current <= start {
        True -> #(start, False)
        False ->
          case current < end {
            True -> #(current + 1, False)
            False -> #(start, True)
          }
      }
    Step(Wildcard, step) -> {
      let offset = current % step
      let next = current + step - offset
      case next <= max {
        True -> #(next, False)
        False -> #(min, True)
      }
    }
    Step(Range(min, max), step) -> {
      let offset = current - min
      let next = current + step - offset % step
      case next <= max {
        True -> #(next, False)
        False -> #(min, True)
      }
    }
    Step(Value(v), step) -> {
      let diff = current - v
      case diff < 0 {
        True -> #(v, False)
        False -> {
          let offset = diff % step
          let next = current + step - offset
          case next <= max {
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
      // Find the next value in the list that is greater than the current value.
      let nexts =
        fields
        |> list.map(fn(f) { next_in_field(f, current, min, max) })
        |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
      let filtered =
        nexts
        |> list.filter(fn(v) { v.0 > current })
      case filtered {
        [] -> #(
          case nexts {
            [] -> panic
            [first, ..] -> first.0
          },
          True,
        )
        [next, ..] -> next
      }
    }
  }
}

/// Returns the minimal value that satisfies the field.
/// (For Wildcard, we use the minimum of the range.)
@internal
pub fn minimal(field: CronField, min: Int, max: Int) -> Int {
  case field {
    Wildcard -> min
    Value(v) -> v
    Range(start, _) -> start
    Step(_, start) -> start
    List(fields) ->
      fields
      |> list.map(minimal(_, min, max))
      |> list.fold(max, fn(a, b) { int.min(a, b) })
  }
}

/// Given a Cron and a starting time, returns the next time that matches the cron expression.
/// This implementation “jumps” by adjusting each field as needed.
pub fn next_occurrence(
  cron: Cron,
  from: timestamp.Timestamp,
) -> timestamp.Timestamp {
  // Start by adding one minute to ensure we move forward.
  jump_candidate(cron, timestamp.add(from, duration.seconds(60)))
}

/// Recursively adjusts the candidate time by “jumping” to the next matching value in each field.
fn jump_candidate(cron: Cron, t: timestamp.Timestamp) -> timestamp.Timestamp {
  // Adjust the minute field.
  let minute_res = next_in_field(cron.minute, get_minute(t), 0, 59)
  let t = set_minute(t, minute_res.0)
  let t = case minute_res.1 {
    // If we had to roll over minutes, add one hour.
    True -> add_hours(t, 1)
    False -> t
  }
  // Adjust the hour field.
  let hour_res = next_in_field(cron.hour, get_hour(t), 0, 23)
  let t = set_hour(t, hour_res.0)
  let t = case hour_res.1 {
    // Rollover of hour adds one day.
    True -> add_days(t, 1)
    False -> t
  }

  // Adjust the day field.
  let max_day = days_in_month(t)
  let day_res = next_in_field(cron.day, get_day(t), 1, max_day)
  let t = set_day(t, day_res.0)
  let t = case day_res.1 {
    // Rollover on day: add one month and reset day.
    True -> {
      let t = add_months(t, 1)
      set_day(t, minimal(cron.day, 1, days_in_month(t)))
    }
    False -> t
  }

  // Adjust the month field.
  let month_res = next_in_field(cron.month, get_month(t), 1, 12)
  let t = set_month(t, month_res.0)
  let t = case month_res.1 {
    // Rollover on month: add one year and reset month.
    True -> {
      let t = add_years(t, 1)
      set_month(t, minimal(cron.month, 1, 12))
    }
    False -> t
  }

  // Finally, adjust the weekday.
  case field_matches(cron.weekday, get_weekday(t)) {
    True -> t
    False ->
      // If the weekday doesn't match, jump ahead one day and re-adjust.
      jump_candidate(cron, add_days(t, 1))
  }
}

fn set_minute(t: timestamp.Timestamp, minute: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let time = calendar.TimeOfDay(..time, minutes: minute)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn get_minute(t: timestamp.Timestamp) -> Int {
  { timestamp.to_calendar(t, calendar.utc_offset).1 }.minutes
}

fn add_hours(t: timestamp.Timestamp, hours: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds(hours * 60 * 60))
}

fn set_hour(t: timestamp.Timestamp, hour: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let time = calendar.TimeOfDay(..time, hours: hour)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn get_hour(t: timestamp.Timestamp) -> Int {
  { timestamp.to_calendar(t, calendar.utc_offset).1 }.hours
}

fn add_days(t: timestamp.Timestamp, days: Int) -> timestamp.Timestamp {
  timestamp.add(t, duration.seconds(days * 24 * 60 * 60))
}

fn days_in_month(t: timestamp.Timestamp) -> Int {
  case { timestamp.to_calendar(t, calendar.utc_offset).0 }.month {
    calendar.January -> 31
    calendar.February -> {
      let year = { timestamp.to_calendar(t, calendar.utc_offset).0 }.year
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
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
  year % 4 == 0 && { year % 100 != 0 || year % 400 == 0 }
}

fn get_day(t: timestamp.Timestamp) -> Int {
  { timestamp.to_calendar(t, calendar.utc_offset).0 }.day
}

fn set_day(t: timestamp.Timestamp, day: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let date = calendar.Date(..date, day: day)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn add_months(t: timestamp.Timestamp, months: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let date_month = case date.month {
    calendar.January -> 0
    calendar.February -> 1
    calendar.March -> 2
    calendar.April -> 3
    calendar.May -> 4
    calendar.June -> 5
    calendar.July -> 6
    calendar.August -> 7
    calendar.September -> 8
    calendar.October -> 9
    calendar.November -> 10
    calendar.December -> 11
  }
  let month = { date_month + months } % 12
  let year = date.year + { date_month + months } / 12
  let month = case month {
    0 -> calendar.January
    1 -> calendar.February
    2 -> calendar.March
    3 -> calendar.April
    4 -> calendar.May
    5 -> calendar.June
    6 -> calendar.July
    7 -> calendar.August
    8 -> calendar.September
    9 -> calendar.October
    10 -> calendar.November
    11 -> calendar.December
    _ -> panic
  }
  let date = calendar.Date(..date, month: month, year: year)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn get_month(t: timestamp.Timestamp) -> Int {
  case { timestamp.to_calendar(t, calendar.utc_offset).0 }.month {
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

fn set_month(t: timestamp.Timestamp, month: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let month = case month {
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
    _ -> panic
  }
  let date = calendar.Date(..date, month: month)
  timestamp.from_calendar(date, time, calendar.utc_offset)
}

fn add_years(t: timestamp.Timestamp, years: Int) -> timestamp.Timestamp {
  let #(date, time) = t |> timestamp.to_calendar(calendar.utc_offset)
  let date = calendar.Date(..date, year: date.year + years)
  timestamp.from_calendar(date, time, calendar.utc_offset)
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

pub fn get_weekday(t: timestamp.Timestamp) -> Int {
  let date = timestamp.to_calendar(t, calendar.utc_offset).0
  // Adjust month and year for January and February
  let year = case month_to_int(date.month) < 3 {
    True -> date.year - 1
    False -> date.year
  }
  let month = case month_to_int(date.month) < 3 {
    True -> month_to_int(date.month) + 12
    False -> month_to_int(date.month)
  }
  let k = year % 100
  let j = year / 100
  // Zeller's congruence: h = (day + ⌊13*(month+1)/5⌋ + k + ⌊k/4⌋ + ⌊j/4⌋ + 5*j) mod 7

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
  // Zeller's output: 0 = Saturday, 1 = Sunday, 2 = Monday, etc.
  // Convert so that 0 = Sunday, 1 = Monday, …, 6 = Saturday.
  case h == 0 {
    True -> 6
    False -> h - 1
  }
}
