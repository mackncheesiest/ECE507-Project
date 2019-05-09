/*
 * main.cu
 *
 *  Created on: Apr 23, 2019
 *      Author: josh
 */

#include <string>

#include <cuda.h>
#include <curand.h>

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>

#include "data.h"

#define NUM_ITER 360000
#define DESTROY_PROB 0.00
#define PRINT_ITER 1000
#define SEED_VAL 1234

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t errCode, const char *file, int line, bool abort=true) {
  if (errCode != cudaSuccess) {
    fprintf(stderr, "GPU Assertion: %s %s %d\n", cudaGetErrorString(errCode), file, line);
    if (abort) exit(errCode);
  }
}

#define KERNEL_VERSION 4

#if KERNEL_VERSION==1
__global__ void spinUpdateKernel(int* spinArr, int* spinArr_temp,
                                 const int* __restrict__ interactionArrHorizontal, const int* __restrict__ interactionArrVertical) {

  int IS0, IS1, currRow, currCol, a, b, newSpin;

  curandState rand_state;
  curand_init((blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x),
              (blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x), 0, &rand_state);

  for (unsigned int i = 0; i < (GRID_LEN-1)/blockDim.y + 1; i++) {
    for (unsigned int j = 0; j < (GRID_LEN-1)/blockDim.x + 1; j++) {
      currRow = i * blockDim.y + threadIdx.y;
      currCol = j * blockDim.x + threadIdx.x;
      if (currRow < GRID_LEN && currCol < GRID_LEN) {
        /*
        IS0 = magneticFieldArr0[currRow * GRID_LEN + currCol];
        IS1 = magneticFieldArr1[currRow * GRID_LEN + currCol];
        */

        a = 0;
        b = 0;

        //Compute influence of external magnetic field
        /*
        if (IS0 == 1) {
          if (IS1 == 1) {
            a++;
          }
          else {
            b++;
          }
        }
        */

        // Compute influence of left neighbor
        if (currCol > 0) {
          if (spinArr[currRow * GRID_LEN + currCol - 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol - 1]) a++;
          else b++;
        }
        // Compute influence of right neighbor
        if (currCol < GRID_LEN-2) {
          if (spinArr[currRow * GRID_LEN + currCol + 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol + 1]) a++;
          else b++;
        }
        // Compute influence of up neighbor
        if (currRow > 0) {
          if (spinArr[(currRow-1) * GRID_LEN + currCol] == interactionArrVertical[(currRow-1) * (GRID_LEN-1) + currCol]) a++;
          else b++;
        }
        // Compute influence of down neighbor
        if (currRow < GRID_LEN-2) {
          if (spinArr[(currRow+1) * GRID_LEN + currCol] == interactionArrVertical[(currRow+1) * (GRID_LEN-1) + currCol]) a++;
          else b++;
        }

        // Update state
        if (a > b) {
          newSpin = 1;
        } else if (a < b) {
          newSpin = -1;
        } else {
          newSpin = curand_uniform(&rand_state) <= 0.5 ? -1 : 1;
//          newSpin = ((a * b) % 2) == 1 ? 1 : -1;
        }

        spinArr_temp[currRow * GRID_LEN + currCol] = newSpin;

        // Randomly flip state
        /*
        if (destroySpinState(DESTROY_PROB)) {
          spinArr_temp[currRow * GRID_LEN + currCol] = -spinArr_temp[currRow * GRID_LEN + currCol];
        }
        */
      }
    }
  }
}
#elif KERNEL_VERSION==2

#define TILE_DIM 16
#define MASK_WIDTH 3
#define MASK_RADIUS MASK_WIDTH/2
#define PADDED_DIM (TILE_DIM + MASK_WIDTH - 1)

