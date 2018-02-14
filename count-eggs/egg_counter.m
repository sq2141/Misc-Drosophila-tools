function egg_counter

clc;
clear all;

fileFolder=uigetdir;
fileList=dir([fileFolder,'\*.jpg']);
fileName={fileList.name};

mkdir(fileFolder,'Manually Corrected')
mkdir(fileFolder,'Before Manual Correction')

for i=1:length(fileName);

figure    

img0=[fileFolder,'\',char(fileName(i))];
    
%get the name of original image as "name" without extension
[pathstr,name,ext,versn] = fileparts(img0);

%load the image
img1=imread(img0);

%convert to gray
img1=rgb2gray(img1);

%convert black and white
img2=im2bw(img1,graythresh(img1));

%save it as inverted black and white before noise filter
BWname=[fileFolder '\Before Manual Correction\' name '_BW.jpg'];
img2=~img2;
imwrite(img2,BWname,'jpg')
img2=~img2;

% remove all object containing fewer than 40 and more than 700 pixels
imgsmallremoved = bwareaopen(img2,40);
imglargeonly = bwareaopen(img2,700);
img2 = imgsmallremoved - imglargeonly;

% fill a gap in the pen's cap
se = strel('disk',2);
img2 = imclose(img2,se);

% fill any holes, so that regionprops can be used to estimate
% the area enclosed by each of the boundaries
img2 = imfill(img2,'holes');

%invert
img2=~img2;

%save after noise filter
filteredName=[fileFolder '\Before Manual Correction\' name '_Filtered.jpg'];
imwrite(img2,filteredName,'jpg')

B = bwboundaries(img2);
imshow(img0)
text(10,10,strcat('\color{green}Objects Found:',num2str(length(B))))
hold on

for k = 1:length(B)
boundary = B{k};
plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.2);
end

resultName=[fileFolder '\Before Manual Correction\' name '_Result.jpg'];
saveas(gcf,resultName,'jpg');

clf;
close;

end

