// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {MyToken} from "./MyToken.sol";

/// @custom:oz-upgrades-from TokenFactory
contract TokenFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    MyToken myToken;
    struct deployedToken {
      uint perMint;
      uint totalSupply;
    }
    mapping(address => deployedToken) public tokens;

    // 使用了UUPSUpgradeable就要在构造函数里面使用_disableInitializers() 来初始化代理合约
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
      __Ownable_init(initialOwner);
      __UUPSUpgradeable_init();
    }

    /**
     * 该方法用来创建 ERC20 token，（模拟铭文的 deploy），
     * symbol 表示 Token 的名称，totalSupply 表示可发行的数量
     * perMint 用来控制每次发行的数量, 用于控制mintInscription函数每次发行的数量
     */
    function deployInscription(
      string memory name,
      string memory symbol,
      uint totalSupply,
      uint perMint
    ) public returns(address){
      require(bytes(symbol).length > 0, "Symbol cannot be empty");
      require(totalSupply > 0, "Total supply must be greater than zero");
      require(perMint > 0, "Per mint must be greater than zero");

      // 使用 Clones 库创建最小代理合约实例
      address newToken = Clones.clone(address(myToken));
      MyToken(newToken).initialize(msg.sender, name, symbol);

      address tokenAddr = address(newToken);

      tokens[tokenAddr] = deployedToken({
        perMint: perMint,
        totalSupply: totalSupply
      });

      return tokenAddr;
    }

    /**
     *  用来发行 ERC20 token，每次调用一次，发行perMint指定的数量
     */
    function mintInscription(address tokenAddr) public {
      MyToken token = MyToken(tokenAddr); 
      deployedToken memory tokenInfo = tokens[tokenAddr];
      token.mint(msg.sender, tokenInfo.perMint, tokenInfo.totalSupply); 
    }

    function _authorizeUpgrade(
      address newImplementation
    ) internal override onlyOwner {}

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        myToken = MyToken(_tokenAddress);
    }
}