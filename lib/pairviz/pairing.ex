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
          ns -> ns |> pairs
        end
      end
  end

  # util, to be extracted
  defp nil_to_map(nil), do: %{}
  defp nil_to_map(a), do: a

  defp pairs([]), do: []
  defp pairs([head | tail]), do: Enum.map(tail, &[head, &1]) ++ pairs(tail)

  defp {:ok, res} >>> f, do: {:ok, f.(res)}
  defp {:error, err} >>> _, do: {:error, err}
  defp :error >>> _, do: {:error, nil}

  # defp map({:ok, res}, f), do: {:ok, f.(res)}
  # defp map(a, _), do: a  

  defp map_error({:error, err}, f), do: {:error, f.(err)}
  defp map_error(:error, f), do: {:error, f.(nil)}
  defp map_error(a, _), do: a
end
