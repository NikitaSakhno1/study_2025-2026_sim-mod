using DrWatson
@quickactivate "lab07"

using DataFrames
using CSV
using Statistics
using Plots

include(srcdir("ross.jl"))

mkpath(datadir("processed"))
mkpath(plotsdir())

# Параметры эксперимента
N_values = [5, 10, 15, 20]
repairer_values = [1, 2, 3]

S = 3
runs = 30

results = DataFrame(
    N = Int[],
    S = Int[],
    repairers = Int[],
    mean_crash_time = Float64[],
    std_crash_time = Float64[]
)

for N in N_values

    for repairers in repairer_values

        crash_times = Float64[]

        for run_id in 1:runs

            result = simulate_ross(
                N = N,
                S = S,
                num_repairers = repairers,
                mean_failure_time = 100.0,
                mean_repair_time = 1.0,
                seed = 10000 + N * 100 + repairers * 10 + run_id
            )

            push!(
                crash_times,
                result.crash_time
            )
        end

        mean_time = mean(crash_times)
        std_time = std(crash_times)

        push!(
            results,
            (
                N,
                S,
                repairers,
                mean_time,
                std_time
            )
        )

        println(
            "N = ", N,
            ", ремонтников = ", repairers,
            ", среднее время до отказа = ",
            mean_time
        )
    end
end

# Сохраняем результаты
CSV.write(
    datadir("processed", "ross_experiments.csv"),
    results
)

# Показываем таблицу
println()
println("======================================")
println("РЕЗУЛЬТАТЫ ЭКСПЕРИМЕНТОВ")
println("======================================")
println(results)

# ------------------------------------------------------------
# График: количество ремонтников
# ------------------------------------------------------------

for N in N_values

    subset = filter(
        :N => ==(N),
        results
    )

    p = plot(
        subset.repairers,
        subset.mean_crash_time,
        marker = :circle,
        xlabel = "Количество ремонтников",
        ylabel = "Среднее время до отказа",
        title = "N = $N",
        legend = false
    )

    savefig(
        p,
        plotsdir("ross_N_$(N)_repairers.png")
    )
end

# ------------------------------------------------------------
# График: количество машин
# ------------------------------------------------------------

for repairers in repairer_values

    subset = filter(
        :repairers => ==(repairers),
        results
    )

    p = plot(
        subset.N,
        subset.mean_crash_time,
        marker = :circle,
        xlabel = "Количество основных машин",
        ylabel = "Среднее время до отказа",
        title = "Ремонтников = $repairers",
        legend = false
    )

    savefig(
        p,
        plotsdir("ross_repairers_$(repairers)_N.png")
    )
end

println()
println("Эксперименты завершены.")
println("CSV: ", datadir("processed", "ross_experiments.csv"))
println("Графики: ", plotsdir())