clear
close all

%% Loading image, resizing to square, and binarizing
im = rgb2gray(imread('Letter.PNG', 'PNG'));
width = max(size(im));
im = imresize(im, [width, width]);
im = imbinarize(im);

%% Finding the horizontal interaction coefficients
horizontal_interaction_coefficients = zeros(width, width - 1);
for row = 1:width
    for col = 1:width-1
        if im(row, col) == im(row, col + 1)
            horizontal_interaction_coefficients(row, col) = 1;
        else
            horizontal_interaction_coefficients(row, col) = -1;
        end
    end
end


%% Finding the vertical interaction coefficients
vertical_interaction_coefficients = zeros(width - 1, width);
for col = 1:width
    for row = 1:width-1
        if im(row, col) == im(row + 1, col)
            vertical_interaction_coefficients(row, col) = 1;
        else
            vertical_interaction_coefficients(row, col) = -1;
        end
    end
end

%% Just setting the magnetic field arrays to zeros
mag_field_0 = zeros(width);
mag_field_1 = zeros(width);

%% Randomly initializing the spin array
spin = rand(width);
spin(spin > 0.5) = 1;
spin(spin <= 0.5) = -1;

%% Creating data file
write_data_file(spin, mag_field_0, mag_field_1, ...
    horizontal_interaction_coefficients, ...
    vertical_interaction_coefficients, 'data.h', width)



%% Creating figures
figure
imshow(im, [])
title("Image to create")

figure
imshow(horizontal_interaction_coefficients, [])
title("Horizontal interaction coefficients")

figure
imshow(vertical_interaction_coefficients, [])
title("Vertical interaction coefficients")


function write_data_file(spin, mag_field_0, mag_field_1, ...
    horizontal_interaction_coefficients, ...
    vertical_interaction_coefficients, file_path, grid_length)    

    spin_str = array_to_c(spin, ...
        'int spinArr[GRID_LEN][GRID_LEN]');
    mag_field_0_str = array_to_c(mag_field_0, ...
        'const int magneticFieldArr0[GRID_LEN][GRID_LEN]');
    mag_field_1_str = array_to_c(mag_field_1, ...
        'const int magneticFieldArr1[GRID_LEN][GRID_LEN]');
    horizontal_interaction_str = ...
        array_to_c(horizontal_interaction_coefficients, ...
        'interactionArrHorizontal[GRID_LEN][GRID_LEN-1]');
    vertical_interaction_str = ...
        array_to_c(vertical_interaction_coefficients, ...
        'interactionArrVertical[GRID_LEN][GRID_LEN-1]');
    
    fid = fopen(file_path,'w');
    fprintf(fid, '#define GRID_LEN %d\n\n', grid_length);
    fprintf(fid, 'int spinArr_temp[GRID_LEN][GRID_LEN];\n\n');
    fprintf(fid, spin_str);
    fprintf(fid, '\n\n');
    fprintf(fid, horizontal_interaction_str);
    fprintf(fid, '\n\n');
    fprintf(fid, vertical_interaction_str);
    fprintf(fid, '\n\n');
    fprintf(fid, mag_field_0_str);
    fprintf(fid, '\n\n');
    fprintf(fid, mag_field_1_str);
    fclose(fid);
end

function ret_str = array_to_c(arr, arr_name)
    ret_str  = strcat(arr_name, ' = {\n\t{');
    [height, width] = size(arr);
    
    
    for row = 1:height
        for col = 1:width
            ret_str = strcat(ret_str, int2str(arr(row, col)));
            if col == width && row == height
                ret_str = strcat(ret_str, '}');
            elseif col == width
                ret_str = strcat(ret_str, '},\n\t{');
            else
                ret_str = strcat(ret_str, ', ');
            end
        end
    end
    
    ret_str  = strcat(ret_str, '\n};');
    
end



