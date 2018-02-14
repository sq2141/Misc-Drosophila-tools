function egg_counter_postManualCorrection

clc;
clear all;
%ask user to browse to folder containing original pictures
fileFolder=uigetdir;
fileList=dir([fileFolder,'\*.jpg']);
fileName={fileList.name};

mkdir(fileFolder,'Manually Corrected\Results')

for i=1:length(fileName);
    
figure    

img0=[fileFolder,'\',char(fileName(i))];
    
%get the name of original image as "name" without extension
[pathstr,name,ext,versn] = fileparts(img0);

%load the image
img1=imread(img0);

%get img3, the manually corrected image in the subdirectory
img3=[fileFolder,'\Manually Corrected\',name,'_Filtered.jpg'];
img4=imread(img3);
img4=im2bw(img4,graythresh(img4));

B = bwboundaries(img4);
imshow(img1)
text(10,10,strcat('\color{green}Objects Found:',num2str(length(B))))
hold on

for k = 1:length(B)
boundary = B{k};
plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.2);
end

resultName=[fileFolder '\Manually Corrected\Results\' name '_Result.jpg'];
saveas(gcf,resultName,'jpg');

clf;
close;

end

