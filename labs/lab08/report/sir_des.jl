using DrWatson

@quickactivate "lab08"

include(srcdir("sir_model.jl"))

using Random
using StatsPlots
using BenchmarkTools

# Параметры модели
tmax = 40.0
u0 = [990, 10, 0]       # S, I, R
p = [0.05, 10.0, 0.25]  # β, c, γ

# Фиксируем зерно генератора случайных чисел
Random.seed!(1234)

# Запуск модели
des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

# Вывод результатов
println(data_des)

# Визуализация
@df data_des plot(
    :t,
    [:S :I :R],
    labels = ["S" "I" "R"],
    xlab = "Время",
    ylab = "Численность",
    title = "Дискретно-событийная SIR модель"
)

savefig(plotsdir("sir_des.png"))