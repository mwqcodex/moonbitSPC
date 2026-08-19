///|
test "sampling plans produce bounded unique indices" {
  let _ = sampling_plan(
    sampling_method=SimpleRandom,
    population=20,
    requested=5,
    seed=7,
  )
  let _ = sampling_plan(
    sampling_method=Systematic,
    population=20,
    requested=5,
    seed=7,
  )
  let _ = sampling_plan(
    sampling_method=Stratified,
    population=20,
    requested=5,
    seed=7,
  )
  let _ = sampling_plan(
    sampling_method=Cluster,
    population=20,
    requested=5,
    seed=7,
  )
  let random = simple_random_indices(population=20, requested=5, seed=7)
  inspect(random.length(), content="5")
  inspect(valid_indices(random, 20), content="true")
  inspect(has_duplicate_indices(random), content="false")
  let systematic = systematic_indices(population=10, requested=3, offset=1)
  debug_inspect(systematic, content="[1, 4, 7]")
}

///|
test "stratified allocation and sample size are deterministic" {
  let allocation = proportional_allocation([50, 30, 20], total=10)
  inspect(allocation_total(allocation), content="10")
  debug_inspect(allocation, content="[5, 3, 2]")
  inspect(
    required_sample_size(confidence_z=1.96, proportion=0.5, margin=0.05),
    content="385",
  )
  inspect(
    finite_population_sample(
      population=100,
      confidence_z=1.96,
      proportion=0.5,
      margin=0.05,
    ),
    content="79",
  )
}
