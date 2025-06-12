// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Donation Platform Contract
/// @author L-202
/// @notice This contract allows the creation of donation cases and accepts ETH donations.
/// @dev Implements design patterns like Access Control and Checks-Effects-Interactions.
///      Includes security practices like ReentrancyGuard and minimum donation validation.
contract Donation is Ownable, ReentrancyGuard {
    
    /// @notice Structure representing each donation case
    struct Case {
        string title;             // Case title
        string description;       // Case description
        address payable recipient;// Recipient wallet address
        uint256 totalDonations;   // Total ETH collected
        bool exists;              // Flag to ensure case validity
    }

    mapping(uint256 => Case) public cases; // Mapping from case ID to case struct
    uint256 public caseCount;              // Counter for case IDs

    /// @notice Minimum acceptable donation amount (0.01 ETH)
    uint256 public constant MIN_DONATION = 0.01 ether;

    /// @notice Emitted when a new donation case is added
    event CaseAdded(uint256 indexed caseId, address indexed recipient);

    /// @notice Emitted when a donation is received
    event DonationReceived(uint256 indexed caseId, address indexed donor, uint256 amount);

    /// @notice Emitted when funds are withdrawn by a recipient
    event Withdrawal(uint256 indexed caseId, address indexed recipient, uint256 amount);

    /// @notice Contract constructor, sets the contract owner
    constructor() Ownable(msg.sender) {}

    /// @notice Add a new donation case
    /// @dev Only the contract owner can call this function
    /// @param _title Title of the case
    /// @param _description Description of the case
    /// @param _recipient Address that will receive the donations
    function addCase(
        string memory _title,
        string memory _description,
        address payable _recipient
    ) external onlyOwner {
        cases[caseCount] = Case({
            title: _title,
            description: _description,
            recipient: _recipient,
            totalDonations: 0,
            exists: true
        });

        emit CaseAdded(caseCount, _recipient);
        caseCount++;
    }

    /// @notice Donate ETH to a specific donation case
    /// @param _caseId The ID of the case to donate to
    /// @dev Enforces a minimum donation amount
    function donate(uint256 _caseId) external payable {
        require(cases[_caseId].exists, "Case not found");
        require(msg.value >= MIN_DONATION, "Min 0.01 ETH");

        cases[_caseId].totalDonations += msg.value;
        emit DonationReceived(_caseId, msg.sender, msg.value);
    }

    /// @notice Withdraw funds from a donation case
    /// @dev Only the case recipient can withdraw funds.
    ///      Uses Checks-Effects-Interactions pattern and ReentrancyGuard.
    /// @param _caseId The ID of the case to withdraw from
    function withdraw(uint256 _caseId) external nonReentrant {
        Case storage c = cases[_caseId];
        require(c.exists, "Case not found");
        require(msg.sender == c.recipient, "Not recipient");
        require(c.totalDonations > 0, "No funds");

        uint256 amount = c.totalDonations;
        c.totalDonations = 0;

        (bool success, ) = c.recipient.call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdrawal(_caseId, c.recipient, amount);
    }

    /// @notice Retrieve details of a specific case
    /// @param _caseId The ID of the case
    /// @return title Title of the case
    /// @return description Description of the case
    /// @return recipient Recipient address
    /// @return totalDonations ETH collected
    function getCase(uint256 _caseId)
        external
        view
        returns (string memory title, string memory description, address recipient, uint256 totalDonations)
    {
        Case memory c = cases[_caseId];
        require(c.exists, "Case not found");
        return (c.title, c.description, c.recipient, c.totalDonations);
    }
}
