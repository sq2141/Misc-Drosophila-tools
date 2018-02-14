%% ------------- Instructions for input images ------------- 
%
% - Name .nd2 video file a number (e.g. 1)
% - In NIS viewer, export to a folder named the video number (e.g. 1)
% - Export as TIF
% - File prefix is video number followed by underscore (e.g. 1_)
% - Index order is c, t
% - Mono image for each channel
% - Scale 12 bit to 16 bit
% - Put folder in the input directory
%
%% ---------------------------------------------------------
%clear variable workspace and screen
clear all;
clc;

%ask user to select .nd2 video files
[file,folder] = uigetfile('*','Select .avi files','Multiselect','on');

%if only one file is selected (if 'file' is a string), convert to cell to
%be consistent with selecting multiple files
if isstr(file)==1;
    file={file};
end

numFiles=size(file,2);

%loop for each video file
for n=1:numFiles;
   
    %close all open figures clear variables before processing the next video
    close all;
    clearvars -except file folder numFiles n
    
    %declare tweaking variable values
    threshModifier=0.1;
    rectModifier=0;
    
    %get file name
    [pathstr,filename]=fileparts(fullfile(folder,file{n}));
    
    %create main output folders and filename subfolders
    mkdir('CellBody');
    mkdir('CellBody/',filename);
    mkdir('ROI');
    mkdir('ROI/',filename');
    mkdir('_maskData');
    
    %get number of .tif files from the input folder
    numFrames=(size(dir(['_input/',filename,'/*.tif']),1))/2;
    
    %read the first frame's red channel image
    imgNameRed=[filename, '_c2t',sprintf('%03d',1)];
    rawRed{1}=imread(['_input/',filename,'/', imgNameRed,'.tif']);
    
    %ask user to select cell body on this image
    raw=rawRed{1};
    imshow(raw);
    title('Click the cell body');
    [userClickX,userClickY] = ginput(1);
    
    %ask user to draw ROI
    title('Draw the ROI');
    roi = imfreehand();
    roiMask{1} = roi.createMask();

    %convert first image to bw and apply a size filter to remove objects
    %smaller than 30 pixels
    bw=im2bw(raw, graythresh(raw)+threshModifier);
    bw=bwareaopen(bw,30);

    %isolate cell body from the bw image using the coordinates of the user's mouse click
    cellBody=bwselect(bw, userClickX, userClickY);
    
    %define centroidIdx as the cell body's centroid
    centroid = regionprops(cellBody,'centroid');
    centroidIdx(1,1:2) = centroid.Centroid;
    
    %create a bounding box around cell body
    cellBodyRect=drawRect(cellBody, rectModifier);
    rectBounds=bwboundaries(cellBodyRect);
    rectxy = rectBounds{1}; 
    
    %for each frame
    for i=1:numFrames;
        %construct frame names for green and red files
        imgNameGre=[filename, '_c1t',sprintf('%03d',i)];
        imgNameRed=[filename, '_c2t',sprintf('%03d',i)];
        
        %load green and red channels
        rawGre{i}=imread(['_input/',filename,'/', imgNameGre,'.tif']);
        rawRed{i}=imread(['_input/',filename,'/', imgNameRed,'.tif']);
                
        %define current red frame to be bw
        bw=im2bw(rawRed{i}, graythresh(raw)+threshModifier);
        bw=bwareaopen(bw,30);
        
        %get current cellbody using previous frames's centroid
        if i~=1
            cellBody=bwselect(bw, centroidIdx(i-1,1), centroidIdx(i-1,2));
        end
        
        %if cellBody couldn't be picked up using centroid of the previous
        %frame, use the previous frames's rect
        k=1;
        while size((cellBody(cellBody==1)),1)==0
            cellBody=bwselect(bw, rectxy(k,2), rectxy(k,1));
            k=k+1;
        end 
        
        %create new centroid from current frame's cell body
        centroid = regionprops(cellBody,'centroid');
        centroidIdx(i,1:2) = centroid.Centroid;
        
        %create new indices of bounding box boundary
        cellBodyRect=drawRect(cellBody, rectModifier);
        rectBounds=bwboundaries(cellBodyRect);
        rectxy = rectBounds{1};
        
        %if not the first frame, also shift the roi
        if i~=1;
            %calculate shift in centroid
            shiftX = round(centroidIdx(i,1) - centroidIdx(i-1,1));
            shiftY = round(centroidIdx(i,2) - centroidIdx(i-1,2));
            
            %apply shift to roi
            roiMask{i}=circshift(roiMask{i-1}, [shiftY shiftX]);
        end
        
        %show cell body overlaid on red image
        h1=imshowpair(rawRed{i}, cellBody);
        saveas(h1, ['CellBody/',filename,'/img',num2str(i),'.tif']);
        
        %show ROI overlaid on red image
        h2=imshowpair(rawRed{i}, roiMask{i});
        saveas(h2, ['ROI/',filename,'/img',num2str(i),'.tif']);
        
        %display text to update progress
        string=sprintf(['Processed file ', num2str(n) ', frame ', num2str(i)]);
        disp(string)
        
        %store current cellBody mask in an array
        cellBodyMask{i}=cellBody;
    end;

    %save ROI and cell body masks, and original red and green images
    save(['_maskData/' filename '.mat'], 'roiMask', 'cellBodyMask', 'rawRed', 'rawGre');
end;