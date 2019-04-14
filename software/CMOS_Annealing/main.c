#define DEBUG

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#ifndef DEBUG
#include <msp430.h>
#endif

#include "data.h"


#define NUM_ITERS 10
#define DESTROY_PROB 0.00
#define PRINT_ITER 2

int destroySpinState(double probability) {
    return (rand() / (double)RAND_MAX) < probability;
}

int randomSpin() {
    return rand() % 2 ? 1 : -1;
}


void spinUpdateKernel(int currRow, int currCol) {
    int a = 0, b = 0, currSpin = spinArr[currRow][currCol], IS0 = magneticFieldArr0[currRow][currCol], IS1 = magneticFieldArr1[currRow][currCol], neighborRow, neighborCol;
    
    //Compute influence of external magnetic field
    if (IS0 == 1) {
        if (IS1 == 1) {
            a++;
        }
        else {
            b++;
        }
    }
    
    // Compute influence of left neighbor
    if (currCol > 0) {
        if (spinArr[currRow][currCol-1] == interactionArrHorizontal[currRow][currCol-1]) a++;
        else b++;
    }
    // Compute influence of right neighbor
    if (currCol < GRID_LEN-1) {
        if (spinArr[currRow][currCol+1] == interactionArrHorizontal[currRow][currCol+1]) a++;
        else b++;
    }
    // Compute influence of up neighbor
    if (currRow > 0) {
        if (spinArr[currRow-1][currCol] == interactionArrVertical[currRow-1][currCol]) a++;
        else b++;
    }
    // Compute influence of down neighbor
    if (currRow < GRID_LEN-1) {
        if (spinArr[currRow+1][currCol] == interactionArrVertical[currRow+1][currCol]) a++;
        else b++;
    }
    
    // Update state
    if (a > b) {
        spinArr_temp[currRow][currCol] = 1;
    } else if (a < b) {
        spinArr_temp[currRow][currCol] = -1;
    } else {
        spinArr_temp[currRow][currCol] = randomSpin();
    }
    
    // Randomly flip state
    if (destroySpinState(DESTROY_PROB)) {
        spinArr_temp[currRow][currCol] = -spinArr_temp[currRow][currCol];
    }
}

void writeToFile(char* filename) {
     // Write results to file
    FILE *fp;
    fp = fopen(filename, "w");

    if (fp == NULL) {
        printf("Unable to create output file.\n");
        exit(EXIT_FAILURE);
    }

    for (int row = 0; row < GRID_LEN; row++) {
        for (int col = 0; col < GRID_LEN; col++) {
            fprintf(fp, "%d ", spinArr[row][col]);
        }
        fprintf(fp, "\n");
    }

    fclose(fp);
}

int main(void)
{
    srand(time(0));

    unsigned int row, col, iter;

#ifndef DEBUG
    WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
#endif

    writeToFile("initial.txt");

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
            int size = 10*4;
            char buffer[size];
            sprintf(buffer,"iter_%d.txt", iter);
            writeToFile(buffer);
        }
    }
    
    writeToFile("final.txt");

    return 0;
}
