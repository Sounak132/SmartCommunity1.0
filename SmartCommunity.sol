pragma solidity 0.5.12;
import "./Ownable.sol";

contract SmartCommunity is Ownable{
    uint public totalMember;

    struct Member{
    //user identification
      bool registered;

    //bytes32 Userid;


    //public info
      string name;
      uint age;
      string hobby;
      string country;
      mapping (address => bool) isFriendOf;
      address[] FriendAddressList;

    //personal info
      mapping (address => bool) pendingRequests;
      bool anyPendingRequest;
      uint noOfPendingRequests;
    }

    struct publiclySharedInfo{
      string name;
      uint age;
      string hobby;
      string country;
    }

    mapping (address => Member) public community;

    modifier costs(uint value){
        require(msg.value >= value);
        _;
    }

    event newMemberAdded(address indexed member, string name);
    event newFriendship(address indexed friend1, string name1, string name2);
    event memberLeft(string name, string message);

    function register(string memory name, uint age, string memory hobby, string memory country)public {
      Member memory newMember;
      newMember.registered = true;
      newMember.name = name;
      newMember.age = age;
      newMember.hobby = hobby;
      newMember.country = country;

      community[msg.sender] = newMember;
      totalMember += 1;
      emit newMemberAdded(msg.sender, name);
    }

    function sendFriendRequest(address targetAddress)public {

      // check if the sender is registered member
      require(community[msg.sender].registered == true, "You need to register first");

      // check wheteher the address is registered at all
      require(community[targetAddress].registered == true, "User has not registered yet");

      // check if there is a pending request to that user from you
      require(community[targetAddress].pendingRequests[msg.sender] == false, "You have already sent him a request");

      // check if he is already your friend
      require(community[msg.sender].isFriendOf[targetAddress]==false, "You are already his friend");

      // send the request
      community[targetAddress].pendingRequests[msg.sender] = true;
      community[targetAddress].anyPendingRequest = true;
      community[targetAddress].noOfPendingRequests ++;
    }

    function acceptRequest(address pending)public {

    //   check wheteher the address is registered at all
      require(community[msg.sender].registered == true, "You have not registered yet");

      // Checkwhether theguy has sent a friend request at all
      require(community[msg.sender].pendingRequests[pending] == true, "This guy has not sent you any request");

      // updating Friend list
      community[msg.sender].FriendAddressList.push(pending);
      community[pending].FriendAddressList.push(msg.sender);

      // update friendshipmap
      community[msg.sender].isFriendOf[pending] =true;
      community[pending].isFriendOf[msg.sender] =true;

      // updating pending Requests of one
      delete community[msg.sender].pendingRequests[pending];
      community[msg.sender].noOfPendingRequests --;

      // emit an event so that others can know
      emit newFriendship(msg.sender, community[msg.sender].name, community[pending].name);
    }

    function disapproveRequest(address pendingFriendAddress)public {
      // user registration
      require(community[msg.sender].registered == true, "You need to register first");

      // Checkwhether theguy has sent a friend request at all
      require(community[msg.sender].pendingRequests[pendingFriendAddress] == true, "This guy has not sent you any request");

      // deleting the request
      delete community[msg.sender].pendingRequests[pendingFriendAddress];
      community[msg.sender].noOfPendingRequests --;
    }

    function getFriendData(uint index)public view returns(string memory name, uint age, string memory hobby, string memory country){
        require(community[msg.sender].registered == true, "User not registered");
        require(index<community[msg.sender].FriendAddressList.length, "You do not have that many friends");

        address requested = community[msg.sender].FriendAddressList[index];
            return (
              community[requested].name,
              community[requested].age,
              community[requested].hobby,
              community[requested].country
            );
    }

    function getFriendAddressList()public view returns(address[] memory friendlist){
        require(community[msg.sender].registered == true, "You are not in the community");
        return community[msg.sender].FriendAddressList;
    }

    function unFriend(address badFriend)public {
        require(community[msg.sender].isFriendOf[badFriend] == true, "He is not even your friend");
        updateFriendsAddressList(msg.sender, badFriend);
        updateFriendsAddressList(badFriend, msg.sender);
    }

    function updateFriendsAddressList(address user, address badFriend)private{
        uint totalFriend = community[user].FriendAddressList.length;
        uint i;
        for (i=0; i<totalFriend; i++){
            if(community[user].FriendAddressList[i] == badFriend)
                break;
        }
        if (i==totalFriend-1){
            delete community[user].FriendAddressList[i];
        }
        else{
            community[user].FriendAddressList[i] = community[user].FriendAddressList[totalFriend-1];
            delete community[user].FriendAddressList[totalFriend-1];
        }
        community[user].FriendAddressList.length--;
    }

    function getTotalNoOfFriends()public view returns(uint){
        return community[msg.sender].FriendAddressList.length;
    }

    function leaveCommunity(string memory message)public {
      string memory nameEmitted = community[msg.sender].name;

      for(uint i=0; i<community[msg.sender].FriendAddressList.length; i++){
          updateFriendsAddressList(community[msg.sender].FriendAddressList[i], msg.sender);
      }
      delete community[msg.sender];
      totalMember--;
      emit memberLeft(nameEmitted, message);
    }
}
