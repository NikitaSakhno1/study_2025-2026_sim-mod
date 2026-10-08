using Random
using StableRNGs
using Distributions
using DataFrames
using ConcurrentSim
using ResumableFunctions


# ============================================================
# Модель одной машины
# ============================================================

@resumable function ross_machine(
    env::Environment,
    repair_facility::Resource,
    spares::Store,
    failure_dist::Distribution,
    repair_dist::Distribution,
    machine_id::Int,
    state_log::Vector{NamedTuple}
)

    while true

        # Машина работает до отказа
        failure_time = rand(failure_dist)

        @yield timeout(env, failure_time)

        # Машина вышла из строя
        push!(
            state_log,
            (
                time = now(env),
                event = "failure",
                machine_id = machine_id,
                healthy = 0,
                queue = length(repair_facility.queue),
                repaired = 0
            )
        )

        # Проверяем наличие резервной машины
        if isempty(spares.store)

            # Резерв закончился — система падает
            throw(StopSimulation("No more spares"))

        end

        # Берём резервную машину
        spare = take!(spares)

        # Заявка на ремонт
        @yield request(repair_facility)

        # Машина начала ремонт
        push!(
            state_log,
            (
                time = now(env),
                event = "repair_start",
                machine_id = machine_id,
                healthy = 0,
                queue = length(repair_facility.queue),
                repaired = 0
            )
        )

        # Ремонт
        repair_time = rand(repair_dist)

        @yield timeout(env, repair_time)

        # Ремонт завершён
        @yield unlock(repair_facility)

        push!(
            state_log,
            (
                time = now(env),
                event = "repair_end",
                machine_id = machine_id,
                healthy = 1,
                queue = length(repair_facility.queue),
                repaired = 1
            )
        )

        # Возвращаем машину в резерв
        @yield put!(spares, spare)
    end
end


# ============================================================
# Запуск модели Росса
# ============================================================

function simulate_ross(;
    N::Int = 10,
    S::Int = 3,
    num_repairers::Int = 1,
    mean_failure_time::Float64 = 100.0,
    mean_repair_time::Float64 = 1.0,
    seed::Int = 42
)

    # Генератор случайных чисел
    rng = StableRNG(seed)

    # Распределения
    failure_dist = Exponential(mean_failure_time)
    repair_dist = Exponential(mean_repair_time)

    # Среда моделирования
    sim = Simulation()

    # Несколько ремонтников
    repair_facility = Resource(sim, num_repairers)

    # Хранилище резервных машин
    spares = Store{Process}(sim, capacity = S)

    # История событий
    state_log = NamedTuple[]

    # --------------------------------------------------------
    # Создаём основные машины
    # --------------------------------------------------------

    machines = Process[]

    for i in 1:N

        proc = @process ross_machine(
            sim,
            repair_facility,
            spares,
            failure_dist,
            repair_dist,
            i,
            state_log
        )

        push!(machines, proc)
    end

    # --------------------------------------------------------
    # Создаём резервные машины
    # --------------------------------------------------------

    for i in 1:S

        proc = @process ross_machine(
            sim,
            repair_facility,
            spares,
            failure_dist,
            repair_dist,
            N + i,
            state_log
        )

        put!(spares, proc)
    end

    # --------------------------------------------------------
    # Запуск
    # --------------------------------------------------------

    crash_time = 0.0
    crash_message = ""

    try

        run(sim)

        crash_time = now(sim)
        crash_message = "Simulation finished"

    catch e

        crash_time = now(sim)
        crash_message = string(e)
    end

    # --------------------------------------------------------
    # История
    # --------------------------------------------------------

    if isempty(state_log)

        history = DataFrame(
            time = Float64[],
            event = String[],
            machine_id = Int[],
            healthy = Int[],
            queue = Int[],
            repaired = Int[]
        )

    else

        history = DataFrame(state_log)

    end

    return (
        crash_time = crash_time,
        message = crash_message,
        history = history
    )
end