%%
% FilopodiaSegmentation.
% Copyright (C) 2018 B. Mattes, Y. Dang, S. Scholpp, R. Mikut, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and
% the following publication:
%
% Mattes, B., Dang, Y., Greicius, G., Kaufmann, L. T., Prunsche, B., 
% Rosenbauer, J., Stegmaier, J., Mikut, R., Özbek, S., Nienhaus, G. U., 
% Schug, A., Virshup D. M., Scholpp, S., "Wnt/PCP controls spreading of 
% Wnt/β-catenin signals by cytonemes in vertebrates". Elife, 7, e36953, 2018.
%
%%

function [wntImage, memImage, projectSettings] = ReadLifImage(fileName, seriesNumber, wntChannelNumber, memChannelNumber)

tmpImage = bfopen(fileName);

numSeries = size(tmpImage,1);
numPlanes = cell(numSeries, 1);
numSlices = cell(numSeries, 1);
numChannels = cell(numSeries, 1);
projectSettings = [];

for i=1:numSeries
    imageSize{i} = size(tmpImage{i,1}{1,1});
    currentMeta{i} = tmpImage{i,1}{1,2};
    splitString{i} = strsplit(currentMeta{i}, ';');

    for j=1:size(splitString{i},2)
        currentString = splitString{i}{j};
        if (~isempty(strfind(currentString, 'series ')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'series ', '')), '/');
            currentSeries = str2num(seriesInfo{1});
            numSeries = str2num(seriesInfo{2});
        end

        if (~isempty(strfind(currentString, 'plane ')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'plane ', '')), '/');
            currentPlane = str2num(seriesInfo{1});
            numPlanes{i} = str2num(seriesInfo{2});
        end

        if (~isempty(strfind(currentString, 'Z=')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'Z=', '')), '/');
            currentSlice = str2num(seriesInfo{1});
            numSlices{i} = str2num(seriesInfo{2});
        end

        if (~isempty(strfind(currentString, 'C=')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'C=', '')), '/');
            currentChannel = str2num(seriesInfo{1});
            numChannels{i} = str2num(seriesInfo{2});
        else
            numChannels{i} = 1;
        end
    end
end

if (nargin == 1)
    fh = figure;
    set(fh,'units','normalized','outerposition',[0 0 1 1])
    for i=1:numSeries
        subplot(ceil(numSeries/4), 4, i);
        imagesc(imadjust(tmpImage{i,1}{1,1}));
        if (isempty(numSlices{i}))
            title(['Series ' num2str(i) '/' num2str(numSeries) ': ' num2str(imageSize{i}(1)) 'x' num2str(imageSize{i}(2)) ', Channels: ' num2str(numChannels{i})]);
        else
            title(['Series ' num2str(i) '/' num2str(numSeries) ': ' num2str(imageSize{i}(1)) 'x' num2str(imageSize{i}(2)) 'x' num2str(numSlices{i}) ', Channels: ' num2str(numChannels{i})]);
        end
        colormap gray;
        axis equal;
    end

    %% ask the user about the voxel size
    projectSettings = inputdlg({'Series Number:', 'Wnt Channel Number:', 'Membrane Channel Number:', 'Voxel Size x (?m):','Voxel Size Y (?m):','Voxel Size Z (?m):', 'Use Edge Enhancement?:', 'Use Single Result File?'},...
    'Project Settings', [1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50], {'1', '1', '2', '0.24', '0.24', '0.67', '1', '1'});

    close(fh);
    seriesNumber = str2num(projectSettings{1});
    wntChannelNumber = str2num(projectSettings{2});
    memChannelNumber = str2num(projectSettings{3});
end

memImage = zeros(imageSize{seriesNumber}(1), imageSize{seriesNumber}(2), numSlices{seriesNumber});
wntImage = zeros(imageSize{seriesNumber}(1), imageSize{seriesNumber}(2), numSlices{seriesNumber});

%% copy the stacks 
for i=1:numPlanes{seriesNumber}
    
    currentMeta = tmpImage{seriesNumber,1}{i,2};
    splitString = strsplit(currentMeta, ';');
    for j=1:size(splitString,2)
        currentString = splitString{j};

        if (~isempty(strfind(currentString, 'Z=')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'Z=', '')), '/');
            currentSlice = str2num(seriesInfo{1});
            numSlices = str2num(seriesInfo{2});
        end

        if (~isempty(strfind(currentString, 'C=')))
            seriesInfo = strsplit(strtrim(strrep(currentString, 'C=', '')), '/');
            currentChannel = str2num(seriesInfo{1});
            numChannels = str2num(seriesInfo{2});
        else
            currentChannel = 1;
            numChannels = 1;
        end
    end
    
    if (currentChannel == wntChannelNumber)
        wntImage(:,:,currentSlice) = im2double(tmpImage{seriesNumber,1}{i,1});
    end
    if (currentChannel == memChannelNumber)
        memImage(:,:,currentSlice) = im2double(tmpImage{seriesNumber,1}{i,1});
    end
end
end