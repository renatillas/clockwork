import birdie
import clockwork
import gleam/time/calendar
import gleam/time/timestamp
import gleeunit
import gleeunit/should
import pprint

pub fn main() {
  gleeunit.main()
}

pub fn from_string_test() {
  "*/15 0 1,15 * 1-5"
  |> clockwork.from_string
  |> pprint.format
  |> birdie.snap("from_string test: */15 0 1,15 * 1-5")
}

pub fn from_string_precedence_test() {
  "1,2,3-5/2 * * * *"
  |> clockwork.from_string
  |> pprint.format
  |> birdie.snap("from_string precedence test: 1,2,3-5/2 * * * *")
}

pub fn from_string_error_test() {
  "*/15 0 1,15 * 1-5 *"
  |> clockwork.from_string
  |> should.be_error
}

pub fn from_string_error_step() {
  "*/15/15 * * * *"
  |> clockwork.from_string
  |> should.be_error
}

pub fn next_all_star_test() {
  // Somebody once told me the world is gonna roll me
  "* * * * *"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2024, calendar.December, 25),
    time: calendar.TimeOfDay(12, 30, 50, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2024, calendar.December, 25),
    calendar.TimeOfDay(12, 31, 0, 0),
  ))
}

pub fn next_at_5_4_star_star_star_test() {
  "5 4 * * *"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2024, calendar.December, 25),
    time: calendar.TimeOfDay(12, 30, 0, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2024, calendar.December, 26),
    calendar.TimeOfDay(4, 5, 0, 0),
  ))
}

pub fn next_at_5_4_25_star_star_test() {
  "5 4 25 * *"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2025, calendar.December, 26),
    time: calendar.TimeOfDay(12, 30, 50, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2026, calendar.January, 25),
    calendar.TimeOfDay(4, 5, 0, 0),
  ))
}

pub fn next_at_5_4_25_12_3_test() {
  "5 4 25 12 3"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2025, calendar.February, 22),
    time: calendar.TimeOfDay(18, 13, 0, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2030, calendar.December, 25),
    calendar.TimeOfDay(4, 5, 0, 0),
  ))
}

pub fn next_at_multiple_test() {
  "*/15 0 1,15 * *"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2025, calendar.February, 22),
    time: calendar.TimeOfDay(18, 0, 0, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2025, calendar.March, 1),
    calendar.TimeOfDay(0, 0, 0, 0),
  ))
}

pub fn to_string_test() {
  let cron = "*/15 0 1,15 * 1-5"
  cron
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.to_string
  |> should.equal(cron)
}

pub fn from_string_with_month_and_weekday() {
  "*/15 0 1,15 DIC MON,TUE"
  |> clockwork.from_string
  |> should.be_ok
  |> clockwork.to_string
  |> should.equal("*/15 0 1,15 12 1,2")
}

pub fn construct_using_builder_test() {
  clockwork.default()
  |> clockwork.with_minute(clockwork.every_time())
  |> clockwork.with_hour(clockwork.exactly(at: 5))
  |> clockwork.with_day(clockwork.every(5))
  |> clockwork.with_month(clockwork.ranging(from: 5, to: 10))
  |> clockwork.with_weekday(clockwork.ranging_every(2, from: 2, to: 6))
  |> clockwork.to_string
  |> should.equal("* 5 */5 5-10 2-6/2")
}
