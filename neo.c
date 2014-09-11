#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

//extern FILE* yyin;
extern int yy_scan_string(const char*);
//extern int yyparse(int* sock);

int main(int argc, char const *argv[])
{
	int serverSock;
	int val = 1;
	struct sockaddr_in serverAddr;
	struct sockaddr_in clientAddr;
	socklen_t clientAddrLen = sizeof(clientAddr);
	char buffer[512];

	fprintf(stdout, "%s\n","Start");
	serverSock = socket(AF_INET, SOCK_STREAM, 0);
	if (serverSock == -1) {
		fprintf(stderr, "%s\n","open socket fail");
		return -1;
	}
	// Make sure the port can be immediately re-used
	if (setsockopt(serverSock, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val)) < 0) {
		fprintf(stderr, "%s\n","can't reuse socket");
		close(serverSock);
		return -1;
	}
	
	memset(&serverAddr, 0, sizeof(serverAddr));
	serverAddr.sin_family = AF_INET;
	serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	serverAddr.sin_port = htons(12345);
	if (bind(serverSock, (struct sockaddr *) &serverAddr, sizeof(serverAddr)) != 0) {
		fprintf(stderr, "%s\n","can't bind socket");
		close(serverSock);
		return -1;
	}
	// Listen to socket
	fprintf(stdout, "%s\n","start listen port 12345");
	if (listen(serverSock, 1024) < 0) {
		return -1;
	}

	while(1){
		//accept will wait for message coming 
		fprintf(stdout, "%s\n","wait accept");
		int clientSock = accept(serverSock, (struct sockaddr *) &clientAddr, &clientAddrLen);

		int total_byte_cnt = 0;
		for (;;) {
			int byteCount = read(clientSock, buffer + total_byte_cnt, sizeof(buffer) - total_byte_cnt - 1);
			if (byteCount >= 0 ) {
				total_byte_cnt += byteCount;
				buffer[total_byte_cnt] = 0;
				fprintf(stdout, "[1] %d bytes read\n", byteCount);
				fprintf(stdout, "%s\n", "========================");
				fprintf(stdout, "%s\n", buffer);
				fprintf(stdout, "%s\n", "========================");
				
				yy_scan_string(buffer);

				break;
			} else {
				fprintf(stdout, "%s\n","[3] oh no");
				break;
			}
		}
	}
	fprintf(stdout, "%s\n","Finish");

	return 0;
}