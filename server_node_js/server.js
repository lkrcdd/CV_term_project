const express = require('express');
const server = express();
const port = 3000;

// 루트 경로('/')에 대한 GET 요청 처리
server.get('/', (req, res) => {
    const data = {
        message: 'Hello from Node.js server!'
    };
    res.json(data);
});

// 서버 시작
server.listen(port, () => {
    console.log(`서버가 http://localhost:${port} 에서 실행 중입니다.`);
});

//서버 실행 -> terminal 에서 node server.js
