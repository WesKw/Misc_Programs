
/************************************************
 *This program takes two commands and			*
 *redirects the standard output of command 1	*
 *to the standard output of command 2.			*
 *Author: Wesley Kwiecinski, z1896564			*
 *CSCI 330 Section 1							*
 *Assignment 5									*
 *Due 23/10/2020								*
 ************************************************/

#include <fcntl.h>
#include <iostream>
#include <sstream>
#include <string>
#include <string.h>
#include <cstring>
#include <cstdlib>
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

using namespace std;

int main(int argc, char* argv[])
{
	string line;
	int pipefd[2], rs;
	char * temp;

	while(true)
	{
		char * args1[7];
		int i = 0; //args counter
		line = "";
		//get first command
		cout << "command1? ";
		getline(cin, line);
		if(line.compare("quit")==0) exit(0); //exit if quit
		//process input for command 1
		temp = strdup(line.c_str());
		char * tok = strtok(temp, " ");
		args1[0] = tok;
		//cout << args1[0] << endl;
		i++;
		while(tok != NULL && i < 7)
		{
			//printf("%s\n", tok);
			tok = strtok(nullptr, " ");
			args1[i] = tok;
			//cout << args1[i] << endl;
			i++;
		}

		//cout << args1[0] << endl;
		//set final value to null
		args1[i] = 0;
		cout << "\n";

		//get second command input
		char * args2[7];
		i = 0; // reset buffer
		cout << "command2? ";
		getline(cin, line);
		if(line.compare("quit")==0) exit(0); //exit if quit

		//process command2
		temp = strdup(line.c_str());
		tok = strtok(temp, " ");	//priming read
		args2[0] = tok;
		i++;
		while(tok != NULL && i < 7)
		{
			tok = strtok(nullptr, " ");	//take in args as tokens
			args2[i] = tok;
			i++;
		}
		args2[i] = NULL;	//set last val to null
		cout << "\n";

		//time to create the pipe
		rs = pipe(pipefd);
		//check for error
		if(rs != 0) { perror("pipe"); exit(rs); }
		//create new child process
		pid_t pid = fork();
		//check for error
		if(pid == -1) { perror("fork"); exit(rs); }

		//child process, read
		if(pid == 0)
		{
			//close write end
			close(pipefd[1]);
			//close stdin
			close(0);
			//dup read end into stdin
			dup(pipefd[0]);
			close(pipefd[0]);
			rs = execvp(args2[0], args2);
			if(rs < 0) { perror("execlp");  exit(rs); } //exit if there's an error
		} else
		{	//parent process
			pid = fork();
			if(pid == 0)
			{
				//parent process, write to pipe
				close(pipefd[0]);	//close read end
				close(1); //close stdout
				dup(pipefd[1]); //dup write end into stdout
				close(pipefd[1]);//close write end
				//execute command 1, then check for error
				//rs = execvp(args1[0], args1);
				rs = execvp(args1[0], args1);
				if(rs < 0) { perror("execlp"); exit(rs); }
			}
			//wait for child process to finish
			waitpid(pid, NULL, 0);
			//close pipes, general clean up
			close(pipefd[1]);
			close(pipefd[0]);
			//delete args1;
			//delete args2;
		}
		//cout << "\n" << endl;
	}

	return 0;
}
