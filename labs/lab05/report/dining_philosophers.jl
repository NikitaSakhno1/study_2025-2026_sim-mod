# # Лабораторная работа №5. Аппарат сетей Петри
#
# ## Задача «Обедающие философы»
#
# В работе рассматриваются две модели сети Петри:
# классическая модель без арбитра и модель с арбитром.
# Для обеих моделей выполняется стохастическое моделирование
# и анализируется наличие взаимной блокировки (deadlock).

# ## Подключение модели

include(joinpath(@__DIR__, "..", "src", "DiningPhilosophers.jl"))
using .DiningPhilosophers
using DataFrames
using CSV
using Plots
using Random

# ## Исходные параметры

N = 5
tmax = 50.0

# ## Классическая сеть Петри

# Создаём классическую сеть для пяти философов.

net_classic, u0_classic, names_classic = build_classical_network(N)

# Для воспроизводимости задаём начальное значение генератора случайных чисел.

Random.seed!(123)

# Выполняем стохастическое моделирование классической сети.

df_classic = simulate_stochastic(net_classic, u0_classic, tmax)

# Сохраняем результаты моделирования.

data_dir = joinpath(@__DIR__, "..", "data")
plots_dir = joinpath(@__DIR__, "..", "plots")

mkpath(data_dir)
mkpath(plots_dir)

CSV.write(
    joinpath(data_dir, "dining_classic_literate.csv"),
    df_classic
)

# Проверяем наличие deadlock.

deadlock_classic = detect_deadlock(
    df_classic,
    net_classic
)

println("Классическая сеть: deadlock = ", deadlock_classic)

# ## График классической сети

p_classic = plot(
    df_classic.time,
    Matrix(df_classic[:, names_classic]),
    label = string.(names_classic),
    xlabel = "Время",
    ylabel = "Количество фишек",
    title = "Классическая сеть Петри"
)

savefig(
    p_classic,
    joinpath(plots_dir, "classic_literate.png")
)

# ## Сеть Петри с арбитром

# Создаём модифицированную сеть с арбитром.

net_arbiter, u0_arbiter, names_arbiter =
    build_arbiter_network(N)

# Выполняем стохастическое моделирование.

Random.seed!(123)

df_arbiter = simulate_stochastic(
    net_arbiter,
    u0_arbiter,
    tmax
)

# Сохраняем результаты.

CSV.write(
    joinpath(data_dir, "dining_arbiter_literate.csv"),
    df_arbiter
)

# Проверяем наличие deadlock.

deadlock_arbiter = detect_deadlock(
    df_arbiter,
    net_arbiter
)

println("Сеть с арбитром: deadlock = ", deadlock_arbiter)

# ## График сети с арбитром

p_arbiter = plot(
    df_arbiter.time,
    Matrix(df_arbiter[:, names_arbiter]),
    label = string.(names_arbiter),
    xlabel = "Время",
    ylabel = "Количество фишек",
    title = "Сеть Петри с арбитром"
)

savefig(
    p_arbiter,
    joinpath(plots_dir, "arbiter_literate.png")
)

# ## Сравнение моделей

# Для сравнения рассматриваем состояния Eat_i.
# В классической сети возможна взаимная блокировка,
# в сети с арбитром она должна предотвращаться.

eat_cols = [Symbol("Eat_$i") for i = 1:N]

p1 = plot(
    df_classic.time,
    Matrix(df_classic[:, eat_cols]),
    label = ["Ф$i" for i = 1:N],
    xlabel = "Время",
    ylabel = "Ест (1/0)",
    title = "Классическая сеть"
)

p2 = plot(
    df_arbiter.time,
    Matrix(df_arbiter[:, eat_cols]),
    label = ["Ф$i" for i = 1:N],
    xlabel = "Время",
    ylabel = "Ест (1/0)",
    title = "Сеть с арбитром"
)

p_final = plot(
    p1,
    p2,
    layout = (2, 1),
    size = (800, 600)
)

savefig(
    p_final,
    joinpath(plots_dir, "literate_comparison.png")
)

# ## Результаты

println()
println("=== Результаты моделирования ===")
println("Количество философов: ", N)
println("Время моделирования: ", tmax)
println("Классическая сеть: deadlock = ", deadlock_classic)
println("Сеть с арбитром: deadlock = ", deadlock_arbiter)
println()
println("Графики сохранены в папке plots.")
println("Данные сохранены в папке data.")