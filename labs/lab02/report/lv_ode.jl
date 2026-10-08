# # Модель Лотки–Вольтерры
#
# Модель описывает взаимодействие двух популяций:
#
# - x — жертвы;
# - y — хищники.
#
# Система уравнений:
#
# $$\frac{dx}{dt}=\alpha x-\beta xy$$
#
# $$\frac{dy}{dt}=\delta xy-\gamma y$$

using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots
using Statistics
using FFTW

# ## Функция модели

function lotka_volterra!(du, u, p, t)

    x, y = u
    α, β, δ, γ = p

    @inbounds begin
        du[1] = α * x - β * x * y
        du[2] = δ * x * y - γ * y
    end

    nothing
end

# ## Параметры модели

p_lv = [
    0.1,
    0.02,
    0.01,
    0.3
]

u0_lv = [
    40.0,
    9.0
]

tspan_lv = (
    0.0,
    200.0
)

dt_lv = 0.01

# ## Решение модели

prob_lv = ODEProblem(
    lotka_volterra!,
    u0_lv,
    tspan_lv,
    p_lv
)

sol_lv = solve(
    prob_lv,
    dt = dt_lv,
    Tsit5(),
    reltol = 1e-8,
    abstol = 1e-10,
    saveat = 0.1,
    dense = true
)

# ## Подготовка данных

df_lv = DataFrame()

df_lv[!, :t] =
    sol_lv.t

df_lv[!, :prey] =
    [u[1] for u in sol_lv.u]

df_lv[!, :predator] =
    [u[2] for u in sol_lv.u]

# ## Стационарная точка

x_star =
    p_lv[4] / p_lv[3]

y_star =
    p_lv[1] / p_lv[2]

println("Стационарная точка:")
println("x* = ", x_star)
println("y* = ", y_star)

# ## Динамика популяций

plt1 = plot(
    df_lv.t,
    [df_lv.prey df_lv.predator],
    label = ["Жертвы" "Хищники"],
    xlabel = "Время",
    ylabel = "Численность",
    title = "Модель Лотки–Вольтерры",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

display(plt1)

# ## Фазовый портрет

plt2 = plot(
    df_lv.prey,
    df_lv.predator,
    label = "Фазовая траектория",
    xlabel = "Жертвы",
    ylabel = "Хищники",
    title = "Фазовый портрет",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

display(plt2)

# ## Статистический анализ

println("\n=== АНАЛИЗ ЛОТКИ–ВОЛЬТЕРРЫ ===")

println(
    "Жертвы: min = ",
    round(minimum(df_lv.prey), digits=2),
    ", max = ",
    round(maximum(df_lv.prey), digits=2),
    ", mean = ",
    round(mean(df_lv.prey), digits=2)
)

println(
    "Хищники: min = ",
    round(minimum(df_lv.predator), digits=2),
    ", max = ",
    round(maximum(df_lv.predator), digits=2),
    ", mean = ",
    round(mean(df_lv.predator), digits=2)
)

println("\nЛитературный код Лотки–Вольтерры выполнен успешно.")