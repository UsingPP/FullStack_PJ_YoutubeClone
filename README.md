추가해야 할 것(~11/6)
==============
프론트엔드에서 댓글 작성 및 목록 보기 서버에 전송하는 거 만들어두고 실제 서버에서 처리하기 구현
동영상 전송 후 일단 서버에 저장해두고 나중에 다시 불러오기 구현

원시적인 프론트엔드 구현(~11/7)
=========
피그마를 쓰든 어쩌든간에 아주 원시적인 프론트엔드를 구현하여 위에서 작성한 프로그램을 프로토타입처럼 만들어두기 

댓글 데이터베이스 구조
=======
|이름|제약조건|
|---|---|
|COMMENT_ID|INT NOT NULL PRIMARY KEY,|
|USER_ID|VARCHAR(10) NOT NULL,|
|USER_PASSWORD|VARCHAR(10) NOT NULL,|
|video_id|int NOT NULL,|
|COMMENT_BODY|VARCHAR(300)|