__global__ void spinUpdateKernel(int* spinArr, int* spinArr_temp,
                                 const int* __restrict__ interactionArrHorizontal, const int* __restrict__ interactionArrVertical) {

  int IS0, IS1, currRow, currCol, a, b, newSpin;

  curandState rand_state;
  curand_init(clock64(), (blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x), 0, &rand_state);

  __shared__ float shared_spinArr[PADDED_DIM * PADDED_DIM];
  __shared__ float shared_interactionArrHorizontal[PADDED_DIM * (PADDED_DIM-1)];
  __shared__ float shared_interactionArrVertical[(PADDED_DIM-1) * PADDED_DIM];

  // Load Batch 1 (Spin Arr):
  int dest = threadIdx.y * TILE_DIM + threadIdx.x;
  int destY = dest / PADDED_DIM;
  int destX = dest % PADDED_DIM;
  int srcY = blockIdx.y * TILE_DIM + destY - MASK_RADIUS;
  int srcX = blockIdx.x * TILE_DIM + destX - MASK_RADIUS;
  int src = srcY * GRID_LEN + srcX;

  if ((srcY >= 0) && (srcX >= 0)) {
    if (srcY < GRID_LEN && srcX < GRID_LEN) {
      shared_spinArr[destY * PADDED_DIM + destX] = spinArr[src];
    } else {
      shared_spinArr[destY * PADDED_DIM + destX] = 0;
    }

    if ((srcY < GRID_LEN) && (srcX < GRID_LEN-1)) {
      shared_interactionArrHorizontal[destY * PADDED_DIM + destX] = interactionArrHorizontal[src];
    } else {
      shared_interactionArrHorizontal[destY * PADDED_DIM + destX] = 0;
    }

    if ((srcY < GRID_LEN-1) && (srcX < GRID_LEN)) {
      shared_interactionArrVertical[destY * PADDED_DIM + destX] = interactionArrVertical[src];
    } else {
      shared_interactionArrVertical[destY * PADDED_DIM + destX] = 0;
    }
  }

  // Load Batch 2 (Spin Arr):
  // Note: this assumes that you have inner threads >= outer threads,
  dest = threadIdx.y * TILE_DIM + threadIdx.x + TILE_DIM * TILE_DIM;
  destY = dest / PADDED_DIM;
  destX = dest % PADDED_DIM;
  srcY = blockIdx.y * TILE_DIM + destY - MASK_RADIUS;
  srcX = blockIdx.x * TILE_DIM + destX - MASK_RADIUS;
  src = srcY * GRID_LEN + srcX;

  if (destY < PADDED_DIM) {
    if ((srcY >= 0) && (srcX >= 0)) {
      if (srcY < GRID_LEN && srcX < GRID_LEN) {
        shared_spinArr[destY * PADDED_DIM + destX] = spinArr[src];
      } else {
        shared_spinArr[destY * PADDED_DIM + destX] = 0;
      }

      if ((srcY < GRID_LEN) && (srcX < GRID_LEN-1)) {
        shared_interactionArrHorizontal[destY * PADDED_DIM + destX] = interactionArrHorizontal[src];
      } else {
        shared_interactionArrHorizontal[destY * PADDED_DIM + destX] = 0;
      }

      if ((srcY < GRID_LEN-1) && (srcX < GRID_LEN)) {
        shared_interactionArrVertical[destY * PADDED_DIM + destX] = interactionArrVertical[src];
      } else {
        shared_interactionArrVertical[destY * PADDED_DIM + destX] = 0;
      }
    }
  }

  __syncthreads();

  currRow = blockIdx.y * TILE_DIM + threadIdx.y;
  currCol = blockIdx.x * TILE_DIM + threadIdx.x;
  if (currRow < GRID_LEN && currCol < GRID_LEN) {
    /*
    IS0 = magneticFieldArr0[currRow * GRID_LEN + currCol];
    IS1 = magneticFieldArr1[currRow * GRID_LEN + currCol];
    */

    a = 0;
    b = 0;

    //Compute influence of external magnetic field
    /*
    if (IS0 == 1) {
      if (IS1 == 1) {
        a++;
      }
      else {
        b++;
      }
    }
    */

    // Compute influence of left neighbor
    if (currCol > 0) {
      if (shared_spinArr[currRow * PADDED_DIM + currCol - 1] == shared_interactionArrHorizontal[currRow * PADDED_DIM + currCol - 1]) a++;
      else b++;
    }
    // Compute influence of right neighbor
    if (currCol < GRID_LEN-2) {
      if (shared_spinArr[currRow * PADDED_DIM + currCol + 1] == shared_interactionArrHorizontal[currRow * PADDED_DIM + currCol + 1]) a++;
      else b++;
    }
    // Compute influence of up neighbor
    if (currRow > 0) {
      if (shared_spinArr[(currRow-1) * PADDED_DIM + currCol] == shared_interactionArrVertical[(currRow-1) * (PADDED_DIM-1) + currCol]) a++;
      else b++;
    }
    // Compute influence of down neighbor
    if (currRow < GRID_LEN-2) {
      if (shared_spinArr[(currRow+1) * PADDED_DIM + currCol] == shared_interactionArrVertical[(currRow+1) * (PADDED_DIM-1) + currCol]) a++;
      else b++;
    }

    // Update state
    if (a > b) {
      newSpin = 1;
    } else if (a < b) {
      newSpin = -1;
    } else {
      newSpin = curand_uniform(&rand_state) <= 0.5 ? -1 : 1;
    }

    spinArr_temp[currRow * GRID_LEN + currCol] = newSpin;

    // Randomly flip state
    /*
    if (destroySpinState(DESTROY_PROB)) {
      spinArr_temp[currRow * GRID_LEN + currCol] = -spinArr_temp[currRow * GRID_LEN + currCol];
    }
    */
  }
}
#elif KERNEL_VERSION==3

