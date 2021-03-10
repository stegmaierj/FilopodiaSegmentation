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

global settings;

currentImage = settings.currentImage;

[path, file, ext] = fileparts(settings.rfpImageFileNames(currentImage+2).name);
%set(settings.mainFigure,'Name', ['File: ' file ext],'NumberTitle','off');

figure(settings.mainFigure);
set(gcf,'Pointer','arrow');
axes(settings.rfpAxes);
cla;
set(gca,'Color','black');

if (settings.colormapId == 1)
    colormap parula;
elseif (settings.colormapId == 2)
    colormap jet;
elseif (settings.colormapId == 3)
    colormap hsv;
elseif (settings.colormapId == 4)
    colormap gray;
elseif (settings.colormapId == 5)
    colormap pink;
elseif (settings.colormapId == 6)
    colormap hot;
elseif (settings.colormapId == 7)
    colormap bone;
elseif (settings.colormapId == 8)
    colormap cool;
end
    
%% perform clustering of the 
if (settings.clusterRadius{settings.currentImage} > 0)
    currentLinkage = linkage([settings.originalEndPoints{settings.currentImage}(:,3), settings.originalEndPoints{settings.currentImage}(:,4)], 'ward', 'euclidean');
    currentClustering = cluster(currentLinkage, 'Cutoff',settings.clusterRadius{settings.currentImage},'Criterion','distance');
    clusterIndices = unique(currentClustering);
    clusterMeans = [];
    clusterIntensities = [];
    for i=clusterIndices'
        clusterMeans = [clusterMeans; i, 0, round(mean(settings.originalEndPoints{settings.currentImage}(currentClustering == i,3:4),1)), 0, 0, 0,max(max(settings.originalEndPoints{settings.currentImage}(currentClustering == i,end),1));];
    end
    settings.endPoints{settings.currentImage} = clusterMeans;
else
  %  settings.endPoints{settings.currentImage} = settings.originalEndPoints{settings.currentImage};
end
    
