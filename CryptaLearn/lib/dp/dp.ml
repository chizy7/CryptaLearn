(** Simple Differential Privacy Module *)

let add_noise x =
  let noise = (Random.float 2.0) -. 1.0 in (* Laplace noise placeholder *)
  x +. noise