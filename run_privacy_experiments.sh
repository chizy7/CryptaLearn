#!/bin/bash
# Script to reproduce all privacy-utility tradeoff experiments
# Compatible with Bash 3.2+ (macOS default)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CryptaLearn Privacy-Utility Tradeoff Experiments          ║"
echo "║  Reproducing results for arXiv paper                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Change to CryptaLearn directory (where dune project is)
cd CryptaLearn

# Create results directory inside docs
mkdir -p docs/experiment_results

# Define epsilon values to test
EPSILONS=(0.05 0.1 0.5 1.0)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Part 1: Privacy Budget (ε) Experiments"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run experiments for each epsilon
for eps in "${EPSILONS[@]}"; do
    echo "🔬 Running experiment with ε=$eps (seed=42)..."
    output_file="docs/experiment_results/epsilon_${eps}.txt"

    dune exec bin/main.exe -- \
        --seed 42 \
        --dp-epsilon $eps \
        --fl-samples 100 \
        > "$output_file" 2>&1

    echo "   ✓ Results saved to docs/experiment_results/epsilon_${eps}.txt"

    # Extract and display key metrics
    fl_acc=$(grep "Final model accuracy (standard FL)" "$output_file" | grep -o '[0-9.]*%' | head -1 | tr -d '%')
    dp_acc=$(grep "DP-SGD accuracy" "$output_file" | grep -o '[0-9.]*%' | tail -1 | tr -d '%')
    sigma=$(grep "DP-SGD accuracy" "$output_file" | grep -o 'σ=[0-9.]*' | cut -d= -f2)

    echo "   Standard FL Accuracy: $fl_acc%"
    echo "   DP-SGD Accuracy: $dp_acc%"
    echo "   Noise Multiplier (σ): $sigma"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Part 2: HE Key Size Experiments"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for keysize in 1024 2048; do
    echo "Running HE experiment with key size $keysize bits..."
    output_file="docs/experiment_results/keysize_${keysize}.txt"

    dune exec bin/main.exe -- \
        --seed 42 \
        --key-size $keysize \
        --skip-fl \
        --skip-dp \
        > "$output_file" 2>&1

    echo "   ✓ Results saved to docs/experiment_results/keysize_${keysize}.txt"

    # Extract timing info
    enc_time=$(grep "Time for Matrix encryption" "$output_file" | head -1 | awk '{print $5}')
    add_time=$(grep "Time for Matrix addition" "$output_file" | awk '{print $5}')
    dec_time=$(grep "Time for Matrix decryption" "$output_file" | awk '{print $5}')

    echo "   Matrix encryption: $enc_time s"
    echo "   Matrix addition: $add_time s"
    echo "   Matrix decryption: $dec_time s"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary Tables"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate privacy-utility tradeoff table
echo "Table 1: Privacy-Utility Tradeoff Results"
echo "────────────────────────────────────────────────────────────────────────"
printf "%-8s | %-12s | %-12s | %-12s\n" "ε" "Noise (σ)" "FL Acc%" "DP-SGD Acc%"
echo "────────────────────────────────────────────────────────────────────────"

for eps in "${EPSILONS[@]}"; do
    output_file="docs/experiment_results/epsilon_${eps}.txt"
    fl_acc=$(grep "Final model accuracy (standard FL)" "$output_file" | grep -o '[0-9.]*%' | head -1 | tr -d '%')
    dp_acc=$(grep "DP-SGD accuracy" "$output_file" | grep -o '[0-9.]*%' | tail -1 | tr -d '%')
    sigma=$(grep "DP-SGD accuracy" "$output_file" | grep -o 'σ=[0-9.]*' | cut -d= -f2)

    printf "%-8s | %-12s | %-12s | %-12s\n" "$eps" "$sigma" "$fl_acc" "$dp_acc"
done
echo ""

# Generate HE performance table
echo "Table 2: Homomorphic Encryption Performance"
echo "────────────────────────────────────────────────────────────"
printf "%-15s | %-12s | %-12s\n" "Operation" "1024-bit" "2048-bit"
echo "────────────────────────────────────────────────────────────"

enc_1024=$(grep "Time for Matrix encryption" "docs/experiment_results/keysize_1024.txt" | head -1 | awk '{print $5}')
add_1024=$(grep "Time for Matrix addition" "docs/experiment_results/keysize_1024.txt" | awk '{print $5}')
dec_1024=$(grep "Time for Matrix decryption" "docs/experiment_results/keysize_1024.txt" | awk '{print $5}')

enc_2048=$(grep "Time for Matrix encryption" "docs/experiment_results/keysize_2048.txt" | head -1 | awk '{print $5}')
add_2048=$(grep "Time for Matrix addition" "docs/experiment_results/keysize_2048.txt" | awk '{print $5}')
dec_2048=$(grep "Time for Matrix decryption" "docs/experiment_results/keysize_2048.txt" | awk '{print $5}')

printf "%-15s | %-12s | %-12s\n" "Encryption" "${enc_1024}s" "${enc_2048}s"
printf "%-15s | %-12s | %-12s\n" "Addition" "${add_1024}s" "${add_2048}s"
printf "%-15s | %-12s | %-12s\n" "Decryption" "${dec_1024}s" "${dec_2048}s"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  All experiments completed successfully!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Results saved to:"
echo "   - docs/experiment_results/epsilon_*.txt (raw outputs)"
echo "   - docs/experiment_results/keysize_*.txt (HE performance)"
echo ""
echo "Summary tables displayed above"
echo ""
echo "See docs/EXPERIMENTAL_METRICS.md for detailed analysis"
echo ""
