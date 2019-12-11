defmodule Pairviz.Pairing do
  def extract_pairs(commit_message, patterns, splitters, name_list \\ nil) do
    pattern =
      if is_list(patterns) do
        patterns
        |> Enum.find(~r//, &Regex.match?(&1, commit_message))
      else
        patterns
      end

    Regex.named_captures(pattern, commit_message)
    |> nil_to_map
    |> Map.fetch("names")
    |> map_error(fn _ -> "name can't be extracted" end) >>>
      fn name_string ->
        names =
          name_string
          |> String.split(splitters)
          |> Enum.map(&String.trim/1)
          |> Enum.filter(fn name ->
            name_list == nil || name_list |> Enum.member?(name)
          end)

        case names do
          [] -> []
          [a] -> [[a, a]]
          ns -> pairs(ns) |> Enum.map(&normalize_pair/1)
        end
      end
  end

  def calculate_pairing_score(commits, patterns, splitters, name_list \\ nil) do
    pairing_by_date =
      commits
      |> Enum.map(fn %{date: date, message: message} ->
        with {:ok, pairs} <- extract_pairs(message, patterns, splitters, name_list) do
          %{date: date, pairs: pairs}
        else
          {:error, err_msg} ->
            IO.puts("""

            Error: #{err_msg}
            > (commit message) #{message}
            """)

            nil
        end
      end)
      |> Enum.filter(fn commit -> commit != nil end)
      |> Enum.group_by(
        fn %{date: date} -> date end,
        fn %{pairs: pairs} -> pairs end
      )

    dates = Map.keys(pairing_by_date)
    coeff = fn date -> decay_coeff(date, Enum.max(dates), Enum.min(dates)) end

    pairing_count =
      pairing_by_date
      |> Enum.map(fn {date, xs} ->
        coeff_val = coeff.(date)

        pairs =
          xs
          |> Enum.reduce([], &(&1 ++ &2))
          |> Enum.uniq()

        pairs |> Enum.map(&{coeff_val, &1})
      end)
      |> Enum.reduce([], &(&1 ++ &2))
      |> Enum.reduce(%{}, fn {coeff, pair}, acc ->
        Map.update(acc, pair, coeff, &(&1 + coeff))
      end)

    total = pairing_count |> Map.values() |> Enum.sum()

    pairing_count
    |> Enum.map(fn {k, v} -> {k, Float.round(v / total, 2)} end)
    |> Enum.into(%{})
  end

  def make_matrix(pairing_scores, transformer \\ fn x -> x end) do
    labels = pairing_scores |> Map.keys() |> List.flatten() |> Enum.uniq() |> Enum.sort()

    matrix =
      labels
      |> Enum.map(fn name_1 ->
        labels
        |> Enum.map(fn name_2 ->
          transformer.(pairing_scores[normalize_pair([name_1, name_2])] || 0)
        end)
      end)

    %{labels: labels, matrix: matrix}
  end

  def decay_coeff(date, date_max, date_min) do
    if Date.compare(date_max, date_min) == :lt do
      raise RuntimeError, message: "max date must be greater than min date"
    end

    if Date.compare(date, date_max) == :gt || Date.compare(date, date_min) == :lt do
      raise RuntimeError, message: "date is out of range"
    end

    Date.diff(date, date_min) / Date.diff(date_max, date_min)
  end

  defp normalize_pair(pair) do
    pair |> Enum.map(&String.capitalize/1) |> Enum.sort()
  end

  # util, to be extracted
  defp nil_to_map(nil), do: %{}
  defp nil_to_map(a), do: a

  defp pairs(list, acc \\ [])
  defp pairs([head | tail], acc), do: pairs(tail, acc ++ Enum.map(tail, &[head, &1]))
  defp pairs([], acc), do: acc

  defp {:ok, res} >>> f, do: {:ok, f.(res)}
  defp {:error, err} >>> _, do: {:error, err}
  defp :error >>> _, do: {:error, nil}

  defp map_error({:error, err}, f), do: {:error, f.(err)}
  defp map_error(:error, f), do: {:error, f.(nil)}
  defp map_error(a, _), do: a
end
