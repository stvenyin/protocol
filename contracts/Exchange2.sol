/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.4.23;
pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";

import "./lib/AddressUtil.sol";
import "./lib/BytesUtil.sol";
import "./lib/ERC20.sol";
import "./lib/MathUint.sol";
import "./lib/MultihashUtil.sol";
import "./lib/NoDefaultFunc.sol";
import "./utils/Data.sol";
import "./utils/OrderSpec.sol";
import "./utils/OrderUtil.sol";
import "./IBrokerRegistry.sol";
import "./IBrokerInterceptor.sol";
import "./IExchange.sol";
import "./ITokenRegistry.sol";
import "./ITradeDelegate.sol";
import "./new/Inputs.sol";
import "./new/OrderSpecs.sol";


/// @title An Implementation of IExchange.
/// @author Daniel Wang - <daniel@loopring.org>,
/// @author Kongliang Zhong - <kongliang@loopring.org>
///
/// Recognized contributing developers from the community:
///     https://github.com/Brechtpd
///     https://github.com/rainydio
///     https://github.com/BenjaminPrice
///     https://github.com/jonasshen
///     https://github.com/Hephyrius
contract Exchange2 is  NoDefaultFunc {
    using AddressUtil   for address;
    using MathUint      for uint;
    using OrderSpec     for uint16;
    using OrderUtil     for Data.Order;

    address public  lrcTokenAddress             = 0x0;
    address public  tokenRegistryAddress        = 0x0;
    address public  delegateAddress             = 0x0;
    address public  brokerRegistryAddress       = 0x0;

    uint64  public  ringIndex                   = 0;

    // Exchange rate (rate) is the amount to sell or sold divided by the amount
    // to buy or bought.
    //
    // Rate ratio is the ratio between executed rate and an order's original
    // rate.
    //
    // To require all orders' rate ratios to have coefficient ofvariation (CV)
    // smaller than 2.5%, for an example , rateRatioCVSThreshold should be:
    //     `(0.025 * RATE_RATIO_SCALE)^2` or 62500.
    uint    public rateRatioCVSThreshold        = 0;

    uint    public constant MAX_RING_SIZE       = 8;

    uint    public constant RATE_RATIO_SCALE    = 10000;

    constructor(
        address _lrcTokenAddress,
        address _tokenRegistryAddress,
        address _delegateAddress,
        address _brokerRegistryAddress,
        uint    _rateRatioCVSThreshold
        )
        public
    {
        require(_lrcTokenAddress.isContract());
        require(_tokenRegistryAddress.isContract());
        require(_delegateAddress.isContract());
        require(_brokerRegistryAddress.isContract());

        require(_rateRatioCVSThreshold > 0);

        lrcTokenAddress = _lrcTokenAddress;
        tokenRegistryAddress = _tokenRegistryAddress;
        delegateAddress = _delegateAddress;
        brokerRegistryAddress = _brokerRegistryAddress;
        rateRatioCVSThreshold = _rateRatioCVSThreshold;
    }

    struct NewContext {
        ITradeDelegate         delegate;
        IBrokerRegistry        brokerRegistry;
        Inputs                 inputs;
        OrderSpecs             orderSpecs;
        uint8[][]   ringSpecs;

        uint numOrders;
        uint numRings;

        Data.Order[] orders;
        Data.Ring[]  rings;
    }

    function submitRings(
        uint16[]    orderSpecs,
        uint8[][]   ringSpecs,
        address[]   addressList,
        uint[]      uintList,
        bytes[]     bytesList
        )
        public
    {
        NewContext memory ctx = NewContext(
            ITradeDelegate(delegateAddress),
            IBrokerRegistry(brokerRegistryAddress),
            new Inputs(addressList, uintList, bytesList),
            new OrderSpecs(orderSpecs),
            ringSpecs,
            orderSpecs.length,
            ringSpecs.length,
            new Data.Order[](orderSpecs.length),
            new Data.Ring[](ringSpecs.length)
        );

        assembleOrders(ctx);
        assembleRings(ctx);
    }

    function assembleOrders(
        NewContext ctx
        )
        internal
    {
        for (uint i = 0; i < ctx.numOrders; i++) {

        }
    }

    function updateOrders(
        NewContext ctx
        )
        internal
    {
        for (uint i = 0; i < ctx.numOrders; i++) {
            Data.Order memory order = ctx.orders[i];
            order.hash = order.getHash();
            order.spendableS = order.getSpendable(ctx.delegate, order.tokenS);
            order.spendableLRC = order.getSpendable(ctx.delegate, lrcTokenAddress);
            order.filledAmount = order.getFilledAmount(ctx.delegate);
            order.scaleBasedOnSpendableAndHistory(ctx.delegate, 0, 0);
        }
    }

    function assembleRings(
        NewContext ctx
        )
        internal
    {
        for (uint i = 0; i < ctx.numRings; i++) {
            uint8[] memory spec = ctx.ringSpecs[i];
            Data.Participation[] memory parts = new Data.Participation[](spec.length);

            for (uint j = 0; j < spec.length; j++) {
                parts[j] = Data.Participation(
                    spec[j],
                    ctx.inputs.nextUint(),
                    ctx.inputs.nextUint()
                );
            }

            ctx.rings[i] = Data.Ring(parts);
        }

    }
}