use Mix.Config

pipe_around_name = ~r/^.*\|(?<names>.*)\|.*$/
bracket_around_name = ~r/^.*\[(?<names>.*)\].*$/

config :pairviz, Pairviz.Pairing,
  name_pattern: [pipe_around_name, bracket_around_name],
  name_splitter: [":", "&"]
