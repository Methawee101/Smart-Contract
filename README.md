
## function Refund

	function Refund()  public  {
	require(numPlayer <  2  ||  (numPlayer ==  2  && numInput <  2));
	require(elapsedMinutes()  >= timeOut);

	for  (uint i =  0; i < players.length; i++)  {
	if  (player_not_played[players[i]])  {
	payable(players[i]).transfer(reward / numPlayer);
	player_not_played[players[i]]  =  false;
	} }
	numInput =  0;
	numPlayer =  0;
	reward =  0;
	delete players;
	}

ตรวจสอบว่ามีจำนวนผู้เล่นน้อยกว่าสองคน หรือมี 2 คน แต่ใส่ Input น้อยกว่า 2คน
ตรวจสอบว่า เวลามากว่าเวลาของ TimeOut หรือไม่
เมื่อตรวจสอบเป็นแบบข้างต้นจะวนลูปตรวจสอบว่าผู้เล่น ได้เล่นเกมหรือยัง 
ถ้าผู้เล่นยังไม่ได้เล่น จะทำการโอนเงินรางวัลคืนให้ โดยเฉลี่ยเท่าๆกัน
และจะรีเซ็ต
  numInput, numPlayer, reward เป็น 0 เนื่องจากเกมเริ่มต้นใหม่

## function input
	
	function input(uint256 choice,  bytes32 randomString)  public onlyPlay {
	require(numPlayer ==  2,  "Not enough players");
	require(choice ==  0||choice ==  1  || choice ==  2  || choice ==  3  || choice ==  4,"Invalid choice");
	require(player_not_played[msg.sender],  "Player has already chosen");

	bytes32 dataHash =  keccak256(abi.encodePacked(choice, randomString));
	commit(dataHash);
	commitments[msg.sender]  = dataHash;
	player_not_played[msg.sender]  =  false;
	numInput++;
	}
ผู้เล่นจะส่ง choice และค่า randomString มาให้ฟังก์ชันนี้
hash choice และ randomString เข้าด้วยกันโดยใช้ฟังก์ชัน keccak256  keccak256 เป็นฟังก์ชัน hash ที่เข้ารหัสทางเดียว ฟังก์ชัน commit จะรับdataHashที่ได้จากการhash และเก็บไว้ใน mapping commitments  mappingนี้จะเก็บ dataHash โดยเชื่อมกับ address ของผู้เล่น  ขั้นตอน commit ผู้เล่นได้ผูกมัดกับตัวเลือกของตัวเองแล้ว แต่ยังไม่เปิดเผยตัวเลือกที่แท้จริง
  mapping(address => bytes32) public commitments;:  ประกาศ mapping ชื่อ commitments  mapping นี้ใช้สำหรับเก็บค่า hash ที่ผู้เล่นcommitไว้  โดย key คือaddressของผู้เล่น และvalue คือ bytes32 ซึ่งเป็นค่าhash 
 

## function reveal

	function reveal(uint choice, string memory secret) public onlyPlay {
	require(numPlayer == 2, "Not enough players");
	require(player_not_played[msg.sender], "Player has already played");
	require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4, "Invalid choice");
	require(revealChoice(choice, secret), "Invalid reveal");

	player_choice[msg.sender] = choice;
	player_not_played[msg.sender] = false;
	numInput++;
	if (numInput == 2) {
	     _checkWinnerAndPay();
	    }
	}

ใช้ `require(revealChoice(choice, secret), "Invalid reveal");` เพื่อตรวจสอบว่า choice ตรงกับ hash ที่ commit ไว้  บันทึกค่าของ choice ลงใน `player_choice`
 ถ้าผู้เล่นทั้งสองคนเปิดเผย choice ครบแล้ว (`numInput == 2`) ให้เรียก `_checkWinnerAndPay();` เพื่อจ่ายเงินรางวัล
