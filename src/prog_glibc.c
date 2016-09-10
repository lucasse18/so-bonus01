#include <stdlib.h> //malloc
#include <stdio.h>  //fread, fwrite

int main(int argc, char *argv[]) {
  if(argc <= 1) exit(1);

  size_t buffsize = atoi(argv[1]);
  char *buffer = malloc(buffsize * sizeof(char));

  size_t bytes_read = fread(buffer, 1, buffsize, stdin);
  while (bytes_read > 0) {
    fwrite(&buffer, 1, bytes_read, stdout);
    bytes_read = fread(buffer, 1, buffsize, stdin);
  }

  free(buffer);
}
