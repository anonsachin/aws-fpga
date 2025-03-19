#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>
#include <errno.h>

#define MAP_SIZE (64 * 1024 * 1024)

int main()
{
    int fd;
    volatile uint32_t *map_base, *operand_1, *operand_2, *result;
    const char *resource_file = "/sys/bus/pci/devices/0000:34:00.0/resource0";

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
    operand_1 = map_base;
    operand_2 = map_base + 1;
    result = map_base + 2;

    // assign the values
    *operand_1 = 1;
    *operand_2 = 2;

    printf("[INFO] The result of [%x]%d + [%x]%d =  [%x]%d\n", (unsigned int)operand_1, *operand_1, (unsigned int)operand_2, *operand_2, (unsigned int)result, *result);

    // assert
    if (*result != 3){
        printf("[ERROR] The result was supposed to be 3 but got %d\n",*result);
    }



    // Clean up: unmap the memory and close the file.
    if (munmap((void*)map_base, MAP_SIZE) == -1) {
        perror("munmap");
    }
    close(fd);
    return EXIT_SUCCESS;
}
