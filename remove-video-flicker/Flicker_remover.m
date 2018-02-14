%clear the screen and workspace
clear all;
clc;

%ask user to select video files
[file,folder] = uigetfile('*','Select .avi files','Multiselect','on');

%if only one file is selected (if 'file' is a string), convert to cell to
%be consistent with selecting multiple files
if isstr(file)==1;
    file={file};
end

numFiles=size(file,2);

mkdir('output_vids');

%loop each video file
for n=1:numFiles;
    
    %clear variables before processing the next video
    close all;
    clearvars -except file folder numFiles n
    
    %extract specific file name and load video
    [pathstr,filename,ext]=fileparts(fullfile(folder,file{n}));
    imgObj = VideoReader(fullfile(folder, file{n}));
    numFrames=imgObj.NumberofFrames;
    
    startFrame=1;
    
    outputVideo = VideoWriter(['output_vids/', filename, '.avi']);
    outputVideo.FrameRate=imgObj.FrameRate;
    open(outputVideo);
    
    %extract frames from object
    for i=startFrame:numFrames;

        img=read(imgObj, i);
        intensity(i)=mean(mean(mean(img)));
        
        %if current frame is not a flicker, write frame to vid
        if intensity(i)<90
            writeVideo(outputVideo,img);
            
            %make current frame available as img_previous
            img_previous=img;
            
        else %otherwise write the previous frame if current frame is not the first frame
            if i~=1
                writeVideo(outputVideo,img_previous);
            end
        end
    end
    close(outputVideo);
end;

%victory song
load handel;
player = audioplayer(y, Fs);
play(player);

sprintf('Completed')

