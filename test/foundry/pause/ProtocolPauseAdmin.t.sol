// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { Errors } from "contracts/lib/Errors.sol";
import { ProtocolAdmin } from "contracts/lib/ProtocolAdmin.sol";
import { IProtocolPauseAdmin } from "contracts/interfaces/pause/IProtocolPauseAdmin.sol";

import { IAccessManaged } from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import { ProtocolPausableUpgradeable } from "contracts/pause/ProtocolPausableUpgradeable.sol";

import { BaseTest } from "../utils/BaseTest.t.sol";
import { MockProtocolPausable } from "../mocks/MockProtocolPausable.sol";
import { TestProxyHelper } from "../utils/TestProxyHelper.sol";

contract ProtocolPauseAdminTest is BaseTest {
    MockProtocolPausable pausable;

    function setUp() public override {
        super.setUp();
        address impl = address(new MockProtocolPausable());
        pausable = MockProtocolPausable(
            TestProxyHelper.deployUUPSProxy(
                impl,
                abi.encodeCall(MockProtocolPausable.initialize, address(protocolAccessManager))
            )
        );
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ProtocolPausableUpgradeable.pause.selector;
        selectors[1] = ProtocolPausableUpgradeable.unpause.selector;
        vm.prank(u.admin);
        protocolAccessManager.setTargetFunctionRole(
            address(pausable),
            selectors,
            ProtocolAdmin.PAUSE_ADMIN_ROLE
        );

    }

    function test_protocolPauser_validate_config() public {
        assertTrue(protocolPauser.isPausableRegistered(address(accessController)));
        assertTrue(protocolPauser.isPausableRegistered(address(disputeModule)));
        assertTrue(protocolPauser.isPausableRegistered(address(licensingModule)));
        assertTrue(protocolPauser.isPausableRegistered(address(royaltyModule)));
        assertTrue(protocolPauser.isPausableRegistered(address(royaltyPolicyLAP)));
        assertTrue(protocolPauser.isPausableRegistered(address(ipAssetRegistry)));
    }

    function test_protocolPauser_addPausable() public {
        vm.expectEmit();
        emit IProtocolPauseAdmin.PausableAdded(address(pausable));
        vm.prank(u.admin);
        protocolPauser.addPausable(address(pausable));
        assertTrue(protocolPauser.isPausableRegistered(address(pausable)));
    }

    function test_protocolPauser_addPausable_revert_zero() public {
        vm.prank(u.admin);
        vm.expectRevert(Errors.ProtocolPauseAdmin__ZeroAddress.selector);
        protocolPauser.addPausable(address(0));
    }

    function test_protocolPauser_addPausable_revert_notPausable() public {
        vm.prank(u.admin);
        vm.expectRevert();
        protocolPauser.addPausable(address(u.admin));
    }

    function test_protocolPauser_addPausable_revert_paused() public {
        vm.startPrank(u.admin);
        pausable.pause();
        vm.expectRevert();
        protocolPauser.addPausable(address(pausable));
        vm.stopPrank();
    }

    function test_protocolPauser_addPausable_revert_alreadyAdded() public {
        vm.prank(u.admin);
        vm.expectRevert(Errors.ProtocolPauseAdmin__PausableAlreadyAdded.selector);
        protocolPauser.addPausable(address(licensingModule));
    }

    function test_protocolPauser_addPausable_revert_notAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        protocolPauser.addPausable(address(protocolPauser));
    }

    function test_protocolPauser_removePausable() public {
        vm.startPrank(u.admin);
        protocolPauser.addPausable(address(pausable));

        vm.expectEmit();
        emit IProtocolPauseAdmin.PausableRemoved(address(pausable));
        protocolPauser.removePausable(address(pausable));
        assertFalse(protocolPauser.isPausableRegistered(address(pausable)));
        vm.stopPrank();
    }

    function test_protocolPauser_removePausable_notFound() public {
        vm.prank(u.admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.ProtocolPauseAdmin__PausableNotFound.selector, address(u.admin)));
        protocolPauser.removePausable(address(u.admin));
    }

    function test_ProtocolPauseAdmin_pauseAll() public {
        vm.prank(u.admin);
        protocolAccessManager.grantRole(ProtocolAdmin.PAUSE_ADMIN_ROLE, address(u.bob), 0);

        vm.expectEmit(address(protocolPauser));
        emit IProtocolPauseAdmin.ProtocolPaused();
        vm.prank(u.bob);
        protocolPauser.pauseAll();
        assertTrue(protocolPauser.isAllProtocolPaused());
    }

    function test_ProtocolPauseAdmin_pauseAll_revert_notPauser() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        protocolPauser.pauseAll();
    }

    function test_ProtocolPauseAdmin_pause() public {
        vm.prank(u.admin);
        protocolPauser.addPausable(address(pausable));


        vm.prank(u.admin);
        protocolAccessManager.grantRole(ProtocolAdmin.PAUSE_ADMIN_ROLE, u.bob, 0);

        address[] memory pausables = new address[](2);
        pausables[0] = address(pausable);
        pausables[1] = address(accessController);

        vm.startPrank(u.bob);
        protocolPauser.pause(pausables);
        assertTrue(pausable.paused());
        assertTrue(accessController.paused());
        assertFalse(protocolPauser.isAllProtocolPaused());
    }

    function test_ProtocolPauseAdmin_pause_revert_notPauser() public {
        address[] memory pausables = new address[](2);
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        protocolPauser.pause(pausables);
    }

    function test_ProtocolPauseAdmin_pause_revert_pausableNotFound() public {
        vm.prank(u.admin);
        protocolAccessManager.grantRole(ProtocolAdmin.PAUSE_ADMIN_ROLE, u.bob, 0);
        address[] memory pausables = new address[](1);
        pausables[0] = address(pausable);

        vm.startPrank(u.bob);
        vm.expectRevert(abi.encodeWithSelector(Errors.ProtocolPauseAdmin__PausableNotFound.selector, address(pausable)));
        protocolPauser.pause(pausables);
    }


    function test_ProtocolPauseAdmin_unpauseAll() public {
        vm.prank(u.admin);
        protocolAccessManager.grantRole(ProtocolAdmin.PAUSE_ADMIN_ROLE, u.bob, 0);

        vm.startPrank(u.bob);
        protocolPauser.pauseAll();
        vm.expectEmit();
        emit IProtocolPauseAdmin.ProtocolUnpaused();
        protocolPauser.unpauseAll();
        assertFalse(protocolPauser.isAllProtocolPaused());
    }

    function test_ProtocolPauseAdmin_notPaused_ifNoPausables() public {
        vm.startPrank(u.admin);
        protocolPauser.removePausable(address(accessController));
        protocolPauser.removePausable(address(disputeModule));
        protocolPauser.removePausable(address(licensingModule));
        protocolPauser.removePausable(address(royaltyModule));
        protocolPauser.removePausable(address(royaltyPolicyLAP));
        protocolPauser.removePausable(address(ipAssetRegistry));
        vm.stopPrank();
        assertFalse(protocolPauser.isAllProtocolPaused());
    }
}
