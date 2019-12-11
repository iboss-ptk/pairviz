# Pairviz

Pairing visualization from your git history

## Setup

To set up, you need to have a directory that looks like this:

```
|- repo_1/
|- repo_2/
|- repo_3/
.
.
.
|- repo_n/
|- pairviz.exs
```

And you need to be able to interact with remote repo from your shell since
we are going to reuse your whole .ssh folder.


For pairviz.exs file, it is a configuration file that tells pairviz how to
extract name out of commit message and what are the people you are interested in
since some of them might already left the team and you don't want to visualize
it anymore.

Here is the example of pairviz.exs file:

```elixir
use Mix.Config

pipe_around_name = ~r/^.*\|(?<names>.*)\|.*$/
bracket_around_name = ~r/^.*\[(?<names>.*)\].*$/

config :pairviz, Pairviz.Pairing,
  name_pattern: [pipe_around_name, bracket_around_name],
  name_splitter: ["&", ":"],
  name_list: ["Dave", "Ops", "Sec"]
```

From the example configuration above, if you have commit message like the
following:

```
#123 | Dave:Ops | Trying to do something useful here
#123 | Dave&Ops | Trying to do something useful here
#123 [ Dave:Ops ] Trying to do something useful here
#123 [ Dave&Ops ] Trying to do something useful here
```

It will recognize Dave and Ops as a pair

You can also have more than two person working together as well, it will be
detected and calculate the pairing score accordingly:

```
#123 | Dave:Ops:Sec | Trying to do something useful here
````

But if there is someone who is not in the name_list appears in the commit
message, they will be ignored:

```
#123 | Dave:Ops:Con | Trying to do something useful here
````

The `Con` guy will be ignored.


## How to run

Run via docker:

```sh
docker run \
  -v ~/.ssh:/root/.ssh \ 
  -v "$(pwd)":/workspace/repositories \ 
  -v "$(pwd)"/pairviz.exs:/workspace/config/pairviz.exs \ 
  -p 4000:4000 \
  -it \
  ibosz/pairviz
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

