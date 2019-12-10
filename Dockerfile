FROM elixir:1.9-alpine

WORKDIR /workspace

RUN apk add --update --no-cache \
    git \
    openssh \
    nodejs

RUN mix local.hex --force

COPY . /workspace

CMD ["sh", "./entrypoint.sh"]
