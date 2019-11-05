defmodule Pairviz.Pairing do
  def extract_pair(commit_message, pattern, splitter) do
    Regex.named_captures(pattern, commit_message)
    |> nil_to_map
    |> Map.fetch("names")
    |> map_error(fn _ -> "name can't be found" end) >>>
      (&String.split(&1, splitter))
  end

  # util, to be extracted
  defp nil_to_map(nil), do: %{}
  defp nil_to_map(a), do: a

  defp {:ok, res} >>> f, do: {:ok, f.(res)}
  defp {:error, err} >>> _, do: {:error, err}
  defp :error >>> _, do: {:error, nil}

  # defp map({:ok, res}, f), do: {:ok, f.(res)}
  # defp map(a, _), do: a

  defp map_error({:error, err}, f), do: {:error, f.(err)}
  defp map_error(:error, f), do: {:error, f.(nil)}
  defp map_error(a, _), do: a
end
