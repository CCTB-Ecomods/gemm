push!(LOAD_PATH, "../src/")

using Documenter, GeMM

makedocs(sitename="GeMM",
         modules = [GeMM],
         pages = ["index.md",
                  "framework.md",
                  "io.md",
                  "processes.md",
                  "extensions.md"])
