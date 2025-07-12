// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IVRFCoordinator, IVRFConsumer} from "../../src/Lumberjack.sol";

contract VRFCoordinatorMock is IVRFCoordinator {
    uint256 private nextRequestId = 1;

    mapping(uint256 => Request) public requests;
    mapping(uint256 => bool) public fulfilledRequests;

    struct Request {
        address requester;
        uint32 numNumbers;
        uint256 clientSeed;
    }

    event RequestRaised(uint256 indexed requestId, address indexed requester, uint32 numNumbers, uint256 clientSeed);

    event RequestFulfilled(uint256 indexed requestId);

    function requestRandomNumbers(uint32 numNumbers, uint256 clientSeed)
        external
        override
        returns (uint256 requestId)
    {
        requestId = nextRequestId++;

        requests[requestId] = Request({requester: msg.sender, numNumbers: numNumbers, clientSeed: clientSeed});

        emit RequestRaised(requestId, msg.sender, numNumbers, clientSeed);

        return requestId;
    }

    function fulfillRandomNumbers(uint256 requestId, uint256[] memory randomNumbers) external {
        require(requests[requestId].requester != address(0), "Invalid request");
        require(!fulfilledRequests[requestId], "Already fulfilled");

        fulfilledRequests[requestId] = true;

        // Call back to the consumer
        IVRFConsumer(requests[requestId].requester).rawFulfillRandomNumbers(requestId, randomNumbers);

        emit RequestFulfilled(requestId);
    }

    function getClientSeed(uint256 requestId) external view override returns (uint256) {
        return requests[requestId].clientSeed;
    }

    function fulfilled(uint256 requestId) external view override returns (bool) {
        return fulfilledRequests[requestId];
    }
}
