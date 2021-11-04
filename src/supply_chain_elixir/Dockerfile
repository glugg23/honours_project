FROM elixir:1.12.3

WORKDIR /supply_chain

ENV MIX_ENV=prod

RUN mix local.hex --force

COPY mix.exs .
COPY mix.lock .

RUN mix deps.get --only=prod
RUN mix deps.compile

COPY . .

ARG EXPERIMENT

RUN mix release

ENTRYPOINT ["_build/prod/rel/supply_chain/bin/supply_chain"]
CMD ["start"]
