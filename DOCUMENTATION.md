# CryptaLearn Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Federated Learning Module](#federated-learning-module)
4. [Homomorphic Encryption Module](#homomorphic-encryption-module)
5. [Differential Privacy Module](#differential-privacy-module)
6. [Advanced Usage](#advanced-usage)
7. [Performance Considerations](#performance-considerations)
8. [API Reference](#api-reference)

## Overview

CryptaLearn is a privacy-preserving machine learning library written in OCaml. It is designed to enable secure and privacy-focused machine learning by combining three key technologies:

1. **Federated Learning (FL)**: A decentralized machine learning approach where the model is trained across multiple devices or servers holding local data samples, without exchanging the raw data itself.

2. **Homomorphic Encryption (HE)**: A form of encryption allowing computations to be performed on encrypted data without decrypting it first.

3. **Differential Privacy (DP)**: A system for publicly sharing information about a dataset by describing patterns of groups within the dataset while withholding information about individuals.

## Architecture

CryptaLearn is organized into three main modules:

```
CryptaLearn/
├── lib/
│   ├── fl/             # Federated Learning module
│   ├── he/             # Homomorphic Encryption module
│   ├── dp/             # Differential Privacy module
```

Each module can be used independently or in combination to create privacy-preserving machine learning solutions.

## Federated Learning Module

The Federated Learning module (`fl.ml`) enables training machine learning models across multiple clients without sharing raw data.

### Key Components

#### Neural Network Architecture
- Supports multi-layer neural networks with adjustable architectures
- Activation functions: ReLU, Sigmoid, Tanh
- Forward/backward propagation implementation

#### Model Integrity Verification
- Validates model structure and parameters
- Ensures weights and biases are within reasonable magnitudes
- Checks for NaN/Inf values
- Verifies activation functions are from the allowed set

#### Training Process
```
┌─────────┐      ┌─────────┐      ┌─────────┐
│ Client 1 │      │ Client 2 │      │ Client 3 │
└────┬────┘      └────┬────┘      └────┬────┘
     │ Train          │ Train          │ Train
     ▼                ▼                ▼
┌────┴────┐      ┌────┴────┐      ┌────┴────┐
│  Update  │      │  Update  │      │  Update  │
└────┬────┘      └────┬────┘      └────┬────┘
     │                │                │
     └────────────────┼────────────────┘
                      │
                      ▼
               ┌────────────┐
               │   Secure   │
               │ Aggregation│
               └─────┬──────┘
                     │
                     ▼
               ┌────────────┐
               │   Global   │
               │    Model   │
               └────────────┘
```

#### Model Versioning
- Maintains semantic versioning (major.minor.patch)
- Tracks model metadata: architecture, creation time, update time, training rounds, client count
- Ensures compatibility between model versions

### API Examples

#### Creating a Model
```ocaml
(* Create a model with 2 inputs, 4 hidden nodes, and 1 output *)
let model = create_model [|2; 4; 1|]
```

#### Training on Client Data
```ocaml
let config = { batch_size = 32; learning_rate = 0.1; num_epochs = 5 } in
let client_update = train_client model client_data config
```

#### Secure Aggregation
```ocaml
let weights = [|0.6; 0.4|] in
let aggregated = secure_aggregate [model1; model2] weights
```

## Homomorphic Encryption Module

The Homomorphic Encryption module (`he.ml`) allows computations on encrypted data without decryption.

### Key Components

#### Paillier Cryptosystem
Implements the Paillier cryptosystem, which is an additively homomorphic encryption scheme:
- Encrypt(m₁) * Encrypt(m₂) = Encrypt(m₁ + m₂)

```
Plain values:      m₁         m₂
                   │          │
                   ▼          ▼
Encryption:    Encrypt     Encrypt
                   │          │
                   ▼          ▼
Ciphertexts:      c₁         c₂
                   │          │
                   └────┬─────┘
                        │
                        ▼
Operation:        c₁ * c₂ = c₃
                        │
                        ▼
Decryption:        Decrypt
                        │
                        ▼
Result:            m₁ + m₂
```

#### Advanced Operations
- Matrix operations on encrypted data
- Batched operations for efficiency
- Parallel processing for improved performance
- Key rotation for enhanced security

### API Examples

#### Key Generation and Encryption
```ocaml
let pk, sk = generate_keypair 1024 in
let encrypted = encrypt pk (Z.of_int 42)
```

#### Homomorphic Operations
```ocaml
let sum = add pk encrypted1 encrypted2 in
let product = mult pk encrypted1 (Z.of_int 5)
```

#### Matrix Operations
```ocaml
let encrypted_matrix = encrypt_matrix pk matrix in
let result = matrix_add pk encrypted_matrix encrypted_matrix
```

## Differential Privacy Module

The Differential Privacy module (`dp.ml`) adds noise to data to provide privacy guarantees.

### Key Components

#### Privacy Mechanisms
- **Laplace Mechanism**: Adds Laplace noise calibrated to sensitivity/epsilon
- **Gaussian Mechanism**: Adds Gaussian noise calibrated to sensitivity/(epsilon*sqrt(ln(1/delta)))
- **Exponential Mechanism**: For non-numeric data with a utility function

#### Privacy Accounting
- Basic composition tracking
- Advanced composition theorem
- Moments accountant for Rényi Differential Privacy (RDP)

```
┌────────────┐       ┌────────────┐
│ Raw Data   │       │ Query 1    │
└─────┬──────┘       └──────┬─────┘
      │                     │
      └──────────┬──────────┘
                 │
                 ▼
        ┌──────────────────┐
        │  Privacy Budget  │◄────┐
        │     Tracking     │     │
        └─────────┬────────┘     │
                  │              │
                  ▼              │
        ┌──────────────────┐     │
        │   Add Noise      │     │
        └─────────┬────────┘     │
                  │              │
                  ▼              │
        ┌──────────────────┐     │
        │ Noisy Response   │     │
        └─────────┬────────┘     │
                  │              │
                  ▼              │
        ┌──────────────────┐     │
        │ Update Privacy   │─────┘
        │    Budget        │
        └──────────────────┘
```

#### Local Differential Privacy
- Randomized response
- Local histograms
- Private mean estimation (optimized implementation that adds noise to the sum rather than individual values)

### API Examples

#### Adding Noise
```ocaml
let params = create_privacy_params 0.1 1e-5 1.0 in
let noisy_value = add_noise Gaussian params 5.0
```

#### Privacy Budget Tracking
```ocaml
let accountant = create_accountant Gaussian in
let updated = update_privacy_budget accountant params in
let (eps, delta) = compute_privacy_spent updated
```

#### Advanced DP Features
```ocaml
let moments = create_moments_accountant Gaussian [|1.5; 2.0; 3.0|] in
let rdp = compute_rdp moments 0.1
```

## Advanced Usage

### Combining All Three Technologies

For maximum privacy and utility, you can combine all three technologies:

1. **Federated Learning with Differential Privacy**:
   - Add noise to gradients before aggregation
   ```ocaml
   let sanitized_gradients = sanitize_gradients Gaussian params gradients
   ```

2. **Homomorphic Encryption in Federated Learning**:
   - Encrypt model updates before sending to server
   ```ocaml
   let encrypted_update = encrypt_vector pk model_update
   ```

3. **Complete Privacy-Preserving Pipeline**:
   - Train locally
   - Add differential privacy noise
   - Encrypt updates
   - Aggregate securely
   - Decrypt only the final model

## Performance Considerations

### Homomorphic Encryption
- Operations on encrypted data are computationally expensive
- Key size affects security and performance (larger keys = more secure but slower)
- Use batch operations when possible
- Consider parallel processing for large datasets

### Differential Privacy
- Higher privacy (lower epsilon) requires more noise
- Balance privacy budget across multiple queries
- Consider sensitivity when designing queries
- Use advanced composition for better privacy accounting
- **Add noise to aggregates rather than individual values when possible for better utility**

### Federated Learning
- Communication efficiency is crucial
- Model architecture affects convergence speed
- Client selection strategy can impact model quality
- Secure aggregation adds overhead but increases privacy

## API Reference

### Federated Learning
| Function | Description |
|----------|-------------|
| `create_model` | Create a new neural network model |
| `train_client` | Train model on client data |
| `aggregate_updates` | Combine updates from multiple clients |
| `evaluate_model` | Evaluate model accuracy |
| `create_version` | Create semantic version number |
| `secure_aggregate` | Securely combine versioned models |

### Homomorphic Encryption
| Function | Description |
|----------|-------------|
| `generate_keypair` | Generate encryption key pair |
| `encrypt` | Encrypt a single value |
| `decrypt` | Decrypt a single value |
| `add` | Add two encrypted values |
| `mult` | Multiply encrypted value by plaintext |
| `encrypt_matrix` | Encrypt a matrix |
| `parallel_encrypt` | Encrypt values in parallel |

### Differential Privacy
| Function | Description |
|----------|-------------|
| `create_privacy_params` | Create privacy parameters |
| `add_noise` | Add privacy-preserving noise |
| `clip_gradients` | Limit sensitivity of gradients |
| `compute_privacy_spent` | Calculate privacy budget used |
| `create_moments_accountant` | Create sophisticated privacy tracking |
| `local_dp_mean` | Privately compute mean by adding noise to the sum (not individual values) |
| `manage_privacy_budget` | Handle multiple queries under budget |