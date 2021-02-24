# This script generates .pax files for all the pdfs in this folder
command = fn x -> System.cmd("pdfannotextractor", [x]) end

tasks =
  File.ls!()
  |> Enum.filter(fn f -> f =~ ~r".*\.pdf$" end)
  |> Enum.map(fn f -> Task.async(fn -> command.(f) end) end)

Task.yield_many(tasks, :infinity)
