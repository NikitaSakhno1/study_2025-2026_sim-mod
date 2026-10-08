using DrWatson

@quickactivate "lab07"

using DataFrames
using CSV
using Statistics
using Plots

include(srcdir("ross.jl"))


# ============================================================
# Параметры
# ============================================================

N = 10
S = 3

num_repairers = 1

mean_failure_time = 100.0
mean_repair_time = 1.0

runs = 30


# ============================================================
# Папки
# ============================================================

mkpath(datadir("processed"))
mkpath(plotsdir())


# ============================================================
# Серия запусков
# ============================================================

crash_times = Float64[]

all_history = DataFrame(
    time = Float64[],
    event = String[],
    machine_id = Int[],
    healthy = Int[],
    queue = Int[],
    repaired = Int[],
    run = Int[]
)


for run_id in 1:runs

    result = simulate_ross(
        N = N,
        S = S,
        num_repairers = num_repairers,
        mean_failure_time = mean_failure_time,
        mean_repair_time = mean_repair_time,
        seed = 1000 + run_id
    )

    push!(crash_times, result.crash_time)

    history = result.history

    if nrow(history) > 0

        history.run = fill(run_id, nrow(history))

        append!(
            all_history,
            history
        )

    end

end


# ============================================================
# Результаты
# ============================================================

mean_crash_time = mean(crash_times)
std_crash_time = std(crash_times)

println()
println("======================================")
println("МОДЕЛЬ РОССА")
println("======================================")
println("Основных машин:       ", N)
println("Резервных машин:      ", S)
println("Ремонтников:          ", num_repairers)
println("Количество прогонов:  ", runs)
println("--------------------------------------")
println("Среднее время до отказа: ", mean_crash_time)
println("Стандартное отклонение:   ", std_crash_time)
println("Минимальное время:        ", minimum(crash_times))
println("Максимальное время:       ", maximum(crash_times))
println("======================================")
println()


# ============================================================
# Таблица результатов
# ============================================================

results = DataFrame(
    N = fill(N, runs),
    S = fill(S, runs),
    repairers = fill(num_repairers, runs),
    run = 1:runs,
    crash_time = crash_times
)


CSV.write(
    datadir("processed", "ross_results.csv"),
    results
)


# ============================================================
# Сохраняем историю
# ============================================================

CSV.write(
    datadir("processed", "ross_history.csv"),
    all_history
)


# ============================================================
# График числа исправных машин
# ============================================================

if nrow(all_history) > 0

    first_run = filter(
        :run => ==(1),
        all_history
    )

    if nrow(first_run) > 0

        # Сортируем события по времени
        sort!(
            first_run,
            :time
        )

        # Количество исправных машин.
        # При старте системы исправны N основных машин.
        healthy_count = fill(
            N,
            nrow(first_run)
        )

        current_healthy = N

        for i in 1:nrow(first_run)

            if first_run.event[i] == "failure"

                current_healthy -= 1

            elseif first_run.event[i] == "repair_end"

                current_healthy += 1

            end

            healthy_count[i] = current_healthy
        end

        p = plot(
            first_run.time,
            healthy_count,
            marker = :circle,
            xlabel = "Время",
            ylabel = "Число исправных машин",
            title = "Изменение числа исправных машин",
            legend = false
        )

        savefig(
            p,
            plotsdir("ross_healthy_machines.png")
        )

    end
end


# ============================================================
# График времени до отказа по прогонам
# ============================================================

p2 = plot(
    1:runs,
    crash_times,
    marker = :circle,
    xlabel = "Номер прогона",
    ylabel = "Время до отказа",
    title = "Время до падения системы",
    legend = false
)

savefig(
    p2,
    plotsdir("ross_crash_times.png")
)


println("Файлы сохранены:")
println(datadir("processed", "ross_results.csv"))
println(datadir("processed", "ross_history.csv"))
println(plotsdir("ross_healthy_machines.png"))
println(plotsdir("ross_crash_times.png"))