// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Limiter, LimiterLibrary, Operation} from "./Limiter.sol";
import {LinkedList, LinkedListLibrary} from "./LinkedList.sol";

using LimiterLibrary for Limiter;
using LinkedListLibrary for LinkedList;

struct InternalBeneficiary {
    address account;
    Limiter limiter;
    uint256 enabledAt;
}

using InternalBeneficiaryLibrary for InternalBeneficiary;

library InternalBeneficiaryLibrary {
    function convert(InternalBeneficiary storage self) internal view returns (Beneficiary memory) {
        return
            Beneficiary({
                account: self.account,
                enabledAt: self.enabledAt,
                limit: self.limiter.limit,
                remainingLimit: self.limiter.remainingLimit(),
                transfers: self.limiter.operations()
            });
    }
}

struct Beneficiary {
    address account;
    uint256 enabledAt;
    uint256 limit;
    int256 remainingLimit;
    Operation[] transfers;
}

struct Beneficiaries {
    LinkedList _keys;
    mapping(uint128 => InternalBeneficiary) _beneficiaries;
    mapping(address => uint128) _addressKeys;
}

using BeneficiariesLibrary for Beneficiaries;

library BeneficiariesLibrary {
    error BeneficiaryAlreadyExists(address beneficiary);
    error BeneficiaryNotEnabled(address beneficiary);
    error BeneficiaryNotDefined(address beneficiary);
    error BeneficiaryLimitExceeded(address beneficiary);

    function addBeneficiary(
        Beneficiaries storage self,
        address _beneficiary,
        uint256 _limit,
        uint256 _cooldown
    ) internal {
        if (self._addressKeys[_beneficiary] != 0) {
            revert BeneficiaryAlreadyExists(_beneficiary);
        }
        uint128 key = self._keys.generate();
        self._beneficiaries[key].account = _beneficiary;
        self._beneficiaries[key].enabledAt = block.timestamp + _cooldown;
        self._beneficiaries[key].limiter.limit = _limit;
        self._addressKeys[_beneficiary] = key;
    }

    function setBeneficiaryLimit(Beneficiaries storage self, address _beneficiary, uint256 _limit) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.limit = _limit;
    }

    function temporarilyIncreaseBeneficiaryLimit(
        Beneficiaries storage self,
        address _beneficiary,
        uint256 _limitIncrease
    ) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.temporarilyIncreaseLimit(_limitIncrease);
    }

    function temporarilyDecreaseBeneficiaryLimit(
        Beneficiaries storage self,
        address _beneficiary,
        uint256 _limitDecrease
    ) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.temporarilyDecreaseLimit(_limitDecrease);
    }

    function addBeneficiaryTransfer(Beneficiaries storage self, address _beneficiary, uint256 _amount) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        if (block.timestamp < beneficiary.enabledAt) {
            revert BeneficiaryNotEnabled(_beneficiary);
        }
        if (!beneficiary.limiter.addOperation(_amount)) {
            revert BeneficiaryLimitExceeded(_beneficiary);
        }
    }

    function _getBeneficiaryKey(Beneficiaries storage self, address _beneficiary) private view returns (uint128) {
        uint128 key = self._addressKeys[_beneficiary];
        if (key == 0) {
            revert BeneficiaryNotDefined(_beneficiary);
        }
        return key;
    }

    function _getBeneficiary(
        Beneficiaries storage self,
        address _beneficiary
    ) private view returns (InternalBeneficiary storage) {
        return self._beneficiaries[_getBeneficiaryKey(self, _beneficiary)];
    }

    function getBeneficiary(
        Beneficiaries storage self,
        address _beneficiary
    ) internal view returns (Beneficiary memory) {
        return _getBeneficiary(self, _beneficiary).convert();
    }

    function removeBeneficiary(Beneficiaries storage self, address _beneficiary) internal {
        uint128 key = _getBeneficiaryKey(self, _beneficiary);
        self._beneficiaries[key].limiter.removeOperations();
        delete self._beneficiaries[key];
        delete self._addressKeys[_beneficiary];
        self._keys.remove(key);
    }

    function getBeneficiaries(Beneficiaries storage self) internal view returns (Beneficiary[] memory) {
        Beneficiary[] memory beneficiaries = new Beneficiary[](self._keys.length());
        uint256 index = 0;
        uint128 key = self._keys.first();
        while (key != 0) {
            beneficiaries[index] = self._beneficiaries[key].convert();
            key = self._keys.next(key);
            index++;
        }
        return beneficiaries;
    }
}
