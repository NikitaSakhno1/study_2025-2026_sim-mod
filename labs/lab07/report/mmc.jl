using Random
using StableRNGs
using Distributions
using DataFrames
using ConcurrentSim
using ResumableFunctions


# Поведение одной заявки
@resumable function mmc_customer(
    env::Environment,
    server::Resource,
    id::Int,
    arrival_time::Float64,
    service_dist::Distribution,
    arrivals::Vector{Float64},
    starts::Vector{Float64},
    finishes::Vector{Float64},
    waits::Vector{Float64},
    services::Vector{Float64}
)

    # Ожидание до момента прибытия
    @yield timeout(env, arrival_time)

    t_arrival = now(env)
    push!(arrivals, t_arrival)

    # Запрос канала обслуживания
    t_request = now(env)
    @yield request(server)

    # Начало обслуживания
    t_start = now(env)

    push!(starts, t_start)
    push!(waits, t_start - t_request)

    # Время обслуживания
    service_time = rand(service_dist)
    push!(services, service_time)

    @yield timeout(env, service_time)

    # Окончание обслуживания
    t_finish = now(env)
    push!(finishes, t_finish)

    # Освобождение канала
    @yield unlock(server)
end


# Модель M/M/c
function simulate_mmc(;
    num_customers::Int = 1000,
    num_servers::Int = 2,
    lambda::Float64 = 0.9,
    mu::Float64 = 0.5,
    seed::Int = 123
)

    rng = StableRNG(seed)

    arrival_dist = Exponential(1 / lambda)
    service_dist = Exponential(1 / mu)

    # Массивы для статистики
    arrivals = Float64[]
    starts = Float64[]
    finishes = Float64[]
    waits = Float64[]
    services = Float64[]

    # Среда моделирования
    sim = Simulation()

    # c одинаковых каналов
    server = Resource(sim, num_servers)

    # Генерируем заявки
    arrival_time = 0.0

    for id in 1:num_customers

        arrival_time += rand(rng, arrival_dist)

        @process mmc_customer(
            sim,
            server,
            id,
            arrival_time,
            service_dist,
            arrivals,
            starts,
            finishes,
            waits,
            services
        )
    end

    # Запуск моделирования
    run(sim)

    # Формируем таблицу результатов
    results = DataFrame(
        id = 1:length(arrivals),
        arrival_time = arrivals,
        service_start = starts,
        service_end = finishes,
        waiting_time = waits,
        service_time = services,
        system_time = finishes .- arrivals
    )

    return results
end