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

pub fn matches_wildcard_test() {
  clockwork.wildcard()
  |> clockwork.field_matches(1)
  |> should.equal(True)
}

pub fn matches_value_test() {
  clockwork.value(3)
  |> clockwork.field_matches(3)
  |> should.equal(True)

  clockwork.value(3)
  |> clockwork.field_matches(4)
  |> should.equal(False)
}

pub fn matches_range_test() {
  clockwork.range(1, 5)
  |> clockwork.field_matches(3)
  |> should.equal(True)

  clockwork.range(1, 5)
  |> clockwork.field_matches(6)
  |> should.equal(False)

  clockwork.range(2, 5)
  |> clockwork.field_matches(1)
  |> should.equal(False)
}

pub fn matches_list_test() {
  clockwork.list([clockwork.value(1), clockwork.value(3), clockwork.value(5)])
  |> clockwork.field_matches(3)
  |> should.equal(True)

  clockwork.list([clockwork.value(1), clockwork.value(3), clockwork.value(5)])
  |> clockwork.field_matches(4)
  |> should.equal(False)
}

pub fn matches_step_wildcard_test() {
  clockwork.step(clockwork.wildcard(), 2)
  |> should.be_ok
  |> clockwork.field_matches(2)
  |> should.equal(True)

  clockwork.step(clockwork.wildcard(), 2)
  |> should.be_ok
  |> clockwork.field_matches(3)
  |> should.equal(False)
}

pub fn matches_step_value_test() {
  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.field_matches(3)
  |> should.equal(False)

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.field_matches(7)
  |> should.equal(True)

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.field_matches(8)
  |> should.equal(False)

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.field_matches(9)
  |> should.equal(True)
}

pub fn matches_step_range_test() {
  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(1)
  |> should.equal(True)

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(3)
  |> should.equal(True)

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(5)
  |> should.equal(True)

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(2)
  |> should.equal(False)

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(4)
  |> should.equal(False)

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.field_matches(6)
  |> should.equal(False)
}

pub fn next_in_field_wildcard_test() {
  clockwork.wildcard()
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(1, False))
}

pub fn next_in_field_value_test() {
  clockwork.value(5)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(5, False))

  clockwork.value(5)
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(5, True))

  clockwork.value(5)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(5, True))
}

pub fn next_in_field_range_test() {
  clockwork.range(1, 5)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(1, False))

  clockwork.range(1, 5)
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  clockwork.range(1, 5)
  |> clockwork.next_in_field(4, 1, 31)
  |> should.equal(#(5, False))

  clockwork.range(1, 5)
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(1, True))

  clockwork.range(1, 5)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(1, True))
}

pub fn next_in_field_list_test() {
  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(4, 1, 31)
  |> should.equal(#(5, False))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(2, True))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(2, True))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  clockwork.list([clockwork.value(2), clockwork.value(3), clockwork.value(5)])
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(5, False))
}

pub fn next_in_field_step_test() {
  clockwork.step(clockwork.wildcard(), 2)
  |> should.be_ok
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  clockwork.step(clockwork.wildcard(), 2)
  |> should.be_ok
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(4, False))

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(5, False))

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(7, False))

  clockwork.step(clockwork.value(5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(31, 1, 31)
  |> should.equal(#(5, True))

  clockwork.step(clockwork.value(12), 3)
  |> should.be_ok
  |> clockwork.next_in_field(11, 1, 12)
  |> should.equal(#(12, False))

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(3, False))

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(5, False))

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(1, True))

  clockwork.step(clockwork.range(1, 5), 2)
  |> should.be_ok
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(1, True))
}

pub fn minimal_wildcard_test() {
  clockwork.wildcard()
  |> clockwork.minimal(1, 31)
  |> should.equal(1)
}

pub fn minimal_value_test() {
  clockwork.value(3)
  |> clockwork.minimal(1, 31)
  |> should.equal(3)
}

pub fn minimal_range_test() {
  clockwork.range(2, 5)
  |> clockwork.minimal(1, 31)
  |> should.equal(2)
}

pub fn minimal_list_test() {
  clockwork.list([clockwork.value(3), clockwork.value(5), clockwork.value(7)])
  |> clockwork.minimal(1, 31)
  |> should.equal(3)
}

pub fn minimal_step_test() {
  clockwork.step(clockwork.wildcard(), 3)
  |> should.be_ok
  |> clockwork.minimal(1, 31)
  |> should.equal(1)
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
