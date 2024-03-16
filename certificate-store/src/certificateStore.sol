// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

error NotFaculty(address);
error NoresultorNotAuthorized(address);

contract CertificateStore {

constructor(string memory uri_,address _faculty , address _admin) {
    faculty = _faculty;
    admin = _admin;
    }

    // mapping (address => bool) faultyPerms;
    address faculty ;
    address admin ;


    struct certDetails{
        // address student;
        string certificateUrl;
        string certificateID;
    }

    mapping (address => certDetails) public certBook;

    modifier onlyFaculty {
        
        if(msg.sender != faculty)
        {
            revert NotFaculty(msg.sender);
        }
        _;
    }    

    modifier onlyAdmin {
           if(msg.sender == admin)
        {
            revert NotFaculty(msg.sender);
        }
        _;
    }

    modifier onlyStudent {
        if (certBook[msg.sender] == 0 ) {
            revert NoresultorNotAuthorized(msg.sender);
        }
        _;
    }

    function mintCertificate(string calldata _certUrl , address _student , string calldata _certificateId) public onlyFaculty returns(uint256){ 
        
    }

    function deleteCertificate() public onlyAdmin returns(bool){

    }

    function viewCertificate () public onlyStudent returns (string){

    }

}