#include <stdio.h>

main() {
  FILE *f;
  unsigned short buffer[32768];
  unsigned int i;

  f = fopen("bios.bin", "rb");
  fread(buffer, 2, 32768, f);
  fclose(f);

  printf("DEPTH = 32768;\n");
  printf("WIDTH = 16;\n");
  printf("ADDRESS_RADIX = HEX;\n");
  printf("DATA_RADIX = HEX;\n");
  printf("CONTENT\n");
  printf("BEGIN\n\n");
  for(i=0; i<32768; i++)
  {
    printf("%.4x : %.4x;\n", i, buffer[i]);
    fflush(stdout);
  }
  printf("\nEND;\n");
}