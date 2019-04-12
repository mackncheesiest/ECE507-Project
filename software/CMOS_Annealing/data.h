#define GRID_LEN 3

int spinArr[GRID_LEN][GRID_LEN] = {
    {-1, -1, 1},
    {-1, 1, 1},
    {-1, -1, 1}
};

int interactionArrHorizontal[GRID_LEN][GRID_LEN-1] = {
    {1, 1},
    {1, 1},
    {1, 1}
};

int interactionArrVertical[GRID_LEN-1][GRID_LEN] = {
    {-1, -1, -1},
    {-1, -1, -1}
};

// Temporary storage so that we can emulate all spins updating in parallel
int spinArr_temp[GRID_LEN][GRID_LEN];

// TODO: Are the magnetic field interactions supposed to be two different arrays? Is one horizontal and the other vertical?
const int magneticFieldArr0[GRID_LEN][GRID_LEN] = {
    {0, 0, 0},
    {0, 0, 0},
    {0, 0, 0}
};

const int magneticFieldArr1[GRID_LEN][GRID_LEN] = {
    {0, 0, 0},
    {0, 0, 0},
    {0, 0, 0},
};