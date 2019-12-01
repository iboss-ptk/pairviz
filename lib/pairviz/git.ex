defmodule Pairviz.Git do
  def repos(path \\ ".") do
    File.ls!(path) |> Enum.filter(fn d -> File.exists?("#{d}/.git") end)
  end

  def pull(repo) do
    with {res, 0} <- System.cmd("git", ["pull", "--force"], cd: repo, stderr_to_stdout: true) do
      {:ok, "[✔] #{repo}"}
    else
      {res, code} ->
        {:error,
         """
         [✘] #{repo}
         exit code #{code}:

         #{res}
         """}

      any ->
        {:error, "unknown error: #{any}"}
    end
  end

  def log(repo) do
    {commits, 0} = System.cmd("git", ["log", "--pretty=format:%ci | %s"], cd: repo)

    commits
    |> String.split("\n")
    |> Enum.map(fn commit ->
      [date | _] = String.split(commit)
      [_, message] = String.split(commit, " | ", parts: 2)
      %{date: Date.from_iso8601!(date), message: message}
    end)
  end
end
