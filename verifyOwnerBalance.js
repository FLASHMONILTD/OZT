const path = require('path');
const fs = require('fs');


const OZTToken = require('./build/contracts/OZTToken.json');
const Web3 = require('web3');

// LOAD PARAMETERS --------------------------------
const ETHNODE_FILEPATH = path.resolve(__dirname) + '/PARAMS/ethereum_node.txt'
const PWD_FILEPATH = path.resolve(__dirname) + '/PARAMS/owner_pwd.txt'
const CONTRACTADDRESS_FILEPATH = path.resolve(__dirname) + '/OUTPUTS/smart-contract-address.txt'

// set parameters -------------------------------------------------
var urlEthereumNode = require('fs').readFileSync(ETHNODE_FILEPATH, 'utf-8')
var ownerPassword = require('fs').readFileSync(PWD_FILEPATH, 'utf-8')
var contractAddress = require('fs').readFileSync(CONTRACTADDRESS_FILEPATH, 'utf-8')
console.log('urlEthereumNode = ' + urlEthereumNode)
console.log('ownerPwd = ' + ownerPassword)
console.log('contractAddress = ' + contractAddress)

let web3 = new Web3(new Web3.providers.HttpProvider(urlEthereumNode))
console.log('Web3 OK')

var oztContract = web3.eth.contract(OZTToken.abi).at(contractAddress);

//web3.personal.unlockAccount(web3.eth.accounts[0], ownerPassword)
console.log('unlockAccount OK')
web3.eth.defaultAccount = web3.eth.accounts[0];


var ownerAddress = web3.eth.accounts[0];

var assignedSupply = oztContract.getAssignedSupply();
console.log("assignedSupply = " + assignedSupply);

oztContract.getAddressAndBalance.call(ownerAddress, function(error, result){
    if (!error) {

        retAddress = result[0];
        retAmount = result[1];

        console.log("getAddressBalance called : " + retAmount + " tokens found for OWNER = " + retAddress); 

        console.log("TOTAL NUMBER of TOKENS = balance[owner]+assignedSupply = " + retAmount + ' <<>> ' +assignedSupply);

    } else {
        console.log("ERROR: " + error);
    }
});
   
  