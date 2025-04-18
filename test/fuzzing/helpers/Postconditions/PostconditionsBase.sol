pragma solidity ^0.8.25;

import "../../properties/Properties.sol";

contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(bytes memory returnData) internal {
        invariant_GLOB_01();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {
        invariant_ERR(returnData);
    }
}
