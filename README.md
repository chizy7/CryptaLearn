# CryptaLearn

CryptaLearn is a privacy-preserving machine learning library in OCaml, implementing federated learning, homomorphic encryption, and differentially private stochastic gradient descent (DP-SGD). This library is designed to enable secure and decentralized machine learning while ensuring user data privacy.

- [CryptaLearn Node](https://github.com/chizy7/cryptalearn_node) - Backend for coordinating federated learning rounds and model updates from OCaml clients in CryptaLearn.

## Features
### Federated Learning (FL)
- Decentralized model training across multiple clients
- Neural network implementation with multiple activation functions (ReLU, Sigmoid, Tanh)
- Mini-batch training with proper gradient computation
- **DP-SGD (Differentially Private Stochastic Gradient Descent)**:
  - Per-example gradient clipping for privacy guarantees
  - Gaussian noise calibrated to (ε, δ)-differential privacy
  - Demonstrates privacy-utility tradeoff across different privacy budgets
  - Full implementation following Abadi et al. (2016)
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

## Quick Start

### 1. Installation
```bash
# Install dependencies
opam install dune core zarith unix threads

# Clone the repository
git clone https://github.com/chizy7/CryptaLearn.git
cd CryptaLearn

# Build the project
dune build
```

### 2. Run Unit Tests
```bash
# Run all 15 unit tests (FL, HE, DP)
dune runtest
```

### 3. Run Complete Test Suite
```bash
# Run with default configuration (ε=0.1)
dune exec bin/main.exe

# Or with reproducible seed
dune exec bin/main.exe -- --seed 42
```

### 4. Explore Privacy-Utility Tradeoff
```bash
# Very strong privacy (ε=0.05) - High noise, lower accuracy
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42

# Strong privacy (ε=0.1) - High noise
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42

# Moderate privacy (ε=0.5) - RECOMMENDED: Best balance
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42

# Lower privacy (ε=1.0) - Low noise, acts as regularization
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42
```

## Command Reference

### Available Options
- `--fl-samples N`: Set number of samples for FL training (default: 100)
- `--key-size N`: Set encryption key size in bits (default: 1024)
- `--dp-epsilon E`: Set privacy budget epsilon (default: 0.1)
- `--dp-delta D`: Set privacy failure probability (default: 1e-05)
- `--seed N`: Set random seed for reproducibility
- `--skip-fl`: Skip federated learning tests
- `--skip-he`: Skip homomorphic encryption tests
- `--skip-dp`: Skip differential privacy tests
- `--fail-fast`: Abort on first test failure
- `--no-verify`: Disable result verification

### Common Commands
```bash
# Clean and rebuild
dune clean && dune build

# Run with larger key size (more secure but slower)
dune exec bin/main.exe -- --key-size 2048 --seed 42

# Run with more FL samples
dune exec bin/main.exe -- --fl-samples 500 --seed 42

# Skip specific test modules
dune exec bin/main.exe -- --skip-he --skip-dp

# Run all privacy experiments sequentially
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42
```

## Testing & Experimental Results

### Expected Results (with seed=42)

**Privacy-Utility Tradeoff:**
| ε Value | Privacy Level | Noise (σ) | Standard FL | DP-SGD Accuracy | Privacy Cost |
|---------|---------------|-----------|-------------|-----------------|--------------|
| 0.05    | Very Strong   | 96.90     | 72.80%      | 48.80%          | 24.0% loss   |
| 0.10    | Strong        | 48.45     | 72.80%      | 48.80%          | 24.0% loss   |
| 0.50    | Moderate   | 9.69      | 72.80%      | 72.80%          | 0.0% loss    |
| 1.00    | Lower         | 4.84      | 72.80%      | 100.00%         | -27.2% (gain)|

**Recommended for production**: ε=0.5 provides the best privacy-utility balance

**Key Observations:**
- Lower ε = stronger privacy = higher noise = lower accuracy
- ε=0.5: Optimal balance with no accuracy loss
- ε=1.0: Low noise acts as regularization, improving accuracy
- All tests include FL, DP-SGD, HE, and DP modules

### Complete Test Run
```bash
# Run everything in sequence
dune clean && \
dune build && \
dune runtest && \
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42

# Or use the automated experiment script (generates results in docs/experiment_results/)
./run_privacy_experiments.sh
```

## Documentation

### Quick Links
- **[commands.md](CryptaLearn/docs/commands.md)** - **Complete command reference** (all commands in one place)

### Detailed Documentation (`docs/` directory)
- **[documentation.md](CryptaLearn/docs/documentation.md)** - Comprehensive API documentation
- **[architecture.md](CryptaLearn/docs/architecture.md)** - System architecture and design
- **[test_results.md](CryptaLearn/docs/test_results.md)** - Complete test results with analysis
- **[experimental_metrics.md](CryptaLearn/docs/experimental_metrics.md)** - Privacy-utility tradeoff analysis

## Example Output
```
CryptaLearn Test Suite
====================
Configuration:
  FL Samples: 100
  Key Size: 1024 bits
  Matrix Size: 2x2
  DP Parameters: ε=0.10, δ=1.00e-05
  Verification: Enabled
  Seed: Random
  Fail on error: No

Running Federated Learning Tests...
Testing Federated Learning:
Final model accuracy (standard FL): 72.80%
✓ Accuracy verification passed (>70%)
Federated Learning Tests completed successfully.

Running DP-SGD Tests...

Testing DP-SGD (Differential Privacy + Federated Learning):
DP-SGD accuracy (ε=0.10, σ=48.45): 48.80%
✓ DP-SGD training completed
  Privacy-utility tradeoff: ε=0.10 → 48.80% accuracy
DP-SGD Tests completed successfully.

Running Homomorphic Encryption Tests...

Testing Homomorphic Encryption:
Matrix addition result:
6.0 8.0 
10.0 12.0 
✓ Matrix addition verification passed

Batch operation result: 1.0 2.0 3.0 4.0 5.0 
✓ Batch operation verification passed

Testing complex matrix operations:
Time for Matrix encryption: 0.005 seconds
Time for Matrix encryption: 0.005 seconds
Time for Matrix addition: 0.001 seconds
Time for Matrix decryption: 0.004 seconds
✓ Matrix addition verification passed
Time for Matrix multiplication: 0.005 seconds
✓ Matrix multiplication verification passed
Time for Parallel encryption: 0.005 seconds
Time for Parallel decryption: 0.004 seconds
✓ Parallel operations verification passed
Complex matrix operations completed.
Homomorphic Encryption Tests completed successfully.

Running Differential Privacy Tests...
Testing Enhanced Differential Privacy:
Privacy accounting:
Budget spent - Epsilon: 0.1000, Delta: 0.0000
✓ Privacy accounting verification passed

Noise addition test:
Original values: 5.0 10.0 15.0 20.0 25.0 
Noisy values: 31.1 62.2 -138.3 -47.7 -6.5 
✓ Noise addition verification passed (avg noise: 66.17)

Testing advanced DP features:
RDP parameters - Epsilon: 0.0825
True mean: 0.550, Private mean: 0.744
✓ Private mean verification passed
Private histogram: 3.6 -2.4 9.5 5.6 -14.3 

Privacy budget management:
Query results: -212.56 -174.50 103.62 150.24 183.81 
Remaining epsilon: 0.000
✓ Budget management verification passed
Differential Privacy Tests completed successfully.

All requested tests completed successfully.
```

## Usage Examples

### Federated Learning
```ocaml
(* Create a model with 2 inputs, 4 hidden nodes, and 1 output *)
let model = create_model [|2; 4; 1|] in

(* Standard FL training *)
let config = {
  batch_size = 32;
  learning_rate = 0.1;
  num_epochs = 5;
} in
let client_update = train_client model client_data config in

(* DP-SGD training with privacy guarantees *)
let dp_config = {
  batch_size = 32;
  learning_rate = 0.1;
  num_epochs = 5;
  clip_norm = 1.0;                (* L2 norm clipping threshold *)
  noise_multiplier = 4.84;        (* Calibrated for ε=1.0, δ=1e-5 *)
  dp_epsilon = 1.0;
  dp_delta = 1e-5;
} in
let dp_update = train_client_dp_sgd model client_data dp_config in

(* Aggregate updates from multiple clients *)
let final_model = aggregate_updates [update1; update2; update3] in

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
- Matrix encryption: ~0.005 seconds
- Matrix addition: ~0.001 seconds
- Matrix decryption: ~0.004 seconds
- Matrix multiplication: ~0.005 seconds
- Parallel encryption: ~0.005 seconds
- Parallel decryption: ~0.004 seconds

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License
This project is licensed under the MIT [License](LICENSE).