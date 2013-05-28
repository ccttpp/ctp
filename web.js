var http = require('http'), fs = require('fs');
 
http.createServer(function (request, response) {
    console.log('request.url: ' + request.url);
    console.log('__dirname: ' + __dirname);
    var filename = __dirname + '/build' + request.url +
            (request.url === '/' ? 'index.html' : '');
    console.log('filename: ' + filename);

    fs.exists(filename, function (exists) {
        if (exists) {
            console.log('filename exists');
            fs.readFile(filename, function (err, data) {
                if (err) {
                    console.log('file cannot be read');
                    response.writeHead(500);
                    response.end();
                } else {
                    console.log('file read ok');
                    response.writeHead(200, {
                        'Content-Length': data.length,
                        'Content-Type': 'text/html'
                    });
                    response.end(data, 'utf-8');
                }
            });
        } else {
            console.log('file does not exist');
            response.writeHead(404);
            response.end();
        }
    });
}).listen(process.env.PORT || 5000);
