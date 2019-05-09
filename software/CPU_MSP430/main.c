#include <stdio.h>
#include <inttypes.h>
#ifdef RUN_LOCAL
#include <string.h>
#include <stdlib.h>
#else
#include <msp430.h>

#endif

#include "data.h"

#define NUM_ITERS 360000
#define PRINT_ITER (NUM_ITERS/10)

#ifdef BE_RANDOM
#include <stdlib.h>
int8_t destroySpinState(double probability) {
    return (rand() / (double)RAND_MAX) < probability;
}

int8_t randomSpin() {
    return rand() % 2 ? 1 : -1;
}
#define DESTROY_PROB 0.00
#else
int8_t tie_break = 1;
#endif

void spinUpdateKernel(unsigned int currRow, unsigned int currCol) {
    int8_t a = 0, b = 0;
#ifdef RUN_LOCAL
    int8_t IS0 = magneticFieldArr0[currRow][currCol], IS1 = magneticFieldArr1[currRow][currCol];

    //Compute influence of external magnetic field
    if (IS0 == 1) {
        if (IS1 == 1) {
            a++;
        }
        else {
            b++;
        }
    }
#endif
    
    // Compute influence of left neighbor
    if (currCol > 0) {
        if (spinArr[currRow][currCol-1] == interactionArrHorizontal[currRow][currCol-1]) { a++; }
        else { b++; }
    }
    // Compute influence of right neighbor
    if (currCol < (GRID_LEN-2)) {
        if (spinArr[currRow][currCol+1] == interactionArrHorizontal[currRow][currCol+1]) { a++; }
        else { b++; }
    }
    // Compute influence of up neighbor
    if (currRow > 0) {
        if (spinArr[currRow-1][currCol] == interactionArrVertical[currRow-1][currCol]) { a++; }
        else { b++; }
    }
    // Compute influence of down neighbor
    if (currRow < (GRID_LEN-2)) {
        if (spinArr[currRow+1][currCol] == interactionArrVertical[currRow+1][currCol]) { a++; }
        else { b++; }
    }
    
    // Update state
    if (a > b) {
        spinArr_temp[currRow][currCol] = 1;
    } else if (a < b) {
        spinArr_temp[currRow][currCol] = -1;
    } else {
#ifdef BE_RANDOM
        spinArr_temp[currRow][currCol] = randomSpin();
#else
        spinArr_temp[currRow][currCol] = tie_break;
        tie_break *= -1;
#endif
    }
    
#ifdef BE_RANDOM
    // Randomly flip state
    if (destroySpinState(DESTROY_PROB)) {
        spinArr_temp[currRow][currCol] = -spinArr_temp[currRow][currCol];
    }
#endif
}

#ifdef RUN_LOCAL
void writeToFile(char* filename) {
     // Write results to file
    FILE *fp;
    fp = fopen(filename, "w");

    if (fp == NULL) {
        printf("Unable to create output file.\n");
        exit(EXIT_FAILURE);
    }

    for (unsigned int row = 0; row < GRID_LEN; row++) {
        for (unsigned int col = 0; col < GRID_LEN; col++) {
            fprintf(fp, "%" PRIi8 " ", spinArr[row][col]);
        }
        fprintf(fp, "\n");
    }

    fclose(fp);
}
#endif

int main(void)
{
#ifdef BE_RANDOM
    srand(100);
#endif

    unsigned int row, col, iter;

#ifndef RUN_LOCAL
    WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
#endif

#ifdef RUN_LOCAL
    writeToFile("initial.txt");
#endif

    // Perform computations
    for (iter = 0; iter < NUM_ITERS; iter++) {
        for (row = 0; row < GRID_LEN; row++) {
            for (col = 0; col < GRID_LEN; col++) {
                spinUpdateKernel(row, col);
            }
        }
        // TODO: Attempts to do this by swapping pointers haven't worked out well. Falling back to what will be slow but should definitely work
        for (row = 0; row < GRID_LEN; row++) {
            for (col = 0; col < GRID_LEN; col++) {
                spinArr[row][col] = spinArr_temp[row][col];
            }
        }
        // Print
        if (iter % PRINT_ITER == 0) {
#ifdef RUN_LOCAL
            int size = 10*4;
            char buffer[size];
            sprintf(buffer,"iter_%d.txt", iter);
            writeToFile(buffer);
#else
            printf("Finished iteration %d\n", iter);
#endif
        }


    }
    
#ifdef RUN_LOCAL
    writeToFile("final.txt");
#else
    for (row = 0; row < GRID_LEN; row++) {
        for (col = 0; col < GRID_LEN; col++) {
            printf("%hhi ", spinArr[row][col]);
        }
        printf(";\n");
    }
#endif

    return 0;
}