/*
 * Assumes that blockDim.x == GRID_LEN (and implicitly that GRID_LEN is smaller than maximum x block size)
 *              blockDim.y == (1024-1)/GRID_LEN + 1
 */

__global__ void spinUpdateKernel(int* spinArr, int* spinArr_temp,
                                 const int* __restrict__ interactionArrHorizontal, const int* __restrict__ interactionArrVertical) {

  int IS0, IS1, globalRow, globalCol, currRow, currCol, a, b, newSpin;

  globalRow = blockIdx.y + threadIdx.y;
  globalCol = threadIdx.x;

  curandState rand_state;
//  curand_init(clock64(), (blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x), 0, &rand_state);
  curand_init((blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x),
              (blockDim.y * blockIdx.y + threadIdx.y) * (blockDim.x * blockIdx.x + threadIdx.x), 0, &rand_state);

  __shared__ float shared_spinArr[((GRID_LEN-1)/1024 + 1 + 2) * GRID_LEN];
//  __shared__ float shared_interactionArrHorizontal[blockDim.y * (GRID_LEN-1)];
//  __shared__ float shared_interactionArrVertical[(blockDim.y-1) * GRID_LEN];

  for (int offset = -1; offset < (blockDim.y+2); offset += blockDim.y) {
    shared_spinArr[(offset+threadIdx.y)] = spinArr[((offset+blockIdx.y) * blockDim.y + threadIdx.y) * GRID_LEN + blockIdx.x];
  }

  __syncthreads();

  currRow = threadIdx.y;
  currCol = threadIdx.x;
  if (globalRow < GRID_LEN && globalCol < GRID_LEN) {
    /*
    IS0 = magneticFieldArr0[currRow * GRID_LEN + currCol];
    IS1 = magneticFieldArr1[currRow * GRID_LEN + currCol];
    */

    a = 0;
    b = 0;

    //Compute influence of external magnetic field
    /*
    if (IS0 == 1) {
      if (IS1 == 1) {
        a++;
      }
      else {
        b++;
      }
    }
    */

    // Compute influence of left neighbor
    if (globalCol > 0) {
      if (shared_spinArr[currRow * GRID_LEN + currCol - 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol - 1]) a++;
      else b++;
    }
    // Compute influence of right neighbor
    if (globalCol < GRID_LEN-2) {
      if (shared_spinArr[currRow * GRID_LEN + currCol + 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol + 1]) a++;
      else b++;
    }
    // Compute influence of up neighbor
    if (globalRow > 0) {
      if (shared_spinArr[(currRow-1) * GRID_LEN + currCol] == interactionArrVertical[(currRow-1) * (GRID_LEN-1) + currCol]) a++;
      else b++;
    }
    // Compute influence of down neighbor
    if (globalRow < GRID_LEN-2) {
      if (shared_spinArr[(currRow+1) * GRID_LEN + currCol] == interactionArrVertical[(currRow+1) * (GRID_LEN-1) + currCol]) a++;
      else b++;
    }

    // Update state
    if (a > b) {
      newSpin = 1;
    } else if (a < b) {
      newSpin = -1;
    } else {
      newSpin = curand_uniform(&rand_state) <= 0.5 ? -1 : 1;
    }

    spinArr_temp[globalRow * GRID_LEN + globalCol] = newSpin;

    // Randomly flip state
    /*
    if (destroySpinState(DESTROY_PROB)) {
      spinArr_temp[currRow * GRID_LEN + currCol] = -spinArr_temp[currRow * GRID_LEN + currCol];
    }
    */
  }
}
#elif KERNEL_VERSION==4
__global__ void spinUpdateKernel(int* spinArr, int* spinArr_temp,
                                 const int* __restrict__ interactionArrHorizontal, const int* __restrict__ interactionArrVertical,
                                 const unsigned int* __restrict__ randomSpins, const int randOffset) {

  int IS0, IS1, currRow, currCol, a, b, newSpin;

  for (unsigned int i = 0; i < (GRID_LEN-1)/blockDim.y + 1; i++) {
    for (unsigned int j = 0; j < (GRID_LEN-1)/blockDim.x + 1; j++) {
      currRow = i * blockDim.y + threadIdx.y;
      currCol = j * blockDim.x + threadIdx.x;
      if (currRow < GRID_LEN && currCol < GRID_LEN) {
        /*
        IS0 = magneticFieldArr0[currRow * GRID_LEN + currCol];
        IS1 = magneticFieldArr1[currRow * GRID_LEN + currCol];
        */

        a = 0;
        b = 0;

        //Compute influence of external magnetic field
        /*
        if (IS0 == 1) {
          if (IS1 == 1) {
            a++;
          }
          else {
            b++;
          }
        }
        */

        // Compute influence of left neighbor
        if (currCol > 0) {
          if (spinArr[currRow * GRID_LEN + currCol - 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol - 1]) a++;
          else b++;
        }
        // Compute influence of right neighbor
        if (currCol < GRID_LEN-2) {
          if (spinArr[currRow * GRID_LEN + currCol + 1] == interactionArrHorizontal[currRow * GRID_LEN + currCol + 1]) a++;
          else b++;
        }
        // Compute influence of up neighbor
        if (currRow > 0) {
          if (spinArr[(currRow-1) * GRID_LEN + currCol] == interactionArrVertical[(currRow-1) * (GRID_LEN-1) + currCol]) a++;
          else b++;
        }
        // Compute influence of down neighbor
        if (currRow < GRID_LEN-2) {
          if (spinArr[(currRow+1) * GRID_LEN + currCol] == interactionArrVertical[(currRow+1) * (GRID_LEN-1) + currCol]) a++;
          else b++;
        }

        // Update state
        if (a > b) {
          newSpin = 1;
        } else if (a < b) {
          newSpin = -1;
        } else {
          newSpin = randomSpins[currRow * GRID_LEN + currCol + randOffset] % 2 == 0 ? -1 : 1;
//          newSpin = ((a * b) % 2) == 1 ? 1 : -1;
        }

        spinArr_temp[currRow * GRID_LEN + currCol] = newSpin;

        // Randomly flip state
        /*
        if (destroySpinState(DESTROY_PROB)) {
          spinArr_temp[currRow * GRID_LEN + currCol] = -spinArr_temp[currRow * GRID_LEN + currCol];
        }
        */
      }
    }
  }
}
#endif

