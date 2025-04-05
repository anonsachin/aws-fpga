#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>

struct GateConfig {
    unsigned int aSelect : 4;
    unsigned int bSelect : 4;
    unsigned int cSelect : 4;
    unsigned int gateSelect : 4;
};

union DataUnion {
    struct GateConfig gates[2];  // Two structs (each 16 bits total)
    uint32_t data;               // 32-bit unsigned integer
};

#define MAP_SIZE (64 * 1024 * 1024)

int main()
{
    int fd;
    volatile uint32_t *map_base, *results, *count;
    const char *resource_file = "/sys/bus/pci/devices/0000:34:00.0/resource0";
    union DataUnion gateConfigStore;

    gateConfigStore.gates[0].gateSelect = 4;
    gateConfigStore.gates[0].cSelect = 1;
    gateConfigStore.gates[0].bSelect = 2;
    gateConfigStore.gates[0].aSelect = 8;

    gateConfigStore.gates[1].gateSelect = 4;
    gateConfigStore.gates[1].cSelect = 1;
    gateConfigStore.gates[1].bSelect = 2;
    gateConfigStore.gates[1].aSelect = 8;

    // Open the PCI resource file.
    fd = open(resource_file, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open resource file");
        exit(EXIT_FAILURE);
    }

    // Map one page of the resource file starting from the page-aligned offset.
    map_base = (volatile uint32_t *) mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (map_base == MAP_FAILED) {
        perror("mmap");
        close(fd);
        exit(EXIT_FAILURE);
    }

    // Calculate the virtual address pointer within the mapped region.
    results = map_base + 1;
    count = map_base + 2;

    // assign the values
    *map_base = gateConfigStore.data;
   

    printf("[INFO] The configs are [%x]%d = %d\n", (unsigned int)map_base, *map_base, gateConfigStore.data);

    // assert
   int counter = 10;

   do {
   sleep(1);
   if (*results == 15) {
    printf("Great the result has the desired value at %d (count): The counter value in hardware =>[%d] \n",counter, *count);
    goto clean_up;
   }
   counter--;
   printf("Stil the result has the desired value at %d (count): The counter value in hardware =>[%d] \n",counter, *count);
   }while (counter > 0);


clean_up:
    // Clean up: unmap the memory and close the file.
    if (munmap((void*)map_base, MAP_SIZE) == -1) {
        perror("munmap");
    }
    close(fd);
    return EXIT_SUCCESS;
}