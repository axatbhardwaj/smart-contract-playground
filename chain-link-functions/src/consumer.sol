// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Anime Quote Fetcher
/// @notice This contract fetches a random anime quote from the Animechan API
/// @dev This contract uses Chainlink Functions to make HTTP GET requests
contract AnimeQuoteFetcher is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    mapping(bytes32 => string) public requestIdToQuote;
    mapping(bytes32 => string) public requestIdToAnimeName;
    mapping(bytes32 => string) public requestIdToCharacterName;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    uint64 public subscriptionId;

    event QuoteFetched(bytes32 indexed requestId, string quote, string animeName, string characterName);

    constructor(address oracle, uint64 _subscriptionId) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {
        subscriptionId = _subscriptionId;
    }

    /// @notice Sends a request to fetch a random anime quote
    function fetchQuote() public onlyOwner {
        FunctionsRequest.Request memory req;
        req.initializeRequestForHttpGet("https://animechan.io/api/v1/quotes/random");
        s_lastRequestId = sendRequest(req, subscriptionId);
    }

    /// @notice Callback function to handle the response from the Chainlink Functions
    /// @param requestId The ID of the request
    /// @param response The response from the API
    /// @param error The error message, if any
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory error) internal override {
        s_lastRequestId = requestId;
        s_lastResponse = response;
        s_lastError = error;

        if (error.length == 0) {
            // Parse the response and extract the quote, anime name, and character name
            (string memory quote, string memory animeName, string memory characterName) = parseQuote(response);
            requestIdToQuote[requestId] = quote;
            requestIdToAnimeName[requestId] = animeName;
            requestIdToCharacterName[requestId] = characterName;
            emit QuoteFetched(requestId, quote, animeName, characterName);
        }
    }

    /// @notice Parses the quote, anime name, and character name from the API response
    /// @param response The response from the API
    /// @return The extracted quote, anime name, and character name
    function parseQuote(bytes memory response) internal pure returns (string memory, string memory, string memory) {
        // Assuming the response is a JSON object with the quote in the "content" field,
        // anime name in the "anime.name" field, and character name in the "character.name" field
        // This is a simplified example, you may need to use a JSON parsing library
        string memory quote = extractValue(response, "content");
        string memory animeName = extractValue(response, "anime.name");
        string memory characterName = extractValue(response, "character.name");
        return (quote, animeName, characterName);
    }

    /// @notice Extracts a value from a JSON object
    /// @param json The JSON object
    /// @param key The key of the value to extract
    /// @return The extracted value
    function extractValue(bytes memory json, string memory key) internal pure returns (string memory) {
        // This is a simplified example, you may need to use a JSON parsing library
        // to properly extract values from the JSON object
        return string(json); // Placeholder implementation
    }
}
