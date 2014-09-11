%{
	#include <stdio.h>
	#include <unistd.h>
	#include <string.h>
	#include <openssl/sha.h>
	#include <openssl/hmac.h>
	#include <openssl/evp.h>
	#include <openssl/bio.h>
	#include <openssl/buffer.h>
	
	const char* magic_str = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	
	char* ws_key = NULL;
	char* ws_proto = NULL;
	
	char* base64(const unsigned char *input, int length) {
		BIO *bmem, *b64;
		BUF_MEM *bptr;

		b64 = BIO_new(BIO_f_base64());
		bmem = BIO_new(BIO_s_mem());
		b64 = BIO_push(b64, bmem);
		BIO_write(b64, input, length);
		BIO_flush(b64);
		BIO_get_mem_ptr(b64, &bptr);

		char *buff = (char *) malloc(bptr->length);
		memset(buff, 0, bptr->length);
		memcpy(buff, bptr->data, bptr->length - 1);

		BIO_free_all(b64);

		return buff;
	}
	
	void send_text(int sock, char* msg) {
	
		unsigned int len = strlen(msg);
		unsigned char buffer[1024];
		memset(buffer, 0, sizeof(buffer));
		
		// step 1: fin, rsv and opcode
		buffer[0] = 0x01 | 0x80; // opcode
		buffer[1] = len; // payload length
		memcpy(buffer + 2, msg, len);
		
		printf("sending %d byte(s)\n", strlen(buffer));
		
		write(sock, buffer, strlen(buffer));
	}
	
	void send_byebye(int sock) {
		unsigned char buffer[1024];
		memset(buffer, 0, sizeof(buffer));
		
		// step 1: fin, rsv, opcode
		buffer[0] = 0x08 | 0x80; // opcode
		
		write(sock, buffer, 2);
	}
	
	void send_ping(int sock) {
		unsigned char buffer[1024];
		memset(buffer, 0, sizeof(buffer));
		
		// step 1: fin, rsv, opcode
		buffer[0] = 0x09 | 0x80; // opcode
		
		write(sock, buffer, 2);
	}
%}

%token REQ_START
%token <sval> REQ_PATH
%token REQ_HTTP_VER
%token <sval> REQ_KEY
%token <sval> REQ_VALUE
%token SPACE
%parse-param { int* sock }
%union {
	int ival;
	char* sval;
}

%%
request:
	REQ_START SPACE REQ_PATH SPACE REQ_HTTP_VER configs
	{
		if (ws_key == NULL) return;
		
		char output[512];
		memset(output, 0, sizeof(output));
		
		strcat(output, "HTTP/1.1 101 Switching Protocols\r\n");
		strcat(output, "Upgrade: websocket\r\n");
		strcat(output, "Connection: Upgrade\r\n");
		strcat(output, "Sec-WebSocket-Accept: ");
		strcat(output, ws_key);
		strcat(output, "\r\n");
		strcat(output, "Sec-WebSocket-Protocol: ");
		strcat(output, ws_proto);
		strcat(output, "\r\n\r\n");
		
		printf("[2] returning %d byte(s)\n", strlen(output));
		printf("===================\n");
		printf("%s", output);
		printf("===================\n");
		write(*sock, output, strlen(output));
		
		free(ws_key);
		ws_key = NULL;
		
		send_text(*sock, "hello world!!");
		
		//send_byebye(*sock);
		send_ping(*sock);
	}
	;

configs:
	configs config
	|
	config
	;

config:
	REQ_KEY SPACE REQ_VALUE
	{
		if (strcmp("Sec-WebSocket-Key", $1) == 0) {
			int i;
			char buffer[512];
			memset(buffer, 0, sizeof(buffer));
			unsigned char data[SHA_DIGEST_LENGTH];
			
			strcat(buffer, $3);
			strcat(buffer, magic_str);
			SHA1((unsigned char *) buffer, strlen(buffer), data);
			ws_key = base64(data, SHA_DIGEST_LENGTH);
		} else if (strcmp("Sec-WebSocket-Protocol", $1) == 0) {
			ws_proto = $3;
		}
	}
	;
%%

int yyerror(char* err) {
	printf("Parse error: %s\n", err);
	return 0;
}

int yywrap() {
	return 1;
}