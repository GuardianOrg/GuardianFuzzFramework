import re

def convert_to_solidity(call_sequence):
    # Regex pattern to extract Medusa call details
    call_pattern = re.compile(
        r"^\s*\d+\)\s*(\w+\.\w+\([^)]*\)\([^)]*\))\s*\(block=(\d+),\s*time=(\d+),\s*gas=\d+,\s*gasprice=\d+,\s*value=\d+,\s*sender=(?:(?:\w+\s*\[)?(0x[0-9a-fA-F]+)\]?)\)"
    )

    solidity_code = "function test_replay() public {\n"
    matches_found = False

    # Split lines and filter out empty ones
    lines = [line.strip() for line in call_sequence.strip().split("\n") if line.strip()]
    last_index = len(lines) - 1

    for i, line in enumerate(lines):
        call_match = call_pattern.match(line)
        if call_match:
            matches_found = True
            call, block, timestamp, sender = call_match.groups()

            # Add warp line for timestamp
            solidity_code += f"    vm.warp({timestamp});\n"

            # Add roll line for block number
            solidity_code += f"    vm.roll({block});\n"

            # Add prank line for sender
            # solidity_code += f"    vm.prank(address({sender}));\n"

            # Extract function name and arguments (remove type signature and contract prefix)
            func_match = re.match(r"\w+\.(\w+)\([^)]*\)\(([^)]*)\)", call)
            if func_match:
                func_name, args = func_match.groups()
                call_clean = f"{func_name}({args})"
            else:
                call_clean = call  # Fallback if parsing fails

            # Add function call with 'this.' prefix
            if i < last_index:
                solidity_code += f"    try this.{call_clean} {{}} catch {{}}\n"
            else:
                solidity_code += f"    this.{call_clean};\n"
            solidity_code += "\n"
        else:
            print(f"Warning: Line not matched: {line}")

    solidity_code += "}"

    if not matches_found:
        print("Error: No valid Medusa calls found in the input.")

    return solidity_code

# Example usage
call_sequence = r"""
1) Fuzz.fuzz_sampleFailWithRequire(bool)(true) (block=28111, time=360616, gas=125000000, gasprice=1, value=0, sender=USER1 [0x10000])
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)