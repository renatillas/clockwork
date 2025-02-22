import clockwork.{Cron, List, Range, Step, Value, Wildcard}
import gleam/time/calendar
import gleam/time/timestamp
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn parse_test() {
  "*/15 0 1,15 * 1-5"
  |> clockwork.parse
  |> should.be_ok()
  |> should.equal(Cron(
    Step(Wildcard, 15),
    Value(0),
    List([Value(1), Value(15)]),
    Wildcard,
    Range(1, 5),
  ))
}

pub fn parse_precedence_test() {
  "1,2,3-5/2 * * * *"
  |> clockwork.parse
  |> should.be_ok()
  |> should.equal(Cron(
    List([Value(1), Value(2), Step(Range(3, 5), 2)]),
    Wildcard,
    Wildcard,
    Wildcard,
    Wildcard,
  ))
}

pub fn parse_error_test() {
  "*/15 0 1,15 * 1-5 *"
  |> clockwork.parse
  |> should.be_error
}

pub fn matches_wildcard_test() {
  Wildcard
  |> clockwork.field_matches(1)
  |> should.equal(True)
}

pub fn matches_value_test() {
  Value(3)
  |> clockwork.field_matches(3)
  |> should.equal(True)

  Value(3)
  |> clockwork.field_matches(4)
  |> should.equal(False)
}

pub fn matches_range_test() {
  Range(1, 5)
  |> clockwork.field_matches(3)
  |> should.equal(True)

  Range(1, 5)
  |> clockwork.field_matches(6)
  |> should.equal(False)

  Range(2, 5)
  |> clockwork.field_matches(1)
  |> should.equal(False)
}

pub fn matches_list_test() {
  List([Value(1), Value(3), Value(5)])
  |> clockwork.field_matches(3)
  |> should.equal(True)

  List([Value(1), Value(3), Value(5)])
  |> clockwork.field_matches(4)
  |> should.equal(False)
}

pub fn matches_step_wildcard_test() {
  Step(Wildcard, 2)
  |> clockwork.field_matches(2)
  |> should.equal(True)

  Step(Wildcard, 2)
  |> clockwork.field_matches(3)
  |> should.equal(False)
}

pub fn matches_step_value_test() {
  Step(Value(5), 2)
  |> clockwork.field_matches(3)
  |> should.equal(False)

  Step(Value(5), 2)
  |> clockwork.field_matches(7)
  |> should.equal(True)

  Step(Value(5), 2)
  |> clockwork.field_matches(8)
  |> should.equal(False)

  Step(Value(5), 2)
  |> clockwork.field_matches(9)
  |> should.equal(True)
}

pub fn matches_step_range_test() {
  Step(Range(1, 5), 2)
  |> clockwork.field_matches(1)
  |> should.equal(True)

  Step(Range(1, 5), 2)
  |> clockwork.field_matches(3)
  |> should.equal(True)

  Step(Range(1, 5), 2)
  |> clockwork.field_matches(5)
  |> should.equal(True)

  Step(Range(1, 5), 2)
  |> clockwork.field_matches(2)
  |> should.equal(False)

  Step(Range(1, 5), 2)
  |> clockwork.field_matches(4)
  |> should.equal(False)

  Step(Range(1, 5), 2)
  |> clockwork.field_matches(6)
  |> should.equal(False)
}

pub fn next_in_field_wildcard_test() {
  Wildcard
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(1, False))
}

pub fn next_in_field_value_test() {
  Value(5)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(5, False))

  Value(5)
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(5, True))

  Value(5)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(5, True))
}

pub fn next_in_field_range_test() {
  Range(1, 5)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(1, False))

  Range(1, 5)
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  Range(1, 5)
  |> clockwork.next_in_field(4, 1, 31)
  |> should.equal(#(5, False))

  Range(1, 5)
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(1, True))

  Range(1, 5)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(1, True))
}