if (settings.singleViewId==1)
    settings.imageHandle = imagesc(settings.rfpImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (RFP Channel, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
elseif (settings.singleViewId==2)
    settings.imageHandle = imagesc(settings.gfpImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (GFP Channel, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
elseif (settings.singleViewId==3)
    settings.imageHandle = imagesc(settings.bfImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (BF Channel, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
elseif (settings.singleViewId==4)
    settings.imageHandle = imagesc(settings.objectnessImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (Objectness Image, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
elseif (settings.singleViewId==5)
    settings.imageHandle = imagesc(settings.binaryImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (Binary Image, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
elseif (settings.singleViewId==6)
    settings.imageHandle = imagesc(settings.skeletonImage{currentImage});
    set(settings.mainFigure,'Name', ['File: ' file ext ' (Skeleton Image, ClusterRadius: ' num2str(settings.clusterRadius{settings.currentImage}) ', Wnt Threshold: ' num2str(settings.wntPositiveThreshold) ')'],'NumberTitle','off');
end

set(gca, 'Units', 'normalized', 'Position', [0,0,1,1]);

if (settings.axesEqual == true)
    axis equal;
else
    axis normal;
    axis tight;
    set(gca, 'Units', 'normalized', 'Position', [0,0,1,1]);
end

hold on;
axis off

plot(settings.endPoints{currentImage}(:,3), settings.endPoints{currentImage}(:,4), '.m');

selectedIndices = settings.endPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage};
selectedPerimeterIndices = settings.perimeterPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage};

if (~isempty(settings.selectedEndPoints{currentImage}))
    plot(settings.selectedEndPoints{currentImage}(:,3), settings.selectedEndPoints{currentImage}(:,4), 'or');
end
plot(settings.perimeterPoints{currentImage}(selectedPerimeterIndices,3), settings.perimeterPoints{currentImage}(selectedPerimeterIndices,4), '.c');
plot(settings.perimeterPoints{currentImage}(~selectedPerimeterIndices,3), settings.perimeterPoints{currentImage}(~selectedPerimeterIndices,4), '.c');
plot(mean(settings.perimeterPoints{currentImage}(selectedPerimeterIndices,3)), mean(settings.perimeterPoints{currentImage}(selectedPerimeterIndices,4)), '*r');

if (isfield(settings, 'axisRange') && ~isempty(settings.axisRange))
    axis(settings.axisRange);
end

numCells = size(settings.currentFilopodia{settings.currentImage},1);
numFilopodiaCurrentCell = 0;
numWntPositiveFilopodia = 0;
averageLengthCurrentCell = 0;
minLengthCurrentCell = inf;
maxLengthCurrentCell = 0;
minGFPIntensity = inf;
maxGFPIntensity = 0;

for j=1:length(settings.currentFilopodia{settings.currentImage})
    %% continue if no filopodia were extracted yet.
    if (isempty(fieldnames(settings.currentFilopodia{settings.currentImage})))
        continue;
    end
        
    if (~isempty(settings.currentFilopodia{settings.currentImage}(j).positions))
        if (settings.currentCell{settings.currentImage} == settings.currentFilopodia{settings.currentImage}(j).cellId)
            plot(settings.currentFilopodia{settings.currentImage}(j).positions(:,1), ...
                settings.currentFilopodia{settings.currentImage}(j).positions(:,2), '-r');

            %% update the statistics values
            numFilopodiaCurrentCell = numFilopodiaCurrentCell + 1;
            averageLengthCurrentCell = averageLengthCurrentCell + settings.currentFilopodia{settings.currentImage}(j).length;
            minLengthCurrentCell = min(minLengthCurrentCell, settings.currentFilopodia{settings.currentImage}(j).length);
            maxLengthCurrentCell = max(maxLengthCurrentCell, settings.currentFilopodia{settings.currentImage}(j).length);
            minGFPIntensity = min(minGFPIntensity, settings.currentFilopodia{settings.currentImage}(j).gfpIntensity);
            maxGFPIntensity = max(maxGFPIntensity, settings.currentFilopodia{settings.currentImage}(j).gfpIntensity);
            
            if (settings.currentFilopodia{settings.currentImage}(j).gfpIntensity > settings.wntPositiveThreshold)
                numWntPositiveFilopodia = numWntPositiveFilopodia + 1;
                plot(settings.currentFilopodia{settings.currentImage}(j).positions(end,1), ...
                     settings.currentFilopodia{settings.currentImage}(j).positions(end,2), '*g');
                plot(settings.currentFilopodia{settings.currentImage}(j).positions(end,1), ...
                    settings.currentFilopodia{settings.currentImage}(j).positions(end,2), 'or');
            end            
        else
            plot(settings.currentFilopodia{settings.currentImage}(j).positions(:,1), ...
                settings.currentFilopodia{settings.currentImage}(j).positions(:,2), '-g');
        end
    end
end

currentAxes = axis;
normalizedScaleBarOffset = settings.scaleBarOffset ./ fliplr([(currentAxes(4) - currentAxes(3)), (currentAxes(2) - currentAxes(1))]);
heightOffset = 0.02 * (currentAxes(4) - currentAxes(3));
widthOffset =  0.02 * (currentAxes(2) - currentAxes(1));
rectangle('Position',[currentAxes(1)+widthOffset + settings.scaleBarOffset(1),currentAxes(4)-2*heightOffset - settings.scaleBarOffset(2),settings.scaleBarSize / settings.pixelToMicrons, 0.25*heightOffset], 'FaceColor', [1 1 1], 'EdgeColor', 'w', 'LineWidth', 1);
text('String', [num2str(settings.scaleBarSize) ' µm'], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.02 0.02] + normalizedScaleBarOffset);

%% compute the average length
averageLengthCurrentCell = averageLengthCurrentCell / numFilopodiaCurrentCell;

text('String', ['Current Cell: ' num2str(settings.currentCell{settings.currentImage})], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.98]);
text('String', ['Number of Filopodia: ' num2str(numFilopodiaCurrentCell)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.93]);
text('String', ['Average Length (µm): ' num2str(averageLengthCurrentCell * settings.pixelToMicrons)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.88]);
text('String', ['Minimum Length (µm): ' num2str(minLengthCurrentCell * settings.pixelToMicrons)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.83]);
text('String', ['Maximum Length (µm): ' num2str(maxLengthCurrentCell * settings.pixelToMicrons)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.78]);
text('String', ['Min / Max GFP Intensity: ' num2str(minGFPIntensity) ' / ' num2str(maxGFPIntensity)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.73]);
text('String', ['Wnt Positive Cells (Wnt Thresh.: ' num2str(settings.wntPositiveThreshold) '): ' num2str(numWntPositiveFilopodia)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.68]);
