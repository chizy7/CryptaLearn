(** Simple Differential Privacy Module *)

type privacy_params = {
  epsilon: float;
  delta: float;
  sensitivity: float;
}

let create_privacy_params epsilon delta sensitivity =
  {epsilon; delta; sensitivity}

(* Generate Laplace noise *)
let sample_laplace scale =
  let u = Random.float 1.0 -. 0.5 in
  let sign = if u >= 0.0 then 1.0 else -1.0 in
  -. scale *. sign *. log(1.0 -. 2.0 *. abs_float u)

let add_laplace_noise params value =
  let scale = params.sensitivity /. params.epsilon in
  value +. sample_laplace scale

(* Clip gradients to bound L2 sensitivity *)
let clip_gradients gradients clip_norm =
  let norm = sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 gradients) in
  if norm > clip_norm then
    Array.map (fun x -> x *. clip_norm /. norm) gradients
  else
    gradients

(* Compute privacy spent using moment accountant (simplified) *)
let compute_privacy_spent params num_iterations =
  (* For now I will use a simplified privacy account
     TODO: Will change to use the moment account method. *)
  let effective_epsilon = params.epsilon *. sqrt(2.0 *. float_of_int num_iterations *. log(1.0 /. params.delta)) in
  let effective_delta = params.delta in
  (effective_epsilon, effective_delta)
