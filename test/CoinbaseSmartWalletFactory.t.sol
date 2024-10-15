// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {Test, console2} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {CoinbaseSmartWallet, MultiOwnable} from "../src/CoinbaseSmartWallet.sol";
import {CoinbaseSmartWalletFactory} from "../src/CoinbaseSmartWalletFactory.sol";

contract CoinbaseSmartWalletFactoryTest is Test {
    CoinbaseSmartWalletFactory factory;
    CoinbaseSmartWallet account;
    EntryPoint entryPoint;
    bytes[] owners;

    function setUp() public {
        account = new CoinbaseSmartWallet();
        factory = new CoinbaseSmartWalletFactory(address(account));
        entryPoint = new EntryPoint();
        owners.push(abi.encode(address(1)));
        owners.push(abi.encode(address(2)));
    }

    function test_constructor_setsImplementation(
        address implementation
    ) public {
        factory = new CoinbaseSmartWalletFactory(implementation);
        assertEq(factory.implementation(), implementation);
    }

    function test_createAccountSetsOwnersCorrectly() public {
        address expectedAddress = factory.getAddress(owners, 0);
        vm.expectCall(
            expectedAddress,
            abi.encodeCall(
                CoinbaseSmartWallet.initialize,
                (address(factory), owners, 0, address(entryPoint))
            )
        );
        CoinbaseSmartWallet a = factory.createAccount{value: 1e18}(
            owners,
            0,
            address(entryPoint)
        );
        assert(a.isOwnerAddress(address(1)));
        assert(a.isOwnerAddress(address(2)));
    }

    function test_revertsIfNoOwners() public {
        owners.pop();
        owners.pop();
        vm.expectRevert(CoinbaseSmartWalletFactory.OwnerRequired.selector);
        factory.createAccount{value: 1e18}(owners, 0, address(entryPoint));
    }

    function test_exitIfAccountIsAlreadyInitialized() public {
        CoinbaseSmartWallet a = factory.createAccount(
            owners,
            0,
            address(entryPoint)
        );
        vm.expectCall(
            address(a),
            abi.encodeCall(
                CoinbaseSmartWallet.initialize,
                (address(factory), owners, 0, address(entryPoint))
            ),
            0
        );
        CoinbaseSmartWallet a2 = factory.createAccount(
            owners,
            0,
            address(entryPoint)
        );
        assertEq(address(a), address(a2));
    }

    function test_RevertsIfLength32ButLargerThanAddress() public {
        bytes memory badOwner = abi.encode(uint256(type(uint160).max) + 1);
        owners.push(badOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiOwnable.InvalidEthereumAddressOwner.selector,
                badOwner
            )
        );
        factory.createAccount{value: 1e18}(owners, 0, address(entryPoint));
    }

    function test_createAccountDeploysToPredeterminedAddress() public {
        address p = factory.getAddress(owners, 0);
        CoinbaseSmartWallet a = factory.createAccount{value: 1e18}(
            owners,
            0,
            address(entryPoint)
        );
        assertEq(address(a), p);
    }

    function test_CreateAccount_ReturnsPredeterminedAddress_WhenAccountAlreadyExists()
        public
    {
        address p = factory.getAddress(owners, 0);
        CoinbaseSmartWallet a = factory.createAccount{value: 1e18}(
            owners,
            0,
            address(entryPoint)
        );
        CoinbaseSmartWallet b = factory.createAccount{value: 1e18}(
            owners,
            0,
            address(entryPoint)
        );
        assertEq(address(a), p);
        assertEq(address(a), address(b));
    }

    function testDeployDeterministicPassValues() public {
        vm.deal(address(this), 1e18);
        CoinbaseSmartWallet a = factory.createAccount{value: 1e18}(
            owners,
            0,
            address(entryPoint)
        );
        assertEq(address(a).balance, 1e18);
    }

    function test_implementation_returnsExpectedAddress() public {
        assertEq(factory.implementation(), address(account));
    }

    function test_initCodeHash() public {
        bytes32 execptedHash = LibClone.initCodeHashERC1967(address(account));
        bytes32 factoryHash = factory.initCodeHash();
        assertEq(factoryHash, execptedHash);
    }
}
