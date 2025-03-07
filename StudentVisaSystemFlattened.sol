// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/access/IAccessControl.sol

// OpenZeppelin Contracts (last updated v5.1.0) (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// src/interface/IFeeManager.sol

interface IFeeManager {
    function getTotalPaid(address applicant) external view returns (uint256);
    function payWithETH(address applicant) external payable;
    // function payWithToken(address applicant, address token, uint256 amount) external;
}

// src/interface/IUniversityHandler.sol

interface IUniversityHandler {
    function registerProgram(string calldata programData) external;
    function verifyAdmission(address applicant, string calldata proof) external;
    function isValidProgram(string calldata universityId, string calldata programId) external view returns (bool);
}

// src/interface/IVerificationHub.sol

interface IVerificationHub {
    struct VerificationResult {
        address verifier;
        uint256 timestamp;
        bool isValid;
        string proof;
    }

    function registerVerifier(address verifier, string calldata credentials) external;
    function getVerificationHistory(address applicant) external view returns (VerificationResult[] memory);
    function calculateTrustScore(address verifier) external view returns (uint256);
}

// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// lib/openzeppelin-contracts/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// src/TimelineEnhancer.sol

contract TimelineEnhancer {
    error TimelineEnhancer__VisaSystemNotConfigured();

    StudentVisaSystem private visaSystem;

    struct Prediction {
        uint256 estimatedDays;
        uint256 successProbability;
        uint256 timestamp;
    }

    mapping(address => Prediction[]) public applicantPredictions;

    constructor(address _visaSystem) {
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    function generatePrediction(address applicant) external returns (Prediction memory) {
        if (address(visaSystem) == address(0)) revert TimelineEnhancer__VisaSystemNotConfigured();

        (StudentVisaSystem.VisaStatus status, uint256 credibility, uint256 created) =
            visaSystem.getApplicationCore(applicant);

        StudentVisaSystem.Priority priority = visaSystem.getTimelinePriority(applicant);
        uint256 deadlineDate = visaSystem.getTimelineDeadline(applicant);

        Prediction memory newPrediction = Prediction({
            estimatedDays: _calculateProcessingTime(priority, created),
            successProbability: _calculateSuccessProbability(credibility, priority),
            timestamp: block.timestamp
        });

        applicantPredictions[applicant].push(newPrediction);
        return newPrediction;
    }

    function _calculateProcessingTime(StudentVisaSystem.Priority priority, uint256 createdAt)
        internal
        view
        returns (uint256)
    {
        if (priority == StudentVisaSystem.Priority.STANDARD) {
            return visaSystem.standardProcessingTime();
        } else if (priority == StudentVisaSystem.Priority.EXPEDITED) {
            return visaSystem.expeditedProcessingTime();
        } else {
            return visaSystem.emergencyProcessingTime();
        }
    }

    function _calculateSuccessProbability(uint256 credibility, StudentVisaSystem.Priority priority)
        internal
        pure
        returns (uint256)
    {
        uint256 base = credibility > 80 ? 90 : 60;
        return base + uint256(priority) * 5; // Add priority bonus
    }
}

// src/UniversityHandler.sol

contract UniversityHandler is AccessControl, IUniversityHandler {
    error UniversityHandler__InvalidProgram();
    error UniversityHandler__ApplicantNotFound();

    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    StudentVisaSystem private visaSystem;

    struct Program {
        string requirements;
        uint256 tuition;
        bool requiresInterview;
        bool isActive;
    }

    mapping(bytes32 => Program) public programs; // programHash => Program
    mapping(address => string) public universityRegistry; // University address => ID

    event ProgramRegistered(string indexed universityId, string programId);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(UNIVERSITY_ROLE, msg.sender);
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    function registerUniversity(address universityAddr, string calldata universityId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        universityRegistry[universityAddr] = universityId;
        _grantRole(UNIVERSITY_ROLE, universityAddr);
    }

    function registerProgram(string calldata programId) external onlyRole(UNIVERSITY_ROLE) {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));
        programs[programHash] = Program({requirements: "", tuition: 0, requiresInterview: false, isActive: true});

        emit ProgramRegistered(universityId, programId);
    }

    function verifyAdmission(address applicant, string calldata programId)
        external
        override
        onlyRole(UNIVERSITY_ROLE)
    {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));

        if (!programs[programHash].isActive) revert UniversityHandler__InvalidProgram();

        if (!visaSystem.hasApplication(applicant)) revert UniversityHandler__ApplicantNotFound();
        visaSystem.submitDocument(
            applicant,
            StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER,
            string(abi.encodePacked(universityId, ":", programId)),
            block.timestamp + 365 days
        );
    }

    function isValidProgram(string calldata universityId, string calldata programId) external view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(universityId, programId));
        return programs[hash].isActive;
    }

    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }
}

