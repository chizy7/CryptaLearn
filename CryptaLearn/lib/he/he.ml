(** Simple Homomorphic Encryption Module *)

module type PublicKey = sig
  val n : Z.t
  val g : Z.t
end

module type PrivateKey = sig
  val lambda : Z.t
  val mu : Z.t
end

type public_key = (module PublicKey)
type private_key = (module PrivateKey)
type ciphertext = Z.t

let generate_prime_bits bits =
  let rec try_prime () =
    let n = Z.random_bits bits in
    if Z.probab_prime n 20 > 0 then n
    else try_prime ()
  in try_prime ()

let lcm a b =
  Z.div (Z.mul a b) (Z.gcd a b)

let l x n =
  Z.div (Z.sub x Z.one) n

let generate_keypair bits =
  (* Convert bits to Z.t and divide by 2 *)
  let bits_z = Z.of_int bits in
  let half_bits = Z.to_int (Z.div bits_z (Z.of_int 2)) in
  
  (* Generate two large prime numbers *)
  let p = generate_prime_bits half_bits in
  let q = generate_prime_bits half_bits in
  let n = Z.mul p q in
  
  (* Compute lambda(n) = lcm(p-1, q-1) *)
  let lambda = lcm (Z.sub p Z.one) (Z.sub q Z.one) in
  
  (* Choose g and compute mu *)
  let g = Z.add n Z.one in
  let mu = Z.invert (l g n) n in
  
  let module PK = struct
    let n = n
    let g = g
  end in
  let module SK = struct
    let lambda = lambda
    let mu = mu
  end in
  ((module PK : PublicKey), (module SK : PrivateKey))

let encrypt ((module PK : PublicKey)) m =
  (* Used numbits instead of log2up for bit length *)
  let r = Z.random_bits (Z.numbits PK.n) in
  let n2 = Z.mul PK.n PK.n in
  let first_term = Z.powm PK.g m PK.n in
  let second_term = Z.powm r PK.n n2 in
  Z.rem (Z.mul first_term second_term) n2

let decrypt ((module PK : PublicKey)) ((module SK : PrivateKey)) c =
  let n2 = Z.mul PK.n PK.n in
  let first_step = Z.powm c SK.lambda n2 in
  let second_step = l first_step PK.n in
  Z.rem (Z.mul second_step SK.mu) PK.n

let add ((module PK : PublicKey)) c1 c2 =
  let n2 = Z.mul PK.n PK.n in
  Z.rem (Z.mul c1 c2) n2

let mult ((module PK : PublicKey)) c m =
  let n2 = Z.mul PK.n PK.n in
  Z.powm c m n2