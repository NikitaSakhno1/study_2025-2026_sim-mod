# # Модель SIR
#
# Модель SIR описывает распространение инфекционного заболевания
# в закрытой популяции.
#
# Популяция разделяется на три группы:
#
# - S — восприимчивые;
# - I — инфицированные;
# - R — выздоровевшие.
#
# Основные уравнения модели:
#
# $$\frac{dS}{dt}=-\beta c\frac{SI}{N}$$
#
# $$\frac{dI}{dt}=\beta c\frac{SI}{N}-\gamma I$$
#
# $$\frac{dR}{dt}=\gamma I$$

using DrWatson
@quickactivate "project"

using DifferentialEquations
using SimpleDiffEq
using Tables
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots
using BenchmarkTools

# ## Функция модели SIR

function sir_ode!(du, u, p, t)
    (S, I, R) = u
    (β, c, γ) = p
    N = S + I + R

    @inbounds begin
        du[1] = -β * c * I / N * S
        du[2] = β * c * I / N * S - γ * I
        du[3] = γ * I
    end

    nothing
end

# ## Параметры модели

δt = 0.1
tmax = 40.0
tspan = (0.0, tmax)

u0 = [990.0, 10.0, 0.0]

p = [0.05, 10.0, 0.25]

# Базовое репродуктивное число

R0 = (p[2] * p[1]) / p[3]

println("Параметры модели SIR:")
println("β = ", p[1])
println("c = ", p[2])
println("γ = ", p[3])
println("R0 = ", round(R0, digits=3))
println("Средняя продолжительность болезни = ",
        round(1 / p[3], digits=2), " дней")

println(
    "Начальные условия: S0 = ",
    u0[1],
    ", I0 = ",
    u0[2],
    ", R0 = ",
    u0[3]
)

# ## Решение дифференциального уравнения

prob_ode = ODEProblem(
    sir_ode!,
    u0,
    tspan,
    p
)

sol_ode = solve(
    prob_ode,
    dt = δt
)

# ## Подготовка результатов

df_ode = DataFrame(
    Tables.table(sol_ode')
)

rename!(
    df_ode,
    ["S", "I", "R"]
)

df_ode[!, :t] = sol_ode.t

df_ode[!, :N] =
    df_ode.S +
    df_ode.I +
    df_ode.R

# ## Основной график

plt1 = @df df_ode plot(
    :t,
    [:S :I :R],
    label = [L"S(t)" L"I(t)" L"R(t)"],
    xlabel = "Время, дни",
    ylabel = "Количество людей",
    title = "Модель SIR: динамика эпидемии",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

display(plt1)

# ## График инфицированных

plt2 = @df df_ode plot(
    :t,
    :I,
    label = L"I(t)",
    xlabel = "Время, дни",
    ylabel = "Количество инфицированных",
    title = "Динамика числа зараженных",
    linewidth = 2,
    grid = true,
    size = (800, 400)
)

peak_idx = argmax(df_ode.I)

peak_time =
    df_ode.t[peak_idx]

peak_value =
    df_ode.I[peak_idx]

println(
    "\nПик заражения: ",
    round(peak_value, digits=2),
    " человек"
)

println(
    "Время пика: ",
    round(peak_time, digits=2),
    " дней"
)

display(plt2)

# ## Доля населения

plt3 = @df df_ode plot(
    :t,
    [:S :I :R] ./ df_ode.N .* 100,
    label = [L"S/N" L"I/N" L"R/N"],
    xlabel = "Время, дни",
    ylabel = "Доля населения, %",
    title = "Динамика долей населения",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

display(plt3)

# ## Эффективное репродуктивное число

df_ode[!, :Re] =
    R0 .* df_ode.S ./ df_ode.N

plt4 = @df df_ode plot(
    :t,
    :Re,
    label = L"R_e(t)",
    xlabel = "Время, дни",
    ylabel = "Rₑ",
    title = "Эффективное репродуктивное число",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

hline!(
    plt4,
    [1.0],
    linestyle = :dash,
    label = "Rₑ = 1"
)

display(plt4)

# ## Фазовый портрет

plt5 = plot(
    df_ode.S,
    df_ode.I,
    xlabel = L"S",
    ylabel = L"I",
    title = "Фазовый портрет SIR",
    label = "Фазовая траектория",
    linewidth = 2,
    grid = true,
    size = (800, 500)
)

display(plt5)

# ## Анализ результатов

println("\n=== АНАЛИЗ РЕЗУЛЬТАТОВ ===")

println(
    "Общая численность населения N = ",
    round(df_ode.N[1], digits=1)
)

println(
    "Пиковое число зараженных I_max = ",
    round(peak_value, digits=1)
)

println(
    "Время достижения пика = ",
    round(peak_time, digits=1),
    " дней"
)

println(
    "Итоговое число переболевших R(∞) = ",
    round(df_ode.R[end], digits=1)
)

println(
    "Доля переболевших = ",
    round(
        df_ode.R[end] / df_ode.N[1] * 100,
        digits=1
    ),
    "%"
)

if R0 > 1

    println(
        "Порог коллективного иммунитета = ",
        round(
            (1 - 1 / R0) * 100,
            digits=1
        ),
        "%"
    )

    println(
        "Теоретический пик при S/N = ",
        round(1 / R0, digits=3)
    )
end

println("\nЛитературный SIR-код выполнен успешно.")