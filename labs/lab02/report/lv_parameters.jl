# # Анализ чувствительности модели Лотки–Вольтерры
#
# Исследуется влияние двух параметров:
#
# - α — скорости размножения жертв;
# - γ — смертности хищников.

using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using Plots

function lotka_volterra!(du, u, p, t)

    x, y = u
    α, β, δ, γ = p

    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y

    nothing
end

# ## Исходные параметры

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

# ## Функция анализа чувствительности

function analyze_parameter_sensitivity(
    param_index,
    values,
    param_name
)

    println(
        "\nАнализ чувствительности к параметру: ",
        param_name
    )

    results = DataFrame(
        parameter = Float64[],
        prey = Float64[],
        predator = Float64[]
    )

    for val in values

        p_test = copy(p_lv)

        p_test[param_index] = val

        prob_test = ODEProblem(
            lotka_volterra!,
            u0_lv,
            tspan_lv,
            p_test
        )

        sol_test =
            solve(
                prob_test,
                dt = dt_lv
            )

        prey_end =
            sol_test.u[end][1]

        predator_end =
            sol_test.u[end][2]

        push!(
            results,
            (
                val,
                prey_end,
                predator_end
            )
        )

        println(
            param_name,
            " = ",
            val,
            ": жертвы = ",
            round(prey_end, digits=2),
            ", хищники = ",
            round(predator_end, digits=2)
        )
    end

    return results
end

# ## Исследование параметра α

println("\n" * "="^60)
println("Влияние параметра α")
println("="^60)

results_alpha =
    analyze_parameter_sensitivity(
        1,
        [0.05, 0.1, 0.2, 0.3],
        "α"
    )

# ## Исследование параметра γ

println("\n" * "="^60)
println("Влияние параметра γ")
println("="^60)

results_gamma =
    analyze_parameter_sensitivity(
        4,
        [0.1, 0.3, 0.5, 0.7],
        "γ"
    )

# ## Результаты

println("\nРезультаты для α:")
println(results_alpha)

println("\nРезультаты для γ:")
println(results_gamma)

println(
    "\nПараметрический анализ завершён успешно."
)