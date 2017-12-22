
const fs = require('fs');
const path = require('path');

const CONTRACTADDRESS_FILEPATH = path.resolve(__dirname) + '/../OUTPUTS/smart-contract-address.txt'

var OZTToken = artifacts.require("./OZTToken.sol");

module.exports = function(deployer) {
  deployer.deploy(OZTToken).then(function() {   
    
            console.log('OZTToken.address = ' + OZTToken.address)
            fs.writeFile(CONTRACTADDRESS_FILEPATH, OZTToken.address, function(err) {
              if(err) {
                  return console.log(err);
              }
              console.log("The file " + CONTRACTADDRESS_FILEPATH + " was saved!");
          }); 
        });
};
