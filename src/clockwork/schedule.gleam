import clockwork
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/otp/actor
import gleam/otp/supervision
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

fn start_actor(scheduler: Scheduler) {
  case scheduler.with_logging {
    True -> logging.configure()
    False -> Nil
  }

  actor.new_with_initialiser(100, fn(self) {
    let state =
      State(
        id: scheduler.id,
        self:,
        cron: scheduler.cron,
        job: scheduler.job,
        with_telemetry: scheduler.with_telemetry,
        offset: scheduler.offset,
      )

    let selector =
      process.new_selector()
      |> process.select(self)

    actor.initialised(state)
    |> actor.selecting(selector)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(loop)
  |> actor.start
}

/// Start an unsupervised scheduler. Prefer to use [`supervised`](#supervised) to start
/// the scheduler as part of your supervision tree.
pub fn start(scheduler: Scheduler) -> Result(Schedule, actor.StartError) {
  start_actor(scheduler)
  |> result.map(fn(started) { Schedule(started.data) })
}

/// Start a scheduler as part of your supervision tree. You should provide a subject to receive
/// the schedule value once your supervisor has started.
///
/// ```gleam
/// let schedule_receiver = process.new_subject()
///
/// let schedule_child_spec = schedule.supervised(scheduler, schedule_receiver)
///
/// // Start your supervision tree...
///
/// let assert Ok(schedule) = process.receive(schedule_receiver, 1000)
///
/// schedule.stop(schedule)
/// ```
pub fn supervised(
  scheduler: Scheduler,
  schedule_receiver: process.Subject(Schedule),
) {
  supervision.worker(fn() {
    use started <- result.try(start_actor(scheduler))
    process.send(schedule_receiver, Schedule(started.data))
    Ok(started)
  })
}

pub fn stop(schedule: Schedule) {
  process.send(schedule.subject, Stop)
}

fn loop(state: State, message: Message) {
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
      process.spawn(fn() {
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
              #("minute", { human_readable_time.1 }.minutes |> int.to_string()),
              #("second", { human_readable_time.1 }.seconds |> int.to_string()),
            ])
            state.job()
          }
          False -> state.job()
        }
      })
      enqueue_job(state.cron, state)
      actor.continue(state)
    }
    Stop -> {
      logging.log(logging.Info, "[CLOCKWORK] Stopping job: " <> state.id)
      actor.stop()
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
