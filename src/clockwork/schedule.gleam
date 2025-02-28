import clockwork
import gleam/erlang/process
import gleam/float
import gleam/function
import gleam/int
import gleam/io
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import glotel/span
import glotel/span_kind
import logging

pub type Schedule {
  Schedule(subject: process.Subject(Message))
}

pub type Message {
  Run
  Stop
}

type State {
  State(
    id: String,
    self: process.Subject(Message),
    cron: clockwork.Cron,
    job: fn() -> Nil,
    with_telemetry: Bool,
    offset: duration.Duration,
  )
}

pub opaque type Scheduler {
  Scheduler(
    id: String,
    cron: clockwork.Cron,
    job: fn() -> Nil,
    with_logging: Bool,
    with_telemetry: Bool,
    offset: duration.Duration,
  )
}

pub fn new(id, cron, job) -> Scheduler {
  Scheduler(id, cron, job, False, False, calendar.utc_offset)
}

pub fn with_logging(scheduler: Scheduler) -> Scheduler {
  Scheduler(
    scheduler.id,
    scheduler.cron,
    scheduler.job,
    True,
    scheduler.with_telemetry,
    scheduler.offset,
  )
}

pub fn with_telemetry(scheduler: Scheduler) -> Scheduler {
  Scheduler(
    scheduler.id,
    scheduler.cron,
    scheduler.job,
    scheduler.with_logging,
    True,
    scheduler.offset,
  )
}

pub fn with_time_offset(
  scheduler: Scheduler,
  offset: duration.Duration,
) -> Scheduler {
  Scheduler(
    scheduler.id,
    scheduler.cron,
    scheduler.job,
    scheduler.with_logging,
    scheduler.with_telemetry,
    offset,
  )
}

pub fn start(scheduler: Scheduler) -> Result(Schedule, actor.StartError) {
  case scheduler.with_logging {
    True -> logging.configure()
    False -> Nil
  }
  actor.start_spec(actor.Spec(
    init: fn() {
      init(
        scheduler.cron,
        scheduler.job,
        scheduler.id,
        scheduler.with_telemetry,
        scheduler.offset,
      )
    },
    loop: loop,
    init_timeout: 100,
  ))
  |> result.map(Schedule)
}

pub fn stop(schedule: Schedule) {
  process.send(schedule.subject, Stop)
}

fn init(cron, job, name, telemetry, offset) {
  let subject = process.new_subject()
  let state = State(name, subject, cron, job, telemetry, offset)

  let selector =
    process.new_selector() |> process.selecting(subject, function.identity)

  enqueue_job(cron, state)
  logging.log(logging.Info, "[CLOCKWORK] Started cron job: " <> state.id)
  actor.Ready(state, selector)
}

fn loop(message: Message, state: State) {
  case message {
    Run -> {
      logging.log(
        logging.Info,
        "[CLOCKWORK] Running job: "
          <> state.id
          <> " at "
          <> timestamp.system_time()
        |> timestamp.add(state.offset)
        |> timestamp.to_unix_seconds
        |> float.to_string(),
      )
      process.start(
        fn() {
          case state.with_telemetry {
            True -> {
              let human_readable_time =
                timestamp.system_time()
                |> timestamp.to_calendar(state.offset)

              use _ <- span.new_of_kind(span_kind.Consumer, "job-" <> state.id, [
                #(
                  "timestamp",
                  timestamp.system_time()
                    |> timestamp.to_unix_seconds
                    |> float.to_string(),
                ),
                #("year", { human_readable_time.0 }.year |> int.to_string()),
                #("month", { human_readable_time.0 }.month |> string.inspect()),
                #("day", { human_readable_time.0 }.day |> int.to_string()),
                #("hour", { human_readable_time.1 }.hours |> int.to_string()),
                #(
                  "minute",
                  { human_readable_time.1 }.minutes |> int.to_string(),
                ),
                #(
                  "second",
                  { human_readable_time.1 }.seconds |> int.to_string(),
                ),
              ])
              state.job()
            }
            False -> state.job()
          }
        },
        True,
      )
      enqueue_job(state.cron, state)
      actor.continue(state)
    }
    Stop -> {
      logging.log(logging.Info, "[CLOCKWORK] Stopping job: " <> state.id)
      actor.Stop(process.Normal)
    }
  }
}

fn enqueue_job(cron, state: State) {
  let now = timestamp.system_time()
  let next_occurrence =
    clockwork.next_occurrence(cron, now, state.offset)
    |> timestamp.difference(now, _)
    |> duration.to_seconds_and_nanoseconds
    |> fn(tuple) {
      let #(seconds, nanoseconds) = tuple
      seconds * 1000 + nanoseconds / 1_000_000
    }

  process.send_after(state.self, next_occurrence, Run)
}
