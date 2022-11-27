// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
/////////╭━━━━┳╮╱╱╱╱╱╭━━━╮///////////////
/////////┃╭╮╭╮┃┃╱╱╱╱╱┃╭━╮┃///////////////
/////////╰╯┃┃╰┫╰━┳━━╮┃┃╱┃┣━━┳━━┳┳━━╮/////
/////////╱╱┃┃╱┃╭╮┃┃━┫┃┃╱┃┃╭╮┃━━╋┫━━┫/////
/////////╱╱┃┃╱┃┃┃┃┃━┫┃╰━╯┃╭╮┣━━┃┣━━┃/////
/////////╱╱╰╯╱╰╯╰┻━━╯╰━━━┻╯╰┻━━┻┻━━╯/////
///////////////////////////////////////*/

interface IOasisRegistry {
    function evolvedCamels() external view returns (address);

    function crazyCamels() external view returns (address);

    function oasisTreasury() external view returns (address);

    function oasisGraveyard() external view returns (address);

    function oasisStakingToken() external view returns (address);

    function oasisMint() external view returns (address);

    function oasisToken() external view returns (address);

    function oasisShop() external view returns (address);

    function oasisStake() external view returns (address);

    function oasisMarketplace() external view returns (address);
}
