% clear
close all
format compact

%% Initializing directory and reading all text files from the directory
data_dir_path = '../CPU_MSP430/';
files = dir(strcat(data_dir_path, 'final*.txt'));
%files = dir(strcat(data_dir_path, '*.txt'));

for i = 1:size(files, 1)
    file_path = strcat(files(i).folder, '\', files(i).name);
    image = dlmread(file_path);
    imshow(image, [])
    drawnow
    
end
