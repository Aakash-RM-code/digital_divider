

# High-Speed and Area-Efficient Digital Divider

## Problem Statement

Design and implement a high-speed and area-efficient digital
divider and investigate different division architectures with
respect to speed, area, power and latency.

## Implemented Architectures

This project implements two parameterized iterative division
architectures:

1. Restoring Division
2. Non-Restoring Division

Both architectures produce:

- Quotient
- Remainder
- Busy indication
- Done indication
- Divide-by-zero indication

## Architecture

The divider uses a sequential iterative datapath.

Each division performs one division iteration per clock cycle.

The operand width is configurable through the WIDTH parameter.

Example:

```systemverilog
restoring_divider #(
    .WIDTH(16)
)