// src/VerificationHub.sol

contract VerificationHub is AccessControl, IVerificationHub {
    error VerificationHub__RequestAlreadyProcessed();
    error VerificationHub__InvalidApplicant();

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant VERIFICATION_HUB_ROLE = keccak256("VERIFICATION_HUB_ROLE");

    StudentVisaSystem public visaSystem;

    enum VerificationType {
        DOCUMENT,
        BIOMETRIC,
        BACKGROUND_CHECK
    }

    struct VerificationRequest {
        address applicant;
        VerificationType vType;
        string proof;
        bool completed;
        address verifier;
    }

    struct VerifierProfile {
        string credentials;
        uint256 totalVerifications;
        uint256 successfulVerifications;
        uint256 lastActivity;
    }

    // Mappings
    mapping(bytes32 => VerificationRequest) public verificationRequests;
    mapping(address => VerifierProfile) public verifiers;
    mapping(address => mapping(VerificationType => VerificationResult[])) public verificationRecords;

    // Events
    event VerificationRequested(bytes32 requestId, address applicant, VerificationType vType);
    event VerificationCompleted(bytes32 requestId, bool result);
    event VerifierRegistered(address verifier);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    /// @notice Initial role setup must be called after deployment
    function initializeRoles() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Grant verification hub role to itself in visa system
        visaSystem.grantRole(address(this), visaSystem.VERIFICATION_HUB_ROLE());
    }

    /// @notice Create a new verification request
    function requestVerification(address applicant, VerificationType vType, string calldata proof)
        external
        onlyRole(visaSystem.VERIFICATION_HUB_ROLE())
    {
        bytes32 requestId = keccak256(abi.encodePacked(applicant, vType, proof, block.timestamp));
        verificationRequests[requestId] = VerificationRequest({
            applicant: applicant,
            vType: vType,
            proof: proof,
            completed: false,
            verifier: address(0)
        });
        emit VerificationRequested(requestId, applicant, vType);
    }

    /// @notice Process verification request (called by verifiers)
    function processVerification(bytes32 requestId, bool isValid) external onlyRole(VERIFIER_ROLE) {
        VerificationRequest storage request = verificationRequests[requestId];
        if (request.completed) revert VerificationHub__RequestAlreadyProcessed();
        if (!visaSystem.hasApplication(request.applicant)) revert VerificationHub__InvalidApplicant();

        // Update verification records
        verificationRecords[request.applicant][request.vType].push(
            VerificationResult({
                verifier: msg.sender,
                timestamp: block.timestamp,
                isValid: isValid,
                proof: request.proof
            })
        );

        // Update verifier stats
        VerifierProfile storage profile = verifiers[msg.sender];
        profile.totalVerifications++;
        if (isValid) profile.successfulVerifications++;
        profile.lastActivity = block.timestamp;

        // Update credibility score
        int8 scoreChange = isValid ? int8(5) : int8(-3);
        visaSystem.updateCredibilityScore(request.applicant, scoreChange);

        // Mark request as completed
        request.completed = true;
        request.verifier = msg.sender;
        emit VerificationCompleted(requestId, isValid);
    }

    /// @notice Admin function to register new verifiers
    function registerVerifier(address verifier, string calldata credentials) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VERIFIER_ROLE, verifier);
        verifiers[verifier] = VerifierProfile({
            credentials: credentials,
            totalVerifications: 0,
            successfulVerifications: 0,
            lastActivity: block.timestamp
        });
        emit VerifierRegistered(verifier);
    }

    /// @notice Get verification history for an applicant
    function getVerificationHistory(address applicant) external view returns (VerificationResult[] memory) {
        VerificationResult[] memory allResults = new VerificationResult[](0);

        for (uint8 vType = 0; vType < uint8(type(VerificationType).max); vType++) {
            VerificationResult[] memory typeResults = verificationRecords[applicant][VerificationType(vType)];
            allResults = concatArrays(allResults, typeResults);
        }
        return allResults;
    }

    /// @notice Calculate verifier trust score
    function calculateTrustScore(address verifier) public view returns (uint256) {
        VerifierProfile memory profile = verifiers[verifier];
        if (profile.totalVerifications == 0) return 0;

        uint256 successRate = (profile.successfulVerifications * 100) / profile.totalVerifications;
        uint256 activityScore = block.timestamp - profile.lastActivity < 30 days ? 20 : 0;
        return successRate + activityScore;
    }

    /// @dev Helper for array concatenation
    function concatArrays(VerificationResult[] memory a, VerificationResult[] memory b)
        internal
        pure
        returns (VerificationResult[] memory)
    {
        VerificationResult[] memory combined = new VerificationResult[](a.length + b.length);
        uint256 i = 0;
        for (; i < a.length; i++) {
            combined[i] = a[i];
        }
        for (uint256 j = 0; j < b.length; j++) {
            combined[i + j] = b[j];
        }
        return combined;
    }

    /// @dev Simplified verification logic (replace with oracle in production)
    function _performVerification(VerificationType, string calldata) internal pure returns (bool) {
        // Always return true in mock implementation
        return true;
    }

    function grantRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }
}

