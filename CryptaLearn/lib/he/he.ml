(** Homomorphic Encryption Module *)

module type PublicKey = sig
  val n : Z.t
  val g : Z.t
  val n_square : Z.t
  val bits : int
end

module type PrivateKey = sig
  val lambda : Z.t
  val mu : Z.t
  val p : Z.t
  val q : Z.t
end

type public_key = (module PublicKey)
type private_key = (module PrivateKey)
type ciphertext = Z.t
type plaintext = Z.t

let generate_prime bits =
  let rec try_prime () =
    let n = Z.random_bits bits in
    if Z.probab_prime n 20 > 0 then n
    else try_prime ()
  in try_prime ()

let is_probable_prime n confidence =
  Z.probab_prime n confidence > 0

let mod_inverse a n =
  try Some (Z.invert a n)
  with Division_by_zero -> None

let generate_keypair bits =
  let p = generate_prime (bits / 2) in
  let q = generate_prime (bits / 2) in
  let n = Z.mul p q in
  let n_square = Z.mul n n in
  
  (* Compute lambda(n) = lcm(p-1, q-1) *)
  let p_minus_1 = Z.sub p Z.one in
  let q_minus_1 = Z.sub q Z.one in
  let lambda = Z.div (Z.mul p_minus_1 q_minus_1) (Z.gcd p_minus_1 q_minus_1) in
  
  (* Choose g and compute mu *)
  let g = Z.add n Z.one in
  let mu = match mod_inverse (Z.div (Z.sub (Z.powm g lambda n_square) Z.one) n) n with
    | Some x -> x
    | None -> failwith "Failed to compute mu" in
  
  let module PK = struct
    let n = n
    let g = g
    let n_square = n_square
    let bits = bits
  end in
  let module SK = struct
    let lambda = lambda
    let mu = mu
    let p = p
    let q = q
  end in
  ((module PK : PublicKey), (module SK : PrivateKey))

let encrypt ((module PK : PublicKey)) m =
  let r = Z.random_bits PK.bits in
  let n_square = PK.n_square in
  let first_term = Z.powm PK.g m n_square in
  let second_term = Z.powm r PK.n n_square in
  Z.rem (Z.mul first_term second_term) n_square

let decrypt ((module PK : PublicKey)) ((module SK : PrivateKey)) c =
  let n_square = PK.n_square in
  let intermediate = Z.powm c SK.lambda n_square in
  let l = Z.div (Z.sub intermediate Z.one) PK.n in
  Z.rem (Z.mul l SK.mu) PK.n

let add ((module PK : PublicKey)) c1 c2 =
  Z.rem (Z.mul c1 c2) PK.n_square

let sub ((module PK : PublicKey)) c1 c2 =
  let neg_c2 = Z.invert c2 PK.n_square in
  Z.rem (Z.mul c1 neg_c2) PK.n_square

let mult ((module PK : PublicKey)) c m =
  Z.powm c m PK.n_square

let neg ((module PK : PublicKey)) c =
  Z.invert c PK.n_square

let encrypt_vector pk vec =
  Array.map (fun x -> encrypt pk (Z.of_float x)) vec

let decrypt_vector pk sk vec =
  Array.map (fun c -> 
    let decrypted = decrypt pk sk c in
    Z.to_float decrypted
  ) vec

let add_vectors pk vec1 vec2 =
  Array.map2 (add pk) vec1 vec2

let inner_product pk enc_vec plain_vec =
  let products = Array.mapi (fun i c -> 
    mult pk c (Z.of_float plain_vec.(i))
  ) enc_vec in
  Array.fold_left (add pk) (encrypt pk Z.zero) products

(* Key serialization *)
let export_public_key ((module PK : PublicKey)) =
  Printf.sprintf "%s,%s,%s,%d"
    (Z.to_string PK.n)
    (Z.to_string PK.g)
    (Z.to_string PK.n_square)
    PK.bits

let import_public_key str =
  match String.split_on_char ',' str with
  | [n_str; g_str; n_square_str; bits_str] ->
      let module PK = struct
        let n = Z.of_string n_str
        let g = Z.of_string g_str
        let n_square = Z.of_string n_square_str
        let bits = int_of_string bits_str
      end in
      (module PK : PublicKey)
  | _ -> failwith "Invalid public key format"

let export_private_key ((module SK : PrivateKey)) =
  Printf.sprintf "%s,%s,%s,%s"
    (Z.to_string SK.lambda)
    (Z.to_string SK.mu)
    (Z.to_string SK.p)
    (Z.to_string SK.q)

let import_private_key str =
  match String.split_on_char ',' str with
  | [lambda_str; mu_str; p_str; q_str] ->
      let module SK = struct
        let lambda = Z.of_string lambda_str
        let mu = Z.of_string mu_str
        let p = Z.of_string p_str
        let q = Z.of_string q_str
      end in
      (module SK : PrivateKey)
  | _ -> failwith "Invalid private key format"