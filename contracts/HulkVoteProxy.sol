// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libs/IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardLockedUp;
        uint256 nextHarvestUntil;
    }

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory);
}

contract HulkVoteProxy {
    using SafeMath for uint256;

    // Hulk Token
    address public hulk = 0x1f546aD641B56b86fD9dCEAc473d1C7a357276B7;
    // Master Chef
    address public masterChef = 0x058451C62B96c594aD984370eDA8B6FD7197bbd4;
    uint256 public hulkPoolPid = 9;
    // Trading Pairs
    address public hulkBNB = 0xC24AD5197DaeFD97DF28C70AcbDF17d9fF92a49B;
    uint256 public hulkBNBFarmPid = 17;
    address public hulkBUSD = 0x9287F5Ad55D7eE8EAE90B865718EB9A7cF3fb71A;
    uint256 public hulkBUSDFarmPid = 16;
    // Vaults
    address public autoSharkHulkPool = 0x2Bc66d715FB0887A8708eCa5d83826eB063ba551;

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "HulkToken Vote Proxy";
    }

    function symbol() external pure returns (string memory) {
        return "HULK-VOTE";
    }

    function totalSupply() external view returns (uint256) {
        return IBEP20(hulk).totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        uint256 balance;

        // Hulk in wallet
        balance = balance.add(IBEP20(hulk).balanceOf(_voter));
        // Hulk in ulk pool
        balance = balance.add(IMasterChef(masterChef).userInfo(hulkPoolPid, _voter).amount);
        // Hulk in HULK-BNB liquidity pool
        balance = balance.add(balanceInLiquidityPoolAndFarm(hulkBNB, hulkBNBFarmPid, _voter));
        // Hulk in HULK-BUSD liquidity pool
        balance = balance.add(balanceInLiquidityPoolAndFarm(hulkBUSD, hulkBUSDFarmPid, _voter));
        // Hulk in vaults
        balance = balance.add(IBEP20(autoSharkHulkPool).balanceOf(_voter));

        return balance;
    }

    function balanceInLiquidityPoolAndFarm(address pair, uint256 pid, address _voter) private view returns (uint256) {
        uint256 lpTotalSupply = IBEP20(pair).totalSupply();
        uint256 voterLpBalance = IBEP20(pair).balanceOf(_voter).add(IMasterChef(masterChef).userInfo(pid, _voter).amount);
        uint256 hulkInLp = IBEP20(hulk).balanceOf(pair);

        if (lpTotalSupply > 0) {
            return voterLpBalance.mul(1e8).div(lpTotalSupply).mul(hulkInLp).div(1e8);
        }

        return 0;
    }
}