pub fn next_in_field_list_test() {
  List([Value(2), Value(3), Value(5)])
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  List([Value(2), Value(3), Value(5)])
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  List([Value(2), Value(3), Value(5)])
  |> clockwork.next_in_field(4, 1, 31)
  |> should.equal(#(5, False))

  List([Value(2), Value(3), Value(5)])
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(2, True))

  List([Value(2), Value(3), Value(5)])
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(2, True))

  List([Value(1), Value(2), Step(Range(3, 5), 2)])
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  List([Value(1), Value(2), Step(Range(3, 5), 2)])
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(5, False))
}

pub fn next_in_field_step_test() {
  Step(Wildcard, 2)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(2, False))

  Step(Wildcard, 2)
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(4, False))

  Step(Value(5), 2)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(5, False))

  Step(Value(5), 2)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(7, False))

  Step(Value(5), 2)
  |> clockwork.next_in_field(31, 1, 31)
  |> should.equal(#(5, True))

  Step(Value(12), 3)
  |> clockwork.next_in_field(11, 1, 12)
  |> should.equal(#(12, False))

  Step(Range(1, 5), 2)
  |> clockwork.next_in_field(1, 1, 31)
  |> should.equal(#(3, False))

  Step(Range(1, 5), 2)
  |> clockwork.next_in_field(2, 1, 31)
  |> should.equal(#(3, False))

  Step(Range(1, 5), 2)
  |> clockwork.next_in_field(3, 1, 31)
  |> should.equal(#(5, False))

  Step(Range(1, 5), 2)
  |> clockwork.next_in_field(5, 1, 31)
  |> should.equal(#(1, True))

  Step(Range(1, 5), 2)
  |> clockwork.next_in_field(6, 1, 31)
  |> should.equal(#(1, True))
}

pub fn minimal_wildcard_test() {
  Wildcard
  |> clockwork.minimal(1, 31)
  |> should.equal(1)
}

pub fn minimal_value_test() {
  Value(3)
  |> clockwork.minimal(1, 31)
  |> should.equal(3)
}

pub fn minimal_range_test() {
  Range(2, 5)
  |> clockwork.minimal(1, 31)
  |> should.equal(2)
}

pub fn minimal_list_test() {
  clockwork.List([clockwork.Value(3), clockwork.Value(5), clockwork.Value(7)])
  |> clockwork.minimal(1, 31)
  |> should.equal(3)
}

pub fn minimal_step_test() {
  clockwork.Step(clockwork.Wildcard, 3)
  |> clockwork.minimal(1, 31)
  |> should.equal(3)
}

pub fn next_all_star_test() {
  // Somebody once told me the world is gonna roll me
  "* * * * *"
  |> clockwork.parse
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2024, calendar.December, 25),
    time: calendar.TimeOfDay(12, 30, 50, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2024, calendar.December, 25),
    calendar.TimeOfDay(12, 31, 50, 0),
  ))
}

pub fn next_at_5_4_star_star_star_test() {
  "5 4 * * *"
  |> clockwork.parse
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2024, calendar.December, 25),
    time: calendar.TimeOfDay(12, 30, 50, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2024, calendar.December, 26),
    calendar.TimeOfDay(4, 5, 50, 0),
  ))
}

pub fn next_at_5_4_25_star_star_test() {
  "5 4 25 * *"
  |> clockwork.parse
  |> should.be_ok
  |> clockwork.next_occurrence(timestamp.from_calendar(
    date: calendar.Date(2025, calendar.December, 26),
    time: calendar.TimeOfDay(12, 30, 50, 0),
    offset: calendar.utc_offset,
  ))
  |> timestamp.to_calendar(calendar.utc_offset)
  |> should.equal(#(
    calendar.Date(2026, calendar.January, 25),
    calendar.TimeOfDay(4, 5, 50, 0),
  ))
}

pub fn next_at_5_4_25_12_3_test() {
  "5 4 25 12 3"
  |> clockwork.parse
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
  |> clockwork.parse
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
