(** Differential Privacy Module *)

type privacy_params = {
  epsilon: float;
  delta: float;
  sensitivity: float;
}

type noise_mechanism = 
  | Laplace
  | Gaussian

type privacy_accountant = {
  total_epsilon: float;
  total_delta: float;
  queries: int;
  mechanism: noise_mechanism;
}

(* Utility functions for noise generation *)
let sample_laplace scale =
  let u = Random.float 1.0 -. 0.5 in
  let sign = if u >= 0.0 then 1.0 else -1.0 in
  -. scale *. sign *. log(1.0 -. 2.0 *. abs_float u)

let sample_gaussian mean std =
  let u1 = Random.float 1.0 in
  let u2 = Random.float 1.0 in
  mean +. std *. sqrt(-2.0 *. log u1) *. cos(2.0 *. Float.pi *. u2)

(* Core privacy operations *)
let create_privacy_params epsilon delta sensitivity =
  { epsilon; delta; sensitivity }

let create_accountant mechanism =
  { total_epsilon = 0.0; total_delta = 0.0; queries = 0; mechanism }

let compute_noise_scale params mechanism =
  match mechanism with
  | Laplace -> params.sensitivity /. params.epsilon
  | Gaussian -> 
      let c = sqrt(2.0 *. log(1.25 /. params.delta)) in
      params.sensitivity *. c /. params.epsilon

let add_noise mechanism params value =
  let scale = compute_noise_scale params mechanism in
  match mechanism with
  | Laplace -> value +. sample_laplace scale
  | Gaussian -> value +. sample_gaussian 0.0 scale

let add_noise_vector mechanism params values =
  Array.map (add_noise mechanism params) values

(* Gradient operations *)
let clip_gradients gradients clip_norm =
  let norm = sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 gradients) in
  if norm > clip_norm then
    Array.map (fun x -> x *. clip_norm /. norm) gradients
  else
    gradients

let sanitize_gradients mechanism params gradients =
  let clipped = clip_gradients gradients params.sensitivity in
  add_noise_vector mechanism params clipped

(* Privacy accounting *)
let compute_privacy_spent accountant =
  match accountant.mechanism with
  | Laplace -> 
      (accountant.total_epsilon, 0.0)  (* Laplace has no delta *)
  | Gaussian ->
      (* Advanced composition theorem *)
      let eps = accountant.total_epsilon *. sqrt(2.0 *. float_of_int accountant.queries *. log(1.0 /. accountant.total_delta)) in
      (eps, accountant.total_delta)

let update_privacy_budget accountant params =
  { accountant with
    total_epsilon = accountant.total_epsilon +. params.epsilon;
    total_delta = accountant.total_delta +. params.delta;
    queries = accountant.queries + 1;
  }

let check_privacy_budget accountant params =
  let eps, delta = compute_privacy_spent accountant in
  eps <= params.epsilon && delta <= params.delta

(* Advanced composition *)
let compute_advanced_composition target_epsilon target_delta num_compositions =
  let epsilon_prime = target_epsilon /. sqrt(2.0 *. float_of_int num_compositions *. log(1.0 /. target_delta)) in
  let delta_prime = target_delta /. float_of_int num_compositions in
  (epsilon_prime, delta_prime)

(* Utility calculations *)
let estimate_l2_sensitivity gradients =
  let max_norm = ref 0.0 in
  Array.iter (fun grad_vector ->
    let norm = sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 grad_vector) in
    max_norm := max !max_norm norm
  ) gradients;
  !max_norm

let compute_optimal_noise_scale params mechanism =
  match mechanism with
  | Laplace -> 
      params.sensitivity *. log(1.0 /. params.delta) /. params.epsilon
  | Gaussian ->
      params.sensitivity *. sqrt(2.0 *. log(1.25 /. params.delta)) /. params.epsilon

let estimate_sample_complexity params target_accuracy =
  let scale = compute_optimal_noise_scale params Gaussian in
  int_of_float (ceil (scale *. scale /. (target_accuracy *. target_accuracy)))
