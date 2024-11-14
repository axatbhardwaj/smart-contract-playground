// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

error NotFaculty(address);
error NotAuthorized(address);

contract CertificateStore {

constructor(address _faculty , address _admin) {
    faculty = _faculty;
    admin = _admin;
    }

    // mapping (address => bool) faultyPerms;
    address faculty ;
    address admin ;

    uint256 certificateCount ;

    struct certDetails{
        // address student;
        string certificateUrl;
        uint256 certificateID;
    }

    mapping (address => certDetails) internal certBook;

    modifier onlyFaculty {
        
        if(msg.sender != faculty)
        {
            revert NotFaculty(msg.sender);
        }
        _;
    }    

    modifier onlyAdmin {
           if(msg.sender != admin)
        {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    function uploadCertificate(string calldata _certUrl , address _student) public onlyFaculty { 
        certificateCount++;

        certBook[_student]=certDetails({
            certificateID: certificateCount,
           certificateUrl : _certUrl
        });

    }

    function deleteCertificate(address _student) public onlyAdmin {
        
        certificateCount--;

        certBook[_student].certificateID=0;
        certBook[_student].certificateUrl="DELETED BY ADMIN";

    }

    function viewCertificate () public view returns (certDetails memory ){
        return certBook[msg.sender];
    }

}