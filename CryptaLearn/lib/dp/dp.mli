(** Differential Privacy Functions *)

type privacy_params = {
  epsilon: float;
  delta: float;
  sensitivity: float;
}

val create_privacy_params : float -> float -> float -> privacy_params
val add_laplace_noise : privacy_params -> float -> float
val clip_gradients : float array -> float -> float array
val compute_privacy_spent : privacy_params -> int -> float * float
