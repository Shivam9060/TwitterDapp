// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0 < 0.9.0;
pragma abicoder v2;

contract TweetContract {

    struct Tweet {
        uint id;
        address author;
        string content;
        uint createdAt;
    }

    struct Message {
        uint id;
        string content;
        address from;
        address to;
        uint createdAt;
    }

    struct UserProfile {
        string username;
        string bio;
        string profilePicture;
    }

    mapping(uint => Tweet) public tweets;
    mapping(address => uint[]) public tweetsOf;
    mapping(address => Message[]) public conversations;
    mapping(address => mapping(address => bool)) public operators;
    mapping(address => address[]) public following;
    mapping(address => UserProfile) public userProfiles; // Added user profiles
    mapping(string => address) public usernameToAddress; // Map usernames to addresses
    mapping(address => address[]) public followers; // Track followers

    uint nextId;
    uint nextMessageId;

    event UserRegistered(address indexed user, string username);

    // Tweet Functions

    function _tweet(address _from, string memory _content) internal {
        require(_from == msg.sender || operators[_from][msg.sender], "You don't have access");
        tweets[nextId] = Tweet(nextId, _from, _content, block.timestamp);
        tweetsOf[_from].push(nextId);
        nextId = nextId + 1;
    }

    function tweet(string memory _content) public { // owner
        _tweet(msg.sender, _content);
    }

    function tweet(address _from, string memory _content) public { // owner -> address access
        _tweet(_from, _content);
    }

    // Message Function

    function _sendMessage(address _from, address _to, string memory _content) internal {
        require(_from == msg.sender || operators[_from][msg.sender], "You don't have access");
        conversations[_from].push(Message(nextMessageId, _content, _from, _to, block.timestamp));
        nextMessageId++;
    }

    function sendMessage(address _to, string memory _content) public {
        _sendMessage(msg.sender, _to, _content);
    }

    function sendMessage(address _from, address _to, string memory _content) public {
        _sendMessage(_from, _to, _content);
    }

    // Follow Function

    function follow(address _followed) public {
        following[msg.sender].push(_followed);
        followers[_followed].push(msg.sender); // Track followers
    }

    // Access Function

    function allow(address _operator) public {
        operators[msg.sender][_operator] = true;
    }

    function disallow(address _operator) public {
        operators[msg.sender][_operator] = false;
    }

    // Latest Tweets

    function getLatestTweets(uint count) public view returns (Tweet[] memory) {
        require(count > 0 && count <= nextId, "Count is not proper");
        Tweet[] memory _tweets = new Tweet[](count);

        uint j;

        for (uint i = nextId - count; i < nextId; i++) {
            Tweet storage _structure = tweets[i];
            _tweets[j] = Tweet(_structure.id, _structure.author, _structure.content, _structure.createdAt);
            j = j + 1;
        }
        return _tweets;
    }

    function getLatestofUser(address _user, uint count) public view returns (Tweet[] memory) {
        Tweet[] memory _tweets = new Tweet[](count);
        uint[] memory ids = tweetsOf[_user];

        require(count > 0 && count <= nextId, "Count is not defined");

        uint j;

        for (uint i = ids.length - count; i < ids.length; i++) {
            Tweet storage _structure = tweets[ids[i]];
            _tweets[j] = Tweet(_structure.id, _structure.author, _structure.content, _structure.createdAt);
            j = j + 1;
        }
        return _tweets;
    }

    // User Registration and Profile Management Functions

    function registerUser(string memory _username, string memory _bio, string memory _profilePicture) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(usernameToAddress[_username] == address(0), "Username is already taken");

        address newUser = msg.sender;
        usernameToAddress[_username] = newUser;
        userProfiles[newUser] = UserProfile(_username, _bio, _profilePicture);

        emit UserRegistered(newUser, _username);
    }

    function updateUserProfile(string memory _username, string memory _bio, string memory _profilePicture) public {
        address user = msg.sender;
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(usernameToAddress[_username] == address(0) || usernameToAddress[_username] == user, "Username is already taken");

        userProfiles[user] = UserProfile(_username, _bio, _profilePicture);
    }
}
