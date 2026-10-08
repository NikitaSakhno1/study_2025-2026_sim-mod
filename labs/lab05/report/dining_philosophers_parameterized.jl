# Параметризованное моделирование обедающих философов

using Random
using DataFrames
using CSV
using Plots

include(joinpath(@__DIR__, "..", "src", "DiningPhilosophers.jl"))
using .DiningPhilosophers

philosophers_set = [3, 4, 5, 6, 7]
tmax = 50.0

results = DataFrame(
    N = Int[],
    classic_deadlock = Bool[],
    arbiter_deadlock = Bool[]
)

for nphilosophers in philosophers_set

    println("Количество философов: ", nphilosophers)

    net_classic = build_classical_network(nphilosophers)

    Random.seed!(123)
    df_classic = simulate_stochastic(net_classic, tmax)

    deadlock_classic = detect_deadlock(
        df_classic,
        net_classic
    )

    net_arbiter = build_arbiter_network(nphilosophers)

    Random.seed!(123)
    df_arbiter = simulate_stochastic(net_arbiter, tmax)

    deadlock_arbiter = detect_deadlock(
        df_arbiter,
        net_arbiter
    )

    push!(
        results,
        (
            nphilosophers,
            deadlock_classic,
            deadlock_arbiter
        )
    )

    println(
        "Классическая сеть: deadlock = ",
        deadlock_classic
    )

    println(
        "Сеть с арбитром: deadlock = ",
        deadlock_arbiter
    )
end

mkpath(joinpath(@__DIR__, "..", "data"))

CSV.write(
    joinpath(
        @__DIR__,
        "..",
        "data",
        "parameterized_results.csv"
    ),
    results
)

println()
println("ИТОГОВЫЕ РЕЗУЛЬТАТЫ")
println(results)

classic_values = Int.(results.classic_deadlock)
arbiter_values = Int.(results.arbiter_deadlock)

plot(
    results.N,
    classic_values,
    marker = :circle,
    label = "Классическая сеть",
    xlabel = "Количество философов N",
    ylabel = "Deadlock (0/1)",
    title = "Зависимость deadlock от количества философов",
    ylim = (-0.1, 1.1)
)

plot!(
    results.N,
    arbiter_values,
    marker = :square,
    label = "Сеть с арбитром"
)

mkpath(joinpath(@__DIR__, "..", "plots"))

savefig(
    joinpath(
        @__DIR__,
        "..",
        "plots",
        "parameterized_results.png"
    )
)

println()
println("Результаты сохранены.")