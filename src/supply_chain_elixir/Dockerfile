FROM elixir:latest

WORKDIR /supply_chain

ENV MIX_ENV=prod

RUN mix local.hex --force

COPY mix.exs .
COPY mix.lock .

RUN mix deps.get --only=prod
RUN mix deps.compile

COPY . .

RUN mix release

ENTRYPOINT ["_build/prod/rel/supply_chain/bin/supply_chain"]
CMD ["start"]