void writeToFile(int* spinArr, std::string filename) {
     // Write results to file
    FILE *fp;
    fp = fopen(filename.c_str(), "w");

    if (fp == NULL) {
        printf("Unable to create output file.\n");
        exit(EXIT_FAILURE);
    }

    for (int row = 0; row < GRID_LEN; row++) {
        for (int col = 0; col < GRID_LEN; col++) {
            fprintf(fp, "%d ", spinArr[row * GRID_LEN + col]);
        }
        fprintf(fp, "\n");
    }

    fclose(fp);
}

int main(void) {

  int *h_outputSpinArr = (int*) malloc(GRID_LEN * GRID_LEN * sizeof(int));
  int *d_spinArr_1, *d_spinArr_2, *d_spinArr_swap, *d_magneticFieldArr0, *d_magneticFieldArr1, *d_interactionArrHorizontal, *d_interactionArrVertical;

  unsigned int *d_randomSpins, randOffset;

  gpuErrchk(cudaMalloc((void**) &d_spinArr_1, GRID_LEN * GRID_LEN * sizeof(int)));
  gpuErrchk(cudaMalloc((void**) &d_spinArr_2, GRID_LEN * GRID_LEN * sizeof(int)));
  gpuErrchk(cudaMalloc((void**) &d_magneticFieldArr0, GRID_LEN * GRID_LEN * sizeof(int)));
  gpuErrchk(cudaMalloc((void**) &d_magneticFieldArr1, GRID_LEN * GRID_LEN * sizeof(int)));
  gpuErrchk(cudaMalloc((void**) &d_interactionArrHorizontal, GRID_LEN * (GRID_LEN-1) * sizeof(int)));
  gpuErrchk(cudaMalloc((void**) &d_interactionArrVertical, (GRID_LEN-1) * GRID_LEN * sizeof(int)));

  gpuErrchk(cudaMalloc((void**) &d_randomSpins, (GRID_LEN * GRID_LEN + 20) * sizeof(int)));

  gpuErrchk(cudaMemcpy(d_spinArr_1, spinArr, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_magneticFieldArr0, magneticFieldArr0, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_magneticFieldArr1, magneticFieldArr1, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_interactionArrHorizontal, interactionArrHorizontal, GRID_LEN * (GRID_LEN-1) * sizeof(int), cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_interactionArrVertical, interactionArrVertical, (GRID_LEN-1) * GRID_LEN * sizeof(int), cudaMemcpyHostToDevice));

  srand(SEED_VAL);

  curandGenerator_t gen;
  curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
  curandSetPseudoRandomGeneratorSeed(gen, SEED_VAL);
  curandGenerate(gen, d_randomSpins, GRID_LEN * GRID_LEN + 20);

  #if KERNEL_VERSION==1
  dim3 dimBlock(min(GRID_LEN, 1024), max(1024/GRID_LEN, 1), 1);
  dim3 dimGrid(1, GRID_LEN/max(1024/GRID_LEN, 1), 1);
  #elif KERNEL_VERSION==2
  const int blockDim = min(GRID_LEN, 16);
  dim3 dimBlock(blockDim, blockDim);
  dim3 dimGrid((GRID_LEN-1)/blockDim + 1, (GRID_LEN-1)/blockDim + 1, 1);
  #elif KERNEL_VERSION==3
  dim3 dimBlock(GRID_LEN, max(1024/GRID_LEN, 1), 1);
  dim3 dimGrid(1, GRID_LEN/max(1024/GRID_LEN, 1), 1);
  #elif KERNEL_VERSION==4
  dim3 dimBlock(min(GRID_LEN, 1024), max(1024/GRID_LEN, 1), 1);
  dim3 dimGrid(1, GRID_LEN/max(1024/GRID_LEN, 1), 1);
  #endif

  for (int i = 0; i < NUM_ITER; i++) {
    randOffset = rand() % 20;
    #if KERNEL_VERSION==4
    spinUpdateKernel<<<dimBlock, dimGrid>>>(d_spinArr_1, d_spinArr_2, d_interactionArrHorizontal, d_interactionArrVertical, d_randomSpins, randOffset);
    #else
    spinUpdateKernel<<<dimBlock, dimGrid>>>(d_spinArr_1, d_spinArr_2, d_interactionArrHorizontal, d_interactionArrVertical);
    #endif
    gpuErrchk(cudaPeekAtLastError());

    d_spinArr_swap = d_spinArr_1;
    d_spinArr_1 = d_spinArr_2;
    d_spinArr_2 = d_spinArr_swap;
    if (i % PRINT_ITER == 0) {
      printf("Finished enqueuing iteration %d...\n", i);
    }
  }

//  gpuErrchk(cudaMemcpy(h_outputSpinArr, d_spinArr, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyDeviceToHost));
  printf("Done enqueuing kernels on host, waiting for GPU to finish...\n");
  cudaDeviceSynchronize();
  printf("GPU finished! Copying output...\n");
  if (NUM_ITER % 2 == 0) {
    gpuErrchk(cudaMemcpy(h_outputSpinArr, d_spinArr_1, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyDeviceToHost));
  } else {
    gpuErrchk(cudaMemcpy(h_outputSpinArr, d_spinArr_2, GRID_LEN * GRID_LEN * sizeof(int), cudaMemcpyDeviceToHost));
  }

  writeToFile(h_outputSpinArr, "final.txt");
  printf("Done!\n");

  return 0;
}

