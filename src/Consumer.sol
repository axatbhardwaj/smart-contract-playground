// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract AnimeConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string public s_lastQuote;
    string public s_lastCharacter;
    string public s_lastAnime;

    bytes32 donID =
        0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;

    uint64 subscriptionId = 216;

    // Callback gas limit
    uint32 gasLimit = 300000;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    constructor(
        address router
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    string source =
        "const apiResponse = await Functions.makeHttpRequest({"
        "  url: 'https://animechan.io/api/v1/quotes/random'"
        "});"
        "if (apiResponse.error) {"
        "  console.error(apiResponse.error);"
        "  throw Error('Request failed');"
        "}"
        "const data = apiResponse.data.data;"
        "const quote = data.content;"
        "const anime = data.anime.name;"
        "const character = data.character.name;"
        "return Functions.encodeString(JSON.stringify({ quote, anime, character }));";

    function sendRequest() external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        // Destructure the response data
        string memory quote = abi.decode(response, (string));

        // Save the destructured response to state variables
        s_lastQuote = quote;

        s_lastError = err;
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}
