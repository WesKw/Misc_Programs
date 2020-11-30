/********************************************************
 *Creates a simple HTTP server using TCP and sockets	*
 *Wesley Kwiecinski, Z1896564				*
 *CSCI 330, Section 1					*
 *Assignment 8 - TCP Programming w/ sockets		*
 *Due 11/20/2020					*
 ********************************************************/

#include <fcntl.h>
#include <cstdlib>
#include <iostream>
#include <stdio.h>
#include <sys/socket.h>
#include <cstring>
#include <string>
#include <dirent.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sstream>
#include <netdb.h>
#include <unistd.h>

using std::cout;
using std::cerr;
using std::endl;
using std::string;

//Check if the client given path is valid
//Args: const char * path - pointer to path to check
//Returns: true if valid, false if not
bool CheckValid(const char * path)
{
	//create temp cpp string
	string test(path);
	if(path[0] == '/')
	{
		//use find to find instances of ".."
		if(test.find("..") != std::string::npos)
		{
			return false;	//return false if found
		}
	} else
	{
		return false;	//return false if path does not start with /
	}
	return true;		//return true if all goes well
}

int main(int argc, char * argv[])
{
	int pipefd[2];
	char buffer[256]; 	//argument buffer
	socklen_t server_length, client_length;
	struct sockaddr_in http_server;
	struct sockaddr_in http_client;

	//check for proper command line arguments:
	if(argc < 3)
	{
		cerr << "HTTP Server use: [Port to host on] [Directory Path to serve as root]" << endl;
		return EXIT_FAILURE;	//exit if less than 2 arguments, anything past arg2 is ignored.
	}

	//check if argv[2] is a valid directory
	//store argument as cpp string
	string arg2(argv[2]);
	DIR * dir = opendir(argv[2]);
	if(dir == nullptr)	//if directory cannot be opened
	{
		cerr << "That is not a valid directory.\n" << endl;	//print error and exit
		return EXIT_FAILURE;
	} else
	{
		closedir(dir);	//directory is good to go!
	}

	//Obtain descriptor using socket(), make TCP socket
	int sd = socket(AF_INET, SOCK_STREAM, 0); //use protocol 0 for TCP, save socket descriptor
	if(sd < 0) { perror("Failed to create socket"); return EXIT_FAILURE; } //return if cannot create socket

	memset(&http_server, 0, sizeof(http_server));	//clear area of memory with sockaddr_in struct
	http_server.sin_family = AF_INET;		//Use IPv4 protocol
	http_server.sin_addr.s_addr = INADDR_ANY;	//any IP address
	http_server.sin_port = htons(atoi(argv[1]));	//convert host byte to network byte

	//bind the socket
	server_length = sizeof(http_server);	//obtain size of the http_server
	if(bind(sd, (struct sockaddr *) &http_server, server_length) < 0)
	{
		perror("Failed to bind http_server socket");
		return EXIT_FAILURE;
	}

	//Switch to passive socket and create & set time of connection queue
	if(listen(sd, 32) < 0)
	{
		perror("Failed to listen");
		return EXIT_FAILURE;
	}

	int new_sd;
	while(new_sd = accept(sd, (struct sockaddr *) &http_client, &client_length))
	{
		//fork to process request
		pid_t pid = fork();
		if(pid == -1) { perror("fork()"); return EXIT_FAILURE; }	//exit if fork failed

		if(pid == 0) //child process, process request
		{
			const char * action;
			struct stat stat_buf;
			ssize_t obtained = read(new_sd, buffer, 255);	//store number read
			string request(buffer);		//store request in cpp string for easier use
			std::istringstream str(request);
			str >> request;	//remove GET
			str >> request;	//directory or file request

			//check if path is valid.
			if(!CheckValid(request.c_str())) { write(new_sd, "Path is not valid.", 19); exit(0); }

			//append request to arg if not just /
			if(request[0] == '/' && request[1] != '\0') { arg2 += request; }

			int stat_value = stat(arg2.c_str(), &stat_buf);	//get file info of arg2

			//check if path is a directory
			if(stat_value == 0 && S_ISDIR(stat_buf.st_mode))
			{
				//action = "ls\0";
				DIR * dir_ptr = opendir(arg2.c_str());	//open known directory
				struct dirent * dir_info;		//make struct for directory information
				dir_info = readdir(dir_ptr);		//priming read
				bool found = false;			//create found flag
				while(dir_info != nullptr && !found)	//look through info until found or if no index file is found
				{
					if(strcmp(dir_info->d_name, "index.html") == 0)	//index.html exists
					{
						//set action to cat to print index.html and adjust arg2.
						action = "cat\0";
						arg2 += "/index.html";
						found = true;		//set found flag to true
					}
					dir_info = readdir(dir_ptr);	//read dir again
				}

				if(!found) { action = "ls\0"; }	//if index.html is not found, set action to print directory.
				closedir(dir_ptr);

			} else if(stat_value == 0 && S_ISREG(stat_buf.st_mode))	//otherwise treat as a file.
			{
				//if a file, then send the contents of the file.
				action = "cat\0";	//set action to cat.
			} else	//otherwise file can't be found
			{
				perror("stat()");
				write(new_sd, "Request not found. ", 21);
				exit(-1);	//exit process if request can't be found
			}

			close(1);						//close stdout
			dup2(new_sd, 1);					//dup socket descriptor into stdout for easier writing
			int rs = execlp(action, action, arg2.c_str(), nullptr);	//call execlp with specific action
			if(rs < 0) { perror("execlp()"); exit(rs); }		//exit if execlp fails
		} else	//otherwise it's parent process, continue with server loop and close new_sd
		{
			waitpid(pid, nullptr, 0);	//wait for child process to finish
			close(new_sd);			//close the new socket descriptor
		}
	}

	//close socket descriptor
	close(sd);
	return 0;
}
