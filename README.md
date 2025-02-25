# CryptaLearn

CryptaLearn is a privacy-preserving machine learning library in OCaml, implementing federated learning, homomorphic encryption, and differentially private stochastic gradient descent (DP-SGD). This library is designed to enable secure and decentralized machine learning while ensuring user data privacy.

## Features
### Federated Learning (FL)
- Decentralized model training across multiple clients
- Neural network implementation with multiple activation functions (ReLU, Sigmoid, Tanh)
- Mini-batch training with proper gradient computation
- Model serialization and aggregation
- Supports weighted model averaging based on client data size
- Model versioning with semantic versioning (major.minor.patch)
- Secure aggregation with model integrity verification

### Homomorphic Encryption (HE)
- Full Paillier cryptosystem implementation
- Secure key generation and management
- Support for encrypted arithmetic operations:
  - Addition of encrypted values
  - Subtraction of encrypted values
  - Multiplication by plaintext
- Vector and matrix operations for batch processing
- Advanced features:
  - Key rotation functionality
  - Parallel encryption/decryption operations
  - Matrix multiplication on encrypted data
- Key serialization and import/export functionality

### Differential Privacy (DP)
- Multiple noise mechanisms:
  - Laplace mechanism
  - Gaussian mechanism
  - Exponential mechanism
- Privacy budget tracking and accounting
- Advanced DP features:
  - Moments accountant for RDP (Rényi Differential Privacy)
  - Local differential privacy mechanisms
  - Adaptive privacy allocation
  - Privacy budget management
- Gradient clipping and sanitization
- Advanced composition theorem implementation
- Utility estimation and optimal noise calculation

## Installation
### Prerequisites
Ensure you have OCaml (4.14.0+) and OPAM installed. Then, install the necessary dependencies:
```bash
opam install dune core zarith unix threads
```

### Clone the repository
```bash
git clone https://github.com/chizy7/CryptaLearn.git
cd CryptaLearn
```

### Building and Running
```bash
dune build
```

To run the main executable with default configuration:
```bash
dune exec bin/main.exe
```

To run with specific options:
```bash
dune exec bin/main.exe -- --key-size 2048 --skip-fl
```

Available options:
- `--fl-samples N`: Set number of samples for FL training
- `--key-size N`: Set encryption key size in bits (default: 1024)
- `--skip-fl`: Skip federated learning tests
- `--skip-he`: Skip homomorphic encryption tests
- `--skip-dp`: Skip differential privacy tests

## Documentation
For detailed information about CryptaLearn's architecture, modules, and advanced usage, please see the [comprehensive documentation](DOCUMENTATION.md).

## Example Output
```
CryptaLearn Test Suite
====================
Configuration:
  FL Samples: 100
  Key Size: 1024 bits
  Matrix Size: 2x2
  DP Parameters: ε=0.10, δ=1.00e-05

Running Federated Learning Tests...
Testing Federated Learning:
Final model accuracy: 48.80%
Federated Learning Tests completed successfully.

Running Homomorphic Encryption Tests...
Testing Homomorphic Encryption:
Matrix addition result:
6.0 8.0 
10.0 12.0 
Batch operation result: 1.0 2.0 3.0 4.0 5.0 
Testing complex matrix operations:
Time for Matrix encryption: 0.004 seconds
Time for Matrix encryption: 0.004 seconds
Time for Matrix addition: 0.001 seconds
Time for Matrix decryption: 0.003 seconds
Time for Matrix multiplication: 0.004 seconds
Time for Parallel encryption: 0.005 seconds
Time for Parallel decryption: 0.004 seconds
Complex matrix operations completed.
Homomorphic Encryption Tests completed successfully.

Running Differential Privacy Tests...
Testing Enhanced Differential Privacy:
Privacy accounting:
Budget spent - Epsilon: 0.4799, Delta: 0.0000
Noise addition test:
Original values: 5.0 10.0 15.0 20.0 25.0 
Noisy values: 66.5 98.0 -54.9 22.0 29.9 
Testing advanced DP features:
RDP parameters - Epsilon: 0.0825
Private mean: 3.474
Private histogram: -7.2 5.1 30.3 14.8 33.2 
Privacy budget management:
Query results: -193.88 104.95 205.84 116.86 -201.66 
Remaining epsilon: 0.000
Differential Privacy Tests completed successfully.

All requested tests completed.
```

## Usage Examples

### Federated Learning
```ocaml
(* Create a model with 2 inputs, 4 hidden nodes, and 1 output *)
let model = create_model [|2; 4; 1|] in

(* Configure training parameters *)
let config = {
  batch_size = 32;
  learning_rate = 0.1;
  num_epochs = 5;
} in

(* Train on client data and get updates *)
let client_update = train_client model client_data config in

(* Aggregate updates from multiple clients *)
let final_model = aggregate_updates [update1; update2; update3]

(* Use model versioning *)
let metadata = {
  version = create_version 1 0 0;
  architecture = [|2; 4; 1|];
  created_at = Unix.time ();
  updated_at = Unix.time ();
  training_rounds = 0;
  total_clients = 1;
} in
let versioned_model = create_versioned_model model metadata in
```

### Homomorphic Encryption
```ocaml
(* Generate encryption keys *)
let pk, sk = generate_keypair 1024 in

(* Encrypt and perform operations *)
let encrypted1 = encrypt pk (Z.of_int 30) in
let encrypted2 = encrypt pk (Z.of_int 12) in
let sum = add pk encrypted1 encrypted2 in
let decrypted = decrypt pk sk sum  (* Result: 42 *)

(* Matrix operations *)
let matrix1 = [|[|1.0; 2.0|]; [|3.0; 4.0|]|] in
let encrypted_matrix = encrypt_matrix pk matrix1 in
let result = matrix_add pk encrypted_matrix encrypted_matrix in
let decrypted_result = decrypt_matrix pk sk result in

(* Key rotation *)
let module KR = (val create_key_rotation 3600 1024) in
let new_pk, new_sk = KR.rotate_keys () in
```

### Differential Privacy
```ocaml
(* Create privacy parameters *)
let params = create_privacy_params 0.1 1e-5 1.0 in

(* Add noise to sensitive data *)
let noisy_value = add_noise Gaussian params 5.0 in
let noisy_vector = add_noise_vector Gaussian params [|1.0; 2.0; 3.0|] in

(* Track privacy budget *)
let accountant = create_accountant Gaussian in
let updated_accountant = update_privacy_budget accountant params in
let (eps_spent, delta_spent) = compute_privacy_spent updated_accountant in

(* Local differential privacy *)
let private_mean = local_dp_mean data params in
let histogram = local_dp_histogram data 5 params in

(* Advanced DP features *)
let alpha_orders = [|1.5; 2.0; 2.5; 3.0; 3.5; 4.0|] in
let moments = create_moments_accountant Gaussian alpha_orders in
let rdp_params = compute_rdp moments 0.1 in
```

## Performance
Performance metrics from test runs:
- Matrix encryption: ~0.004 seconds
- Matrix addition: ~0.001 seconds
- Matrix decryption: ~0.003 seconds
- Matrix multiplication: ~0.004 seconds
- Parallel encryption: ~0.005 seconds

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT [License](LICENSE).