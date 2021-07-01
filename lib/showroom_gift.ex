defmodule ShowroomGift do
  @moduledoc """
  Documentation for `ShowroomGift`.
  """
  require Logger

  alias ShowroomGift.ShowroomClient

  @telemetry_event_id "finch-timings"

  def submit_gift(live_id, gift_id, size, turns, csrf_token) do
    {:ok, http_timings_agent} = Agent.start_link(fn -> [] end)
    start_time = System.monotonic_time
    attach_telemetry_event(http_timings_agent)

    payload = %{"gift_id" => gift_id, "size" => size, "live_id" => live_id, "csrf_token" => csrf_token}
    Enum.each(0..turns-1, fn _ ->
      ShowroomClient.submit_gift(payload)
      |> IO.inspect

      :timer.sleep(1000)
    end)

    average_time = average_req_time(http_timings_agent)
    total_time = System.convert_time_unit(System.monotonic_time - start_time, :native, :millisecond)

    :ok = Agent.stop(http_timings_agent)
    :ok = :telemetry.detach(@telemetry_event_id)

    IO.puts("Average request time: #{average_time}ms")
    IO.puts("Total time: #{total_time}ms")
  end

  defp attach_telemetry_event(http_timings_agent) do
    :telemetry.attach(
      @telemetry_event_id,
      [:finch, :response, :stop],
      fn _event, %{duration: duration}, _metadata, _config ->
        Agent.update(http_timings_agent, fn timings -> [duration | timings] end)
      end,
      nil
    )
  end

  defp average_req_time(http_timings_agent) do
    http_timings_agent
    |> Agent.get(fn timings -> timings end)
    |> Enum.reduce({0, 0}, fn timing, {sum, count} ->
      {sum + timing, count + 1}
    end)
    |> case do
      {_, 0} ->
        "0"

      {sum, count} ->
        sum
        |> System.convert_time_unit(:native, :millisecond)
        |> Kernel./(count)
        |> :erlang.float_to_binary(decimals: 2)
    end
  end
end
