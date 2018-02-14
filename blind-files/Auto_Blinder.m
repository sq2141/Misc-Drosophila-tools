%------------------------INSTRUCTIONS---------------------------
%
% 1)Back up the files you want to rename!
%
% 2)Make sure none of the files has just a number as a file name (e.g. 1.jpg,
% 5.avi); a name that includes numbers (e.g. movie3.avi) or has leading
% zeros (e.g. 003.jpg) is fine.
%
% 3)Run this program only ONCE on any given folder
%
%---------------------------------------------------------------

%clear workspace variables and screen
clear all;
clc;

%user selects a folder; extracts file names in that folder
folder=uigetdir('*');
files=dir(folder);
fileNames=setdiff({files.name},{'.','..'})'; 

%get m, number of files to rename
[m n]=size(fileNames);

%generate scrambled integer numbers
randNums=randperm(m);

%enter scrambled integers into column 1 of a matrix called key 
for i=1:m
    key{i,1}=randNums(i);
end;

%enter original file names into column 2 of key
key(:,2)=fileNames;

%go through each row of key, and rename old_File to new File name
for j=1:m
    %build old file path and get the extension
    old_File=fullfile(folder,key{j,2});
    [pathstr,name,ext] = fileparts(old_File);
    
    %build new file path
    new_File=fullfile(folder,sprintf([num2str(key{j,1}),ext]));
    
    %rename the file
    movefile(old_File,new_File);;
end;

%sort key by new file number
sorted_key=sortrows(key, 1);

%save key in the same directory as the files as key.xls
xlswrite([folder, '\key.xls'], sorted_key);