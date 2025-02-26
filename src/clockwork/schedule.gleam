import clockwork
import gleam/erlang/process
import gleam/float
import gleam/function
import gleam/otp/actor
import gleam/result
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import logging

pub type Schedule {
  Schedule(subject: process.Subject(Message))
}

pub type Message {
  Run
  Stop
}

pub type State {
  State(
    id: String,
    self: process.Subject(Message),
    cron: clockwork.Cron,
    job: fn() -> Nil,
  )
}

pub fn start(
  name: String,
  with cron: clockwork.Cron,
  do job: fn() -> Nil,
) -> Result(Schedule, actor.StartError) {
  logging.configure()
  actor.start_spec(actor.Spec(
    init: fn() { init(cron, job, name) },
    loop: loop,
    init_timeout: 100,
  ))
  |> result.map(Schedule)
}

pub fn stop(schedule: Schedule) {
  process.send(schedule.subject, Stop)
}

fn init(cron, job, name) {
  let subject = process.new_subject()
  let state = State(name, subject, cron, job)

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
        |> timestamp.to_unix_seconds
        |> float.to_string(),
      )
      process.start(fn() { state.job() }, True)
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
    clockwork.next_occurrence(cron, now)
    |> timestamp.difference(now, _)
    |> duration.to_seconds_and_nanoseconds
    |> fn(tuple) {
      let #(seconds, nanoseconds) = tuple
      seconds * 1000 + nanoseconds / 1_000_000
    }
  timestamp.system_time()
  |> timestamp.to_calendar(calendar.local_offset())

  process.send_after(state.self, next_occurrence, Run)
}
