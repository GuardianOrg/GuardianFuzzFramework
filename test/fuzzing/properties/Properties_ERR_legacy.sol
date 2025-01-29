// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";

/*
*   FUZZER NOTE: 
* 
*   This default invariant raises on every possible revert:
*    - require fails,
*    - assertion fails, 
*    - Error(sting) errors,
*    - unwhitelisted Panic(uint) codes,
*    - unwhiteslites protocol errors
*    - empty returnData
*
*   - *Choose* if catching require() or revert() errors, by commenting the line:    
*     // fl.t(false, "require() or revert() or unhandled error encountered!");
*
*   - Choose if allow reverts with empty bytes returnData, by uncommenting the line:  
*     // allowedErrors[1] = bytes4(abi.encode(""));  
*     // getPanicCode() will fail if empty revert is allowed, revert will return 0
*     // _getRevertMsg() will fail if empty revert is allowed, revert will return "Invalid revert data length"
*
*   - Choose if allow unknown panic codes, by uncommenting the line:
*     - PANIC_ASSERT
*     - PANIC_ARITHMETIC
*     - PANIC_DIVISION_BY_ZERO
*     - PANIC_STORAGE_BYTES_ARRAY_ENCODING
*     - PANIC_ALLOC_TOO_MUCH_MEMORY
*     - PANIC_ZERO_INIT_INTERNAL_FUNCTION
*
*   - Choose if allow legacy ERC20 errors, creating SEPARATE property keccak256(returnData) == keccak256(INSUFFICIENT_ALLOWANCE):
*     - INSUFFICIENT_ALLOWANCE
*     - TRANSFER_FROM_ZERO
*     - TRANSFER_TO_ZERO
*     - APPROVE_TO_ZERO
*     - MINT_TO_ZERO
*     - BURN_FROM_ZERO
*     - BURN_EXCEEDS_BALANCE
*     - EXCEEDS_BALANCE_ERROR
*/

abstract contract Properties_ERR is PropertiesBase {
    function invariant_ERR(bytes memory returnData) internal {
        bytes4 returnedError;
        assembly {
            returnedError := mload(add(returnData, 0x20))
        }

        // ==============================================================
        // PANIC HANDLING
        // ==============================================================

        if (returnedError == bytes4(keccak256("Panic(uint256)"))) {
            uint256[] memory panicCodes = new uint256[](3);

            // Ignore:
            panicCodes[0] = PANIC_ENUM_OUT_OF_BOUNDS; // Enum conversion out of bounds
            panicCodes[1] = PANIC_POP_EMPTY_ARRAY; // Pop on empty array
            panicCodes[2] = PANIC_ARRAY_OUT_OF_BOUNDS; // Array index out of bounds

            // Throw on (commented for reference):
            // PANIC_ASSERT                          // Assertion error
            // PANIC_ARITHMETIC                      // Arithmetic underflow or overflow
            // PANIC_DIVISION_BY_ZERO               // Division or modulo by zero
            // PANIC_STORAGE_BYTES_ARRAY_ENCODING   // Storage byte array incorrectly encoded
            // PANIC_ALLOC_TOO_MUCH_MEMORY         // Memory allocation overflow
            // PANIC_ZERO_INIT_INTERNAL_FUNCTION    // Call to a non-contract address

            // Use the new getPanicCode function instead of inline assembly
            uint256 panicCode = getPanicCode(returnData);

            // Check if it's a known panic code
            bool isKnownPanic = false;
            for (uint256 i = 0; i < panicCodes.length; i++) {
                if (panicCode == panicCodes[i]) {
                    isKnownPanic = true;
                    break;
                }
            }

            fl.log("Panic code", bytes32(panicCode));

            if (!isKnownPanic) {
                fl.t(false, "Disallowed Panic code encountered!");
            }
            // ==============================================================
            // ERC20 v4.9 ERROR HANDLING
            // ==============================================================
        } else if (returnedError == bytes4(keccak256("Error(string)"))) {
            string memory revertMsg = _getRevertMsg(returnData);
            fl.log("Error(string) revert returnData: ", revertMsg);
            // Get the actual revert message for logging

            if (
                keccak256(returnData) == keccak256(INSUFFICIENT_ALLOWANCE)
                    || keccak256(returnData) == keccak256(TRANSFER_FROM_ZERO)
                    || keccak256(returnData) == keccak256(TRANSFER_TO_ZERO)
                    || keccak256(returnData) == keccak256(APPROVE_TO_ZERO)
                    || keccak256(returnData) == keccak256(MINT_TO_ZERO)
                    || keccak256(returnData) == keccak256(BURN_FROM_ZERO)
                    || keccak256(returnData) == keccak256(DECREASED_ALLOWANCE)
                    || keccak256(returnData) == keccak256(BURN_EXCEEDS_BALANCE)
                    || keccak256(returnData) == keccak256(EXCEEDS_BALANCE_ERROR)
            ) {
                console.log("ERC20 error");
            } else {
                string memory revertMsg = _getRevertMsg(returnData);
                fl.t(false, revertMsg);
            }

            // ==============================================================
            // PROTOCOL CUSTOM ERRORS HANDLING
            // ==============================================================
        } else {
            fl.log("Custom protocol error returnData: ", _getRevertMsg(returnData));

            bytes4[] memory allowedErrors = new bytes4[](2);

            // OracleCouncilV2 Errors [0-1]
            // allowedErrors[0] = SampleContract.SampleError.selector; //excluded to reproduce

            // EVM errors returns nothing
            // allowedErrors[1] = bytes4(abi.encode("")); //NOTE: choose if allow empty reverts,

            fl.errAllow(returnedError, allowedErrors, ERR_01);
        }
    }

    function getPanicCode(bytes memory revertData) internal returns (uint256) {
        fl.log("REVERT DATA LENGTH", revertData.length);
        if (revertData.length < 36) {
            fl.t(false, "Unexpected revert data length for panic code"); // Fail the test instead of silent return
            return 0;
        }

        uint256 panicCode;
        assembly {
            panicCode := mload(add(revertData, 36))
        }
        return panicCode;
    }

    function _getRevertMsg(bytes memory _returnData) internal returns (string memory) {
        if (_returnData.length < 68) {
            fl.log("Raw revert data (hex)", _returnData); // Log the raw data
            fl.t(false, "Returned data is not a valid revert message"); // Fail the test
            return "Invalid revert data length";
        }

        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}
