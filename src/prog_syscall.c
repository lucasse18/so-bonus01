#include <stdlib.h> //malloc
#include <unistd.h> //read, write

#define stdin 0
#define stdout 1

int main(int argc, char *argv[]) {
  if(argc <= 1) exit(1);

  size_t buffsize = atoi(argv[1]);
  char *buffer = malloc(buffsize * sizeof(char));

  ssize_t bytes_read = read(stdin, buffer, buffsize);
  while (bytes_read > 0) {
    write(stdout, buffer, bytes_read);
    bytes_read = read(stdin, buffer, buffsize);
  }

  free(buffer);
}
