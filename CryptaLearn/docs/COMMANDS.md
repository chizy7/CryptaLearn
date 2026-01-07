# CryptaLearn - Complete Command Reference

This document contains all commands to build, test, and run CryptaLearn experiments.

---

## Installation & Setup

```bash
# Install the dependencies
opam install dune core zarith unix threads

# Clone the repository
git clone https://github.com/chizy7/CryptaLearn.git
cd CryptaLearn

# Build the project
dune build
```

---

## Basic Commands

### Build & Clean
```bash
# Build the project
dune build

# Clean build artifacts
dune clean

# Clean and rebuild
dune clean && dune build
```

### Run Unit Tests
```bash
# Run all 15 unit tests (FL, HE, DP, DP-SGD)
dune runtest

# Run tests with verbose output
dune exec test/test_CryptaLearn.exe
```

### Run Default Test Suite
```bash
# Run with default configuration (ε=0.1)
dune exec bin/main.exe

# Run with reproducible seed
dune exec bin/main.exe -- --seed 42
```

---

## Privacy-Utility Tradeoff Experiments

### Individual Epsilon Values
```bash
# Very strong privacy (ε=0.05) - High noise, 24% accuracy loss
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42

# Strong privacy (ε=0.1) - High noise, 24% accuracy loss
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42

# Moderate privacy (ε=0.5) - RECOMMENDED: No accuracy loss
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42

# Lower privacy (ε=1.0) - Acts as regularization, 27.2% accuracy gain
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42
```

### Run All Experiments Sequentially
```bash
# Run all 4 epsilon values in sequence
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42
```

### Complete Test Run (Everything)
```bash
# Clean, build, test, and run all experiments
dune clean && \
dune build && \
dune runtest && \
dune exec bin/main.exe -- --dp-epsilon 0.05 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.1 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42 && \
dune exec bin/main.exe -- --dp-epsilon 1.0 --seed 42
```

---

## Command-Line Options

### Common Options
```bash
# Set number of FL training samples (default: 100)
dune exec bin/main.exe -- --fl-samples 500

# Set encryption key size in bits (default: 1024)
dune exec bin/main.exe -- --key-size 2048

# Set privacy budget epsilon (default: 0.1)
dune exec bin/main.exe -- --dp-epsilon 0.5

# Set privacy failure probability delta (default: 1e-05)
dune exec bin/main.exe -- --dp-delta 1e-6

# Set random seed for reproducibility
dune exec bin/main.exe -- --seed 42

# Set matrix size for HE tests (default: 2)
dune exec bin/main.exe -- --matrix-size 3
```

### Skip Options
```bash
# Skip federated learning tests
dune exec bin/main.exe -- --skip-fl

# Skip homomorphic encryption tests
dune exec bin/main.exe -- --skip-he

# Skip differential privacy tests
dune exec bin/main.exe -- --skip-dp

# Skip multiple modules
dune exec bin/main.exe -- --skip-he --skip-dp
```

### Advanced Options
```bash
# Disable result verification
dune exec bin/main.exe -- --no-verify

# Abort on first test failure
dune exec bin/main.exe -- --fail-fast

# Combine multiple options
dune exec bin/main.exe -- --fl-samples 500 --key-size 2048 --dp-epsilon 0.5 --seed 42
```

---

## Example Use Cases

### Quick Verification
```bash
# Fastest way to verify everything works
dune build && dune runtest
```

### Research Experiments
```bash
# High-quality reproducible experiments for research
dune exec bin/main.exe -- --fl-samples 500 --dp-epsilon 0.05 --seed 42
dune exec bin/main.exe -- --fl-samples 500 --dp-epsilon 0.1 --seed 42
dune exec bin/main.exe -- --fl-samples 500 --dp-epsilon 0.5 --seed 42
dune exec bin/main.exe -- --fl-samples 500 --dp-epsilon 1.0 --seed 42
```

### High Security Testing
```bash
# Test with larger keys (slower but more secure)
dune exec bin/main.exe -- --key-size 2048 --seed 42
```

### Development Testing
```bash
# Fast testing during development (skip expensive tests)
dune exec bin/main.exe -- --skip-he --fl-samples 50
```

### CI/CD Pipeline
```bash
# Suitable for continuous integration
dune clean && dune build && dune runtest && dune exec bin/main.exe -- --seed 42
```

---

## Expected Results (with seed=42)

### Privacy-Utility Tradeoff
| ε Value | Command | Privacy Level | DP-SGD Accuracy | Privacy Cost |
|---------|---------|---------------|-----------------|--------------|
| 0.05 | `--dp-epsilon 0.05` | Very Strong | 48.80% | 24.0% loss |
| 0.10 | `--dp-epsilon 0.1` | Strong | 48.80% | 24.0% loss |
| 0.50 | `--dp-epsilon 0.5` | Moderate | 72.80% | 0.0% loss |
| 1.00 | `--dp-epsilon 1.0` | Lower | 100.00% | -27.2% gain |

**Recommended for production**

### Unit Test Results
- **Total Tests**: 15
- **Pass Rate**: 100%
- **Coverage**: FL (4 tests), HE (6 tests), DP (5 tests)

### Performance Benchmarks
| Operation | Time (1024-bit) | Time (2048-bit) |
|-----------|-----------------|-----------------|
| Matrix Encryption | ~0.005s | ~0.032s |
| Matrix Addition | ~0.001s | ~0.006s |
| Matrix Decryption | ~0.004s | ~0.026s |

---

## Troubleshooting

### Build Fails
```bash
# Clean and rebuild
dune clean && dune build

# If dependencies are missing
opam install dune core zarith unix threads
```

### Tests Fail
```bash
# Run with verbose output
dune exec test/test_CryptaLearn.exe

# Run with fail-fast to see first error
dune exec bin/main.exe -- --fail-fast
```

### Inconsistent Results
```bash
# Always use a seed for reproducibility
dune exec bin/main.exe -- --seed 42
```

---

## Help

```bash
# Display help message
dune exec bin/main.exe -- --help
```
