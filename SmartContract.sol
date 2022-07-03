// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract VatPayment {

    address payable[] private vAddresses;
    address payable owner;

    uint256 public VAT6;
    uint256 public VAT13;
    uint256 public VAT24;
    uint256 public totalVAT;   

    struct Recipient {       
      address Eaddress;
      uint amount_received;
      uint id;
   }
    
    Recipient[] private recipients;  

    event LogTransfer(address recipientsAddress, uint amount);
    event LogTransfer(address recipientsAddress, uint amount, string LevelOfVat);
    event LogTransfer(address recipientsAddress, uint amount, string LevelOfVat, string comment);

    constructor(address payable[] memory _vAddresses) {
        owner = payable(msg.sender);
        vAddresses = _vAddresses;
    
        VAT6 = 0;
        VAT13 = 0;
        VAT24 = 0;
        totalVAT = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "This can be used only by the owner.");
        _;
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    //find the recepient with biggest total ammount by checking the array of the recipients.
    //if array.length==0, the null address is returned
    function BiggestProcceds() public onlyOwner view returns (address, uint256, uint256) {
        uint idx;
        uint biggest_amount = 0;

        if(recipients.length == 0){
            return(0x0000000000000000000000000000000000000000, 0, 0);
        } else {
            for(uint i = 0; i < recipients.length; i++) {
                if(recipients[i].amount_received > biggest_amount){
                    biggest_amount = recipients[i].amount_received;
                    idx = i;
                }
            }
            return (recipients[idx].Eaddress, recipients[idx].id, recipients[idx].amount_received);
        }
    }

    function pay(address payable destinationAddress) public payable {
        require(msg.value <= 0.05 ether, "The amount to be sent should be 0.05 ETH or less!");
        
        uint256 amount = msg.value;
        destinationAddress.transfer(amount);

        emit LogTransfer(destinationAddress, msg.value);
    }

    function pay(address payable destinationAddress, uint id, uint8 vatId) public payable {
        require(vatId >= 0 && vatId < 3, "Invalid VAT id.");

        uint rec_id;
        bool found = false;
        string memory LevelOfVat;
        uint256 vat = 0;

        if(vatId == 0) {
            LevelOfVat = "24%";
            vat = msg.value * 24/100;
            VAT24 += vat;
        } else if(vatId == 1){
            LevelOfVat = "13%";
            vat = msg.value * 13/100;
            VAT13 += vat;
        } else if(vatId == 2){
            LevelOfVat = "6%";
            vat = msg.value * 6/100;
            VAT6 += vat;
        }

        totalVAT += vat;

        destinationAddress.transfer(msg.value - vat);
        vAddresses[vatId].transfer(vat);

        //check the array of recipients to check if the address exists
        for(uint i = 0; i < recipients.length; i++) {
            if(recipients[i].Eaddress == destinationAddress){
                rec_id = i;
                found = true; 
                break;
            }
        }

        if(found) {
            recipients[rec_id].amount_received += msg.value;
        } else {
            recipients.push(Recipient(destinationAddress, id, msg.value));   
        }

        emit LogTransfer(destinationAddress, msg.value, LevelOfVat);
    }

    function pay(address payable destinationAddress, uint id, uint8 vatId, string memory comment) public payable {
        require(vatId >= 0 && vatId < 3, "Invalid VAT id.");
        require(bytes(comment).length <= 80, "Comment length should not exceed 80 characters.");

        uint rec_id;
        bool found = false;
        string memory LevelOfVat;
        uint256 vat = 0;

        if(vatId == 0) {
            LevelOfVat = "24%";
            vat = msg.value * 24/100;
            VAT24 += vat;
        } else if(vatId == 1){
            LevelOfVat = "13%";
            vat = msg.value * 13/100;
            VAT13 += vat;
        } else if(vatId == 2){
            LevelOfVat = "6%";
            vat = msg.value * 6/100;
            VAT6 += vat;
        }

        totalVAT += vat;

        vAddresses[vatId].transfer(vat);
        destinationAddress.transfer(msg.value - vat);

        for(uint i = 0; i < recipients.length; i++) {
            if(recipients[i].Eaddress == destinationAddress){
                rec_id = i;
                found = true; 
                break;
            }
        }

        if(found) {
            recipients[rec_id].amount_received += msg.value;
        } else {
            recipients.push(Recipient(destinationAddress, id, msg.value));   
        }

        emit LogTransfer(destinationAddress, msg.value, LevelOfVat, comment);
    }
}
