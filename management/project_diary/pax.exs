# This script generates .pax files for all the pdfs in this folder

tasks =
  File.ls!()
  |> Enum.filter(fn f -> f =~ ~r".*\.pdf$" end)
  |> Enum.map(&Task.async(fn -> System.cmd("pdfannotextractor", [&1]) end))

Task.yield_many(tasks, :infinity)
