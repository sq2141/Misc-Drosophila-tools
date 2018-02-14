%% ----- Uses MaskData to measure fluorescence -----

%clear variable workspace and screen
clear all;
clc;

%ask user to select .mat data files
[file,folder] = uigetfile('*','Select .mat files','Multiselect','on');

%if only one file is selected (if 'file' is a string), convert to cell to
%be consistent with selecting multiple files
if isstr(file)==1;
    file={file};
end

%get number of files to process
numFiles=size(file,2);

for n=1:numFiles

    %close all open figures clear variables before processing the next video
    close all;
    clearvars -except file folder numFiles n
    
    %get file name
    [pathstr,filename]=fileparts(fullfile(folder,file{n}));
    
    %create output directories
    mkdir('Output_figures');
    mkdir('Output_tables');
    mkdir('Filtered');
    mkdir('Filtered',filename);
    mkdir('Filtered_minusCB/');
    mkdir('Filtered_minusCB/',filename);
    mkdir('Filtered_GreenOnly');
    mkdir('Filtered_GreenOnly/',filename);
    mkdir('Filtered_GreenOnly_minusCB');
    mkdir('Filtered_GreenOnly_minusCB/',filename);
    
    %load file
    load(fullfile(folder,file{n}));
    
    %declare tweak variables
    filterThreshold=0.25;
    xdim=512;
    ydim=512;
    
    %get number of frames
    numFrames=size(rawRed,2);
    
    %for each frame
    for i=1:numFrames
        
        %redesignate variables
        red=rawRed{i};
        gre=rawGre{i};
        roi=roiMask{i};
        cb=cellBodyMask{i};
        
        %preallocate array to store cropped images
        redROI=uint16(zeros([xdim ydim]));
        greROI=uint16(zeros([xdim ydim]));
        redCB=uint16(zeros([xdim ydim]));
        greCB=uint16(zeros([xdim ydim]));
   
        %crop roi region by scanning for 1's in binary mask
        for a=1:xdim
            for b=1:ydim
                if roi(a,b)==1
                    redROI(a,b)=red(a,b);
                    greROI(a,b)=gre(a,b);
                end 
            end
        end
        %crop cell body (CB) region by scanning for 1's in binary mask
        for a=1:xdim
            for b=1:ydim
                if cb(a,b)==1
                    redCB(a,b)=red(a,b);
                    greCB(a,b)=gre(a,b);
                end 
            end
        end
        
        %get non-zero fluorescence
        roiRedF(i)=mean(redROI(redROI~=0));
        roiGreF(i)=mean(greROI(greROI~=0));
        cbRedF(i)=mean(redCB(redCB~=0));
        cbGreF(i)=mean(greCB(greCB~=0));
        
        %% Further thresholded filtering
        
        %declare array for filtered data
        redROI_filtered=uint16(zeros([xdim ydim]));
        greROI_filtered=uint16(zeros([xdim ydim]));

        %threshold filter 
        redROI_filtered_mask=im2bw(redROI,filterThreshold);
        
        %crop filtered ROI by scanning for 1's in filtered binary mask
        for a=1:xdim
            for b=1:ydim
                if redROI_filtered_mask(a,b)==1
                    redROI_filtered(a,b)=red(a,b);
                    greROI_filtered(a,b)=gre(a,b);
                end 
            end
        end
        
        %get F from filtered ROI
        roiRedF_filtered(i)=mean(redROI_filtered(redROI_filtered~=0));
        roiGreF_filtered(i)=mean(greROI_filtered(greROI_filtered~=0));
        
        %% Exclude cell body
        
        %declare array for filtered and cb-subtraction data
        redROI_filtered_minusCB=uint16(zeros([xdim ydim]));
        greROI_filtered_minusCB=uint16(zeros([xdim ydim]));
        
        %crop filtered ROI by scanning for 1's in filtered binary mask and
        %excluding cell body
        for a=1:xdim
            for b=1:ydim
                if (redROI_filtered_mask(a,b)==1 && cb(a,b)==0)
                    redROI_filtered_minusCB(a,b)=red(a,b);
                    greROI_filtered_minusCB(a,b)=gre(a,b);
                end 
            end
        end
        
        %get F
        roiRedF_filtered_minusCB(i)=mean(redROI_filtered_minusCB(redROI_filtered_minusCB~=0));
        roiGreF_filtered_minusCB(i)=mean(greROI_filtered_minusCB(greROI_filtered_minusCB~=0));
        
        %create and save images
        h1=imshowpair(greROI_filtered,redROI_filtered);
        saveas(h1, ['Filtered/',filename,'/img',num2str(i),'.tif']);
        
        h2=imshowpair(greROI_filtered_minusCB,redROI_filtered_minusCB);
        saveas(h2, ['Filtered_minusCB/',filename,'/img',num2str(i),'.tif']);
        
        h3=imshow(greROI_filtered);
        saveas(h3, ['Filtered_GreenOnly/',filename,'/img',num2str(i),'.tif']);
        
        h4=imshow(greROI_filtered_minusCB);
        saveas(h4, ['Filtered_GreenOnly_minusCB/',filename,'/img',num2str(i),'.tif']);
        
        %display text to update progress
        string=sprintf(['Processed file ', num2str(n) ', frame ', num2str(i)]);
        disp(string)
    end
    
    %create time series graphs for this file
    figure;
    cbF=cbGreF./cbRedF;
    plot(cbF);
    title('Cell Body Fluorescence');
    saveas(gcf, ['Output_figures/',filename,'_cellBodyF.tif']);

    figure;
    roiF=roiGreF./roiRedF;
    plot(roiF);
    title('ROI Fluorescence');
    saveas(gcf, ['Output_figures/',filename,'_roiF.tif']);

    figure;
    roiF_filtered=roiGreF_filtered./roiRedF_filtered;
    plot(roiF_filtered);
    title('ROI Fluorescence (filtered out background)');
    saveas(gcf, ['Output_figures/',filename,'_roiF_filtered.tif']);

    figure;
    roiF_filtered_minusCB=roiGreF_filtered_minusCB./roiRedF_filtered_minusCB;
    plot(roiF_filtered_minusCB);
    title('ROI-CB Fluorescence (filtered out background)');
    saveas(gcf, ['Output_figures/',filename,'_roiF_filtered_minusCB.tif']);
    
    %create table for export
    table(1:numFrames,1)=cbRedF;
    table(1:numFrames,2)=cbGreF;
    table(1:numFrames,3)=roiRedF;
    table(1:numFrames,4)=roiGreF;
    table(1:numFrames,5)=roiRedF_filtered;
    table(1:numFrames,6)=roiGreF_filtered;
    table(1:numFrames,7)=roiRedF_filtered_minusCB;
    table(1:numFrames,8)=roiGreF_filtered_minusCB;
    
    colHeader={'CB Red','CB Green','ROI Red','ROI Green','ROI Red Filtered','ROI Green Filtered','ROI Red Filtered, excluded CB','ROI Green Filtered, excluded CB'};
    
    xlswrite(['Output_tables/',filename,'.xlsx'],colHeader,'Sheet1','A1');
    xlswrite(['Output_tables/',filename,'.xlsx'],table,'Sheet1','A2');
end

