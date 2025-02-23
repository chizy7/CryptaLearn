(** Homomorphic Encryption Module *)

(* === Key Module Types === *)
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

module type KeyRotation = sig
  val rotation_period : int  (* in seconds *)
  val key_bits : int
  val current_key : unit -> (module PublicKey) * (module PrivateKey)
  val rotate_keys : unit -> (module PublicKey) * (module PrivateKey)
  val last_rotation : unit -> float
end

(* === Basic Types === *)
type public_key = (module PublicKey)
type private_key = (module PrivateKey)
type ciphertext = Z.t
type plaintext = Z.t

type matrix = {
  rows: int;
  cols: int;
  data: ciphertext array array;
}

(* === Core Utility Functions === *)
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

(* === Core Encryption Operations === *)
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

(* === Basic Homomorphic Operations === *)
let add ((module PK : PublicKey)) c1 c2 =
  Z.rem (Z.mul c1 c2) PK.n_square

let sub ((module PK : PublicKey)) c1 c2 =
  let neg_c2 = Z.invert c2 PK.n_square in
  Z.rem (Z.mul c1 neg_c2) PK.n_square

let mult ((module PK : PublicKey)) c m =
  Z.powm c m PK.n_square

let neg ((module PK : PublicKey)) c =
  Z.invert c PK.n_square

(* === Vector Operations === *)
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

(* === Matrix Operations === *)
let encrypt_matrix pk matrix =
  let rows = Array.length matrix in
  let cols = Array.length matrix.(0) in
  let encrypted = Array.make_matrix rows cols (encrypt pk (Z.of_float 0.0)) in
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      encrypted.(i).(j) <- encrypt pk (Z.of_float matrix.(i).(j))
    done
  done;
  { rows; cols; data = encrypted }

let decrypt_matrix pk sk matrix =
  let decrypted = Array.make_matrix matrix.rows matrix.cols 0.0 in
  for i = 0 to matrix.rows - 1 do
    for j = 0 to matrix.cols - 1 do
      let dec = decrypt pk sk matrix.data.(i).(j) in
      decrypted.(i).(j) <- Z.to_float dec
    done
  done;
  decrypted

let matrix_add pk m1 m2 =
  if m1.rows <> m2.rows || m1.cols <> m2.cols then
    failwith "Matrix dimensions must match for addition";
  let result = Array.make_matrix m1.rows m1.cols (encrypt pk (Z.of_float 0.0)) in
  for i = 0 to m1.rows - 1 do
    for j = 0 to m1.cols - 1 do
      result.(i).(j) <- add pk m1.data.(i).(j) m2.data.(i).(j)
    done
  done;
  { rows = m1.rows; cols = m1.cols; data = result }

let matrix_mult pk m1 m2_plain =
  let m2_cols = Array.length m2_plain.(0) in
  let result = Array.make_matrix m1.rows m2_cols (encrypt pk (Z.of_float 0.0)) in
  for i = 0 to m1.rows - 1 do
    for j = 0 to m2_cols - 1 do
      let sum = ref (encrypt pk (Z.of_float 0.0)) in
      for k = 0 to m1.cols - 1 do
        let prod = mult pk m1.data.(i).(k) (Z.of_float m2_plain.(k).(j)) in
        sum := add pk !sum prod
      done;
      result.(i).(j) <- !sum
    done
  done;
  { rows = m1.rows; cols = m2_cols; data = result }

let matrix_transpose m =
  let result = Array.make_matrix m.cols m.rows m.data.(0).(0) in
  for i = 0 to m.rows - 1 do
    for j = 0 to m.cols - 1 do
      result.(j).(i) <- m.data.(i).(j)
    done
  done;
  { rows = m.cols; cols = m.rows; data = result }

(* === Key Management === *)
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

(* === Key Rotation Implementation === *)
module KeyRotationImpl = struct
  type t = {
    mutable current_pk: public_key;
    mutable current_sk: private_key;
    mutable last_rotation_time: float;
    rotation_period: int;
    key_bits: int;
  }

  let state = ref None

  let init rotation_period key_bits =
    let pk, sk = generate_keypair key_bits in
    state := Some {
      current_pk = pk;
      current_sk = sk;
      last_rotation_time = Unix.time ();
      rotation_period;
      key_bits;
    }

  let get_state () =
    match !state with
    | Some s -> s
    | None -> failwith "Key rotation not initialized"

  let rotation_needed () =
    let s = get_state () in
    Unix.time () -. s.last_rotation_time > float_of_int s.rotation_period
end

let create_key_rotation rotation_period key_bits =
  KeyRotationImpl.init rotation_period key_bits;
  let module KR = struct
    let rotation_period = rotation_period
    let key_bits = key_bits
    
    let current_key () =
      let s = KeyRotationImpl.get_state () in
      (s.current_pk, s.current_sk)
    
    let rotate_keys () =
      let s = KeyRotationImpl.get_state () in
      if KeyRotationImpl.rotation_needed () then  (* Use the function *)
        let new_pk, new_sk = generate_keypair s.key_bits in
        s.current_pk <- new_pk;
        s.current_sk <- new_sk;
        s.last_rotation_time <- Unix.time ();
        (new_pk, new_sk)
      else
        (s.current_pk, s.current_sk)
    
    let last_rotation () =
      let s = KeyRotationImpl.get_state () in
      s.last_rotation_time
  end in
  (module KR : KeyRotation)

(* === Batch Operations === *)
let batch_encrypt pk values =
  Array.map (fun x -> encrypt pk (Z.of_float x)) values

let batch_decrypt pk sk values =
  Array.map (fun c -> Z.to_float (decrypt pk sk c)) values

let batch_add pk c1 c2 =
  Array.map2 (add pk) c1 c2

let batch_mult pk c values =
  Array.map2 (fun ci v -> mult pk ci (Z.of_float v)) c values

(* === Parallel Operations === *)
let parallel_encrypt pk values =
  let num_threads = 4 in
  let chunk_size = Array.length values / num_threads in
  let results = Array.make (Array.length values) (encrypt pk (Z.of_float 0.0)) in
  
  let rec process_chunk start_idx end_idx =
    if start_idx >= end_idx then ()
    else begin
      results.(start_idx) <- encrypt pk (Z.of_float values.(start_idx));
      process_chunk (start_idx + 1) end_idx
    end
  in
  
  let threads = Array.init num_threads (fun i ->
    let start_idx = i * chunk_size in
    let end_idx = if i = num_threads - 1 then Array.length values 
                  else (i + 1) * chunk_size in
    Thread.create (fun () -> process_chunk start_idx end_idx) ()
  ) in
  
  Array.iter Thread.join threads;
  results

let parallel_decrypt pk sk values =
  let num_threads = 4 in
  let chunk_size = Array.length values / num_threads in
  let results = Array.make (Array.length values) 0.0 in
  
  let rec process_chunk start_idx end_idx =
    if start_idx >= end_idx then ()
    else begin
      results.(start_idx) <- Z.to_float (decrypt pk sk values.(start_idx));
      process_chunk (start_idx + 1) end_idx
    end
  in
  
  let threads = Array.init num_threads (fun i ->
    let start_idx = i * chunk_size in
    let end_idx = if i = num_threads - 1 then Array.length values 
                  else (i + 1) * chunk_size in
    Thread.create (fun () -> process_chunk start_idx end_idx) ()
  ) in
  
  Array.iter Thread.join threads;
  results