#! /usr/bin/env elixir

# This script generates .pax files for all the pdfs in this folder

tasks =
  File.ls!()
  |> Enum.filter(&(Path.extname(&1) == ".pdf"))
  |> Enum.map(&Task.async(fn -> System.cmd("pdfannotextractor", [&1]) end))

Task.yield_many(tasks, :infinity)
