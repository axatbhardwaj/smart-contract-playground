// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

interface IbiKeys {
    function setMultiplier(
        string memory propertyKey,
        uint256 multiplier
    ) external;
}

/// @title A title that should describe the contract/interface
/// @author axatbhardwaj
/// @notice This is a consumer contract that sends requests to the Chainlink Functions contract to fetch the multiplier for a given property key
/// @dev This contract has hardcoded values to work on the Base Sepolia network and IbiKeys contract
contract IbicashOracleConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    mapping(bytes32 => string) public requestIdToId;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    uint64 public subscriptionId;
    address public ibiKeysAddress;

    // Custom error type
    /// @notice Thrown when the request ID does not match the expected ID
    /// @param requestId The unexpected request ID
    error UnexpectedRequestID(bytes32 requestId);

    /// @notice Thrown when the IbiKeys address is not set
    error ibiKeysAddressNotSet();

    /// @notice Thrown when the request is not from the IbiKeys contract
    /// @param sender The address that sent the request
    error requestNotFromIbikeys(address sender);

    /// @notice Thrown when the subscription ID is not set
    error noSubscriptionId();

    // Router address - Hardcoded for Base Sepolia
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xf9B8fc078197181C841c296C876945aaa425B278;

    // JavaScript source code
    // Fetch multiplier from the specified API.
    string source =
        "const propertyKey = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "  url: `http://164.52.196.63:3000/api/project_sites/${propertyKey}/multiplier`"
        "});"
        "if (apiResponse.error) {"
        "  console.error(apiResponse.error);"
        "  throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "console.log('API response data:', JSON.stringify(data, null, 2));"
        "return Functions.encodeUint256(parseInt(data.multiplier));";

    // Callback gas limit
    uint32 gasLimit = 300000;

    // donID - Hardcoded for Base Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID =
        0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;

    // Event to log responses
    /// @notice Emitted when a response is received
    /// @param requestId The ID of the request
    /// @param propertyKey The key of the property
    /// @param multiplier The multiplier value
    /// @param response The HTTP response data
    /// @param err Any errors from the Functions request
    event Response(
        bytes32 indexed requestId,
        string indexed propertyKey,
        uint256 indexed multiplier,
        bytes response,
        bytes err
    );

    // Event to log the sent request
    /// @notice Emitted when a request is sent
    /// @param requestId The ID of the request
    /// @param propertyKey The key of the property
    event RequestSent(bytes32 indexed requestId, string indexed propertyKey);

    /// @notice Ensures the caller is the IbiKeys contract
    modifier onlyIbiKeys() {
        if (msg.sender != ibiKeysAddress) {
            revert requestNotFromIbikeys(msg.sender);
        }
        _;
    }

    /// @notice Sets the subscription ID for Chainlink Functions
    /// @param _subscriptionId The subscription ID to set
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /// @notice Sets the address of the IbiKeys contract
    /// @param _ibiKeysAddress The address of the IbiKeys contract
    function setIbiKeysAddress(address _ibiKeysAddress) external onlyOwner {
        ibiKeysAddress = _ibiKeysAddress;
    }

    /// @notice Updates the multiplier for a given property key by sending a request to the consumer contract
    /// @param propertyKey The key of the property for which the multiplier is to be updated
    /// @return Returns true if the request is successfully sent
    function updateMultiplier(
        string calldata propertyKey
    ) external onlyIbiKeys returns (bool) {
        if (subscriptionId == 0) {
            revert noSubscriptionId();
        }
        sendRequest(propertyKey);
        emit RequestSent(s_lastRequestId, propertyKey);
        return true;
    }

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
        uint64 _subscriptionId,
        address _ibiKeysAddress
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        subscriptionId = _subscriptionId;
        ibiKeysAddress = _ibiKeysAddress;
    }

    /**
     * t
     * @notice Sends an HTTP request for multiplier information
     * @param propertyKey The ID to be used in the API request
     * @return requestId The ID of the request
     */
    function sendRequest(
        string calldata propertyKey
    ) internal onlyIbiKeys returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        req.setArgs(new string[](1)); // Initialize the array with one element
        req.args[0] = propertyKey; // Set the ID as an argument for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        requestIdToId[s_lastRequestId] = propertyKey;

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        uint256 multiplier = abi.decode(response, (uint256)); // Decode the response to uint256
        s_lastError = err;

        string memory propertyKey = requestIdToId[requestId];

        if (ibiKeysAddress == address(0)) {
            revert ibiKeysAddressNotSet();
        }

        // Call the IbiKeys contract to update the multiplier for the property key
        IbiKeys(ibiKeysAddress).setMultiplier(propertyKey, multiplier);

        // Emit an event to log the response
        emit Response(
            requestId,
            propertyKey,
            multiplier,
            s_lastResponse,
            s_lastError
        );
    }
}