// src/StudentVisaSystem.sol

/// @title Student Visa System
/// @author Akash Kolekar
/// @notice This is the main contract for the Student Visa System
/// @dev This contract is used to manage the student visa application process
contract StudentVisaSystem is AccessControl, Pausable, ReentrancyGuard {
    error StudentVisaSystem__ApplicationAlreadyExists();
    error StudentVisaSystem__EnrollmentDateMustBeInFuture();
    error StudentVisaSystem__EnrollmentDateTooFar();
    error StudentVisaSystem__InvalidProgram();
    error StudentVisaSystem__InsufficientFeePaid();
    error StudentVisaSystem__FeePaymentFailed();

    error StudentVisaSystem__ApplicationNotFound();
    error StudentVisaSystem__Unauthorized();

    error StudentVisaSystem__BiometricsVerified();
    error StudentVisaSystem__ApplicationNotUnderReview();
    error StudentVisaSystem__ReviewAlreadyAuthorized();

    error StudentVisaSystem__OnlyUpgradePriority();
    error StudentVisaSystem__InsufficientAdditionalFee();
    error StudentVisaSystem__ApplicationNotUnderApproval();

    error StudentVisaSystem__ApplicationAlreadyProcessed();
    error StudentVisaSystem__WithdrawalFailed();
    error StudentVisaSystem__CannotModifyFinalizedApplication();

    error StudentVisaSystem__InvalidStatusUpdate();
    error StudentVisaSystem__ApplicationNotRejected();

    error StudentVisaSystem__ApplicationAlreadyApproved();
    error StudentVisaSystem__ApplicationAlreadyRejected();

    error StudentVisaSystem__DocumentExpired();
    error StudentVisaSystem__DocumentNotSubmittedNotVerified();

    /////////////////////////////
    ///// State Variables ///////
    /////////////////////////////

    IUniversityHandler public universityHandler;
    VerificationHub public verificationHub;
    IFeeManager public feeManager;
    TimelineEnhancer public timelineEnhancer;

    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFICATION_HUB_ROLE = keccak256("VERIFICATION_HUB_ROLE");

    enum DocumentType {
        PASSPORT,
        ACADEMIC_RECORDS,
        FINANCIAL_PROOF,
        ACCEPTANCE_LETTER,
        BACKGROUND_CHECK,
        HEALTH_CERTIFICATE,
        LANGUAGE_PROFICIENCY
    }

    enum VerificationStatus {
        NOT_SUBMITTED,
        SUBMITTED,
        IN_REVIEW,
        VERIFIED,
        REJECTED
    }

    enum VisaStatus {
        NOT_STARTED,
        DOCUMENTS_PENDING,
        UNDER_REVIEW,
        ADDITIONAL_DOCUMENTS_REQUIRED,
        CONDITIONALLY_APPROVED,
        APPROVED,
        REJECTED
    }

    /// @dev
    // This Priority enum is used to determine the priority of the visa application
    // This is the very important feature of the system

    enum Priority {
        STANDARD,
        EXPEDITED,
        EMERGENCY
    }

    struct Document {
        string documentHash;
        VerificationStatus status;
        address verifiedBy;
        uint256 timestamp;
        string comments;
        uint256 expiryDate; // When document expires
    }

    struct Verification {
        address verifier;
        uint256 timestamp;
        string verificationProof;
    }

    struct Timeline {
        uint32 targetDate; // Expected enrollment date // timestamp fits in 32 bits until 2106
        uint32 deadlineDate; // Visa processing deadline
        Priority priority;
        bool isExpedited;
    }
    // uint256 lastReminderSent;

    struct Application {
        address applicant;
        mapping(DocumentType => Document) documents;
        VisaStatus status;
        uint256 createdAt;
        uint256 updatedAt;
        string universityId;
        Timeline timeline;
        uint256 credibilityScore;
        mapping(address => bool) authorizedViewers;
        bool isBiometricVerified;
        uint256 applicationFee;
        bool feesPaid;
        string[] previousVisaCountries;
        uint8 attemptCount;
        uint256 paidFees;
        bool isPriorityUpgraded;
    }

    // Reputation system for verifiers
    struct VerifierStats {
        uint256 totalVerifications;
        uint256 averageResponseTime;
        uint256 reputationScore;
        bool isActive;
    }

    mapping(address => Application) public applications;
    mapping(address => bool) public hasApplication;
    mapping(address => VerifierStats) public verifierStats;
    mapping(string => address) public universityRegistry;
    mapping(address => TimelineEnhancer.Prediction[]) public applicantPredictions;

    uint32 public standardProcessingTime = 30 days;
    uint32 public expeditedProcessingTime = 10 days;
    uint32 public emergencyProcessingTime = 3 days;

    uint256 public standardFee = 0.000001 ether;
    uint256 public expeditedFee = 0.000003 ether;
    uint256 public emergencyFee = 0.000005 ether;

    uint256 public totalApplications;
    uint256 public totalApproved;
    uint256 public totalRejected;

    event ApplicationCreated(address indexed applicant, uint256 timestamp, Priority priority);
    event DocumentSubmitted(address indexed applicant, DocumentType docType, string documentHash);
    event DocumentVerified(address indexed applicant, DocumentType docType, address verifier);
    event DocumentRejected(address indexed applicant, DocumentType docType, address verifier, string reason);
    event ApplicationStatusUpdated(address indexed applicant, VisaStatus status);
    event TimelineCritical(address indexed applicant, uint256 daysRemaining);
    event BiometricVerified(address indexed applicant, uint256 timestamp);
    event FeePaid(address indexed applicant, uint256 amount, Priority priority);
    event CredibilityScoreUpdated(address indexed applicant, uint256 newScore);
    event ViewerAuthorized(address indexed applicant, address viewer);
    event ProcessingExpedited(address indexed applicant, Priority newPriority);
    event PredictionGenerated(address applicant, uint256 estimatedDays, uint256 probability);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    ///////////////////////////////
    //// External Functions
    //////////////////////////////
    // Feature 1: Prioritized processing with different fee tiers
    function createApplication(
        string calldata universityId,
        string calldata programId,
        uint32 enrollmentDate,
        Priority priority,
        string[] calldata previousVisaCountries
    ) external payable {
        if (hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationAlreadyExists();
        if (enrollmentDate <= block.timestamp) revert StudentVisaSystem__EnrollmentDateMustBeInFuture();
        if (enrollmentDate >= block.timestamp + 365 days) revert StudentVisaSystem__EnrollmentDateTooFar();
        if (!universityHandler.isValidProgram(universityId, programId)) revert StudentVisaSystem__InvalidProgram();

        // Determine required fee and processing time
        (uint256 requiredFee, uint32 processingTime) = getFeeAndProcessingTime(priority);

        // Process any ETH sent with the transaction
        if (msg.value > 0) {
            // feeManager.payWithETH{value: msg.value}(msg.sender); //causing error?

            (bool success,) =
                address(feeManager).call{value: requiredFee}(abi.encodeWithSignature("payWithETH(address)", msg.sender));
            if (!success) {
                revert StudentVisaSystem__FeePaymentFailed();
            }
        }

        // Verify total payments meet requirement
        if (feeManager.getTotalPaid(msg.sender) < requiredFee) revert StudentVisaSystem__InsufficientFeePaid();

        // Initialize application
        Application storage app = applications[msg.sender];
        _initializeApplicationCore(app, universityId);
        _initializeApplicationTimeline(app, enrollmentDate, priority, processingTime);
        _handlePreviousCountries(app, previousVisaCountries);

        // Update state
        hasApplication[msg.sender] = true;
        totalApplications++;

        emit ApplicationCreated(msg.sender, block.timestamp, priority);
        emit FeePaid(msg.sender, requiredFee, priority);
    }

    // Helper function for fee calculation
    function getFeeAndProcessingTime(Priority priority) public view returns (uint256, uint32) {
        if (priority == Priority.STANDARD) {
            return (standardFee, standardProcessingTime);
        } else if (priority == Priority.EXPEDITED) {
            return (expeditedFee, expeditedProcessingTime);
        }
        return (emergencyFee, emergencyProcessingTime);
    }

    // Feature 2: Advanced document handling with expiry dates
    function submitDocument(address applicant, DocumentType docType, string calldata documentHash, uint256 expiryDate)
        external
    {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        if (applicant != msg.sender && hasRole(UNIVERSITY_ROLE, msg.sender)) revert StudentVisaSystem__Unauthorized();

        Application storage app = applications[applicant];
        _validateDocumentSubmission(app);
        _updateDocument(app.documents[docType], documentHash, expiryDate);

        app.updatedAt = block.timestamp;

        emit DocumentSubmitted(applicant, docType, documentHash);

        _checkTimelineCritical(msg.sender);

        verificationHub.requestVerification(applicant, VerificationHub.VerificationType.DOCUMENT, documentHash);
    }

    // Feature 3: Biometric verification
    function submitBiometricVerification(string calldata biometricHash) external {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.isBiometricVerified) revert StudentVisaSystem__BiometricsVerified();

        app.isBiometricVerified = true;
        app.updatedAt = block.timestamp;

        // Increase credibility score for biometric verification
        _updateCredibilityScore(msg.sender, 10);

        emit BiometricVerified(msg.sender, block.timestamp);
    }

    // Feature 5: Conditional approval with time-bound requirements
    function conditionallyApproveVisa(address applicant, string calldata conditions, uint32 conditionDeadline)
        external
        onlyRole(EMBASSY_ROLE)
    {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (app.status != VisaStatus.UNDER_REVIEW) revert StudentVisaSystem__ApplicationNotUnderReview();

        app.status = VisaStatus.CONDITIONALLY_APPROVED;
        app.timeline.deadlineDate = conditionDeadline;
        app.updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, VisaStatus.CONDITIONALLY_APPROVED);
    }

    // Feature 6: Selective disclosure authorization
    function authorizeViewer(address viewer) external {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.authorizedViewers[viewer]) revert StudentVisaSystem__ReviewAlreadyAuthorized();

        app.authorizedViewers[viewer] = true;

        emit ViewerAuthorized(msg.sender, viewer);
    }

    // Feature 7: Emergency processing upgrade
    function upgradeProcessingPriority(Priority newPriority) external payable {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.timeline.priority >= newPriority) revert StudentVisaSystem__OnlyUpgradePriority();

        uint256 additionalFee;
        if (newPriority == Priority.EXPEDITED) {
            additionalFee = expeditedFee - standardFee;
        } else if (newPriority == Priority.EMERGENCY) {
            if (app.timeline.priority == Priority.STANDARD) {
                additionalFee = emergencyFee - standardFee;
            } else {
                additionalFee = emergencyFee - expeditedFee;
            }
        }

        if (msg.value < additionalFee) revert StudentVisaSystem__InsufficientAdditionalFee();

        app.timeline.priority = newPriority;
        if (newPriority == Priority.EXPEDITED) {
            app.timeline.deadlineDate = uint32(block.timestamp) + expeditedProcessingTime;
        } else {
            app.timeline.deadlineDate = uint32(block.timestamp) + emergencyProcessingTime;
        }

        app.timeline.isExpedited = true;
        app.applicationFee += msg.value;

        emit ProcessingExpedited(msg.sender, newPriority);
        emit FeePaid(msg.sender, msg.value, newPriority);
    }

    // Feature 9: Verifier reputation system

    function verifyDocument(address applicant, DocumentType docType, string calldata verificationProof) external {
        if (!_isAuthorizedVerifier()) revert StudentVisaSystem__Unauthorized();

        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        Document storage doc = app.documents[docType];

        _validateDocumentVerification(doc);
        _updateVerificationState(doc, msg.sender);

        uint256 responseTime = block.timestamp - doc.timestamp;
        updateVerifierStats(msg.sender, responseTime);
        _updateCredibilityIfEarly(app);

        app.updatedAt = block.timestamp;

        emit DocumentVerified(applicant, docType, msg.sender);

        _checkAllDocumentsVerified(applicant);
    }

    function approveVisa(address applicant) external onlyRole(EMBASSY_ROLE) nonReentrant {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (app.status != VisaStatus.UNDER_REVIEW && app.status != VisaStatus.CONDITIONALLY_APPROVED) {
            revert StudentVisaSystem__ApplicationNotUnderApproval();
        }

        app.status = VisaStatus.APPROVED;
        app.updatedAt = block.timestamp;

        totalApproved++;

        emit ApplicationStatusUpdated(applicant, VisaStatus.APPROVED);
    }

    function rejectVisa(address applicant, string calldata reason) external onlyRole(EMBASSY_ROLE) nonReentrant {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (app.status == VisaStatus.APPROVED || app.status != VisaStatus.REJECTED) {
            revert StudentVisaSystem__ApplicationAlreadyProcessed();
        }

        app.status = VisaStatus.REJECTED;
        app.updatedAt = block.timestamp;

        // Update applicant credibility based on rejection
        _updateCredibilityScore(applicant, -10);

        totalRejected++;

        emit ApplicationStatusUpdated(applicant, VisaStatus.REJECTED);
    }

    // Administrative functions
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Allow withdrawal of fees by admin
    function withdrawFees(address payable recipient, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
        // @audit: is the checks really necessary? since solidity will revert underflow value
        require(amount <= address(this).balance, "Insufficient balance");
        (bool sent,) = recipient.call{value: amount}("");
        if (!sent) revert StudentVisaSystem__WithdrawalFailed();
        // recipient.transfer(amount);
    }

    function setVerificationHub(address _hub) external onlyRole(ADMIN_ROLE) {
        verificationHub = VerificationHub(_hub);
    }

    function updateCredibilityScore(address applicant, int8 change) external onlyRole(VERIFICATION_HUB_ROLE) {
        _updateCredibilityScore(applicant, change);
    }

    function updateApplicationStatus(address applicant, VisaStatus newStatus) external onlyRole(EMBASSY_ROLE) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        if (
            applications[applicant].status == VisaStatus.APPROVED
                || applications[applicant].status == VisaStatus.REJECTED
        ) revert StudentVisaSystem__CannotModifyFinalizedApplication();
        if (newStatus != VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED && newStatus != VisaStatus.UNDER_REVIEW) {
            revert StudentVisaSystem__InvalidStatusUpdate();
        }

        applications[applicant].status = newStatus;
        applications[applicant].updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, newStatus);
    }

    function resetApplication() external {
        if (applications[msg.sender].status != VisaStatus.REJECTED) revert StudentVisaSystem__ApplicationNotRejected();

        delete applications[msg.sender];
        hasApplication[msg.sender] = false;
    }

    function initializeDependencies(
        address _universityHandler,
        address _verificationHub,
        address _feeManager,
        address _timelineEnhancer
    ) external onlyRole(ADMIN_ROLE) {
        universityHandler = IUniversityHandler(_universityHandler);
        verificationHub = VerificationHub(_verificationHub);
        feeManager = IFeeManager(_feeManager);
        timelineEnhancer = TimelineEnhancer(_timelineEnhancer);
    }

    /////////////////////////////////////
    // Internal View and Pure Functions
    /////////////////////////////////////

    function _initializeApplicationCore(Application storage app, string calldata universityId) internal {
        app.applicant = msg.sender;
        app.status = VisaStatus.DOCUMENTS_PENDING;
        app.universityId = universityId;
        app.credibilityScore = 100; // Default score
        app.feesPaid = true;
        app.applicationFee = msg.value;
        app.attemptCount = 1;
        app.createdAt = block.timestamp;
        app.updatedAt = block.timestamp;
    }

    function _initializeApplicationTimeline(
        Application storage app,
        uint32 enrollmentDate,
        Priority priority,
        uint32 processingTime
    ) internal {
        app.timeline = Timeline({
            targetDate: enrollmentDate,
            deadlineDate: uint32(block.timestamp) + processingTime,
            priority: priority,
            isExpedited: (priority != Priority.STANDARD)
        });
    }

    function _handlePreviousCountries(Application storage app, string[] calldata previousVisaCountries) internal {
        for (uint256 i = 0; i < previousVisaCountries.length; i++) {
            app.previousVisaCountries.push(previousVisaCountries[i]);
        }
    }

    function _validateDocumentSubmission(Application storage app) internal view {
        if (app.status == VisaStatus.APPROVED) revert StudentVisaSystem__ApplicationAlreadyApproved();
        if (app.status == VisaStatus.REJECTED) revert StudentVisaSystem__ApplicationAlreadyRejected();
    }

    function _updateDocument(Document storage doc, string calldata hash, uint256 expiryDate) internal {
        if (expiryDate <= block.timestamp) revert StudentVisaSystem__DocumentExpired();

        doc.documentHash = hash;
        doc.status = VerificationStatus.SUBMITTED;
        doc.timestamp = block.timestamp;
        doc.expiryDate = expiryDate;
    }

    // Feature 4: Credibility scoring system
    function _updateCredibilityScore(address applicant, int8 change) internal {
        Application storage app = applications[applicant];

        if (change > 0) {
            app.credibilityScore = min(app.credibilityScore + uint8(change), 100);
        } else {
            uint8 absoluteChange = uint8(-change);
            if (app.credibilityScore > absoluteChange) {
                app.credibilityScore -= absoluteChange;
            } else {
                app.credibilityScore = 0;
            }
        }

        emit CredibilityScoreUpdated(applicant, app.credibilityScore);
    }

    function updateVerifierStats(address verifier, uint256 responseTime) internal {
        VerifierStats storage stats = verifierStats[verifier];

        if (stats.totalVerifications == 0) {
            stats.averageResponseTime = responseTime;
        } else {
            stats.averageResponseTime =
                (stats.averageResponseTime * stats.totalVerifications + responseTime) / (stats.totalVerifications + 1);
        }

        stats.totalVerifications++;

        // Update reputation based on response time
        if (responseTime < 1 days) {
            stats.reputationScore = min(stats.reputationScore + 2, 100);
        } else if (responseTime < 3 days) {
            stats.reputationScore = min(stats.reputationScore + 1, 100);
        } else if (responseTime > 7 days) {
            stats.reputationScore = stats.reputationScore > 1 ? stats.reputationScore - 1 : 0;
        }
    }

    function _isAuthorizedVerifier() internal view returns (bool) {
        return
            hasRole(UNIVERSITY_ROLE, msg.sender) || hasRole(EMBASSY_ROLE, msg.sender) || hasRole(BANK_ROLE, msg.sender);
    }

    function _validateDocumentVerification(Document storage doc) internal view {
        if (doc.status != VerificationStatus.SUBMITTED) revert StudentVisaSystem__DocumentNotSubmittedNotVerified();
        if (doc.expiryDate <= block.timestamp) revert StudentVisaSystem__DocumentExpired();
    }

    function _updateVerificationState(Document storage doc, address verifier) internal {
        doc.status = VerificationStatus.VERIFIED;
        doc.verifiedBy = verifier;
        doc.timestamp = block.timestamp;
    }

    function _updateCredibilityIfEarly(Application storage app) internal {
        // Increase credibility score for quick document submission
        if (block.timestamp - app.createdAt < 7 days) {
            _updateCredibilityScore(app.applicant, 5);
        }
    }

    function _checkAllDocumentsVerified(address applicant) internal {
        Application storage app = applications[applicant];

        // Check required documents based on application type
        bool allVerified = true;

        // Basic required documents
        if (
            app.documents[DocumentType.PASSPORT].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.ACADEMIC_RECORDS].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.FINANCIAL_PROOF].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.ACCEPTANCE_LETTER].status != VerificationStatus.VERIFIED
        ) {
            allVerified = false;
        }

        // Additional check for language proficiency
        if (app.previousVisaCountries.length == 0) {
            if (app.documents[DocumentType.LANGUAGE_PROFICIENCY].status != VerificationStatus.VERIFIED) {
                allVerified = false;
            }
        }

        if (allVerified) {
            app.status = VisaStatus.UNDER_REVIEW;
            emit ApplicationStatusUpdated(applicant, VisaStatus.UNDER_REVIEW);
        }
    }

    function _checkTimelineCritical(address applicant) internal {
        if (address(timelineEnhancer) != address(0)) {
            TimelineEnhancer.Prediction memory prediction = timelineEnhancer.generatePrediction(applicant);

            applicantPredictions[applicant].push(prediction);
            emit PredictionGenerated(applicant, prediction.estimatedDays, prediction.successProbability);

            // Auto-extend deadline if probability < 50%
            if (prediction.successProbability < 50) {
                applications[applicant].timeline.deadlineDate += 7 days;
            }
        }

        Application storage app = applications[applicant];

        uint256 daysUntilDeadline = (app.timeline.deadlineDate - block.timestamp) / 1 days;
        uint256 daysUntilEnrollment = (app.timeline.targetDate - block.timestamp) / 1 days;

        if (daysUntilDeadline <= 3 || daysUntilEnrollment <= 14) {
            emit TimelineCritical(applicant, min(daysUntilDeadline, daysUntilEnrollment));
        }
    }

    // Utility function to get minimum of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function grantRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////

    // Getters for application information
    function getApplicationStatus(address applicant) external view returns (VisaStatus) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        return applications[applicant].status;
    }

    function getDocumentStatus(address applicant, DocumentType docType) external view returns (VerificationStatus) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        if (msg.sender != applicant && !applications[applicant].authorizedViewers[msg.sender]) {
            revert StudentVisaSystem__Unauthorized();
        }

        return applications[applicant].documents[docType].status;
    }

    function getCredibilityScore(address applicant) external view returns (uint256) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        if (
            msg.sender != applicant && !applications[applicant].authorizedViewers[msg.sender]
                && !hasRole(ADMIN_ROLE, msg.sender) && !hasRole(EMBASSY_ROLE, msg.sender)
        ) revert StudentVisaSystem__Unauthorized();

        return applications[applicant].credibilityScore;
    }

    function getApplicationDetails(address applicant)
        external
        view
        returns (
            VisaStatus status,
            uint256 credibilityScore,
            uint256 createdAt,
            uint256 updatedAt,
            Timeline memory timeline
        )
    {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        Application storage app = applications[applicant];
        return (app.status, app.credibilityScore, app.createdAt, app.updatedAt, app.timeline);
    }

    function getApplicationCore(address applicant)
        external
        view
        returns (VisaStatus status, uint256 credibilityScore, uint256 createdAt)
    {
        Application storage app = applications[applicant];
        return (app.status, app.credibilityScore, app.createdAt);
    }

    function getTimelinePriority(address applicant) external view returns (Priority) {
        return applications[applicant].timeline.priority;
    }

    function getTimelineDeadline(address applicant) external view returns (uint256) {
        return applications[applicant].timeline.deadlineDate;
    }
}
