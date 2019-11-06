defmodule Pairviz.Pairing do
  def extract_pairs(commit_message, pattern, splitter) do
    Regex.named_captures(pattern, commit_message)
    |> nil_to_map
    |> Map.fetch("names")
    |> map_error(fn _ -> "name can't be found" end) >>>
      fn name_string ->
        names =
          name_string
          |> String.split(splitter)
          |> Enum.map(&String.trim/1)

        case names do
          [] -> []
          [a] -> [[a, a]]
          ns -> pairs(ns)
        end
      end
  end

  def calculate_pairing_score(commits) do
    commits
    |> Enum.map(fn %{date: date, message: message} ->
      {:ok, pairs} = extract_pairs(message, ~r/^.*\| (?<names>.*) \|.*$/, ["&", ":"])
      %{date: date, pairs: pairs}
    end)
    |> Enum.group_by(
      fn %{date: date} -> date end,
      fn %{pairs: pairs} ->
        pairs
        |> Enum.reduce([], &(&1 ++ &2))
      end
    )
    # uniq pairs per day
    |> Map.values()
    |> Enum.map(&Enum.uniq/1)
    |> Enum.reduce([], &(&1 ++ &2))
    |> Enum.map(&List.flatten/1)
    |> Enum.reduce(%{}, fn pair, acc ->
      Map.update(acc, pair, 1, &(&1 + 1))
    end)
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

  # defp map({:ok, res}, f), do: {:ok, f.(res)}
  # defp map(a, _), do: a  

  defp map_error({:error, err}, f), do: {:error, f.(err)}
  defp map_error(:error, f), do: {:error, f.(nil)}
  defp map_error(a, _), do: a
end
