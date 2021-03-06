pragma solidity 0.4.15;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract OZTToken is StandardToken, Ownable {

	/* Overriding some ERC20 variables */
	string public constant name      = "OZTToken";
	string public constant symbol    = "OZT";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_NUM_OZT_TOKENS    =  730000000 * 10 ** decimals;

	// Freeze duration for Advisors accounts
	// uint256 public constant START_ICO_TIMESTAMP   = 1501595111;  // ONLY FOR TESTING! CHANGE IN PROD!  line to decomment for the PROD before the main net deployment
	uint256 public START_ICO_TIMESTAMP; // !!! line to remove before the main net deployment (not constant for testing and overwritten in the constructor)
	int public constant DEFROST_MONTH_IN_MINUTES = 1; // month in minutes  (1month = 43200 min) ONLY FOR TESTING! CHANGE IN PROD!
	int public constant DEFROST_MONTHS = 3; 	

	/*
		modalités de sorties des advisors investisseurs ou des earlybirds j’opte pour 
		- un Freeze à 6 mois puis au bout du 6ème mois
		- possible de sortir du capital de 50% du montant investi 
		- puis par la suite 5% tous les mois ce qui nous donnera une sortie effective au bout de 10 mois et au total ça fera donc 16 mois 
	*/

	uint public constant DEFROST_FACTOR = 20;

	// Fields that can be changed by functions
	address[] public vIcedBalances;
	mapping (address => uint256) public icedBalances_frosted;
    mapping (address => uint256) public icedBalances_defrosted;

	// Variable usefull for verifying that the assignedSupply matches that totalSupply
	uint256 public assignedSupply;
	//Boolean to allow or not the initial assignement of token (batch)
	bool public batchAssignStopped = false;
	bool public stopDefrost = false;

	uint oneTokenWeiPrice;
	address defroster;

	function OZTToken() {
		owner                	= msg.sender;
		assignedSupply = 0;

		// mint all tokens
        balances[msg.sender] = MAX_NUM_OZT_TOKENS;
        Transfer(address(0x0), msg.sender, MAX_NUM_OZT_TOKENS);

		// for test only: set START_ICO to contract creation timestamp
		START_ICO_TIMESTAMP = now; // line to remove before the main net deployment 
	}

	function setDefroster(address addr) onlyOwner {
		defroster = addr;
	}

 	modifier onlyDefrosterOrOwner() {
        require(msg.sender == defroster || msg.sender == owner);
        _;
    }

	/**
   * @dev Transfer tokens in batches (of adresses)
   * @param _vaddr address The address which you want to send tokens from
   * @param _vamounts address The address which you want to transfer to
   */
  function batchAssignTokens(address[] _vaddr, uint[] _vamounts, uint[] _vDefrostClass ) onlyOwner {
	  
			require ( batchAssignStopped == false );
			require ( _vaddr.length == _vamounts.length && _vaddr.length == _vDefrostClass.length);
			//Looping into input arrays to assign target amount to each given address
			for (uint index=0; index<_vaddr.length; index++) {

				address toAddress = _vaddr[index];
				uint amount = SafeMath.mul(_vamounts[index], 10 ** decimals);
				uint defrostClass = _vDefrostClass[index]; // 0=ico investor, 1=reserveandteam/advisors
							
				if (  defrostClass == 0 ) {
					// investor account
					transfer(toAddress, amount);
					assignedSupply = SafeMath.add(assignedSupply, amount);
				}
				else if(defrostClass == 1){
				
					// Iced account. The balance is not affected here
                    vIcedBalances.push(toAddress);                  
                    icedBalances_frosted[toAddress] = amount;
					icedBalances_defrosted[toAddress] = 0;
					assignedSupply = SafeMath.add(assignedSupply, amount);
				}
			}
	}

	function getBlockTimestamp() constant returns (uint256){
		return now;
	}

	function getAssignedSupply() constant returns (uint256){
		return assignedSupply;
	}

	function elapsedMonthsFromICOStart() constant returns (int elapsed) {
		elapsed = (int(now-START_ICO_TIMESTAMP)/60)/DEFROST_MONTH_IN_MINUTES;
	}

	function getDefrostFactor()constant returns (uint){
		return DEFROST_FACTOR;
	}
	
	function lagDefrost()constant returns (int){
		return DEFROST_MONTHS;
	}

	function canDefrost() constant returns (bool){
		int numMonths = elapsedMonthsFromICOStart();
		return  numMonths > DEFROST_MONTHS && 
							uint(numMonths) <= SafeMath.add(uint(DEFROST_MONTHS),  DEFROST_FACTOR/2+1);
	}

	function defrostTokens(uint fromIdx, uint toIdx) onlyDefrosterOrOwner {

		require(now>START_ICO_TIMESTAMP);
		require(stopDefrost == false);
		require(fromIdx>=0 && toIdx<=vIcedBalances.length);
		if(fromIdx==0 && toIdx==0){
			fromIdx = 0;
			toIdx = vIcedBalances.length;
		}

		int monthsElapsedFromFirstDefrost = elapsedMonthsFromICOStart() - DEFROST_MONTHS;
		require(monthsElapsedFromFirstDefrost>0);
		uint monthsIndex = uint(monthsElapsedFromFirstDefrost);
		//require(monthsIndex<=DEFROST_FACTOR);
		require(canDefrost() == true);

		/*
			if monthsIndex == 1 => defrost 50%
			else if monthsIndex <= 10  defrost 5%
		*/

		// Looping into the iced accounts
        for (uint index = fromIdx; index < toIdx; index++) {

			address currentAddress = vIcedBalances[index];
            uint256 amountTotal = SafeMath.add(icedBalances_frosted[currentAddress], icedBalances_defrosted[currentAddress]);
            uint256 targetDeFrosted = 0;
			uint256 fivePercAmount = SafeMath.div(amountTotal, DEFROST_FACTOR);
			if(monthsIndex==1){
				targetDeFrosted = SafeMath.mul(fivePercAmount, 10);  //  10 times 5% = 50%
			}else{
				targetDeFrosted = SafeMath.mul(fivePercAmount, 10) + SafeMath.div(SafeMath.mul(monthsIndex-1, amountTotal), DEFROST_FACTOR);
			}
            uint256 amountToRelease = SafeMath.sub(targetDeFrosted, icedBalances_defrosted[currentAddress]);
           
		    if (amountToRelease > 0 && targetDeFrosted > 0) {
                icedBalances_frosted[currentAddress] = SafeMath.sub(icedBalances_frosted[currentAddress], amountToRelease);
                icedBalances_defrosted[currentAddress] = SafeMath.add(icedBalances_defrosted[currentAddress], amountToRelease);
				transfer(currentAddress, amountToRelease); 
	        }
        }
	}

	function getStartIcoTimestamp() constant returns (uint) {
		return START_ICO_TIMESTAMP;
	}

	function stopBatchAssign() onlyOwner {
			require ( batchAssignStopped == false);
			batchAssignStopped = true;
	}

	function getAddressBalance(address addr) constant returns (uint256 balance)  {
			balance = balances[addr];
	}

	function getAddressAndBalance(address addr) constant returns (address _address, uint256 _amount)  {
			_address = addr;
			_amount = balances[addr];
	}

	function setStopDefrost() onlyOwner constant {
			stopDefrost = true;
	}

	function killContract() onlyOwner {
		selfdestruct(owner);
	}


}
