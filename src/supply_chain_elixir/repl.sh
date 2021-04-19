#!/usr/bin/env bash

# Development script to start iex with a given node name and agent type

NAME=${1-agent}
export AGENT_TYPE=${2-manufacturer}

iex --sname $NAME -S mix
