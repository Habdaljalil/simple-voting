# SimpleVoting
[Git Source](https://github.com/Habdaljalil/simple-voting/blob/421c97b61ccf2492e8be3f23b17008d8d845c09a/src/SimpleVoting.sol)

**Author:**
Hassan Abdaljalil

Implements a simple, one-session voting system where an authorized entity can register voters and candidates and dictate the stages of voting


## State Variables
### stateMachine
The State struct that controls the stages of the voting procedure


```solidity
VotingLibrary.State private stateMachine
```


### addressToVoter
Maps every address to a voter identity(struct)


```solidity
mapping(address => VotingLibrary.Voter) private addressToVoter
```


### nameToCandidate
Maps every candidate name to a candidate identity(struct)


```solidity
mapping(string => VotingLibrary.Candidate) nameToCandidate
```


### numberOfRegisteredVoters
A count of the number of voters registered by the owner


```solidity
uint256 private numberOfRegisteredVoters
```


### candidates
A collection of the names of the candidates


```solidity
string[] private candidates
```


### winner
The name of the winner


```solidity
string private winner
```


### I_OWNER
The address of the deployed instance's owner


```solidity
address private immutable I_OWNER
```


## Functions
### constructor


```solidity
constructor() ;
```

### eqState


```solidity
modifier eqState(VotingLibrary.State expectedState) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`expectedState`|`VotingLibrary.State`|What the expected stage of voting is(i.e. Registration)|


### _eqState

Compares the expected stage of voting vs the actual stage; reverts if they do not match


```solidity
function _eqState(VotingLibrary.State expectedState) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`expectedState`|`VotingLibrary.State`|What the expected stage of voting is(i.e. Registration)|


### onlyOwner


```solidity
modifier onlyOwner() ;
```

### _onlyOwner


```solidity
function _onlyOwner() internal view;
```

### candidateExists


```solidity
modifier candidateExists(string memory candidateName) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`candidateName`|`string`|The name of the candidate who supposedly exists|


### _candidateExists

The function looks to see if the candidate is registered


```solidity
function _candidateExists(string memory candidateName) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`candidateName`|`string`|The name of the candidate who supposedly exists|


### isRegistered


```solidity
modifier isRegistered() ;
```

### _isRegistered

Checks to see if msg.sender is a registered voter


```solidity
function _isRegistered() internal view;
```

### registerVoter

Only the owner can register voters; the function checks to see if the voter is not registered, otherwise it will revert; it updates correlated state variables subsequently


```solidity
function registerVoter(address _voterAddress)
    external
    onlyOwner
    eqState(VotingLibrary.State.isRegistering)
    returns (VotingLibrary.Voter memory registeredVoter);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_voterAddress`|`address`|The address of the voter to register|


### registerCandidate

Only the owner can call this function; registeres a candidate and updates state if they are not already registered


```solidity
function registerCandidate(string memory _name) external onlyOwner eqState(VotingLibrary.State.isRegistering);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|The name of the candidate to register|


### vote

If a registered voter has not yet voted, then they can vote for a registered candidate once


```solidity
function vote(string memory candidateName)
    external
    candidateExists(candidateName)
    isRegistered
    eqState(VotingLibrary.State.isVoting);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`candidateName`|`string`|The name of the candidate|


### startVoting


```solidity
function startVoting() external onlyOwner;
```

### endVoting




```solidity
function endVoting() external eqState(VotingLibrary.State.isVoting) onlyOwner;
```

### getWinner

Checks to see if voting has ended; then it looks for the winner, if they haven't already been found


```solidity
function getWinner()
    external
    eqState(VotingLibrary.State.isClosed)
    returns (string memory, VotingLibrary.Candidate memory returnedWinner);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|winnerName Name of the winner|
|`returnedWinner`|`VotingLibrary.Candidate`| Data(struct) associated with the winner|


### getOwner


```solidity
function getOwner() external view returns (address);
```

### getAddressToVoter


```solidity
function getAddressToVoter(address voter) external view returns (VotingLibrary.Voter memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`voter`|`address`|Address of the voter|


### getCandidateNames


```solidity
function getCandidateNames() external view returns (string[] memory);
```

### getCandidateByName


```solidity
function getCandidateByName(string memory name)
    external
    view
    candidateExists(name)
    returns (VotingLibrary.Candidate memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|Name of the candidate|


### getState


```solidity
function getState() external view returns (VotingLibrary.State);
```

## Events
### VoterRegistered

```solidity
event VoterRegistered(address indexed voter);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`voter`|`address`|The address of the voter that was registered|

### CandidateRegistered



```solidity
event CandidateRegistered(string indexed candidate);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`candidate`|`string`|The name of the candidate that was registered|

### Voted

```solidity
event Voted(address indexed voter, string indexed candidate);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`voter`|`address`|the name of the registered voter who voted for the candidate|
|`candidate`|`string`|the name of the registered candidate|

### RegistrationEnded

```solidity
event RegistrationEnded();
```

### VotingStarted

```solidity
event VotingStarted();
```

### VotingEnded

```solidity
event VotingEnded();
```

