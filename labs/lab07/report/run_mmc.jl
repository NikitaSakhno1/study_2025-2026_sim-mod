using DrWatson
@quickactivate "lab07"

using DataFrames
using CSV
using Statistics
using Plots

include(srcdir("mmc.jl"))

mkpath(datadir("processed"))
mkpath(plotsdir())

# Параметры модели
num_customers = 1000
num_servers = 2
lambda = 0.9
mu = 0.5
seed = 123

# Запуск
results = simulate_mmc(
    num_customers = num_customers,
    num_servers = num_servers,
    lambda = lambda,
    mu = mu,
    seed = seed
)

# Основные показатели
println("M/M/c")
println("======================")
println("Заявок: ", nrow(results))
println("Каналов: ", num_servers)
println("λ = ", lambda)
println("μ = ", mu)
println("Среднее ожидание: ", mean(results.waiting_time))
println("Среднее время обслуживания: ", mean(results.service_time))
println("Среднее время в системе: ", mean(results.system_time))

rho = lambda / (num_servers * mu)

println("Загрузка системы ρ = ", rho)

# Сохранение данных
CSV.write(
    datadir("processed", "mmc_results.csv"),
    results
)

# График времени ожидания
p1 = plot(
    results.id,
    results.waiting_time,
    xlabel = "Номер заявки",
    ylabel = "Время ожидания",
    title = "Время ожидания заявок",
    legend = false
)

savefig(p1, plotsdir("mmc_waiting_time.png"))

# График времени в системе
p2 = plot(
    results.id,
    results.system_time,
    xlabel = "Номер заявки",
    ylabel = "Время в системе",
    title = "Время пребывания заявок в системе",
    legend = false
)

savefig(p2, plotsdir("mmc_system_time.png"))

println()
println("Результаты сохранены:")
println(datadir("processed", "mmc_results.csv"))
println(plotsdir("mmc_waiting_time.png"))
println(plotsdir("mmc_system_time.png"))