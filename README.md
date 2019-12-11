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

To run via docker:

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

