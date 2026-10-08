using Literate

source = joinpath(@__DIR__, "..", "literate", "sirpetri.jl")

mkpath(joinpath(@__DIR__, "generated"))
mkpath(joinpath(@__DIR__, "..", "notebooks"))
mkpath(joinpath(@__DIR__, "..", "docs"))

Literate.script(
    source,
    joinpath(@__DIR__, "generated")
)

Literate.notebook(
    source,
    joinpath(@__DIR__, "..", "notebooks")
)

Literate.markdown(
    source,
    joinpath(@__DIR__, "..", "docs")
)

println("Генерация завершена.")