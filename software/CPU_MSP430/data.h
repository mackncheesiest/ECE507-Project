#define GRID_LEN 20

int spinArr_temp[GRID_LEN][GRID_LEN];

int spinArr[GRID_LEN][GRID_LEN] = {
	{1,-1,-1,-1,1,1,1,1,-1,1,-1,-1,1,1,1,-1,-1,-1,-1,1},
	{1,1,-1,1,-1,-1,1,-1,-1,1,1,-1,1,1,-1,-1,1,1,1,1},
	{1,-1,-1,-1,1,-1,1,1,-1,1,-1,-1,-1,-1,-1,-1,1,-1,1,1},
	{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,1,1,1,1,-1,-1,-1,1},
	{1,-1,-1,-1,1,1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,-1,-1},
	{-1,1,1,1,1,-1,1,-1,-1,1,-1,-1,1,1,-1,-1,1,-1,-1,-1},
	{1,-1,1,1,1,1,-1,-1,-1,-1,-1,1,1,-1,-1,1,1,-1,1,1},
	{1,1,1,-1,-1,1,-1,1,1,1,-1,1,1,1,1,-1,1,-1,-1,1},
	{-1,-1,-1,-1,-1,1,-1,1,-1,-1,1,-1,1,1,1,-1,-1,1,1,1},
	{1,1,-1,-1,-1,-1,-1,-1,1,-1,1,1,-1,1,-1,1,1,-1,1,1},
	{1,-1,-1,1,-1,-1,1,-1,-1,1,1,1,-1,1,-1,1,1,1,1,1},
	{-1,-1,-1,-1,1,-1,1,1,1,-1,-1,-1,-1,-1,1,-1,-1,1,1,1},
	{1,1,-1,1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,1,-1,1,-1,-1,1},
	{-1,-1,-1,1,-1,1,1,1,-1,1,-1,1,1,1,-1,1,-1,-1,-1,1},
	{-1,-1,1,-1,1,1,1,-1,1,-1,1,-1,1,1,1,-1,-1,1,-1,-1},
	{1,1,-1,-1,-1,1,1,1,1,-1,1,-1,-1,-1,1,-1,1,-1,-1,1},
	{1,1,1,-1,-1,1,-1,-1,-1,-1,-1,1,-1,1,1,-1,-1,1,-1,-1},
	{1,-1,1,-1,1,1,-1,-1,-1,1,-1,-1,-1,-1,1,-1,1,-1,1,-1},
	{-1,1,-1,-1,-1,1,-1,-1,1,-1,1,1,1,-1,1,1,-1,-1,-1,1},
	{-1,-1,-1,1,1,1,1,-1,-1,-1,1,-1,1,-1,1,-1,-1,1,-1,-1}
};

int interactionArrHorizontal[GRID_LEN][GRID_LEN-1] = {
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,-1,-1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,-1,1,-1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,-1,1,1,-1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,-1,1,1,-1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,-1,1,1,1,1,-1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,-1,-1,-1,1,1,-1,1,1,1,1,1,1},
	{1,1,1,1,1,1,-1,1,-1,1,-1,1,-1,1,1,1,1,1,1},
	{1,1,1,1,1,1,-1,-1,1,1,-1,1,1,-1,1,1,1,1,1},
	{1,1,1,1,1,-1,1,-1,1,1,-1,1,1,-1,1,1,1,1,1},
	{1,1,1,1,1,-1,-1,1,1,1,1,-1,1,-1,1,1,1,1,1},
	{1,1,1,1,-1,1,1,1,1,1,1,1,1,1,-1,1,1,1,1},
	{1,1,1,1,-1,-1,1,1,1,1,1,-1,1,1,-1,1,1,1,1},
	{1,1,1,-1,1,-1,1,1,1,1,1,1,-1,1,1,-1,1,1,1},
	{1,1,1,-1,-1,1,1,1,1,1,1,1,-1,1,1,-1,1,1,1},
	{1,1,-1,1,-1,1,1,1,1,1,1,1,1,-1,1,-1,1,1,1},
	{1,1,-1,1,-1,1,1,1,1,1,1,1,-1,1,1,1,-1,1,1},
	{1,-1,1,1,1,-1,1,1,1,1,1,1,-1,1,1,1,1,-1,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

int interactionArrVertical[GRID_LEN-1][GRID_LEN] = {
	{1,1,1,1,1,1,1,1,1,1,-1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,-1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,1,1,-1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,-1,1,1,1,-1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,-1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,-1,1,1,-1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,-1,1,1,1,1,-1,1,1,1,1,1,1},
	{1,1,1,1,1,1,-1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,-1,1,1,1,-1,1,1,1,1,1,1,1,1},
	{1,1,1,1,1,-1,1,-1,-1,-1,-1,-1,1,1,-1,1,1,1,1,1},
	{1,1,1,1,1,1,-1,-1,-1,-1,-1,-1,1,1,1,1,1,1,1,1},
	{1,1,1,1,-1,1,1,1,1,1,1,1,-1,1,1,-1,1,1,1,1},
	{1,1,1,1,1,-1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,1,1,-1,1,1,1,1,1,1,1,1,1,-1,1,1,1,1,1,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,-1,1,1,-1,1,1,1},
	{1,1,-1,1,1,-1,1,1,1,1,1,1,1,1,1,1,1,-1,1,1},
	{1,1,-1,-1,-1,-1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1,1,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

const int magneticFieldArr0[GRID_LEN][GRID_LEN] = {
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
};

const int magneticFieldArr1[GRID_LEN][GRID_LEN] = {
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
};