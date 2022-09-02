// SPDX-License-Identifier: GPL-3.0

pragma solidity  0.8.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract Constant_Product_AMM{

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public  reserve0;
    uint public  reserve1;

    uint public  total_LPtokens;
    mapping(address => uint) public LPtokens_ofuser;


    constructor(address _token0,address _token1){
        token0 = IERC20(_token0);       
        token1 = IERC20(_token1);
    }

    function _mintLP(address _account,uint _amount) private{
        total_LPtokens += _amount;
        LPtokens_ofuser[_account] += _amount;
    }

    function _burnLP(address _account,uint _amount) private{
        total_LPtokens -= _amount;
        LPtokens_ofuser[_account] -= _amount;
    }

    function add_Liquidity(uint _amount0,uint _amount1) external{
        (reserve0 == 0 )  ?
        require(_amount0 == _amount1):
        require((_amount0/_amount1) == (reserve0/reserve1),"wrong proportion") ;

        token0.transferFrom(msg.sender, address(this), _amount0);
        reserve0 += _amount0;
        token1.transferFrom(msg.sender, address(this), _amount1);
        reserve1 += _amount1;

        uint LPs_tomint;

        total_LPtokens == 0 ?  
        LPs_tomint = sqrt(reserve0 * reserve1):
        LPs_tomint = (total_LPtokens * _amount1) /reserve1 ;

        require(LPs_tomint > 0);
        _mintLP(msg.sender, LPs_tomint);
        // here the lptokens will have a separate erc20 address so the transferFrom function to transfer the lp tokens    
        // but this contract is just for simplifying things AND understanding the math and function flow

    }

    function swap(address _tokenIn,uint _amountIn) external{
        bool token0_In = _tokenIn == address(token0);
        bool token1_In = _tokenIn == address(token1);

        require(token0_In || token1_In,"invalid token In");
        require(_amountIn > 0);

        //swap IN
        token0_In ? 
        (token0.transferFrom(msg.sender,address(this),_amountIn), reserve0 += _amountIn):
        (token1.transferFrom(msg.sender,address(this),_amountIn), reserve1 += _amountIn);

        // 0.25% fees
        uint _amountfee = (_amountIn * 975)/1000;

        // swap OUT
        uint _amountOUT;
        token1_In ?
        ( _amountOUT = (reserve1 * _amountfee)/(reserve0 + _amountfee),
        reserve1 -= _amountOUT0, 
        token1.transfer(msg.sender, _amountOUT0)) :

        (_amountOUT =(reserve0 * _amountfee)/(reserve1 + _amountfee) ,
        reserve0 -= _amountOUT, 
        token0.transfer(msg.sender, _amountOUT));
        
    }

    function remove_liquidity(uint _LPtokensIn) external {
        require(LPtokens_ofuser[msg.sender] > 0);

        uint _tokenOut =  _LPtokensIn * reserve0/total_LPtokens;

        require(_tokenOut > 0);
        
        _burnLP(msg.sender, _tokenOut);
        reserve0 -= _tokenOut;
        reserve1 -= _tokenOut; 

        token0.transfer(msg.sender, _tokenOut);
        token1.transfer(msg.sender, _tokenOut);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
