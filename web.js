var http = require('http'), fs = require('fs'), path = require('path');
 
http.createServer(function (request, response) {
    var filePath = './build' +
            (request.url === '/' ? '/index.html' : request.url);

    path.exists(filePath, function (exists) {
        if (exists) {
            fs.readFile(filePath, function (error, content) {
                if (error) {
                    response.writeHead(500);
                    response.end();
                } else {
                    response.writeHead(200, { 'Content-Type': 'text/html' });
                    response.end(content, 'utf-8');
                }
            });
        } else {
            response.writeHead(404);
            response.end();
        }
    });
}).listen(process.env.PORT || 5000);
