defmodule Chaperon.Export.JSON do
  @moduledoc """
  JSON metrics export module.
  """

  @columns [
    :total_count, :max, :mean, :median, :min, :stddev,
    {:percentile, 75}, {:percentile, 90}, {:percentile, 95}, {:percentile, 99},
    {:percentile, 999}, {:percentile, 9999}, {:percentile, 99999}
  ]

  @doc """
  Encodes metrics of given `session` into JSON format.
  """
  def encode(session, _opts \\ []) do
    session.metrics
    |> Enum.map(fn
      {[:duration, :call, func], vals} ->
        %{action: :call, function: func, metrics: metrics(vals)}
      {[:duration, action, url], vals} ->
        %{action: action, url: url, metrics: metrics(vals)}
      {[:duration, action], vals} ->
        %{action: action, metrics: metrics(vals)}
    end)
    |> Poison.encode!
  end

  def metrics([]), do: %{}

  def metrics([v | vals]) do
    Map.merge(metrics(v), metrics(vals))
  end

  def metrics(vals) when is_map(vals) do
    metrics =
      vals
      |> Map.take(@columns)
      |> Enum.map(fn
        {{:percentile, p}, val} ->
          {"percentile_#{p}", round(val)}
        {k, v} ->
          {k, round(v)}
      end)
      |> Enum.into(%{})

    %{vals[:session_name] => metrics}
  end
end
