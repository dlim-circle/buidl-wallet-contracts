/*
 * Copyright 2024 Circle Internet Group, Inc. All rights reserved.

 * SPDX-License-Identifier: GPL-3.0-or-later

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.24;

import {IERC777} from "@openzeppelin/contracts/interfaces/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/interfaces/IERC777Recipient.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";
import {NotImplemented} from "../../src/msca/6900/shared/common/Errors.sol";

contract TestERC777 is IERC777 {
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount);

    mapping(address => uint256) private _balances;
    IERC1820Registry private erc1820Registry;

    constructor(IERC1820Registry _erc1820Registry) {
        erc1820Registry = _erc1820Registry;
    }

    // just for testing
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }

    function send(address to, uint256 amount, bytes calldata) public override {
        transferFrom(msg.sender, to, amount);
        emit Sent(msg.sender, msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address implementer = erc1820Registry.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer == address(0)) {
            revert NotImplemented(msg.sig, 0);
        }
        IERC777Recipient(to).tokensReceived(msg.sender, from, to, amount, bytes(""), bytes(""));
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }

    function balanceOf(address tokenHolder) public view returns (uint256) {
        return _balances[tokenHolder];
    }

    function burn(uint256 amount, bytes calldata data) external {}

    function granularity() external view returns (uint256) {
        return 0;
    }

    function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
        return false;
    }

    function name() external view returns (string memory) {
        return "777";
    }

    function symbol() external view returns (string memory) {
        return "777";
    }

    function totalSupply() external view returns (uint256) {
        return 1000;
    }

    function authorizeOperator(address) external {}

    function revokeOperator(address) external {}

    function defaultOperators() external view returns (address[] memory a) {
        return new address[](0);
    }

    function operatorSend(address, address, uint256, bytes calldata, bytes calldata) external {}

    function operatorBurn(address, uint256, bytes calldata, bytes calldata) external {}
}
